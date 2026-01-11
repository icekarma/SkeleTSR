;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; BSS.ASM: Uninitialized data segment declarations
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

include common.inc

public commandLineBuffer
public argv
public argc

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
