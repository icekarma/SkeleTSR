;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; MPLEX.ASM: Multiplex interrupt interface implementation
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

include common.inc

public MultiplexId
public SavedMultiplexVector

public MultiplexInterruptHandler

extrn Psp: word

;;================================================
;; Resident data
;;================================================

.data

;; Dispatch table for multiplex subfunctions
MultiplexDispatchTable  dw InstallationCheck ; 00h
                        dw Uninstall         ; 01h

;; Saved multiplex (interrupt 2Fh) vector
SavedMultiplexVector    dd ?

;; Multiplex ID
MultiplexId             db 0

;;================================================
;; MultiplexInterruptHandler: Our multiplex interrupt handler
;;
;; Inputs:   AH = multiplex ID
;;           AL = subfunction
;; Outputs:  AL = result code
;; Clobbers: none
MultiplexInterruptHandler proc far
    ; Is this interrupt for us?
    cmp ah, cs:[MultiplexId]                        ; check multiplex ID
    jne short @@ChainToSavedHandler                 ; not for us, chain to saved handler

    ; Clear direction flag; enable interrupts
    cld
    sti

    ; Check subfunction
    cmp al, 1
    ja @@UnknownFunction

    ; Dispatch to handler
    push bx
    mov bl, al
    xor bh, bh
    shl bx, 1
    call word ptr cs:[bx + MultiplexDispatchTable]
    pop bx
    iret

@@ChainToSavedHandler:
    jmp dword ptr cs:[SavedMultiplexVector]

@@UnknownFunction:
    mov al, 01h
    iret
MultiplexInterruptHandler endp

;;================================================
;; InstallationCheck: Respond to Installation Check subfunction
;;
;; Inputs:   none
;; Outputs:  AL    = 0FFh to indicate installed
;;           SI:DI = ZMP signature 'ZIVE'
;;           DX    = TSR signature 'SK'
;; Clobbers: none
InstallationCheck proc near
    mov al, 0FFh ; Indicate installed
    mov si, 'ZI' ; ZMP signature in BX:DX -- 'ZIVE'
    mov di, 'VE'
    mov dx, 'SK' ; TSR signature in DX -- 'SK'
    ret
InstallationCheck endp

;;================================================
;; Uninstall: Respond to Uninstall subfunction, uninstalling our TSR if possible
;;
;; Inputs:   none
;; Outputs:  AL = 0 on success
;;           AL = 1 on failure
;; Clobbers: none
Uninstall proc near
    multipush ax, dx, ds, es

    ;;================================================
    ;; Can we uninstall?
    ;;================================================

    ; Does the multiplex vector still point to us?
    DosGetVector 2Fh
    mov ax, cs
    mov dx, es
    cmp dx, ax
    jne @@CantUninstall
    cmp bx, offset cs:MultiplexInterruptHandler
    jne @@CantUninstall

    ;;================================================
    ;; Yes; can uninstall
    ;;================================================

    ; Restore original multiplex vector
    lds dx, dword ptr cs:[SavedMultiplexVector]
    DosSetVector 2Fh, ds, dx

    ; Free PSP and our resident code/data
    mov es, word ptr cs:[Psp]
    mov ah, 49h
    int 21h

    ; Return success
    multipop es, ds, dx, ax
    xor al, al
    ret

    ;;================================================
    ;; No; cannot uninstall
    ;;================================================

@@CantUninstall:
    ; Return failure
    multipop es, ds, dx, ax
    mov al, 01h
    ret
Uninstall endp

; Initialization code segment
_INIT_TEXT  segment byte public 'INITCODE'
_INIT_TEXT  ends

; Initialization data segment
_INIT_DATA  segment byte public 'INITDATA'
_INIT_DATA  ends

; Initialization uninitialized data segment
_INIT_BSS   segment byte public 'INITBSS'
_INIT_BSS   ends

end
