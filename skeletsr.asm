;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; SKELETSR.ASM: Main program code
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

include common.inc

public  Psp
public  HelpMsg

extrn   MultiplexId:                byte
extrn   SavedMultiplexVector:       dword
extrn   StartupAction:              byte
extrn   START_OF_NONRESIDENT_AREA:  byte
extrn   START_OF_INIT_BSS:          byte
extrn     END_OF_INIT_BSS:          byte

MultiplexInterruptHandler           proto far
ParseCommandLine                    proto near

ExtraParagraphs                     equ 4           ; extra paragraphs to allocate for resident portion

;;================================================
;; Resident data
;;================================================

.data

;; PSP segment
Psp                                 dw ?

;;================================================
;; Resident code
;;================================================

.code

;;================================================
;; Program entry point for tiny model
;;================================================

if @Model EQ 1
    org 100h

    Start proc near
        jmp Main
    Start endp
endif

;;================================================
;; Initialization code
;;================================================

_INIT_TEXT segment byte public 'CODE_INIT'

;;================================================
;; Main: Main program
;;
;; Inputs:   none
;; Outputs:  AL = 0 on success
;;           AL = 1 on failure
;; Clobbers: none
Main proc near
    assume ds: DGROUP

    ;; --- Ensure direction flag is clear ---
    cld

    ;; --- Save PSP ---
    mov cs:[Psp], ds

    ;; --- Clear BSS ---
    call InitBSS

    ;; --- Find the multiplex ID of an existing instance, if any ---
    call FindOurMultiplexId

    ;; --- Examine command line parameters ---
    call ParseCommandLine

    xor bh, bh
    mov bl, [StartupAction]
    cmp bx, 2
    ja @@InvalidParameter

    shl bx, 1
    call [bx + StartupActionDispatchTable]

    ; should never get here, but just in case...
    DosTerminateProcess 0

@@InvalidParameter:
    ;; --- Print usage and exit ---
    DosTerminateWithMessage 4, HelpMsg
Main endp

;;================================================
;; InstallCommand: Install the TSR
;;
;; Inputs:   none
;; Outputs:  none (never returns)
InstallCommand proc near
    ;; --- Are we already installed? ---
    cmp [MultiplexId], 0
    jne @@AlreadyInstalled

    ;; --- Search for a free multiplex ID and store it ---
    call FindFreeMultiplexId
    jnc @@GotFreeId

    ;; --- No free ID found ---
    ; Complain and exit
    DosTerminateWithMessage 1, NoFreeIdMsg

    ;; --- Print 'already installed' message and exit
@@AlreadyInstalled:
    DosTerminateWithMessage 0, AlreadyInstalledMsg

@@GotFreeId:
    ;; --- Save original multiplex vector ---
    DosGetVector 2Fh
    mov word ptr [SavedMultiplexVector],     bx
    mov word ptr [SavedMultiplexVector + 2], es

    ;; --- Set our multiplex interrupt handler ---
    DosSetVector 2Fh, ds, <offset MultiplexInterruptHandler>

    ;; --- Print multiplex ID message ---
    call FormatMultiplexId
    DosWriteString MultiplexIdMsg

    ;; --- Print "successfully installed" message ---
    DosWriteString SuccessfullyInstalledMsg

    ;; --- Free environment, if present ---
    mov ax, ds:[2Ch]                                ; AX = block to free: the environment segment
    cmp ax, -1                                      ; no segment allocated?
    je @@CalcResident
    DosFreeAllocatedMemory ax
    mov word ptr ds:[2Ch], -1                       ; Clear environment segment in PSP

    ;; --- Calculate memory footprint of resident portion ---
@@CalcResident:
    mov dx, offset (START_OF_NONRESIDENT_AREA + 15)
    mov cl, 4                                       ; convert to paragraphs
    shr dx, cl
if ExtraParagraphs GT 0
    add dx, ExtraParagraphs                         ; add extra paragraphs for run-time needs
endif

    ;; --- Terminate and stay resident ---
    DosKeepProgram dx
InstallCommand endp

;;================================================
;; UninstallCommand: Uninstall the TSR
;;
;; Inputs:   none
;; Outputs:  none (never returns)
UninstallCommand proc near
    ; Get our multiplex ID
    cmp [MultiplexId], 0
    je @@NotInstalled

    ; Format the multiplex ID into MultiplexIdMsg and print it
    call FormatMultiplexId
    DosWriteString MultiplexIdMsg

    ; Call our uninstall subfunction
    mov ah, [MultiplexId]
    mov al, 1
    int 2Fh

    or al, al
    jnz @@UninstalledFailed

    DosTerminateWithMessage 0, SuccessfullyUninstalledMsg

@@NotInstalled:
    DosTerminateWithMessage 2, NotInstalledMsg

@@UninstalledFailed:
    DosTerminateWithMessage 3, UninstallFailedMsg
UninstallCommand endp

;;================================================
;; InitBSS: Initialize the BSS segment to zero
;;
;; Inputs:   none
;; Outputs:  none
;; Clobbers: AX, CX, DI, ES
InitBSS proc near
    lsr es, ds
    assume es: DGROUP

    mov di, offset START_OF_INIT_BSS
    xor al, al
    mov cx, offset END_OF_INIT_BSS
    sub cx, di
    shr cx, 1
    rep stosw
    ret

    assume es: nothing
