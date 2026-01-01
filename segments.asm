;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; SEGMENTS.ASM: Define segments and, importantly, link order
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

;;================================================
;; Segment definitions
;;================================================

; Resident code segment
_TEXT       segment byte public 'CODE'
_TEXT       ends

; Resident data segment
_DATA       segment byte public 'DATA'
_DATA       ends

; Initialization code segment
_INIT_TEXT  segment para public 'INITCODE'
_INIT_TEXT  ends

; Initialization data segment
_INIT_DATA  segment byte public 'INITDATA'
_INIT_DATA  ends

; Initialization uninitialized data segment
_INIT_BSS   segment byte public 'INITBSS'
_INIT_BSS   ends

DGROUP      group   _TEXT, _DATA, _INIT_TEXT, _INIT_DATA, _INIT_BSS

end
