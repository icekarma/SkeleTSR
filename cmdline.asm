;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; CMDLINE.ASM: Command line parsing code
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

include common.inc

public  ParseCommandLine

extrn   commandLineBuffer:            byte
extrn   argv:                         word
extrn   argc:                         word

extrn   HelpMsg:                      byte

;;================================================
;; Initialization code
;;================================================

_INIT_TEXT segment byte public 'CODE_INIT'

;;================================================
;; Command line parsing notes
;;
;; Command line parameters are found in the PSP at offset 80h.
;;
;; The first byte at 80h is the length of the command line (not including
;; the length byte itself or the terminating carriage return and NUL). The
;; command line parameters follow immediately after that byte.
;;
;; Parameters are separated by whitespace (spaces, tabs). They are terminated
;; by a carriage return (0Dh).
;;
;; So, we need to do two stages:
;;     1. split the command line up into { argc, argv }
;;     2. parse each argv
;;
;; Algorithm for splitting:
;;     loop:
;;         * skip whitespace
;;         * if at end, done
;;         * bump argc
;;         * add start index to argv
;;         * copy characters until whitespace or '/' or end
;;

;;================================================
;; SplitCommandLine: Split command line into argc/argv
;;
;; Inputs:   none
;; Outputs:  none
;; Clobbers: AX, CX
SplitCommandLine proc near
    multipush si, di, bp, es

    ;; --- Split command line into individual parameters ---
    mov si, 80h                                     ; offset of command line length byte
    mov cl, ds:[si]                                 ; get length
    inc si                                          ; point to first character

    mov [argc], 0                                   ; initialize argc to 0
    mov bp, offset argv                             ; point BP to argv array
    mov di, offset commandLineBuffer                ; point DI to command line buffer
    lsr es, ds

    ;; DS:SI => PSP command line buffer
    ;; ES:DI => local command line buffer
    ;; DS:BP => current argv entry
    ;; CL    =  remaining length

@@SkipWhitespace:
    ; out of characters?
    or cl, cl
    jz @@Done

    ; get next character
    dec cl
    lodsb

    ; is it whitespace?
    call IsSpace
    jnc @@SkipWhitespace                            ; skip whitespace

    ;; --- Found start of parameter ---
@@FoundParameter:
    ; Increment argc
    inc [argc]

    ; Store pointer to parameter in argv
    mov [bp], di
    add bp, 2                                       ; advance to next argv entry
    stosb                                           ; copy character to buffer

    ;; --- Copy characters until whitespace or '/' or end ---
@@CopyParameter:
    ; out of characters?
    or cl, cl
    jz @@Done

    dec cl
    lodsb

    call IsSpace
    jnc @@EndCurrParameter                          ; end of parameter

    cmp al, '/'                                     ; check for '/'
    je @@StartNewParameter                          ; start of new parameter

    stosb                                           ; copy character to buffer
    jmp @@CopyParameter

@@StartNewParameter:
    ; NUL-terminate current parameter
    push ax
    xor al, al
    stosb
    pop ax

    jmp @@FoundParameter

@@EndCurrParameter:
    ; NUL-terminate current parameter
    xor al, al
    stosb

    jmp @@SkipWhitespace

@@Done:
    multipop es, bp, di, si
    ret
SplitCommandLine endp

;;================================================
;; ParseCommandLine: Parse command line parameters
;;
;; Inputs:   none
;; Outputs:  CF = 0 clear if actionable command line parameter found
;;             AX = 1 if uninstall
;;           CF = 1 if no actionable parameter found
;; Clobbers: AX, BX, DX
ParseCommandLine proc near
    push si

    call SplitCommandLine

    xor bx, bx
    mov dx, [argc]

@@Top:
    or dx, dx
    jz @@Fail                                       ; no more parameters
    dec dx

    mov si, [bx + argv]                             ; get pointer to parameter
    add bx, 2                                       ; advance to next parameter

    lodsb
    or al, al
    jz @@Top                                        ; empty parameter, skip

    cmp al, '/'                                     ; check for '/'
    je @@CheckParam
    cmp al, '-'                                     ; check for '-'
    jne @@BadParam

@@CheckParam:
    lodsb
    or al, al
    jz @@BadParam                                   ; no parameter after '/' or '-'

    ; Check for 'u' (for "uninstall")
    or al, 20h                                      ; make lowercase
    cmp al, 'u'
    jne @@BadParam

    ; Check for trailing characters
    lodsb
    or al, al
    jnz @@BadParam                                  ; trailing characters after 'u'

    pop si
    mov ax, 1                                       ; uninstall command
    clc                                             ; clear carry to indicate success
    ret

@@BadParam:
    DosTerminateWithMessage 4, HelpMsg

@@Fail:
    pop si
    stc                                             ; set carry to indicate failure
    ret
ParseCommandLine endp

;;================================================
;; IsSpace: Check if AL is a whitespace character
;;
;; Inputs:   AL = character to check
;; Outputs:  CF = 0 if AL is whitespace
;;           CF = 1 if not
;; Clobbers: none
IsSpace proc near
    cmp al, 32                                      ; space
    je @@Yes
    cmp al, 13                                      ; carriage return
    je @@Yes
    cmp al, 10                                      ; line feed
    je @@Yes
    cmp al, 9                                       ; tab
    je @@Yes

    ; Not whitespace
    stc
    ret

    ; Is whitespace
@@Yes:
    clc
    ret
IsSpace endp

_INIT_TEXT ends

end