InitBSS endp

;;================================================
;; FindFreeMultiplexId: Find a free multiplex ID in range 0C0h-0FFh
;;
;; Inputs:   none
;; Outputs:  CF = 0 if successful
;;             Free ID stored in MultiplexId
;;           CF = 1 if no free ID found
;; Clobbers: AX, CX
FindFreeMultiplexId proc near
    mov cx, 0FF00h ; start at 0FFh and work down to 0C0h

@@FindFreeId:
    mov ax, cx
    push cx
    int 2Fh
    pop cx
    or al, al
    jnz @@NextId                                    ; if AL is not 0, ID is not free

    mov [MultiplexId], ch
    clc                                             ; clear carry to indicate success
    ret

@@NextId:
    dec ch
    cmp ch, 0C0h
    jae @@FindFreeId

    ;; --- No free ID found ---
    stc                                             ; set carry to indicate failure
    ret
FindFreeMultiplexId endp

;;================================================
;; FindOurMultiplexId: Find a multiplex ID with our signature in range 0C0h-0FFh
;;
;; Inputs:   none
;; Outputs:  Found ID stored in MultiplexId on success
;; Clobbers: AX, CX, DX, SI, DI
FindOurMultiplexId proc near
    mov cx, 0C000h ; start at 0C0h and work up to 0FFh

@@FindOurId:
    mov ax, cx
    push cx
    int 2Fh
    pop cx
    or al, al
    jz @@NextId                                     ; if AL is 0, ID is not in use
    cmp si, 'ZI'                                    ; ZMP signature in SI:DI -- 'ZIVE'
    jne @@NextId
    cmp di, 'VE'
    jne @@NextId
    cmp dx, 'SK'                                    ; TSR signature in DX -- 'SK'
    je @@Found

@@NextId:
    inc ch
    jnz @@FindOurId

    ;; --- Our ID not found ---
@@NotFound:
    ret

    ;; --- Our ID found ---
@@Found:
    mov [MultiplexId], ch
    ret
FindOurMultiplexId endp

;;================================================
;; FormatMultiplexId: Format the multiplex ID in CH as two ASCII hex digits at DS:BX
;;
;; Inputs:   CH    =  multiplex ID
;; Outputs:  DS:BX => two ASCII hex digits representing the multiplex ID
;; Clobbers: none
FormatMultiplexId proc near
    multipush ax, bx

    ; convert multiplex ID to hex
    mov ah, ds:[MultiplexId]
    call ByteToHex

    ; store digits into message
    mov bx, offset MultiplexIdHexDigits
    mov [bx], ah
    mov [bx + 1], al

    multipop bx, ax
    ret
FormatMultiplexId endp

;;================================================
;; ByteToHex: Convert a byte in AH to its ASCII hex representation in AH and AL
;;
;; Inputs:   AH = byte to convert
;; Outputs:  AH = ASCII hex digit for high nibble
;;           AL = ASCII hex digit for low nibble
;; Clobbers: none
ByteToHex proc near
    ; stretch byte to word (1200h => 0102h)
    push cx
    mov cl, 4
    shr ax, cl
    shr al, cl
    pop cx

    ; convert to ASCII hex
    add ax, 3030h

    ; adjust high nibble if >9
    cmp ah, 39h
    jbe @@CheckLowNibble

    add ah, 7

@@CheckLowNibble:
    ; adjust low nibble if >9
    cmp al, 39h
    jbe @@Done

    add al, 7

@@Done:
    ret
ByteToHex endp

_INIT_TEXT ENDS

;;================================================
;; Initialization data
;;================================================

_INIT_DATA segment byte public 'DATA_INIT'

;; Messages
NoFreeIdMsg                 db 'No free multiplex ID found. Terminating.',       13, 10, '$'
MultiplexIdMsg              db 'Using multiplex ID '
MultiplexIdHexDigits        db '00h.',                                           13, 10, '$'
SuccessfullyInstalledMsg    db 'SkeleTSR successfully installed.',               13, 10, '$'
SuccessfullyUninstalledMsg  db 'SkeleTSR successfully uninstalled.',             13, 10, '$'
UninstallFailedMsg          db 'SkeleTSR uninstall failed.',                     13, 10, '$'
NotInstalledMsg             db 'SkeleTSR is not installed.',                     13, 10, '$'
HelpMsg                     db 'Usage: SkeleTSR [/i | /u | /?]',                 13, 10
                            db '  /i    Install SkeleTSR (default).',            13, 10
                            db '  /u    Uninstall SkeleTSR.',                    13, 10
                            db '  /?    Display this help message.',             13, 10, '$'
AlreadyInstalledMsg         db 'SkeleTSR is already installed. Terminating.',    13, 10, '$'

StartupActionDispatchTable  dw InstallCommand       ; action 0: default
                            dw InstallCommand       ; action 1: install
                            dw UninstallCommand     ; action 2: uninstall

_INIT_DATA ends

;;================================================
;; The end
;;================================================

if @Model EQ 1
    EndSym equ <Start>
else
    EndSym equ <Main>
endif
end EndSym
