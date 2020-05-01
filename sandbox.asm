%DEFINE SANDBOX
%include "var_header.inc"		; Header has global variable definitions for other modules
%include "func_header.inc"		; Header has global function definitions for other modules
;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Sandbox area for temporary experiments
;
; File:   sandbox.asm
; Module: sandbox.asm, sandbox.o
; Exec:   calc-pi
;
;--------------------------------------------------------------
; MIT License
;
; Copyright 2014-2020 David Bolenbaugh
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:

; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.

; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE and NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;-------------------------------------------------------------
; SandBox:
;-------------------------------------------------

SECTION		.data   ; Section containing initialized data

SandboxMsg:	db	0xD, 0xA, "     - - Sandbox Loaded - -", 0xD, 0xA, 0xA,
		db	"Program: Calculate e result stored in X-Reg", 0xD, 0xA, 0xA, 00

SECTION		.bss    ; Section containing uninitialized data

SandVar:	resq	1

SECTION		.text		; Section containing code


;-------------------
;
;  Tiny Sandbox
;
;-------------------
Sand:

		; ------------------
		; Function goes here
		; ------------------

	mov	rax, .sandmsg
	call	StrOut
	ret
.sandmsg:	db "Sand: Tiny Sand Box - No program loaded", 0xD, 0xA, 0
;-------------------------------------------------
;
;      * * *  S A N D B O X  * * * *
;
;
;-------------------------------------------------
SandBox:	;for breakpoint
	nop

;----
; jmp BenchMark
; jmp TestFastPrint
;----

	cmp	rax, 1
	je	Sandbox_test_1

	cmp	rax, 2
	je	Sandbox_test_2

	cmp	rax, 3
	je	Timingloop

	mov	rax, .Msg
	call	StrOut
	ret
.Msg:	db	"Sandbox: No function specified", 0xD, 0xA, 0

Sandbox_test_1:
		; Generic register push
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15
	; -----------------------------------------------


	; -----------------------------------------------
	; Generic register pop
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret



Sandbox_test_2:
; Generic register push
push	rax
push	rbx
push	rcx
push	rdx
push	rsi
push	rdi
push	r8
push	r9
push	r10
push	r11
push	r12
push	r13
push	r14
push	r15
; -----------------------------------------------

; -----------------------------------------------
; Generic register pop
pop	r15
pop	r14
pop	r13
pop	r12
pop	r11
pop	r10
pop	r9
pop	r8
pop	rdi
pop	rsi
pop	rdx
pop	rcx
pop	rbx
pop	rax
ret
;--------------------------------------
; Benchmark time of functions
;
; Registers Reg0 and Ret1 are used
; to test arithmetic functions.
; Example long division time
; ------------------------------------
Timingloop:
	mov	rcx, 1				; get counter value
;
;
;  Timing Loop
;
.loop:
;------------------------------
;	mov	rsi, HAND_ACC
;	mov	rdi, HAND_OPR
;	call	Right1BitAdjExp
;------------------------------
	mov	rsi, HAND_REG1
	mov	rdi, HAND_OPR
	call	CopyVariable
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_ACC
	call	CopyVariable
;---------------------------------
;	mov	rsi, HAND_ACC
;	call	ClearVariable

;	mov	rbx, FP_Acc+MAN_MSW_OFST
            ; Ruler-->FEDCBA9876543210
;	mov	rax, 0x4000000000000000
;	and	[rbx], rax

	call	FP_Division

	loop	.loop


	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable

	ret
