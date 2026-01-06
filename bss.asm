;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; BSS.ASM: Uninitialized data segment declarations
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

include common.inc

public InitBSS

public commandLineBuffer
public argv
public argc

;;================================================
;; Initialization code
;;================================================

_INIT_TEXT  segment byte public 'CODE_INIT'

InitBSS proc near
    lsr es, ds
    assume ds: DGROUP, es: DGROUP

    mov di, offset START_OF_INIT_BSS
    xor al, al
    mov cx, (offset END_OF_INIT_BSS - offset START_OF_INIT_BSS + 1) SHR 1
    rep stosw
    ret

    assume ds: nothing, es: nothing
InitBSS endp

_INIT_TEXT  ends

;;================================================
;; Initialization uninitialized data
;;================================================

_INIT_BSS   segment byte public 'BSS_INIT'

START_OF_INIT_BSS           label byte

commandLineBuffer           db 256 dup (?)
argv                        dw 128 dup (?)
argc                        dw ?

END_OF_INIT_BSS             label byte

_INIT_BSS   ends

end
