;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Calculation of Pi using Chudnovsky Formula
;
; File:   calc-pi-ch.asm
; Module: calc.asm, calc.o
; Exec:   calc-pi
;
; Created   01/02/2014
; Last Edit 01/03/2015
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
;--------------------------------------------------------------
; Function_calc_pi_chud:
;--------------------------------------------------------------
;
; Calculation of Pi using the Chudnovsky formula
;
; Calculated using fixed  point math
;
;===============================
;
; Calculations requires square root of 10005 to full accuracy
; XReg must contain sqrt(10005) at start calculated externally
;
; Summation Term A:  [(6n)!(13591409)] / [(n!^3)(3n!)(-640320^3n)]
;
; Summation Term B:  [(6n)!(545140134)(n)] / [(n!^3)(3n!)(-640320^3n)]
;
; Final Divisions pi = (426880(sqrt(10005)) / summations
;
;  ACC = Sum
;  Reg0 = Square root of 10005 (for now from XREG)
;  Reg1 = Term-A [(6n)!(13591409)] / [(n!^3)(3n!)(-640320^3n)]
;  Reg2 = Term-B [(6n)!(545140134)(n)] / [(n!^3)(3n!)(-640320^3n)]
;
;  R15 = n
;  R14 = 6n for running 6n! calculation
;  R13 = 3n for running 3n! calculation
;  R12 = (640320)^3 = 262537412640768000
;  R11 - Flag, term B done
;  R10 - Flag, term A done
;
;  ACC contains result, copied to Xreg
;
Function_calc_pi_chud:
	push	rax				; General use
	push	rbx				; Pass data to display update counter
	push	rcx				; Loop counter
	push	rsi				; Variable handle number
	push	rdi				; Variable handle number
	push	r10				; Flag Term A done
	push	r11				; Flag Term B done
	push	r12				; Holds (640320)^3
	push	r13				; 3n for running 3n! calculation
	push	r14				; 6n for running 6n! calculation
	push	r15				; n counter

;	mov	rax, .msg_pi			; Print calculaton on screen
;	call	StrOut
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep] 		; print selected terms
	mov	rax, 0x06000000			; set skip counter from RBX
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Initialize Register Variables
;
;
; At program start square root 10005 expected in XREG
; Move square root of 10005 from XREG to Reg0
;
	mov	rsi, HAND_XREG			; * * * XREG must contain Sqrt(10005) at start
	mov	rdi, HAND_REG0
	call	CopyVariable			; Reg0 = sqrt(10005)
;
; X-Reg: (Sum) Initialize to hold 13591409 for term #0, Sum will start with term n=1
;
	mov	rsi, HAND_ACC
	mov	rax, 13591409
	call	FIX_Load64BitNumber
;
; Reg1 (Term A) Initialize to 13591409  n=0 in Term-A
;
	mov	rsi, HAND_REG1
	mov	rax, 13591409
	call	FIX_Load64BitNumber
;
; Reg2 (Term B) Initialize to 545140134 n=0 in Term-B
;
	mov	rsi, HAND_REG2
	mov	rax, 545140134
	call	FIX_Load64BitNumber		; Reg2 = 545140134
;
;  Initialize to 0 for summation index n at term 0
;
	mov	r15, 0				; R15 = 0 (n)
	mov	r14, 0				; R14 = 0 (6n)
	mov	r13, 0				; R13 = 0 (3n)
	mov	r12, (640320*640320*640320)
						; R12 = (640320^3)
	mov	r11, 0				; flag tern B not done
	mov	r10, 0				; flag term A not done
;
;
; * * * * * * * * * * * * * * *
;
;  M A I N    L O O P
;
; * * * * * * * * * * * * * * *
;
;
.loop:
;
; Increment n in R15
;
	inc	r15				; n = n+1;
;
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
;
;  F I R S T   T E R M   A
;
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
;
; Skip if term was previously zero
;
	or	r10, r10			; R10 flag for Term A done
	jnz	.skip05
;
; Using R14, build the (6n)! in numerator
;
	mov	rsi, HAND_REG1			; RSI is Variable handle number
	mov	rcx, 6				; RCX is couner for loop command
.loopx1:
	inc	r14				; Previous n counter value
	mov	rax, r14			; Input for division
	call	FIX_US_Multiplication		; Reg1 = Reg1 * RAX
	loop	.loopx1				; Dec RCX, loop again
	sub	r14, 6				; reduce by 4 for use with term B
;
; Using r13, build the (3n)! in denominator
;
	mov	rcx, 3				; RCX is couner for LOOP command
.loopx1a:
	inc	r13				; Previous n counter value
	mov	rax, r13			; Input for division
	call	FIX_US_Division			; Reg1 = Reg1 / RAX
	loop	.loopx1a			; Decrement RCX, loop again
	sub	r13, 3				; reduce by 4 for use with term B
;
; Using n, build (n!)^3 in denominator
;
	mov	rcx, 3				; REX is counter for LOOP command
.loopx2:
	mov	rax, r15			; R15 = n
	call	FIX_US_Division			; Reg1 = Reg1 / RAX
	loop	.loopx2
