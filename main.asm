%define MAINFILE
%include "var_header.inc"			; Header has global variable definitions for other modules
%include "func_header.inc"			; Header has global function definitions for other modules
;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; David Bolenbaugh
;
; Program Entry Point
;
; File:   main.asm
; Module: main.asm, main.o
; Exec:   calc-pi
;
; Created:   10/15/14
; Last Edit: 04/29/20
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
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;-------------------------------------------------------------

;----------------------------------------
; _start
; FatalError
;----------------------------------------


SECTION	.data   ; Section containing initialized data

SECTION	.bss    ; Section containing uninitialized data

SECTION	.text	; Section containing code
;
;-----------------------
; Program Entry Point
;-----------------------
_start:
	nop					; keep debugger happy
;
	mov	rax, 0
	mov	[StackPtrSnapshot], rax		; need to be zero at command parser entry
	mov	[StackPtrEntry], rsp
;
	call	ReadSysTime			; Read system clock
	mov	[ProgSTime], rax
;
	call	ClrScr;				; clear terminal screen
	mov	qword[HeaderMode], 0

	call	Help_Welcome			; Welcome message
;
	call	FP_Initialize			; Initialize varaibles.
;
	call	PrintAccuracy			; Show default significant digits setting
	; call	PrintAccVerbose
	call	CROut
;
	call	PrintResult
;
; Infinite loop command processor
;
NextCmd:
	call	ParseCmd			; Issue Prompt, Get and parse command line
	jmp	NextCmd				; Always taken

ProgramExit:
	call	FileCloseForExit
;
	mov	rax, 1
	test	[HeaderMode], rax
	jz	.skip1
	call	Header_Cancel
.skip1:

	mov     rax, NormalExitStr1
	call    StrOut
	call    ReadSysTime			; Read system clock in seconds in RAX
	sub     rax, [ProgSTime]
	call    PrintDDHHMMSS			; Print elapsed time
	mov     rax, NormalExitStr2		; Point to normal exit message
	call    StrOut				; Print the message
;

	mov	rax, sys_exit
	mov	rdi, 0
	syscall

NormalExitStr1:	db	"     Program run time: ", 0
NormalExitStr2:	db	" Graceful Exit", 0xD, 0xA, 0xA, 0

;
;   Error Handler
;
;   RAX = 0, assume error message already printerd
;
FatalError:
	push	rax
	call	FileCloseForExit
;
	mov	rax, 1
	test	[HeaderMode], rax
	jz	.skip2
	call	Header_Cancel
.skip2:
	pop	rax
	or	rax, rax			; is error code zero (assume message already printed
	jnz	.skip1				; nonzero, show message number
	mov	rax, .ErrorMsg3			; Point to program exit message
	call	StrOut				; Print message
	jmp	.skip3
.skip1:
	push	rax
	mov	rax, .ErrorMsg1 		; An error code provided
	call	StrOut
	pop	rax
	call	PrintHexWord			; Print the error code
	mov	rax, .ErrorMsg2
	call	StrOut
.skip3:



	mov	rax, sys_exit
	mov	rdi, 0
	syscall

.exit:




.ErrorMsg1:	db	"Error Code: ", 00h
.ErrorMsg2:	db	" Program halted!", 0DH, 0AH, 00H
.ErrorMsg3:	db	0xD, 0xA, "Program halted due to error.", 0xD, 0xA, 0xA, 0


;
; Error List - use leading zero to be searchable
; 0001 DIvide by zero in math-div.asm

; 00000010h parsecodes: numeric op code
; 00000020h GetVarAdd: handle out of range
; 00000021h GetVarNameAdd: handle out of range
; 00000022h Varibles address not Word alligned

; 00004001h FP output error

; 00009001h DebugLocalMathFunc - no vector

; 8001 PrintSciNot ?
; 8002 PrintDecWord RAX is neg;
; 8003 PrintDecWOrd RAX is out of range
;--------------------
; main-asm - EOF
;--------------------
