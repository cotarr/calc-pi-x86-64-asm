;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Calculation of Pi using Ramanujan Formula
;
; File:   calc-pi-ra.asm
; Module: calc.asm, calc.o
; Exec:   calc-pi
;
;  Created   11/13/2014
;  Last Edit 01/04/2015
;
;-------------------------------------------------------------
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
; Function_calc_pi_ram:
;-------------------------------------------------------------
;
; Calculation of Pi using the Ramanujan formula
;
; Calculated using fixed  point math
;
;===============================
;
; Calculations requires square root of 2 to full accuracy
; XReg must contain sqrt(2) at start calculated externally
;
; Summation Term A:  [(4n)!(1103)] / [(n!^4)(396^4)]
;
; Summation Term B:  [(4n)!(26360)(n)] / [(n!^4)(396^4)]
;
; Final Divisions pi = (9801/(2*sqrt(2))) / summations
;
;  ACC = Sum
;
;  Reg0 = Square root of 2 (for now from XREG)
;  Reg1 = Term-A (4n)!( 1103  )/(n!)^4(396)^4
;  Reg2 = Term-B (4n)!(26390*n)/(n!)^4(396)^4
;
;  r15 = n
;  r14 = 4n for running 4n! calculation
;  r13 = (396)^4 = 24,591,257,856
;  r12 - Flag, term B done
;  r11 - Flag, term A done
;
;  ACC contains result, copied to Xreg
;
Function_calc_pi_ram:
	push	rax				; General use
	push	rbx				; Pass data to display update counter
	push	rcx				; Loop counter
	push	rsi				; Variable handle number
	push	rdi				; Variable handle number
	push	r11				; Flag Term A done
	push	r12				; Flag Term B done
	push	r13				; Holds (396)^4
	push	r14				; 4n for running 4n! calculation
	push	r15				; n counter

;	mov	rax, .msg_pi	;Print calculaton on screen
;	call	StrOut
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep] 		; print each 100 term
	mov	rax, 0x06000000			; set skip counter from rbx
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Initialize Register Variables
;
;
; At program start square root 2 expected in XREG
; Move square root of 2 from XREG to Reg0
;
	mov	rsi, HAND_XREG			; * * * XREG must contain Sqrt(2) at start
	mov	rdi, HAND_REG0
	call	CopyVariable			; Reg0 = sqrt(2)
;
; X-Reg: (Sum) Initialize to hold 1103 for term #0, Sum will start with term n=1
;
	mov	rsi, HAND_ACC
	mov	rax, 1103
	call	FIX_Load64BitNumber
;
; Reg1 (Term A) Initialize to 1103  n=0 in Term-A
;
	mov	rsi, HAND_REG1
	mov	rax, 1103
	call	FIX_Load64BitNumber
;
; Reg2 (Term B) Initialize to 25390 n=0 in Term-B
;
	mov	rsi, HAND_REG2
	mov	rax, 26390
	call	FIX_Load64BitNumber		; Reg2 = 26390
;
;  Initialize to 0 for summation index n at term 0
;
	mov	r15, 0				; R15 = 0 (n)
	mov	r14, 0				; R14 = 0 (4n)
	mov	r13, (396*396*396*396)		; R13 = (396^4)
	mov	r12, 0				; flag tern B not done
	mov	r11, 0				; flag term A not done
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
; Increment n in r15
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
	or	r11, r11			; R11 flag for Term A done
	jnz	.skip05
;
; Using r14, build the (4n)! in numerator
;
	mov	rsi, HAND_REG1			; RSI is Variable handle number
	mov	rcx, 4				; RCX is couner for LOOP command
.loopx1:
	inc	r14				; Previous n counter value
	mov	rax, r14			; Input for division
	call	FIX_US_Multiplication		; Reg1 = Reg1 * RAX
	loop	.loopx1				; Decrement RCX, loop again
	sub	r14, 4				; reduce by 4 for use with term B