;
; Divide to build (640320)^(4n) in denominator)
;
	mov	rax, r12			; RAX = (640320)^4
	call	FIX_US_Division			; Reg1 = Reg1 / RAX
.skip05:
;
; At this point term-A is complete
;
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
;
;  S E C O N D   T E R M   B
;
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
;
; Skip if term was previously zero
;
	or	r11, r11			; R11 is flag for Term B done
	jnz	.skip07
;
; Using R14, build the (6n)! in numerator
;
	mov	rsi, HAND_REG2			; RSI is variable handle number
	mov	rcx, 6				; RCX is counter for LOOP command
.loopx3:
	inc	r14				; R14 is n counter value
	mov	rax, r14			; RAX input for multiplication
	call	FIX_US_Multiplication		; Reg2 = Reg2 / RAX
	loop	.loopx3				; Dec RCX and loop again
;
; Using r13, build the (3n)! in denominator
;
	mov	rcx, 3				; RCX is couner for LOOP command
.loopx3a:
	inc	r13				; Previous n counter value
	mov	rax, r13			; Input for division
	call	FIX_US_Division			; Reg1 = Reg1 / RAX
	loop	.loopx3a			; Decrement RCX, loop again
;
; Divide by previous by n-1 in numerator
;
	mov	rax, r15			; RAX = n
	dec	rax				; RAX = n-1 to cancel previous term n
	or	rax, rax			; Skip term n=1 --> n=0 --> division by zero
	jz	.skip06				; for term n=1 (first loop)
	call	FIX_US_Division			; Reg2 = Reg2 / RAX
.skip06:
;
; Multiply by n in numerator, will be reversed next loop by division
;
	mov	rax, r15			; RAX = n
	call	FIX_US_Multiplication		; Reg2 = Reg2 / RAX
;
; Using n, build (n!)^3 in denominator
;
	mov	rcx, 3				; RCX is loop couner
.loopx4:
	mov	rax, r15			; R15 = n value
	call	FIX_US_Division			; Reg2 = Reg2 / RAX
	loop	.loopx4				; Dec RCX and loop again
;
; Divide to build (640320)^(4n) in denominator)
;
	mov	rax, r12			; RAX = (640320)^3
	call	FIX_US_Division			; Reg2 = Reg2 / RAX
.skip07:
;
; At this point term-B is complete
;
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
;
; Perform summation
;
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
;
;
; Add term-A to sum
;
	or	r10, r10
	jnz	.skip08
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	test	r15, 1
	jnz	.skip07a
	call	FIX_Addition			; ACC = ACC + Reg1
	jmp	.skip08
.skip07a:
	call	FIX_Subtraction			; ACC = ACC - Reg1
.skip08:
;
; Add term-B to sum
;
	or	r11, r11
	jnz	.skip09
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2
	test	r15, 1
	jnz	.skip08a
	call	FIX_Addition			; ACC = ACC + Reg2
	jmp	.skip09
.skip08a:
	call	FIX_Subtraction			; ACC = ACC - Reg2
.skip09:
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01010101 | 0x00000404 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Debug
;
;	cmp	r15, 3
;	je	.done
;	jmp	.loop
;
; Check if done
;
	mov	rsi, HAND_REG1
	call	FIX_Check_Sum_Done		; is Term A significant?
	mov	r10, rax
	mov	rsi, HAND_REG2
	call	FIX_Check_Sum_Done		; is Term B significant?
	mov	r11, rax
	add	rax, r10			; When done 1+1=2
	cmp	rax, 2				; Done?
	jne	.loop				; no, not 2, loop again
;						; else done
.done:
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x000F0303 | 0x00000800 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Convert FIX to FP numbers
;
	mov	rsi, HAND_ACC
	call	Conv_FIX_to_FP
;
;	mov	rsi, HAND_REG1
;	call	Conv_FIX_to_FP
;	mov	rsi, HAND_REG2
;	call	Conv_FIX_to_FP
;
; Place 1 in OPR, divide by ACC
;
	mov	rsi, HAND_ACC
	call	FP_Reciprocal			; ACC = Oper / ACC which is 1/sum
;
; Move ACC-->OPR, copy square root 2 from REG0 to ACC and divide sqrt(2)
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable
	mov	rsi, HAND_REG0			; Reg0 contains square root of 10005
	mov	rdi, HAND_ACC
	call	CopyVariable
	call	FP_Multiplication		; ACC = OPR * ACC Divide by square root 2
;
; Move result back to XReg
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; move to oper in case word multiply will work
	mov	rsi, HAND_ACC
	mov	rax, 426880
	call	FP_Load64BitNumber
	call	FP_Multiplication
;
; Clear Temporary Variables
;
	mov	rsi, HAND_REG0
	call	ClearVariable
	mov	rsi, HAND_REG1
	call	ClearVariable
	mov	rsi, HAND_REG2
	call	ClearVariable

	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
; For debug
;
.exit:

;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x000F0303 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax
	ret

.msg_pi:	db	0xD, 0xA, 0xA, "Calculating Pi using Chudnovsky formula", 0xD, 0xA, 0
