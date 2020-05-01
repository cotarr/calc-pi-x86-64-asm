;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Calculation of Trig functions
;
; File:   func-trig.asm
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
; Function_cos_x:
; Function_sin_x:
; Function_arcsin_x:
;-------------------------------------------------------------
;
;  Function:  cos(x)
;
;  Input:
;     XREG = Input number (X)
;
;  Program use:
;      REG0 = Sum
;      REG1 = Term (always positive, add sign on add)
;      REG2 = n
;      REG3 = x^2
;
;  Output:
;      XREG = Cos(X)
;
;  cos(x) = 1 - x^2/2! + x^4/4! - x^6/6! ...
;
;--------------------------------------------------------------
;
Function_cos_x:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rbp
	push	rsi
	push	rdi
	push	r8				; Used as (-1)^n counter
;
; Check for zero. If zero, return arccos(0) = 1
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
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep]		; print each 100 term
	mov	rax, 0x02000000			; set skip counter from rbx
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Used to reduce accuracy during divisions
;
	call	ClearGrabAccuracy		; initialize reduced accuracy variables
;
; Load 1 into Reg0 as initial sum
;
	mov	rsi, HAND_REG0
	call 	SetToOne			; Reg0 = 1 first term
;
; Load 1 into REG1 as first(previous) n=0 term
;
	mov	rsi, HAND_REG1
	call	SetToOne			; REG1 (term) = 1
;
;  Set n counter in REG2 to 0, for 2,4,6 ...
;
	mov	rsi, HAND_REG2
	call	ClearVariable			; REG2 = 0 (n counter)
;
; Load X*X int REG3
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_ACC
	call 	CopyVariable			; ACC = X the number
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = X the number
	call	FP_Multiplication		; OPR = X * X
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG3
	call	CopyVariable			; REG3 = x*x
;
; Init sign counter for (-1)^n
;
	mov	r8, 0
;
; * * * * * * * * * * * * * * * * * * * * * * * * * *
;
;  M A I N    L O O P
;
; * * * * * * * * * * * * * * * * * * * * * * * * * *
;
.loop1:
;
;  Add 1 to n
;
	mov	rsi, HAND_REG2
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last n
	mov	rsi, HAND_ACC
	call	SetToOne			; ACC = 1
	call	FP_Addition			; ACC = n+1
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2
	call	CopyVariable			; REG2 = n+1
;
; Move last term and divide by n+2
;
	mov	rsi, HAND_REG1
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (n+1)
	call	RestoreFullAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	call	CopyVariable			; [ REG1 = (last-term) / n+1
;
;  Add 1 to n
;
	mov	rsi, HAND_REG2
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last n
	mov	rsi, HAND_ACC
	call	SetToOne			; ACC = 1
	call	FP_Addition			; ACC = n+2
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2
	call	CopyVariable			; REG2 = n+2
;
; Move last term and divide by n+2
;
	mov	rsi, HAND_REG1
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (n+2)
	call	RestoreFullAccuracy
;
; Get X*X and multiply
;
	mov	rsi, HAND_REG3
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = X*X
	call	ReduceSeriesAccuracy
	call	FP_Multiplication		; ACC = term / (n+2)
	call	RestoreFullAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	call	CopyVariable			; REG1 is term, save for next
;
; If odd term change sign
;
	inc	r8				; sign counter
	test	r8, 1				; is bit 1 positive
	jz	.skip1
	mov	rsi, HAND_ACC
	call	FP_TwosCompliment		; Change sign
;
; get sum and add term
;
.skip1:
	mov	rsi, HAND_REG0
	mov	rdi, HAND_OPR
	call	CopyVariable
	call	FP_Addition
	call	GrabSeriesAccuracy
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
	jnz	.done1				; Done go exit
	jmp	.loop1				; Else loop back
;------------------------------------------------------------------
;
;       E X I T   L O O P 1
;
;------------------------------------------------------------------
.done1:
;
; Copy result to XREG
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_XREG
	call	CopyVariable
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00030303 | 0x00008000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Clear temporary variables
;
;	mov	rsi, HAND_REG0
;	call	ClearVariable
;	mov	rsi, HAND_REG1
;	call	ClearVariable
;	mov	rsi, HAND_REG2
;	call	ClearVariable
;	mov	rsi, HAND_REG3
;	call	ClearVariable
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00033003 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.exit:
	pop	r8
	pop	rdi
	pop	rsi
	pop	rbp
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret


;--------------------------------------------------------------
;
;  Function:  sin(x)
;
;  Input:
;     XREG = Input number = X
;
;  Program use:
;      REG0 = Sum
;      REG1 = Term (always positive, apply sin during add)
;      REG2 = n
;      REG3 = x^2
;
;  Output:
;      XREG = Sin(X)
;
; sin(x) = x - x^3/3! + x^5/5! - x^7/7! ....
;
;--------------------------------------------------------------
;
Function_sin_x:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rbp
	push	rsi
	push	rdi
	push	r8				; Used as (-1)^n counter
;
; Check for zero. If zero, return arcsin(0) = 0
;
	mov	rbx, FP_X_Reg			; Point RBX at Xreg variable
	mov	rax, [rbx+MAN_MSW_OFST]		; Get MS word
	or	rax, rax			; Check of ACC = 0
	jnz	.notZero			; Not zero, continue
        jmp     .exit				; then exit with result in X-Reg
.notZero:

;
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep]		; print each 100 term
	mov	rax, 0x02000000			; set skip counter from rbx
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Used to reduce accuracy during divisions
;
	call	ClearGrabAccuracy		; initialize reduced accuracy variables
