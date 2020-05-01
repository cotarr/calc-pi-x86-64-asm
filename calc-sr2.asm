;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Calculation of Roots and Powers
;
; File:   calc-sr2.asm
; Module: calc.asm, calc.o
; Exec:   calc-pi
;
; Created   12/13/2014
; Last Edit 05/12/2015
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
; Function_calc_sr2:
;-------------------------------------------------------------
;
; Rewrite for use with Newton Raphson reciprocal functions.
;
;--------------------------------------------------------
;
; Calculate Square Root of 2
;
;  Input: none
;
; During calculation:
;    Reg0 - holds next/last guess (not preserved)
;
; After calculation:
;    XReg - Square root 2
;    Reg0 - not preserved.
;
;-----------------------------------------
;
;  Method: Iterative approximations
;
;  X(i) = last guess   X(i+1) = next guess  A = input number
;
;  X(i+1) =  [  (A / X(i) ) + (X(i)) ] / 2
;
;      First guess will be setup in REG0
;  A:
;      Move REG0 (guess) to ACC
;  B:
;      Calculate 1/ACC (Reciprocal)
;  C:
;      Move 2.000... to OPR
;  D:
;      Multiply OPR * (1/ACC)
;  E:
;      Move REG0 (guess) to OPR
;  F:
;      FP_Add (OPR+ACC) = ACC
;  G:
;      Divide by 2 by decrement exponent
;  H:
;      Check if Reg0 = ACC
;  I:
;      Move ACC --> REG0 (to be next guess)
;
;-------------
;
;  To reduce time, accuracy is reduced early in the calc
;
;-------------
Function_calc_sr2:
; Preserve registers
;
	push	rax				; Working REgister
	push	rbx				; Used to command progress display tool
	push	rcx				; loop vairiable
	push	rdx				; Counter matching words
	push	rsi				; Variable handle
	push	rdi				; Variable handle
	push	rbp				; Pointer index
;
;
	mov	rax, .Msg1
	call	StrOut
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, 1				; print iteration counter
	mov	rax, 0x04000000			; set skip counter from rbx
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; First make a guess, 1 is as good as any
; Place first guess into Reg0
;
	mov	rax, 1
	mov	rsi, HAND_REG0
	call	FP_Load64BitNumber
;
; Move a copy of the guess to the ACC register
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_ACC
	call	CopyVariable
;
; Reduce accuracy for the calculation
;
	mov	rax, 8				; initial accuracy
	mov	rbx, rax			; New value in RBX
	cmp	rbx, MINIMUM_WORD		; Below minimum ?
	jge	.skip1				; No, don't adjust
	mov	rbx, MINIMUM_WORD		; Else, yes, reset to minimum
.skip1:
	mov	rax, [D_Flt_Word]		; Maximum mantissa size
	cmp	rax, rbx			; Over maximum size?
	jge	.skip2				; No don't adjust
	mov	rbx, rax			; Else, yes, reset to maximum
.skip2:
	mov	rax, rbx			; rax input to function
	call	Set_No_Word_Temp		; Set accuracy
;
; Initialize loop counter
;
	mov	r8, 0				; loop counter
;
;-----------------------------
;
;   M A I N    L O O P
;
;-----------------------------
;
.loop:
;
	inc	r8				; increment loop counter
;
; For debugging, exit if counter over limit
;
	cmp	r8, 200
	jl	.limitOK
	mov	rax, .Msg_Error1
	call	StrOut
	mov	rax, 0
	jmp	FatalError
.limitOK:
;
; Calculate reciprocal of guess Guess  (first time outside loop)
;
	call	FP_Reciprocal			; ACC = 1/Guess = 1/Reg0
;
; This is alternate way to calculate reciprocal using
; floatig point division.
;
;	mov	rax, 1
;	mov	rsi, HAND_OPR
;	call	FP_Load64BitNumber		; OPR = 1
;	call	FP_Division			; ACC = 1/ACC = 1/Guess
;
;
; Multiply 2 * (1/guess)
;
	mov	rax, 2
	mov	rsi, HAND_OPR
	call	FP_Load64BitNumber		; OPR = 2 (for root 2)
;
	call	FP_Multiplication		; ACC =  OPR*ACC = 2 * (1/guess)