;
; Using n, build (n!)^4 in denominator
;
	mov	rcx, 4				; REX is counter for LOOP command
.loopx2:
	mov	rax, r15			; R15 = n
	call	FIX_US_Division			; Reg1 = Reg1 / RAX
	loop	.loopx2
;
; Divide to build (396)^(4n) in denominator)
;
	mov	rax, r13			; RAX = (396)^4
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
	or	r12, r12			; R12 is flag for Term B done
	jnz	.skip07
;
; Using r14, build the (4n)! in numerator
;
	mov	rsi, HAND_REG2			; RSI is variable handle number
	mov	rcx, 4				; RCX is counter for LOOP command
.loopx3:
	inc	r14				; R14 is n counter value
	mov	rax, r14			; RAX input for multiplication
	call	FIX_US_Multiplication		; Reg2 = Reg2 / RAX
	loop	.loopx3				; Decrement RCX and loop again
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
; Using n, build (n!)^4 in denominator
;
	mov	rcx, 4				; RCX is loop couner
.loopx4:
	mov	rax, r15			; R15 = n value
	call	FIX_US_Division			; Reg2 = Reg2 / RAX
	loop	.loopx4				; Dec RCX and loop again
;
; Divide to build (396)^(4n) in denominator)
;
	mov	rax, r13			; RAX = (396)^4
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
	or	r11, r11
	jnz	.skip08
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	call	FIX_Addition			; ACC = ACC + Reg1
.skip08:
;
; Add term-B to sum
;
	or	r12, r12
	jnz	.skip09
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2
	call	FIX_Addition			; ACC = ACC + Reg2
.skip09:
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01110101 | 0x00000404 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Debug
;www
;	CMP	r15, 3
;	JE	.done
;	JMP	.loop
;
; Check if done
;
	mov	rsi, HAND_REG1
	call	FIX_Check_Sum_Done		; is Term A significant?
	mov	r11, rax
	mov	rsi, HAND_REG2
	call	FIX_Check_Sum_Done		; is Term B significant?
	mov	r12, rax
	ADD	rax, r11			; When done 1+1=2
	CMP	rax, 2				; Done?
	JNE	.loop				; no, not 2, loop again
;						; else done
.done:
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00030303 | 0x00000800 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; In future will do [1/root(2)] / ACC
;  So it is simple to divide by 9801 and mult x 2
;
	mov	rsi, HAND_ACC
	mov	rax, 9801
	call	FIX_US_Division			; ACC = ACC / 9801
;
	mov	rax, 2
	call	FIX_US_Multiplication		; ACC = ACC * 2
;
; Convert FIX to FP numbers
;
	mov	rsi, HAND_ACC
	call	Conv_FIX_to_FP
;	mov	rsi, HAND_REG1
;	call	Conv_FIX_to_FP
;	mov	rsi, HAND_REG2
;	call	Conv_FIX_to_FP
;
; Place 1 in OPR, divide by ACC
;
	mov	rsi, HAND_OPR
	call	SetToOne
	call	FP_Division			; ACC = Oper / ACC which is 1/sum
;
; Move ACC-->OPR, copy square root 2 from REG0 to ACC and divide sqrt(2)
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable
	mov	rsi, HAND_REG0			; Reg0 contains square root of 2
	mov	rdi, HAND_ACC
	call	CopyVariable
	call	FP_Division			; ACC = OPR/ACC Divide by square root 2
;
; Move result back to XReg
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable			; XReg = Pi (Done)
;
; Clear Temporary Variables
;
	mov	rsi, HAND_REG0
	call	ClearVariable
	mov	rsi, HAND_REG1
	call	ClearVariable
	mov	rsi, HAND_REG2
	call	ClearVariable

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
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax
	ret

.msg_pi:	DB	0xD, 0xA, 0xA, "Calculating Pi using Ramanujan formula", 0xD, 0xA, 0
