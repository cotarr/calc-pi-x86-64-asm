;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Calculation of e
;
; File:   calc-e.asm
; Module: calc.asm, calc.o
; Exec:   calc-pi
;
; Created   12/7/2014
; Last Edit 06/26/2015
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
; Function_calc_e_Fix:
; Function_calc_ln2:
; Function_calc_e_FP:
; Function_calc_e_Reg:
;====================================
;
;   Calculate e using FIXED format
;
;  26Jun15 - Set variable accuracy fixed
;
;  Seconds for calculation of 1M digits e
;  193 - without skip leading zero
;  164 - skip leading zero division by checking words
;  150 - Variable accuracy addition
;  153 - Variable accuracy division
;  143 - Both Variable Addition and Division
;
;===============================;
;
;  ACC = Current n-factorial term
;  OPR = Running Sum
;  R15 = Runnning value of n
;
;  Result: XReg = SUM
;
Function_calc_e_Fix:
	push	rax
	push	rbx
	push	rsi
	push	rdi
	push	r15

	mov	rax, .msg_e			; Print calculaton on screen
	call	StrOut
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep]		; print occasional samples
	mov	rax, 0x06000000			; set skip counter from RBX
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Initialize FP Variables
;
	mov	rsi, HAND_ACC
	mov	rax, 1
	call	FIX_Load64BitNumber
;
	mov	rsi, HAND_OPR
	mov	rax, 1
	call	FIX_Load64BitNumber
;
	mov	r15, 0				; R15=0 as first n value
;
	mov	rax, 0
	mov	[Last_Shift_Count], rax		; Initialize shift counter
	mov	[Last_Nearly_Zero], rax		; Done Flag
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
; Calculate next in 1/n! term
;
	mov	rax, r15			; Pass to division routine
	mov	rsi, HAND_ACC
	call	FIX_US_VA_Division		; ACC = last / n
;
; Add term to summation
;
	mov	rsi, HAND_OPR
	mov	rdi, HAND_ACC
	call	FIX_VA_Addition			; OPR = OPR + ACC
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01310101 | 0x00000404 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Check if done
;
;;	mov	rsi, HAND_ACC
;;	call	FIX_Check_Sum_Done

	mov	rax, [Last_Nearly_Zero]		; Done flag

	or	rax, rax			; Result = RAX, 1 = done
	jz	.loop
;
;  Loop is finished because last term added not significant
;
	mov	rsi, HAND_OPR
	mov	rdi, HAND_XREG
	call	CopyVariable			; X = sum (value of e)
	mov	rsi, HAND_XREG
	call	Conv_FIX_to_FP			; Return X = last 1/n! term
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00230003 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	pop	r15
	pop	rdi
	pop	rsi
	pop	rbx
	pop	rax
	ret
.n_overflow_error:
	mov	rax, .errorMsg1			; Print the error message
	call	StrOut
	mov	rax, 0				; Error message already printed
	jmp	FatalError			; Unrecoverble, exit program
.errorMsg1:	db	"Error: Summation error, n overflow", 0xD, 0xA, 0
.msg_e:		db	"Function_calc_e_Fix: Calculating e using sum 1/n!", 0xD, 0xA, 0


;--------------------------------------------------------------
;
; Calculate natural log of x
;
; Ln( x/(x-1) ) = SUM ( 1/(n*x^n) )
;
;  x/(x-1) -->  2/(2-1) = 2
;
; Ln(2) = Sum ( 1/(n*2^n)
;
;   Calculate ln3 using FIXED format
;
;  ACC = Current n-factorial term
;  OPR = Running Sum
;  R15 = Runnning value of n
;
;  Result: XReg = SUM
;
Function_calc_ln2:
	push	rax
	push	rbx
	push	rsi
	push	rdi
	push	r15

	mov	rax, .msg_ln2			; Print calculaton on screen
	call	StrOut
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep]		; print occasional samples
	mov	rax, 0x06000000			; set skip counter from RBX
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Initialize FP Variables
;
	mov	rsi, HAND_ACC
	mov	rax, 1
	call	FIX_Load64BitNumber		; ACC (Sum) = 1
	mov	rax, 2
	call	FIX_US_Division			; ACC (sum) = 1/2
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR (term) = 1/2
;
	mov	r15, 1				; R15=0 as first n value
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
; Calculate next in 1/n! term
;
	mov	rsi, HAND_ACC
	mov	rax, 2
	call	FIX_US_Division			; OPR (term) = (last term / 2) for 2^n
	mov	rax, r15
	call	FIX_US_Division 		; OPR (term) = (   ) / n
	dec	rax
	call	FIX_US_Multiplication	;(term)*(n-1) this reverses last n
;
; Add term to summation
;
	mov	rsi, HAND_OPR
	mov	rdi, HAND_ACC
	call	FIX_Addition			; OPR = OPR + ACC
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01110101 | 0x00000804 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Check if done
;
	mov	rsi, HAND_ACC
	call	FIX_Check_Sum_Done
	or	rax, rax			; Result = RAX, 1 = done
	jz	.loop
.done:
	mov	rsi, HAND_OPR
	mov	rdi, HAND_XREG
	call	CopyVariable			; X = sum (value of e)
	mov	rsi, HAND_XREG
	call	Conv_FIX_to_FP			; Return X = last 1/n! term
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00030003 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	pop	r15
	pop	rdi
	pop	rsi
	pop	rbx
	pop	rax
	ret
.n_overflow_error:
	mov	rax, .errorMsg1			; Print the error message
	call	StrOut
	mov	rax, 0				; Error message already printed
	jmp	FatalError			; Unrecoverble, exit program
