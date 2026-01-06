;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; COMMON.INC: Build configuration and includes
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

.8086
.model tiny

;;================================================
;; Segment definitions
;;================================================

; Resident code segment
_TEXT       segment word public 'CODE'
_TEXT       ends

; Resident data segment
_DATA       segment word public 'DATA'
_DATA       ends

; Initialization code segment
_INIT_TEXT  segment byte public 'CODE_INIT'
_INIT_TEXT  ends

; Initialization data segment
_INIT_DATA  segment byte public 'DATA_INIT'
_INIT_DATA  ends

; Initialization uninitialized data segment
_INIT_BSS   segment byte public 'BSS_INIT'
_INIT_BSS   ends

DGROUP      group   _TEXT, _DATA, _INIT_TEXT, _INIT_DATA, _INIT_BSS

;;================================================
;; Build configuration
;;================================================

assume  nothing
assume  cs: DGROUP

ifdef ??version
    proto equ <procdesc>

    locals
endif

include cpumacs.inc
include dosmacs.inc
