;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; CPUMACS.INC: Macro definitions for CPU operations
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

;;================================================
;; Macro definitions
;;================================================

;;================================================
;; lsr: Faux instruction to load a segment register from another register
;;
;; Inputs:   destSegReg = register to load
;;           srcReg     = register containing segment value (or anything you can PUSH, really)
;; Outputs:  None
lsr macro destSegReg: req, srcReg: req
    .erridni <&destSegReg>, <&srcReg>, "lsr: destSegReg and srcReg cannot be the same register"
    push srcReg
    pop  destSegReg
endm

;;================================================
;; cpush: Push one or more items onto the stack, counting how many were pushed
;;
;; Inputs:   regList     =  list of items to push
;; Outputs:  counterName => number of items pushed
cpush macro counterName: req, regList: vararg
    counterName = 0
    irp reg, <regList>
        ifidni <&reg>, <flags>
            pushf
        else
            push reg
        endif
        counterName = counterName + 1
    endm
endm

;;================================================
;; cpop: Pop one or more items from the stack, generating an error if the expected count does not match
;;
;; Inputs:   expectedCount = number of items expected to pop
;;           regList       = list of items to pop
;; Outputs:  none
cpop macro expectedCount: req, regList: vararg
    local count
    count = expectedCount
    irp reg, <regList>
        ifidni <&reg>, <flags>
            popf
        else
            pop reg
        endif
        count = count - 1
    endm
    if count NE 0
        .err "cpop: Mismatched pop count"
    endif
endm

;;================================================
;; multipush: Push one or more items onto the stack
;;
;; Inputs:   regList =  list of items to push
;; Outputs:  none
multipush macro regList: vararg
    irp reg, <regList>
        ifidni <&reg>, <flags>
            pushf
        else
            push reg
        endif
    endm
endm

;;================================================
;; multipop: Pop one or more items from the stack
;;
;; Inputs:   regList = list of items to pop
;; Outputs:  none
multipop macro regList: vararg
    irp reg, <regList>
        ifidni <&reg>, <flags>
            popf
        else
            pop reg
        endif
    endm
endm
