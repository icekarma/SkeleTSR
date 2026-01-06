;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; DOSMACS.INC: Macro definitions for DOS API calls and other utilities
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

;;================================================
;; Macro definitions
;;================================================

;;================================================
;; DosWriteString: Write a string to standard output
;;
;; Inputs:   msg = string to write, '$'-terminated
;; Outputs:  none
DosWriteString macro msg: req
    mov ah, 09h                                     ; Write String
    mov dx, offset msg                              ; Load address of string
    int 21h                                         ; Call DOS
endm

;;================================================
;; DosSetVector: Macro to set an interrupt vector
;;
;; Inputs:   intNum     =  interrupt number (compile-time constant)
;;           handlerSeg =  segment of interrupt handler
;;           handlerOff =  offset of interrupt handler
;; Outputs:  none
DosSetVector macro intNum: req, handlerSeg: req, handlerOff: req
    mov ax, 2500h OR ( intNum AND 0FFh )            ; Set Interrupt Vector
    ifdifi <&handlerSeg>, <ds>
        lsr ds, handlerSeg                          ; Handler segment
    endif
    ifdifi <&handlerOff>, <dx>
        mov dx, handlerOff                          ; Handler offset
    endif
    int 21h                                         ; Call DOS
endm

;;================================================
;; DosKeepProgram: Terminate process, with optional exit code, but keep program in memory ("Terminate and Stay Resident")
;;
;; Inputs:   exitCode = (optional) exit code to return to DOS (compile-time constant)
;;           memSize  = size of memory to keep resident (in paragraphs)
;; Outputs:  none (never returns)
DosKeepProgram macro memSize: req, exitCode
    ifb <exitCode>                                  ; Check if argument is blank
        mov ax, 3100h                               ; Keep Program with default exit code
    else
        mov ax, 3100h OR ( exitCode AND 0FFh )      ; Keep Program with supplied exit code
    endif
    ifdifi <&memSize>, <dx>
        mov dx, memSize
    endif
    int 21h                                         ; Call DOS
endm

;;================================================
;; DosGetVector: Macro to get an interrupt vector
;;
;; Inputs:   intNum =  interrupt number (compile-time constant)
;; Outputs:  ES:BX  => interrupt handler
DosGetVector macro intNum: req
    mov ax, 3500h OR ( intNum AND 0FFh )            ; Get Interrupt Vector
    int 21h                                         ; Call DOS
endm

;;================================================
;; DosFreeAllocatedMemory: Free memory allocated with DosAllocateMemory
;;
;; Inputs:   seg = segment of memory to free
;; Outputs:  CF set on error
DosFreeAllocatedMemory macro segmentToFree: req
    mov ah, 49h                                     ; Free Allocated Memory
    ifdifi <&segmentToFree>, <es>
        lsr es, segmentToFree                       ; Segment to free
    endif
    int 21h                                         ; Call DOS
endm

;;================================================
;; DosTerminateProcess: Terminate process, with optional exit code
;;
;; Inputs:   exitCode = (optional) exit code to return to DOS (compile-time constant)
;; Outputs:  none (never returns)
DosTerminateProcess macro exitCode
    ifb <exitCode>
        mov ax, 4C00h                               ; Terminate Process with default exit code
    else
        mov ax, 4C00h OR ( exitCode AND 0FFh )      ; Terminate Process with supplied exit code
    endif
    int 21h                                         ; Call DOS
endm

;;================================================
;; DosTerminateWithMessage: Write a string to standard output and then terminate process
;;
;; Inputs:   exitCode = exit code to return to DOS (compile-time constant)
;;           msg      = string to write, '$'-terminated
;; Outputs:  none (never returns)
DosTerminateWithMessage macro exitCode: req, msg: req
    DosWriteString      msg
    DosTerminateProcess exitCode
endm
