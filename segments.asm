;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; SEGMENTS.ASM: Define segments and, importantly, link order
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

include common.inc

public START_OF_NONRESIDENT_AREA

_INIT_TEXT segment byte public 'CODE_INIT'

START_OF_NONRESIDENT_AREA label byte

_INIT_TEXT ends

end
