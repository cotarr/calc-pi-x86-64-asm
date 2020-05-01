;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Calculation of Roots and Powers
;
; File:   func-roots.asm
; Module: func.asm, func.o
; Exec:   calc-pi
;
; Created   10/27/2014
; Last Edit 01/04/2015
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
;
; for nth root of ACC
;
;  INPUT: rax = N for Nth root number, 2=square root, 3=cube 4=4th root
;         X-Reg = Floating point number A
;
; During calculation:
;    XReg - Original A
;    Reg0 - holds next/last guess (not preserved)
;    r15  - N of Nth root
;
; After calculation:
;    X-Reg - nth root of A
;    Reg0 - not preserved.
;
;-----------------------------------------
;
;  Method: Iterative approximations
;
;  X(i) = last guess   X(i+1) = next guess  A = input number
;
;                          n-1
;  X(i+1) =  [  (A / ( X(i)    ) ) + (X(i)*n) ] / n
;
;      Original A is in Xreg
;      First guess will be setup in REG0
;  A:
;      Move XREG to OPR
;      Move REG0 to ACC
;      Divide ACC = OPR/ACC
;  B:
;      Move ACC to OPR
;      Move REG0 to ACC
;      Divide ACC = OPR/ACC
;      Loop B   ; for (n - 1) divisions
;  C:
;      Move ACC to OPR
;      Move REG0 to ACC
;      Add ACC = OPR + ACC
;      Loop C   ; for (n-1) additions
;
;      Move ACC to OPR
;      Divide by N
;
;      Move ACC to REG0    ; to be next  guess
;
;      Compare Last guess in REG0 to average in ACC, are we done? If Done exit
;       Else, not done, loop to A
;
;-------------
;
;  To reduce time, accuracy is reduced early in the calc
;
;-------------
Function_nth_root_x:

	push	rax				; Working REgister
	push	rbx				; Used to command progress display tool
	push	rcx				; loop vairiable
	push	rdx				; Counter matching words
	push	rsi				; Variable handle
	push	rdi				; Variable handle
	push	rbp				; Pointer index
	push	r8				; Loop counter for main loop
	push	r9				; Minimum Accuracy
	push	r10				; Address Pointer
	push	r11				; Address Pointer
	push	r15				; Input value for nth root
;
; Save input value of N for Nth root
;
	mov	r15, rax 		; Input Value
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, 1				; print iteration counter
	mov	rax, 0x04000000			; set skip counter from rbx
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Check input in range
;
	mov	rax, r15			; Get n of nth root
	cmp	rax, 2				; Must be 2root or greater
	jl	.error1				; Root number Out of range
	cmp	rax, 1000			; Just some maximum
	jg	.error1				; Root number Out of range
	mov	AL, [FP_X_Reg+MAN_MSB_OFST]	; Get M.S. Byte
	test	AL, 0x80			; negative?
	jnz	.error2				; X-Reg negative
;
; Check for zero
;
	mov	AL, [FP_X_Reg+MAN_MSB_OFST]	; Get M.S. Byte
	test	AL, 0x40			; Is input zero?
	jnz	.not_zero
	mov	rsi, HAND_XREG
	call	ClearVariable			; if zero, result is zero
	jmp	.exit
.not_zero:
;
	call 	ClearGrabAccuracy		; initialize for reduce division accuracy
	mov	rax, [D_Flt_Word]		; Number words in mantissa
	sub	rax, MINIMUM_WORD		; less minimum words
	mov	[Last_Shift_Count], rax		; Accuray will be reduced at first
	mov	r9, rax				; Save for check later in program
;
; First make a guess, 1 is as good as any
; Place in WorkB
;
	mov	rax, 1
	mov	rsi, HAND_REG0
	call	FP_Load64BitNumber
;
	mov	r8, 0				; loop counter
;
;-----------------------------
;
;   M A I N    L O O P
;
;-----------------------------
;
.loopA:
;
	inc	r8				; increment loop counter
