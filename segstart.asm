;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; SEGSTART.ASM: Define START_OF_ symbols
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

include common.inc

public START_OF_TEXT
public START_OF_DATA
public START_OF_INIT_TEXT
public START_OF_INIT_DATA
public START_OF_INIT_BSS

public START_OF_NONRESIDENT_AREA

_TEXT                       segment word public 'CODE'
START_OF_TEXT               label byte
_TEXT                       ends

_DATA                       segment word public 'DATA'
START_OF_DATA               label byte
_DATA                       ends

_INIT_TEXT                  segment byte public 'CODE_INIT'
START_OF_INIT_TEXT          label byte
START_OF_NONRESIDENT_AREA   label byte
_INIT_TEXT                  ends

_INIT_DATA                  segment byte public 'DATA_INIT'
START_OF_INIT_DATA          label byte
_INIT_DATA                  ends

_INIT_BSS                   segment byte public 'BSS_INIT'
START_OF_INIT_BSS           label byte
_INIT_BSS                   ends

end
