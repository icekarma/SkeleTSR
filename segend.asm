;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; SEGEND.ASM: Define END_OF_ symbols
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

include common.inc

public END_OF_TEXT
public END_OF_DATA
public END_OF_INIT_TEXT
public END_OF_INIT_DATA
public END_OF_INIT_BSS

_TEXT                       segment word public 'CODE'
END_OF_TEXT                 label byte
_TEXT                       ends

_DATA                       segment word public 'DATA'
END_OF_DATA                 label byte
_DATA                       ends

_INIT_TEXT                  segment byte public 'CODE_INIT'
END_OF_INIT_TEXT            label byte
_INIT_TEXT                  ends

_INIT_DATA                  segment byte public 'DATA_INIT'
END_OF_INIT_DATA            label byte
_INIT_DATA                  ends

_INIT_BSS                   segment byte public 'BSS_INIT'
END_OF_INIT_BSS             label byte
_INIT_BSS                   ends

end