.errorMsg1:	db	"Error: Summation error, n overflow", 0xD, 0xA, 0
.msg_ln2:	db	"Function_calc_ln2: Calculating ln(2).", 0xD, 0xA, 0


;------------------------------------------
;
;   Calculate e
;   Using Floating Point format
;
;   n is held in floating point variable
;   which is the slowest method
;
;------------------------------------------
;
;  Reg0 = Sum
;  Reg1 = Current n-factorial value
;  Reg2 = N term
;
;  Result in XREG
;
;------------------------------------------
Function_calc_e_FP:
	push	rax				; Working Register
	push	rbx				; Used to initialize progress monitor
	push	rsi				; Variable handle number
	push	rdi				; Variable handle number

	mov	rax, .msg_e			; Print calculaton on screen
	call	StrOut
;
; Used to reduce accuracy during divisions
;
	call	ClearGrabAccuracy		; initialize reduced accuracy variables
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep]		; print occasional samples
	mov	rax, 0x06000000			; set skip counter from RBX
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Initialize FP Variables
;
	mov	rsi, HAND_REG0
	call	SetToOne			; Initial sum is 1
	mov	rsi, HAND_REG1
	call	SetToOne			; Current factorial = 1
	mov	rsi, HAND_REG2
	call	ClearVariable			; Count N is zero
;
; Increment N stored in REG2 leaving N in ACC
;
.loop:
	mov	rsi, HAND_REG2
	mov	rdi, HAND_ACC
	call	CopyVariable
	mov	rsi, HAND_OPR
	call	SetToOne
	call	FP_Addition
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2
	call	CopyVariable
;
; Calculate divide term factorial, leave in ACC
;
	mov	rsi, HAND_REG1
	mov	rdi, HAND_OPR
	call	CopyVariable
;
	call	ReduceSeriesAccuracy
	call	FP_Division			; Small term in ACC for short division
	call	RestoreFullAccuracy
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	call	CopyVariable
;
; Add term to sum
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_OPR
	call	CopyVariable
	call	FP_Addition			; Add the term to sum
	call	GrabSeriesAccuracy		; Grab the Shift_Count and Nearly_Zero
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG0
	call	CopyVariable
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01110101 | 0x00000404 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Check if last term was not significant
;
	mov	rax, [Nearly_Zero]		; Check for done
	or	rax, rax
	jnz	.done				; one go exit
	jmp	.loop				; Else loop back
.done:
;
;  Loop is finished because last term added not significant
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00030003 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rsi, HAND_REG0
	mov	rdi, HAND_XREG
	call	CopyVariable
;
; Clear temporary variable
;
	mov	rsi, HAND_REG0
	call	ClearVariable
	mov	rsi, HAND_REG1
	call	ClearVariable
	mov	rsi, HAND_REG2
	call	ClearVariable

	pop	rdi
	pop	rsi
	pop	rbx
	pop	rax
	ret

.msg_e:	db	"Function_calc_e_FP: Calculating e using sum 1/n!", 0xD, 0xA, 0


;===============================
;
;   Calculate e
;   Using Floating Point
;   With n as 64 bit register
;   using register division
;
;===============================;
;
;  ACC  = Sum
;  REG0 = Current Term
;  R8   = n
;
;  Result in XREG
;
;-------------------------------
Function_calc_e_Reg:
	push	rax
	push	rbx
	push	rsi
	push	rdi
	push	r8				; used to hold n value

	mov	rax, .msg_e			; Print calculaton on screen
	call	StrOut
;
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep]		; print each 100 term
	mov	rax, 0x06000000			; set skip counter from RBX
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Used to reduce accuracy during divisions
;
	call	ClearGrabAccuracy		; initialize reduced accuracy variables
;
; Initialize FP Variables
;
	mov	rsi, HAND_REG0
	call	SetToOne			; Initial term is 1
	mov	rax, 2
	mov	rsi, HAND_ACC
	call	FP_Load64BitNumber		; Initial sum is 2
	mov	r8, 1				; Initial n is 1
;
; Main loop
;
.loop:
	inc	r8
	mov	rax, r8
	rcl	rax, 1				; Check top bit for 1
	jc	.overflow_err
	rcl	rax, 1
	jnc	.no_overflow
.overflow_err:
	mov	rax, .msg_overflow
	call	StrOut
	mov	rax, 0
	jmp	FatalError
;
; Divide OPR by value in R8
;
.no_overflow:
	mov	rsi, HAND_REG0
	mov	rax, r8
	call	ReduceSeriesAccuracy
	call	FP_Register_Division
	call	RestoreFullAccuracy
;
; Add OPR to runnig sum in ACC
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_OPR
	call	CopyVariable
	call	FP_Addition			; Add the term to sum
	call	GrabSeriesAccuracy		; Grab the Shift_Count and Nearly_Zero
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01110101 | 0x00000404 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Check if last term was not significant
;
	mov	rax, [Nearly_Zero]		; Check for done
	or	rax, rax
	jnz	.done				; Done go exit
	jmp	.loop				; Else loop back

.done:
;
;  Loop is finished because last term added not significant
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00030003 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable

	mov	rsi, HAND_REG0
	call	ClearVariable
;
	pop	r8
	pop	rdi
	pop	rsi
	pop	rbx
	pop	rax
	ret

.msg_e:		db	"Function_calc_e_Reg: Calculating e using sum 1/n!", 0xD, 0xA, 0
.msg_overflow:	db	"Function_calc_e_Reg: Overflow error, R8 top bits not zero.", 0xD, 0xA, 0