;
; Add to last guess
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR is last guess
;
; Add last guess + new guess
;
	call	FP_Addition			; ACC = (last guess) + (new guess)
;
; Divide by two by decrement exponent
;
	mov	rbx, FP_Acc+EXP_WORD_OFST
	DEC	QWORD [rbx]			; ACC = average --> (last+new)/2

;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01110101 | 0x00000804 | 0x20000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
;  Skip first few iterations
;
	cmp	r8, 4				; Don't do first few terms, will false done
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
	mov	rax, [No_Word]			; Get program accuracy
	cmp	rax, [D_Flt_Word]		; Compare reduced accuracy
	jne	.skip01				; Not full accuracy, don't exit
;
; Exit check, if matching enough word and if at full accuracy

	mov	rax, [No_Word]			; Get word count
	sub	rax, GUARDWORDS			; Subtract guard words
	add	rax, 1				; Option to match guard word (see below)
;----------------------------------------
; at 1,000,000 digits and 3 guard words
;
; #1 with add rax,1 greater than 1 guard word
; 36 term 258 Seconds 00:04:18 (with add rbx,1)
; 2 - (sr2*sr2) = 2.0856 E-1000032
; 33: 32765 No_Word: 51909
; 34: 51906 No_Word: 51909
; 35: 51906 No_Word: 51909
; Then done
;
; #2 without add,rax,1 (all mantissa match)
; 33 term 156 Seconds 00:02:36 (without)
; 2 - (sr2*sr2) = +2.0856 E-1000032
; 31: 16381 No_Word: 32768
; 32: 32763 No_Word: 51909
; 33: 32765 No_Word: 51909
; Then done
;
; Set guard word from 3to 4 and repeat,
; also did same Add,1 in FP_Reciprocal
;  Repeat test:
;
; #1 with add rax,1 greater than 1 guard word
; 34 term 155 Seconds 00:02:35
;
; #2 without add,rax,1 (all mantissa match)
; 34 term 155 Seconds 00:02:35
;
; Conclusion, for Newton Raphson approximations
; it is necessary to have 4 guard words.
;---------------------------------------------
;
;
;----------------------------------------
	cmp	rcx, rax			; Compare number of bytes the same
	jl	.skip01				; Do another iteration?
	jmp	.done				; End calculation, enough words match
;
; Adjust accuracy, rcx = mumber of words the same
;
.skip01:
	mov	rax, [No_Word]			; Get current mantissa size
	shr	rax, 1				; Divide by 2, wait until half of words match
	cmp	rcx, rax			; Are matching words more than half of words
	jl	.skip02				; No don't adjust accuracy
;
	mov	rbx, [No_Word]			; Get accuracy
	shl	rbx, 1				; Increase X 2
	mov	rax, [D_Flt_Word]		; Maximum mantissa size
	cmp	rax, rbx			; Over maximum size?
	jge	.skip_sa2			; No don't adjust
	mov	rbx, rax			; Else, yes, reset to maximum
.skip_sa2:
	mov	rax, rbx			; For call
	call	Set_No_Word_Temp
;
; Move result back to Reg0 to become next n+1 guess
;
.skip02:
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG0
	call	CopyVariable			; Reg0 = next guess
; Debug Code

%IFDEF xcv
;
;  Debug printing
;
	mov	rax, .Msg4
	call	StrOut
	mov	rax, r8
	call	PrintWordB10
	mov	AL, ' '
	call	CharOut
	mov	rax, .Msg2
	call	StrOut
	mov	rax, rcx
	call	PrintWordB10
	mov	AL, ' '
	call	CharOut
	mov	rax, .Msg3
	call	StrOut
	mov	rax, [No_Word]
	call	PrintWordB10
	call	CROut
%ENDIF
;
; Loop back and perform another iteration
;
	jmp	.loop
;
;------------------------
;  Loop exit to here
;------------------------
;
.done:
;
; Copy result back to XREG
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
	mov	rsi, HAND_REG0
	call	ClearVariable
;
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
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
.Msg1:	db	"Calculating Square Root of 2", 0xD, 0xA, 0
.Msg_Error1:	db	"Function_calc_sr2: Error: loop counter exceed limit.", 0xD, 0xA, 0

; for debug printing
.Msg2:	db	"rcx: ", 0
.Msg3:	db	"No_Word: ", 0
.Msg4:	db	"r8: ", 0
