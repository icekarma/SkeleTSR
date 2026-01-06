;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; SKELETSR.ASM: Main program code
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

include common.inc

public  Psp
public  START_OF_NONRESIDENT_AREA

extrn   MultiplexId:                byte
extrn   SavedMultiplexVector:       dword

ifdef ??version
MultiplexInterruptHandler           procdesc far
else
MultiplexInterruptHandler           proto far
endif

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

_INIT_TEXT segment byte public 'INITCODE'

START_OF_NONRESIDENT_AREA label byte

;;================================================
;; Main: Main program
;;
;; Inputs:   none
;; Outputs:  AL = 0 on success
;;           AL = 1 on failure
;; Clobbers: none
Main proc near
    ;; --- Ensure direction flag is clear ---
    cld

    ;; --- Save PSP ---
    mov cs:[Psp], ds

    ;; --- Set up segment registers ---
if @Model EQ 1
    ; only load DS in tiny memory model -- other models have it set up already
    lsr ds, cs
endif
    assume ds: DGROUP
    lsr es, ds
    assume es: DGROUP

    ;; --- Clear BSS ---
    xor ax, ax
    mov di, offset START_OF_INIT_BSS
    mov cx, (offset END_OF_INIT_BSS - offset START_OF_INIT_BSS + 1) SHR 1
    rep stosw

    ;; --- Find the multiplex ID of an existing instance, if any ---
    call FindOurMultiplexId

    ;; --- Examine command line parameters ---
    call ParseCommandLine
    jc @@DoInstall

    cmp ax, 1
    je @@DoUninstall

    ;; --- Print usage and exit ---
    DosTerminateWithMessage 4, HelpMsg

    ;; --- Install the TSR ---
@@DoInstall:
    jmp InstallCommand

    ;; --- Uninstall the TSR ---
@@DoUninstall:
    jmp UninstallCommand
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

    ;; --- Free environment ---
    mov ax, ds:[2Ch]                                ; AX = block to free: the environment segment
    cmp ax, -1                                      ; no segment allocated?
    je @@CalcResident

    mov es, ax                                      ; ES = block to free
    mov ah, 49h                                     ; Free Block
    int 21h                                         ; Call DOS

    mov word ptr ds:[2Ch], -1                       ; Clear environment segment in PSP

    ;; --- Calculate memory footprint of resident portion ---
@@CalcResident:
    mov dx, offset (START_OF_NONRESIDENT_AREA + 15)
    mov cl, 4                                       ; convert to paragraphs
    shr dx, cl
    add dx, ExtraParagraphs                         ; add extra paragraphs for run-time needs

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

_INIT_DATA segment byte public 'INITDATA'

;; Messages
NoFreeIdMsg                 db 'No free multiplex ID found. Terminating.',       13, 10, '$'
MultiplexIdMsg              db 'Using multiplex ID '
MultiplexIdHexDigits        db '00h.',                                           13, 10, '$'
SuccessfullyInstalledMsg    db 'SkeleTSR successfully installed.',               13, 10, '$'
SuccessfullyUninstalledMsg  db 'SkeleTSR successfully uninstalled.',             13, 10, '$'
UninstallFailedMsg          db 'SkeleTSR uninstall failed.',                     13, 10, '$'
NotInstalledMsg             db 'SkeleTSR is not installed.',                     13, 10, '$'
HelpMsg                     db 'Usage: SkeleTSR [/u] [/?]',                      13, 10
                            db '  /u    Uninstall SkeleTSR if it is installed.', 13, 10
                            db '  /?    Display this help message.',             13, 10, '$'
AlreadyInstalledMsg         db 'SkeleTSR is already installed. Terminating.',    13, 10, '$'

_INIT_DATA ends

;;================================================
;; Initialization uninitialized data
;;================================================

_INIT_BSS segment byte public 'INITBSS'
_INIT_BSS ends

;;================================================
;; The end
;;================================================

if @Model EQ 1
    EndSym equ <Start>
else
    EndSym equ <Main>
endif
end EndSym
