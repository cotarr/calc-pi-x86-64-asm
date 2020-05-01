;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Calculation of exponential and log functions
;
; File:   func-ln.asm
; Module: func.asm, func.o
; Exec:   calc-pi
;
; Created   11/13/2014
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
; Function_ln_x
;-------------------------------------------------------------


;
; Input:
;   X-Reg = Argument for ln(XReg)
;
; Working Variables
;   Reg0 - Current Guess for intrative Newton method
;   Reg1 - EXP(guess), also holds sum for exp() series
;   Reg2 - (1st use) Current term for EXP sum,
;   Reg2 - (2nd use) Save (x-exp(guess))
;   r8 - n for exp() calculation
;   r9 - Newton method loop counter
;   [f_ln_noword_newton] - Accuracy during Newton's iterative loop
;   [f_ln_noword_exp]  - Accuracy mult,Div inside exponential series loop
;
; Result
;   X-Reg contains result
;
; Iterations:
;
;                               (xreg - exp(guess(n))
;  Guess(n+1) = guess(n) + 2*(-------------------------)
;                               (xreg + exp(guess(n))
;
;-------------------------------------------------------------
;
Function_ln_x_by_guess:
	push	rax				; General use
	push	rbx
	push	rcx
	push	rdx
	push	rsi				; Handle for function call
	push	rdi				; Handle for function call
	push	rbp
	push	r8
	push	r9

;
; Check for zero. If zero, return exp(0)= 1
;
	mov	rbx, FP_X_Reg			; Point RBX at Xreg variable
	mov	rax, [rbx+MAN_MSW_OFST]		; Get MS word
	or	rax, rax			; Check of ACC = 0
	jnz	.notZero			; Not zero, continue
	mov	rax,.msg_err1
	call	StrOut
	mov	rax,0
	jmp	FatalError
.notZero:
	rcl	rax, 1
	jnc	.notNegative
	mov	rax,.msg_err1
	call	StrOut
	mov	rax,0
	jmp	FatalError
.msg_err1:
	db	"Function_ln_x invalid input. Expect Xreg > 0", 0xD, 0xA, 0

.notNegative:

;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, 1				; print iteration counter
	mov	rax, 0x04000000			; set skip counter from rbx
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

;
; Init Variables
;
	mov	rsi, HAND_REG0
	call	SetToOne			; Reg0 = 1, first guess
	mov	rsi, HAND_REG1
	call	ClearVariable
	mov	rsi, HAND_REG2
	call	ClearVariable
	mov	rsi, HAND_WORKC
	call	ClearVariable
	mov	r9, 0				; Counter for Newton loop
;
; Set initial accuracy small, increase as we go
;
	mov	rax, 8				; Get Proposed
	cmp	rax, MINIMUM_WORD		; Minimum word count
	jge	.skipinit2			; >- Zero, in range
	mov	rax, MINIMUM_WORD
.skipinit2:
	mov	[f_ln_noword_newton],rax
;
;--- Debug Option
;
;;;	mov	rax, [No_Word]
;;;	mov	[f_ln_noword_newton], rax

;---------------------------------------
; Begin Newtom method
;---------------------------------------
.newton_loop:

	mov	rax, [f_ln_noword_newton]; For call
	call	Set_No_Word_Temp

;---------------------------------------
; Begin Calculate Exponential of Guess
;---------------------------------------
;
	mov	r8, 1				; initialize term counter n
	mov	rsi, HAND_REG0
	mov	rdi, HAND_REG2
	call	CopyVariable			; Reg2 is current term (guess(n))
	mov	rsi, HAND_ACC
	call	SetToOne			; OPR = 1 for addition
	mov	rsi, HAND_REG0
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = current guess
	call	FP_Addition			; ACC = 1 + guess (first two terms)
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	call	CopyVariable			; Reg1 first 2 term of EXP sum
;
; At beginning use accuracy of Newton's iterative LN() loop
; Then it will be decreased during the loop
;
	mov	rax, [f_ln_noword_newton];Newton's LN() loop accuracy
	mov	[f_ln_noword_exp], rax		; Initial exponential series accuracy
;
; Loop
;
.exp_loop:
	inc	r8				; n = n+1
	mov	rsi, HAND_REG2
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = current exp term
	mov	rsi, HAND_REG0
	mov	rdi, HAND_ACC
	call	CopyVariable			; ACC = Current guess
;
; Reduce accuracy temporarily
;
	mov	rax, [f_ln_noword_exp]
	call	Set_No_Word_Temp
;
; Multiply by guess
;
;
	call	FP_Multiplication		; Term = Term * (XREG)
;
; Divide by n
;
	mov	rsi, HAND_ACC
	mov	rax, r8				; n
	call	FP_Register_Division		; Term = Term / n
;
; Restore accuracy for addition
;
	mov	rax, [f_ln_noword_newton]
	call	Set_No_Word_Temp
;
; Setup for sum
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2
	call	CopyVariable			; Reg2 = current exp term
	mov	rsi, HAND_REG1
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = running sum
;
; Add term to sum
;
	call	FP_Addition			; ACC = Exponential series sum
;
; After sum, [Shift_Count] and [Nearly_Zero] are set by FP_Additoin
;
; Determine reduced accuracy for next loop
; This takes [Shift_Count] from FP_Additon and
; computes a value for [f_ln_noword_exp] for use in loop
;
;          Uses rcx temporarily
;
	mov	rax, [f_ln_noword_newton] ; Max word count from LN2 loop
	sub	rax, [Shift_Count]		; Subtract shift count of words from addition
	inc	rax				; Add extra word for safety
	mov	rcx, rax			; Save temporarily
;
; Check upper limit (could be negative)
;
	mov	rax, [f_ln_noword_newton]	; Maximum allowed
	cmp	rax, rcx			; Subtract Proposed
	jge	.skip1				; >= Zero, in range
	mov	rcx, [f_ln_noword_newton]	; Else out of range, use default
.skip1:
	mov	rax, rcx			; Get Proposed
	cmp	rax, MINIMUM_WORD		; Minimum word count
	jge	.skip2				; >- Zero, in range
	mov	rcx, MINIMUM_WORD
.skip2:
	mov	[f_ln_noword_exp], rcx
;
;
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	call	CopyVariable			; Reg1 = sum for exp(guess)

	mov	rax, [Nearly_Zero]		; Check for done
	or	rax, rax
	jnz	.done_exp_loop		;Done
	jmp	.exp_loop		;Else loop back
.done_exp_loop:


;---------------------------------------
; End Calculate Exponential of Guess
;---------------------------------------

	mov	rsi, HAND_XREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = argument for LN( )
	mov	rsi, HAND_REG1
	mov	rdi, HAND_ACC
	call	CopyVariable			; ACC = exp(guess)
;
	mov	rsi, HAND_ACC
	call	FP_TwosCompliment
	call	FP_Addition			; ACC = (x - exp(guess))
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2
	call	CopyVariable			; 2nd use, save temporarily (x-exp(guess))
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = argument for LN( )
	mov	rsi, HAND_REG1
	mov	rdi, HAND_ACC
	call	CopyVariable			; ACC = exp(guess)
;
	call	FP_Addition			; ACC = (x + exp(guess))
;
;
	mov	rsi, HAND_REG2
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = (x = exp(guess))
;
	call	FP_Division			; ACC = (x-exp(guess) / (x+exp(guess))
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = (x-exp(guess) / (x+exp(guess))
	mov	rsi, HAND_ACC
	call	SetToTwo			; ACC = 2
;
	call	FP_Multiplication		; ACC = 2 * (x-exp(guess) / (x+exp(guess))
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = guess
;
	call	FP_Addition			; ACC = guess + 2 * (x-exp(guess) / (x+exp(guess))


;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01110101 | 0x00000804 | 0x20000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

;
;  ****  Check for done here
;
	inc	r9
;
;  Skip first few iterations
;
	cmp	r9, 4				; Don't do first few terms, will false done
	jl	.skip01
;
; Check if done and adjust accuracy if needed.

	mov	rbx, FP_Acc			; Next guess Xn
	mov	rdx, FP_Reg0			; Last guess Xn-1
	mov	rbp, MAN_MSW_OFST		; Point at MSWord
	mov	rcx, 0				; Initialize word Counter
;
; This counts in rcx how many words match
;
.loop_ck:
	mov	rax, [rbx+rbp]			; Get word from ACC
	cmp	rax, [rdx+rbp]			; Compare to Reg0
	jne	.endloop			; Not equal, exit to stop counting
	sub	rbp, BYTE_PER_WORD		; point at next word
	inc	rcx				; Increment count of bytes same
	mov	rax, [LSWOfst]			; Get lower limit index
	cmp	rbp, rax			; Check if done (checked last word?)
	jge	.loop_ck			; No, keep checking, else done
.endloop:
;
; Check if at full accuracy, if yes, full accuracy, then check for exit
;
	mov	rax, [f_ln_noword_newton]	; Get Newton loop accuracy
	cmp	rax, [D_Flt_Word]		; Compare reduced accuracy
	jne	.skip01				; Not full accuracy, don't exit
;
; Exit check, if matching enough word and if at full accuracy

	mov	rax, [f_ln_noword_newton]	; Get word count
	sub	rax, GUARDWORDS			; Subtract guard words
	add	rax, 1				; Option to match guard word (see below)
;----------------------------------------
	cmp	rcx, rax			; Compare number of bytes the same
	jl	.skip01				; Do another iteration?
	jmp	.done				; End calculation, enough words match
;
; Adjust accuracy, rcx = mumber of words the same
;
.skip01:
	mov	rax, [f_ln_noword_newton]	; Get current mantissa size
	shr	rax, 1				; Divide by 2, wait until half of words match
	cmp	rcx, rax			; Are matching words more than half of words
	jl	.skip02				; No don't adjust accuracy
;
	mov	rbx, [f_ln_noword_newton]	; Get accuracy
	add	rbx, [f_ln_noword_newton]	; Increase X2
	add	rbx, [f_ln_noword_newton]	; Increase X3
	mov	rax, [D_Flt_Word]		; Maximum mantissa size
	cmp	rax, rbx			; Over maximum size?
	jge	.skip_sa2			; No don't adjust
	mov	rbx, rax			; Else, yes, reset to maximum
.skip_sa2:
	mov	[f_ln_noword_newton], rbx	; New accuracy
;
; Move result back to Reg0 to become next n+1 guess
;
.skip02:



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG0
	call	CopyVariable			; REG0 = next guess
;
	jmp	.newton_loop

.done:


;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x000F0303 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


	mov	rsi, HAND_REG0
	mov	rdi, HAND_XREG
	call	CopyVariable

;	mov	rsi, HAND_REG0
;	call	ClearVariable
;	mov	rsi, HAND_REG1
;	call	ClearVariable
;	mov	rsi, HAND_REG2
;	call	ClearVariable

	pop	r9
	pop	r8
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret





;--------------------------------------------------------------
;
; Calculate natural log of x
;
; Ln( x/(x-1) ) = SUM ( 1/(n*x^n) )
;
; Input:
;    XREG
;
; Program Use:
;    REG0 = Sum
;    REG1 = Last 1/x^n Term
;    REG2 = x/(x-1)
;    REG3 = current n value
;
; Output:
;    XREG = Result
;
;------------------------------------------
;
Function_ln_x_series:
	push	rax				; General use
	push	rbx
	push	rcx
	push	rcx
	push	rsi				; Handle for function call
	push	rdi				; Handle for function call
	push	rbp
;
; Check for zero. If zero, return exp(0)= 1
;
	mov	rbx, FP_X_Reg			; Point RBX at Xreg variable
	mov	rax, [rbx+MAN_MSW_OFST]		; Get MS word
	or	rax, rax			; Check of ACC = 0
	jnz	.notZero			; Not zero, continue
	mov	rax,.msg_err1
	call	StrOut
	mov	rax,0
	jmp	FatalError
.notZero:
	rcl	rax, 1
	jnc	.notNegative
	mov	rax,.msg_err1
	call	StrOut
	mov	rax,0
	jmp	FatalError
.msg_err1:
	db	"Function_ln_x_series invalid input. Expect Xreg > 0", 0xD, 0xA, 0

.notNegative:
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep]		; print occasional samples
	mov	rax, 0x06000000			; set skip counter from rbx
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
	call	ClearGrabAccuracy
;
	mov	rsi, HAND_REG3			; REG3 = n
	call	SetToOne

	mov	rsi, HAND_XREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; X is in Opr
	mov	rsi, HAND_ACC
	call	SetToOne			; Acc = 1
	call	FP_TwosCompliment		; change sign ACC
	call	FP_Addition			; ACC = (X-1)
	mov	rsi, HAND_XREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; Move e to OPR
	call 	FP_Division			; ACC = X/(X-1)
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2			; reg2 = X/X-1
	call	CopyVariable
;
	mov	rsi, HAND_OPR
	call	SetToOne
	call	FP_Division			; ACC = 1 /  (X/X-1)
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	call	CopyVariable			; Reg-1 = last term;
	mov	rdi, HAND_REG0
	call	CopyVariable			; Reg-0 = sum with first term

.loop2:
;
; Increment N in Reg3
;
	mov	rsi, HAND_REG3
	mov	rdi, HAND_ACC
	call	CopyVariable
	mov	rsi, HAND_OPR
	call	SetToOne
	call	FP_Addition			; ACC = n+1 (form the new n)
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG3
	call	CopyVariable
;
; get last 1/x^n term and divide by x   for next 1/x^n+1
;
	mov	rsi, HAND_REG1
	mov	rdi, HAND_OPR
	call 	CopyVariable
	mov	rsi, HAND_REG2
	mov	rdi, HAND_ACC
	call	CopyVariable			; last 1/ term divde by e/e-1
	call	ReduceSeriesAccuracy
	call	FP_Division			; divide by c/c-1
	call	RestoreFullAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	call 	CopyVariable			; move to back
;
; Now divide by N but don't save result
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable
	mov	rsi, HAND_REG3
	mov	rdi, HAND_ACC			; put n in acc
	call	CopyVariable
	call	ReduceSeriesAccuracy
	call 	FP_Division			; Divide by n
	call	RestoreFullAccuracy
;
; Sum the term
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_OPR
	call	CopyVariable
	call 	FP_Addition
	call	GrabSeriesAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG0
	call	CopyVariable
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01110101 | 0x00004404 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
;
; Check if last term was not significant
;
	mov	rax, [Nearly_Zero]		; Check for done
	or	rax, rax
	jnz	.done2				; Done go exit
	jmp	.loop2				; Else loop back
;
;
.done2:

	mov	rsi, HAND_REG0			; Get sum
	mov	rdi, HAND_XREG			; move to X-Reg
	call	CopyVariable
;
; Clear temporary variables
;
	mov	rsi, HAND_REG0
	call	ClearVariable
	mov	rsi, HAND_REG1
	call	ClearVariable
	mov	rsi, HAND_REG2
	call	ClearVariable
	mov	rsi, HAND_REG3
	call	ClearVariable
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00030303 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