;
; Divide A / Guess  (first time outside loop)
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = A (got n-root(A)
	mov	rsi, HAND_REG0
	mov	rdi, HAND_ACC
	call	CopyVariable			; ACC = current guess


	call	ReduceSeriesAccuracy
	call 	FP_Division			; Acc = A / guess
	call	RestoreFullAccuracy
;
; Sub loop
;
	mov	rcx, r15			; rcx = n for nth root
	dec	rcx				; n-1 (for method)
	dec	rcx				; n-2 (already divided one time)
	jz	.skipN2				; dont divide again if n = 2
.loopB:
;
; Divide by guess again
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = in process number
	mov	rsi, HAND_REG0
	mov	rdi, HAND_ACC
	call	CopyVariable			; ACC = current guess
	call	ReduceSeriesAccuracy
	call 	FP_Division			; Acc = A / (product of guesses)
	call	RestoreFullAccuracy
	LOOP	.loopB
.skipN2:
;
;  Sub Loop
;
	mov	rcx, r15			; RCX = n for nth root
	dec	rcx				; for formula (n-1)
;
;  Add the guess (n-1) times)
;
.loopC:
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = A / (product of guesses)
	mov	rsi, HAND_REG0
	mov	rdi, HAND_ACC
	call	CopyVariable			; ACC = guess
	call	FP_Addition			; ACC = (A/(guesses) + (sum of guesses)
	LOOP	.loopC
;
; Divide by (n)
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; ACC = (A/(guesses) + (sum of guesses)
	mov	rax, r15				; rax = n for nth root
	mov	rsi, HAND_ACC
	call	FP_Load64BitNumber		; ACC = n
	call	ReduceSeriesAccuracy
	call 	FP_Division			; Acc = Average of new result and sum of old guesses
;	call	RestoreFullAccuracy
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01110101 | 0x00000804 | 0x20000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
;
; Checking to see if it is done
;
;
;  Skip first few iterations
;
	cmp	r8, 4				; Don't do first few terms, will false done
	jl	.skip02
;
;
;  Setup address pointers to variables
;
	mov	r10, FP_Acc			; Address of ACC
	mov	r11, FP_Reg0			; Address of Reg0
	mov	rbp, MAN_MSW_OFST		; Point at MSWord
	mov	rdx, 0				; Initialize word Counter
;
; loop checking if words match
;
.loop_ck:
	mov	rax, [r10+rbp]			; Get word from ACC
	cmp	rax, [r11+rbp]			; Compare to OPR
	jne	.skip01				; Not equal, exit
	sub	rbp, BYTE_PER_WORD		; point at next word
	inc	rdx				; Increment number of bytes same


	mov	rax, [D_Flt_Word]		; Total words in mantissa
	sub	rax, GUARDWORDS			; less guard words
	cmp	rdx, rax			; Significant words in mantissa
	jle	.loop_ck			; last of mantissa?

	mov	rax, [No_Word]			; Set to full accuracy?
	cmp	rax, [D_Flt_Word]
	jne	.skip01

	mov	rax, [Last_Shift_Count]		; 0 = temporary full accuracy
	or	rax, rax			; is it 0?, are we at full accuracy?
	jnz	.skip01				; No, not full accuracy yet

	jmp	.done				; End calculation, all mantissa words equial (except guard words)
.skip01:
;
;  rdx = count of the number of words that are the same
;  Want accuracy to be double this. Each next calculation
;  approximately doubles accuracy.
;
;  Calculate new accuracy
;
;  2014-12-07
;  at 100,000 digits square root 3
; 2x 55 sec 30 terms
; 3x 35 sec 22 terms
; 4x 39 sec 20 terms
; 5x 36 sec 19 terms
; 6x 45 sec 19 terms
; 8x 50 sec 19 terms
;
;
	mov	rax, rdx			; Fractional part
;;;	shl	rax, 1				; Scale for adition
	shl	rdx, 1				; Multiply accuracy shl = times 2
	add	rdx, rax			; Add
;
; Convert to [Last_Shift_count] so it can be used by existing accuracy functions
;
	mov	rax, [D_Flt_Word]		; Number words in mantissa
	sub	rax, rdx			; Subtract to get shift count
	mov	rdx, rax			; rdx = new shift count
	rcl	rax, 1				; Rotate MSBit into carry, negative?
	jnc	.skip01a			; Negative, adjust (Negative not allowed)
	mov	rdx, 0				; Shift count zero is full accuracy calculation
.skip01a:
;
; Check minimum accuracy
;
	mov	rax, rdx			;
	cmp	rax, r9
	jl	.skip1b
	mov	rdx, r9				; minimum shift count (see start of function)
.skip1b:
	mov	[Last_Shift_Count], rdx		; Shift count will be used next cycle
;
; First few terms skip to here without comparisson
;
.skip02:
;
; New Guess, move back to X to be the new guess on the next cycle
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG0
	call	CopyVariable			; move average result back to be next guess
;
; In case it gets stuck, escape after 100 loops
;www
;	cmp	r8, 1
;	jge	.done	;FOR DEBUGGING ONLY
;
; Loop back
;
	jmp	.loopA
.done:
;
; Restore full accuracy
;
	call	RestoreFullAccuracy		; just to be sure
;
; Exit with result in the XREG register
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
	mov	rsi, HAND_REG0
	call	ClearVariable

.exit:
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x000F0303 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Restore Registers
;
	pop	r15
	pop	r11
	pop	r10
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
;
.error1:
	mov	rax, .Msg_root_error1
	call	StrOut
	mov	rax, 0
	jmp	FatalError
;
.error2:
	mov	rax, .Msg_root_error2
	call	StrOut
	mov	rax, 0
	jmp	FatalError
;
.Msg_root_error1: 	db	0xD, 0xA, "Function_nth_root: Error, n of nth root out of range.", 0xD, 0xA, 0
.Msg_root_error2:	db	0xD, 0xA, "Function_nth_root: Error, Attempting root of negative number", 0xD, 0xA, 0

;------------------------------------------------------
;
; Function_IntPower
;
; Input X-Reg = number to raise to power
;       rax   = y for X^Y, integer value
;
; Result in X-Register
;
; This is intended to check n-Root calculations
;
;------------------------------------------------------
;
Function_int_power_x:
	push	rax				; Working REgister
	push	rbx				; Update counter
	push	rcx				; loop vairiable
	push	rsi				; Variable handle
	push	rdi				; Variable handle
;
; Setup variables and check for errors
;
	mov	rcx, rax			; rax = y of x^y
	dec	rcx
	mov	rax, rcx			; get count
	or	rax, rax			; Is it zero?
	jz	.error1
	shl	rax, 1				; Sign flag to carry
	jc	.error1				; Error, out of range
	cmp	rcx, 1001			; Random upper limit
	jg	.error1				; Error out of range
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, 1				; print iteration counter
	mov	rax, 0x00000000			; set skip counter from rbx
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Setup Variables
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_ACC
	call	CopyVariable			; ACC = number to square
;
; loop for multiply
;
.loopD:
;
; multiply result (n-1) times
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = result
	mov	rsi, HAND_XREG
	mov	rdi, HAND_ACC
	call	CopyVariable			; ACC = guess
	call	FP_Multiplication
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00001101 | 0x00000804 | 0xA0000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	LOOP	.loopD				; Dec rcx until done
;
;  save result in XREG
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00003303 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
.error1:
	mov	rax, .Msg_error1
	call	StrOut
	mov	rax, 0
	jmp	FatalError

.Msg_error1:	db	0xD, 0xA, "Function_IntPower: Error, input out of range", 0xD, 0xA, 0