;
; Load X into Reg0 as initial sum
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_REG0
	call 	CopyVariable			; REG0 = X the first term
;
; Load x into REG1 as first n=0 term
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_REG1
	call	CopyVariable			; REG1 (term) = x
;
;  Set n counter in REG2 to 1, for 1,3,5 ...
;
	mov	rsi, HAND_REG2
	call	SetToOne			; REG2 = 1 (n counter)
;
; Load X*X int REG3
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_ACC
	call 	CopyVariable			; ACC = X the number
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = X the number
	call	FP_Multiplication		; OPR = X * X
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG3
	call	CopyVariable			; REG3 = x*x
;
; Init sign counter for (-1)^n
;
	mov	r8, 0
;
; * * * * * * * * * * * * * * * * * * * * * * * * * *
;
;  M A I N    L O O P
;
; * * * * * * * * * * * * * * * * * * * * * * * * * *
;
.loop1:
;
;  Add 1 to n
;
	mov	rsi, HAND_REG2
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last n
	mov	rsi, HAND_ACC
	call	SetToOne			; ACC = 1
	call	FP_Addition			; ACC = n+1
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2
	call	CopyVariable			; REG2 = n+1
;
; Move last term and divide by n+2
;
	mov	rsi, HAND_REG1
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (n+1)
	call	RestoreFullAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	call	CopyVariable			; [ REG1 = (last-term) / n+1
;
;  Add 1 to n
;
	mov	rsi, HAND_REG2
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last n
	mov	rsi, HAND_ACC
	call	SetToOne			; ACC = 1
	call	FP_Addition			; ACC = n+2
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2
	call	CopyVariable			; REG2 = n+2
;
; Move last term and divide by n+2
;
	mov	rsi, HAND_REG1
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (n+2)
	call	RestoreFullAccuracy
;
; Get X*X and multiply
;
	mov	rsi, HAND_REG3
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = X*X
	call	ReduceSeriesAccuracy
	call	FP_Multiplication		; ACC = term / (n+2)
	call	RestoreFullAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	call	CopyVariable			; REG1 is term,  save for next
;
; If odd term change sign
;
	inc	r8				; sign counter
	test	r8, 1				; is bit 1 positive
	jz	.skip1
	mov	rsi, HAND_ACC
	call	FP_TwosCompliment		; Change sign
;
; get sum and add term
;
.skip1:
	mov	rsi, HAND_REG0
	mov	rdi, HAND_OPR
	call	CopyVariable
	call	FP_Addition
	call	GrabSeriesAccuracy
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
	jnz	.done1				; Done go exit
	jmp	.loop1				; Else loop back
;------------------------------------------------------------------
;
;       E X I T   L O O P 1
;
;------------------------------------------------------------------
.done1:
;
; Copy result to XREG
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_XREG
	call	CopyVariable
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00030303 | 0x00008000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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
	mov	rax, (0x00033003 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.exit:
	pop	r8
	pop	rdi
	pop	rsi
	pop	rbp
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;--------------------------------------------------------------
;
;  Function:  arcsin(x)
;
;  Input:
;     XREG = Input number = X
;
;  Program use:
;      REG0 = Sum
;      REG1 = Term (always positive, apply sin during add)
;      REG2 = n
;      REG3 = x^2
;
;  Output:
;      XREG = arcsin(X)
;                   1   x^3     1*3   x^5     1*3*5   x^7
; arcsin(x) = x + ( - )*-   + ( --- )*-   + ( ----- )*- + ....
;                   2   3       2*4   5       2*4*6   7
;
;--------------------------------------------------------------
;
Function_arcsin_x:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rbp
	push	rsi
	push	rdi
;
; Check for zero. If zero, return arcsin(0) = 0
;
	mov	rbx, FP_X_Reg			; Point RBX at Xreg variable
	mov	rax, [rbx+MAN_MSW_OFST]		; Get MS word
	or	rax, rax			; Check of ACC = 0
	jnz	.notZero			; Not zero, continue
        jmp     .exit				; then exit with result in X-reg
.notZero:
;
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep]		; print each 100 term
	mov	rax, 0x02000000			; set skip counter from rbx
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Used to reduce accuracy during divisions
;
	call	ClearGrabAccuracy		; initialize reduced accuracy variables
;
; Load X into Reg0 as initial sum
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_REG0
	call 	CopyVariable			; REG0 = X the first term
;
; Load x into REG1 as first n=0 term
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_REG1
	call	CopyVariable			; REG1 (term) = x
;
;  Set n counter in REG2 to 0
;
	mov	rsi, HAND_REG2
	call	SetToOne			; REG2 = 1 (n counter)
;
; Load X*X int REG3
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_ACC
	call 	CopyVariable			; ACC = X the number
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = X the number
	call	FP_Multiplication		; OPR = X * X
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG3
	call	CopyVariable			; REG3 = x*x
;
; * * * * * * * * * * * * * * * * * * * * * * * * * *
;
;  M A I N    L O O P
;
; * * * * * * * * * * * * * * * * * * * * * * * * * *
;
.loop1:
;
; Move last term and multiply by n
;
	mov	rsi, HAND_REG2
	mov	rdi, HAND_ACC
	call	CopyVariable			; ACC = last n value
	mov	rsi, HAND_REG1
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
;	call	ReduceSeriesAccuracy
	call	FP_Multiplication		; ACC = term * n
;	call	RestoreFullAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	call	CopyVariable			; [ REG1 = (last-term) * n
;
;  Add 1 to n
;
	mov	rsi, HAND_REG2
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last n
	mov	rsi, HAND_ACC
	call	SetToOne			; ACC = 1
	call	FP_Addition			; ACC = n+1
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2
	call	CopyVariable			; REG2 = n+1
;
; Move last term and divide by n+1
;
	mov	rsi, HAND_REG1
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
;	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (n+1)
;	call	RestoreFullAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	call	CopyVariable			; [ REG1 = (last-term) / n+1
;
; Get X*X and multiply
;
	mov	rsi, HAND_REG3
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = X*X
;	call	ReduceSeriesAccuracy
	call	FP_Multiplication		; ACC = term * x^2
;	call	RestoreFullAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1
	call	CopyVariable			; REG1 is term, save for next
;
;  Add 1 to n
;
	mov	rsi, HAND_REG2
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last n
	mov	rsi, HAND_ACC
	call	SetToOne			; ACC = 1
	call	FP_Addition			; ACC = n+2
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2
	call	CopyVariable			; REG2 = n+2
;
; Move last term and divide by n+2, But... do not save result as next Reg1 term
;
	mov	rsi, HAND_REG1
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
;	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (n+2)
;	call	RestoreFullAccuracy

;
; get sum and add term
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_OPR
	call	CopyVariable
	call	FP_Addition
	call	GrabSeriesAccuracy
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
;www
	mov	rax, [Nearly_Zero]		; Check for done
	or	rax, rax
	jnz	.done1				; Done go exit
	jmp	.loop1				; Else loop back
;------------------------------------------------------------------
;
;       E X I T   L O O P 1
;
;------------------------------------------------------------------
.done1:
;
; Copy result to XREG
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_XREG
	call	CopyVariable
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00030303 | 0x00008000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Clear temporary variables
;
;	mov	rsi, HAND_REG0
;	call	ClearVariable
;	mov	rsi, HAND_REG1
;	call	ClearVariable
;	mov	rsi, HAND_REG2
;	call	ClearVariable
;	mov	rsi, HAND_REG3
;	call	ClearVariable
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00033003 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.exit:
	pop	rdi
	pop	rsi
	pop	rbp
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret


;------------------
;  End func-trig.asm
;------------------
