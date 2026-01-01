;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; COMMON.INC: Build configuration and includes
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

;;================================================
;; Build configuration
;;================================================

DGROUP  group   _TEXT, _DATA, _INIT_TEXT, _INIT_DATA, _INIT_BSS

assume  nothing
assume  cs: DGROUP

.8086
.model  tiny, nolanguage

locals

include dosmacs.inc
