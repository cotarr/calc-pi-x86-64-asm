;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Calculation of exponential and log functions
;
; File:   funcl-exp.asm
; Module: func.asm, func.o
; Exec:   calc-pi
;
; Created   11/13/2014
; Last Edit 01/17/2015
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
; Function_exp_x:
;-------------------------------------------------------------

;===============================
;
;   Calculate  exp(x)
;
;===============================;
;
;  XReg = Sum
;  REG0 = Current term
;  REG1 = Original X
;  REG2 = N term
;
;
Function_exp_x:
	push	rax
	push	rbx
	push	rsi
	push	rdi

;
; Check for zero. If zero, return exp(0)= 1
;
	mov	rbx, FP_X_Reg			; Point RBX at Xreg variable
	mov	rax, [rbx+MAN_MSW_OFST]		; Get MS word
	or	rax, rax			; Check of ACC = 0
	jnz	.notZero			; Not zero, continue
	mov	rsi, HAND_XREG
	call	SetToOne			; If zero, set cosine to 1
        jmp     .exit				; then exit with result in X-Reg
.notZero:
;
; Used to reduce accuracy during divisions
;
	call	ClearGrabAccuracy		; initialize reduced accuracy variables
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep]		; print each 100 term
	mov	rax, 0x02000000			; set skip counter from rbx
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Initialize FP Variables
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_REG1
	call	CopyVariable			; REG1 = originial x value
	mov	rsi, HAND_XREG
	call	SetToOne			; first term 1
	mov	rsi, HAND_REG0
	call	SetToOne			; Current factorial = 1
	mov	rsi, HAND_REG2
	call	ClearVariable			; Count N
;Debug
; mov R12, 0

;--------------
;
;    L O O P
;
;--------------
;
; Increment N stored in Z-Reg leaving N in ACC
;
.loop:
	mov	rsi, HAND_REG2
	mov	rdi, HAND_ACC
	call	CopyVariable			; ACC = previous n
	mov	rsi, HAND_OPR
	call	SetToOne
	call	FP_Addition			; ACC = n+1
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2
	call	CopyVariable
;
; Calculate divide term factorial, leave in ACC
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_OPR
	call	CopyVariable			; Get last term
;
	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = (last term)/(n+1)
	call	RestoreFullAccuracy
;
; Mult numerator by x (x in acc to use short multiplication if possible)
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = term
;
	mov	rsi, HAND_REG1
	mov	rdi, HAND_ACC
	call	CopyVariable			; ACC = x value
;
	call	ReduceSeriesAccuracy
	call	FP_Multiplication		; ACC = (last term) * x
	call	RestoreFullAccuracy
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG0
	call	CopyVariable			; Reg0, remember running term
;
; Add term to sum
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = previous sum
	call	FP_Addition			; ACC = (previous sum) + (current term)
	call	GrabSeriesAccuracy		; Grab the Shift_Count and Nearly_Zero
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable			; XREG = running sum
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01110101 | 0x00000404 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Check if last term was not significant
;
		mov	rax, [Nearly_Zero]	; Check for done
	or	rax, rax
	jnz	.done				; Done go exit
	jmp	.loop				; Else loop back
.done:
;
;  Loop is finished because last term added not significant
;
	mov	rsi, HAND_REG0
	call	ClearVariable
	mov	rsi, HAND_REG1
	call	ClearVariable
	mov	rsi, HAND_REG2
	call	ClearVariable

;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00030003 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.exit:
	pop	rdi
	pop	rsi
	pop	rbx
	pop	rax
	ret

.msg_e:		db	0xD, 0xA, 0xA, "Calculating e using sum 1/n!", 0xD, 0xA, 0
.msg_err1:	db	0xD, 0xA, "Function_exp_x: Error: Can't calculate exp(0) with series summation.", 0xD, 0xA, 0

;------------------
; End func-exp.asm
;------------------
