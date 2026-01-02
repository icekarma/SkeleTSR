;;================================================
;; SKELETSR: A skeleton DOS TSR program
;; STACKMGR.ASM: Reentrantly manage multiple private stacks
;; Copyright © 2026 Zive Technology Research
;; Licensed under the BSD 2-Clause License
;;================================================

include common.inc

extrn START_OF_NONRESIDENT_AREA: byte

public StackSwap
public StackRestore

;;================================================
;; Resident data
;;================================================

.data

StackSize        equ 64                             ; Fixed size per stack
StackSizeShift   equ  6                             ; log2(StackSize), for shifts
MaxStacks        equ  3                             ; Maximum number of stacks

StackPoolBase    dw  START_OF_NONRESIDENT_AREA
StacksInUse      dw  0

SavedStacks      dd  MaxStacks dup (?)

;;================================================
;; Resident code
;;================================================

.code

;;================================================
;; StackSwap: Swap to a free private stack
;;
;; Inputs:   none
;; Outputs:  CF = 0 if successful, stack swapped
;;             AX = stack index (for StackRestore)
;;           CF = 1 if no stacks available
;; Clobbers: none
StackSwap proc near
    cpush @@PushCount, bx, cx, si, di, ds, es, flags
    @@StackCopySize equ (@@PushCount * 2 + 2)       ; registers + return address

    ;; --- Check if we have a stack available ---

    cli                                             ; Start critical section

    mov bx, word ptr cs:[StacksInUse]
    xor cx, cx
    mov dx, 1

@@CheckLoop:
    test bx, dx
    jz @@StackAvailable
    shl dx, 1
    inc cl
    cmp cl, MaxStacks
    jae @@NoStacks
    jmp @@CheckLoop

@@StackAvailable:
    ;; Mark stack as used
    or word ptr cs:[StacksInUse], dx

    ;; Calculate SP for the private stack
    mov ax, bx
    mov cl, StackSizeShift
    shl ax, cl                                      ; AX = Index * StackSize
    add ax, word ptr cs:[StackPoolBase]             ; Add base of stack pool
    add ax, StackSize                               ; Adjust to end of stack, since stack grows downwards
    sub ax, @@StackCopySize                         ; Space for copied stack elements

    ;; Perform the actual swap

    ; Copy saved registers and return address from original stack to private stack
    lsr ds, ss                                      ; DS:SI => original stack
    mov si, sp

    lsr es, cs                                      ; ES:DI => private stack
    mov di, ax

    mov cx, (@@StackCopySize SHR 1)
    cld
    rep movsw

    add sp, @@StackCopySize                         ; Remove copied elements from original stack

    ; Save current stack pointer
    shl bx, 1
    shl bx, 1
    mov word ptr cs:[bx + SavedStacks], sp
    mov word ptr cs:[bx + SavedStacks + 2], ss

    ; Switch to private stack
    lsr ss, cs
    mov sp, ax

    ;; --- Done ---
    ;sti ; not actually needed, popf will handle it ; End critical section
    cpop @@PushCount, flags, bx, cx, si, di, ds, es
    clc
    ret

@@NoStacks:
    ;sti ; not actually needed, popf will handle it ; End critical section
    cpop @@PushCount, flags, bx, cx, si, di, ds, es
    stc
    ret

    purge @@PushCount
StackSwap endp

;;================================================
;; StackRestore: Swap back to the original stack and release the private stack
;;
;; Inputs:   AX = stack index (from StackSwap)
;; Outputs:  CF = 0 if successful, stack restored
;;           CF = 1 if invalid stack index
;; Clobbers: none
StackRestore proc near
    ;; --- Validate stack index ---

    cmp ax, MaxStacks
    jb @@ValidIndex
    stc
    ret

@@ValidIndex:
    cpush @@PushCount, bx, cx, si, di, ds, es, flags
    @@StackCopySize equ (@@PushCount * 2 + 2)       ; registers + return address

    cli                                             ; Start critical section

    ;; --- Mark stack as free ---

    mov dx, 1
    mov cx, ax
    shl dx, cl                                      ; DX = bitmask for stack index
    not dx
    and word ptr cs:[StacksInUse], dx

    ;; --- Copy saved registers and return address from private stack to original stack ---

    mov bx, ax                                      ; BX = stack index
    shl bx, 1

    lsr ds, ss                                      ; DS:SI => private stack
    mov si, sp

    les di, dword ptr cs:[bx + SavedStacks]         ; ES:DI => original stack
    sub di, @@StackCopySize                         ; Make room for copied elements

    mov cx, (@@StackCopySize SHR 1)
    cld
    rep movsw

    add sp, @@StackCopySize                         ; Remove copied elements from private stack

    sti                                             ; End critical section
    clc
    ret
StackRestore endp

; Initialization code segment
_INIT_TEXT  segment byte public 'INITCODE'
_INIT_TEXT  ends

; Initialization data segment
_INIT_DATA  segment byte public 'INITDATA'
_INIT_DATA  ends

; Initialization uninitialized data segment
_INIT_BSS   segment byte public 'INITBSS'
_INIT_BSS   ends

end
