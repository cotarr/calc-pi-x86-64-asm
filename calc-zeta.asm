;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Calculation of zeta functions by summation
;
; File:   calc-zeta.asm
; Module: calc.asm, calc.o
; Exec:   calc-pi
;
; Created   08/11/2015
; Last Edit 04/29/2020
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
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;-------------------------------------------------------------
; Function_calc_zeta
; Function_calc_pi_zeta2
;===================================

;===================================
;
; Calculate pi using zeta 2
;
; zeta(2) = (pi^2)/6
;
; pi = sqrt( 6*zeta(2) )
;
; Result in Acc and copied to Xreg
;
;===================================
Function_calc_pi_zeta2:
	push	rax
	push	rsi
	push	rdi
;
; calculate zeta(2) = Sum 1/n^2
;
	mov	rax, 2		; integer power of a
	call	Function_calc_zeta

	mov	rsi, HAND_XREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; X = zeta(2)
;
	mov	rax, 6
	mov	rsi, HAND_ACC
	call	FP_Load64BitNumber
;
	call	FP_Multiplication
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable

	mov	rax, 2				; 2 for square root (nroot XREG)
	call	Function_nth_root_x

	pop	rdi
	pop	rsi
	pop	rax
	ret


;====================================
;
;   Calculate 1/n^a using FIXED  format
;
;===============================;
;
; Input: rax = integer power of a
;
;  ACC = Current 1/n^a term
;  OPR = Running Sum
;  r15 = Runnning value of n
;
;  Result: XReg = Sum
;          YReg = last term
;
;===============================;
Function_calc_zeta:
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi
	push	r14				; holds a exponent
	push	r15

	mov	r14, rax			; Remember exponet a from rax

	mov	rax,  .msg_fn_desc1		; Print descrxiption on screen
	call	StrOut
	mov	rax, r14			; R14 = a power of n for 1/(n^a)
	call	PrintWordB10
	mov	rax, .msg_fn_desc2
	call	StrOut
	mov	rax, [Sum_Limit]		; limit to number of terms
	call	PrintWordB10
	mov	rax, .msg_fn_desc3
	call	StrOut
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep] 		; print occasional samples
	mov	rax, 0x06000000			; set skip counter from rbx
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Initialize FP Variables
;
;
	mov	rsi, HAND_OPR
	mov	rax, 0
	call	FIX_Load64BitNumber		; (to get exponent)
;
	mov	r15, 0				; R15=0 as first n value
;
; Main loop
;
.loop:
;
; Increment n and check for limits
;
	inc	r15				; Increment n
	mov	rax, r15
	rcl	rax, 1				; Bit 63 not allowed
	jc	.n_overflow_error
	rcl	rax, 1				; Bit 62 not allowed
	jc	.n_overflow_error
;
; Calculate next in 1/n^a term
;
	mov	rsi, HAND_ACC
	mov	rax, 1
	call	FIX_Load64BitNumber
	mov	rax, r15			; Pass to division routine
	mov	rsi, HAND_ACC
	mov	rcx, r14
.divloop:
	call	FIX_US_Division			; XReg = last / n
	loop	.divloop
;
;
; Add term to summation
;
	mov	rsi, HAND_OPR
	mov	rdi, HAND_ACC
	call	FIX_Addition			; YReg = YReg + XReg
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01110101 | 0x00000404 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
;  Abort at lower n counter value
;www
;	mov	rax, 100000000000
	mov	rax, [Sum_Limit]
	cmp	rax, r15
	jle	.slimit_abort

;
; Check if done
;
	mov	rsi, HAND_ACC
	call	FIX_Check_Sum_Done
	or	rax, rax			; Result = RAX, 1 = done
	jz	.loop
	jmp	.done

.slimit_abort:
	mov	rax, .msg_abort
	call	StrOut


;
;  Loop is finished because last term added not significant
;
.done:



	mov	rsi, HAND_OPR
	mov	rdi, HAND_XREG
	call	CopyVariable			; X = sum (value of e)
	mov	rsi, HAND_XREG
	call	Conv_FIX_to_FP			; Return X = last 1/n! term
;
;	mov	rsi, HAND_ACC
;	mov	rdi, HAND_YREG
;	call	CopyVariable			; X = sum (value of e)
;	mov	rsi, HAND_YREG
;	call	Conv_FIX_to_FP			; Return X = last 1/n! term
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00030003 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.abort:
	pop	r15
	pop	r14
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax
	ret
.n_overflow_error:
	mov	rax, .errorMsg1			; Print the error message
	call	StrOut
	mov	rax, 0				; Error message already printed
	jmp	FatalError			; Unrecoverble, exit program
.errorMsg1:	db	"Error: Summation error, overflow", 0xD, 0xA, 0
.msg_fn_desc1:	db	0xD, 0xA, 0xA, "Zeta, sum 1/n^", 0
.msg_fn_desc2:	db	" over ", 0
.msg_fn_desc3:	db	" terms [Sum_Limit]", 0xD, 0xA, 0
.msg_abort:
		db	0xD, 0xA
		; set color red
		db	27, "[31m"
		db	 " * * * Calculation aborted due to slimit exceeded * * *", 0xD, 0xA
		; cancel color red
		db	27, "[0m", 0
