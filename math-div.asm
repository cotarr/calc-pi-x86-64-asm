;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Arithmetic functions:  Division
;
; File:   math-div.asm
; Module: math.asm, math.o
; Exec:   calc-pi
;
; Created:     10/23/2014
; Last edit:   05/08/2020
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
; FP_Division
; FP_Long_Division
; FP_Short_Division
; FP_Register_Division
; FP_Reciprocal
; _Sub_Reciprocal_Mult (internal use only)
; _Sub_Long_Reciprocal_Mult (internal use only)
;-------------------------------------------------------------
;
;   Floating Point Division
;
;   Input:  OPR register is the Numerator
;           ACC register is the Denominator
;
;   Output  ACC register contains the Quotient
;
;-------------------------------------------------------------
;
;-------------------------------------------------------------
;
;  FP_Division algorithm selector
;
;  Check ACC and check if short multiplication can be used
;
;---------------------------------------------------------------

FP_Division:
	; Preserve registers
	push	rax				; Working Reg
	push	rcx				; Loop Counter
	push	rbp				; Pointer Index
	push	r10				; Pointer Address to FP_Acc
	;
	; Check if requested to disable auto Short Division
	;
	mov	rax, [MathMode]			; Get current value of mmode flag
	test	rax, 8				; Bit 0x08 = Disable: 64 bit i7 DIV with single word non-zero.
	jnz	.skip_short_division
	;
	;Check if capable to use short division
	;
	mov	r10, FP_Acc			; Address of ACC
	mov	rbp, MAN_MSW_OFST-BYTE_PER_WORD	; Check if all ACC words below MSW are zero
	mov	rcx, [No_Word]			; Loop Counter
	dec	rcx				; Adjust for 1 word down
	; OPTION SUB	rcx, GUARDWORDS		; Don't check guard words
.loop1:
	mov	rax, [r10+rbp]			; Get word from ACC
	or	rax, rax			; is it zero
	jnz	.skip_short_division		; Not zero, must do full multiplication
	sub	rbp, BYTE_PER_WORD		; Decrement index
	loop	.loop1				; Dec RCX, loop until all words checked
	;
	pop	r10
	pop	rbp
	pop	rcx
	pop	rax

	jmp	FP_Short_Division
	;
.skip_short_division:
	;
	mov	rax, [MathMode]			; Get current value of mmode
	test	rax, 2				; Bit 0x02 = Force: FP_Long_Div (binary shift and subtract)
	jnz	.full_bitwise_long_division
	;
	; In accordance with mmode [MathMode], take reciprocal and multiply in place of division
	;
	pop	r10
	pop	rbp
	pop	rcx
	pop	rax
	call	FP_Reciprocal			; Take reciprocal of divisor with intention to multiply
	;
	mov	rax, [MathMode]			; Get current value of mmode
	test	rax, 32				; Bit 0x020 = FP_Reciprocal: bitwise multiplication.
	jz	.skip_bitwise_mult
	;
	; Perform full binary long multiplication (of reciprocal)
	;
	jmp	FP_Long_Multiplication
	;
	; Else, perform 64 bit word multiplication with processor MUL commands
	;
.skip_bitwise_mult:
	jmp	FP_Word_Multiplication

	;
	; Else, Do the full binary long division
	;
.full_bitwise_long_division:
	pop	r10
	pop	rbp
	pop	rcx
	pop	rax
	jmp	FP_Long_Division

;
;-----------------------------------------
;
;  FP_Long_Division
;
;  Perform full binary long division
;
;  shift, subtract  --> borrow? --> CF
;
;-----------------------------------------
;
FP_Long_Division:
	; Preserve registers
	push	rax				; General use
	push	rbx				; Number of bits in mantissa (long division)
	push	rcx				; Loop Counting
	push	rdx				; Used DIV command
	push	rsi				; Variable handle number for function calls
	push	rdi				; Variable handle number for function calls
	push	rbp				; Variable offset address pointer
	push	r10				; Address ACC Variable
	push	r11				; Address OPR Variable
	push	r12				; Address WorkA Variable
	push	r13				; Address WorkB Variable
	;
	; In case profiling, increment counter for short and long methods
	;
%IFDEF PROFILE
	inc	qword [iCntFPDivLong]
%ENDIF
	;
	; Setup pointers Address Pointers
	;
	mov	r10, FP_Acc			; Address of ACC
	mov	r11, FP_Opr			; Addresss of OPR
	mov	r12, FP_WorkA			; Address of WorkA
	mov	r13, FP_WorkB			; Address of WorkF
	;
	; Check Divisior and Dividend to determine sign of Quotent
	;
	mov	rax, [r11+MAN_MSW_OFST]		; Get sign OPR
	xor	rax, [r10+MAN_MSW_OFST]		; XOR ACC sign to form result sign
	mov	[DSIGN], rax			; Save sign for later
	;
	; Check sign of ACC, if negative then call two's compliment
	;
	mov	rax, WORD8000			; Mask for sign bit
	test	[r10+MAN_MSW_OFST], rax		; Test M.S.Word of ACC
	jz	.skip1				; Positive, skip 2's comp.
	mov	rsi, HAND_ACC			; Handle number of ACC
	call	FP_TwosCompliment		; Form 2's compliment ACC
	;
	; Check ACC for zero, division by zero is fatal error, exit program
	;
.skip1:
	mov	rax, WORDFFFF			; Mask for bit test
	test	[r10+MAN_MSW_OFST], rax		; Test M.S.Word of ACC for zero
	jnz	.skip2				; Non-zero, continue
	mov	rax, .MsgDivZero
	call	StrOut
	mov	rax, 0x0			; else, Error Division by zero
	jmp	FatalError			; Print error and exit program
	;
	;Check sign of OPR, if negative then call two's compliment
	;
.skip2:
	mov	rax, WORD8000			; Mask for sign bit
	test	[r11+MAN_MSW_OFST], rax		; Test M.S.Word of OPR
	jz	.skip3				; Positive, skip 2's comp.
	mov	rsi, HAND_OPR			; Handle number of ACC
	call	FP_TwosCompliment		; Form 2's compliment ACC
	;
	; Check OPR for zero. If zero then return zero result
	;
.skip3:
	mov	rax, WORDFFFF			; Mask for bit test
	test	[r11+MAN_MSW_OFST], rax		; Test M.S.Word of OPR for zero
	jnz	.skip4				; non-zero, continue
	mov	rsi, HAND_ACC			; Case of ACC is zero
	call	ClearVariable			; Clear ACC, result is zero
	jmp	.exit				; and exit result 0/x = 0
.skip4:
	;
	;-------------------------
	; Long division routine for
	; full accuracy goes here
	;-------------------------
	;
	; Add exponents from  ACC and OPR, result in ACC
	;
	mov	rax, [r11+EXP_WORD_OFST]	; Get exponet OPR
	sub	rax, [r10+EXP_WORD_OFST]	; Subtract exponent ACC
	add	rax, 1				; Adjust Exponent
	mov	[r10+EXP_WORD_OFST], rax	; Save exponent in ACC
	;
	; Clear ACC variable and store exponent
	;
	mov	rsi, HAND_WORKA			; Point handle to WorkA
	call	ClearVariable			; Clear WorkA
	mov	rsi, HAND_WORKB			; Point handle to WorkB
	call	ClearVariable			; Clear WorkB
	;
	; Calculate the number of bits in mantissa, save in R10
	;
	mov	rbx, [No_Byte]			; Get number of types in Mantissa
	shl	rbx, 3				; X2, X4, X8 for 8 bit/byte
	sub	rbx, 1				; Adjust for sign bit
;
;=================================================================================
;
;    . Loop55 is start of main loop
;
;       Subtract WorkA[i] = OPR[i] - ACC[i]
;       If result negative (highest bit 1) then copy OPR = WorkA
;	Rotate OPR and WorkB left 1 bit at a time
;          For each cycle, if M.S.Bit of WorkA = 1 then Rotate 1 into L.S. Bit WorkB
;       When done all bits, result mantissa is in WorkB
;=================================================================================
;
.loop55:
	mov	rbp, [LSWOfst]			; Point at mantissa L.S.Word
	mov	rcx, [No_Word]			; Number of words
	;
	;   Loop through words. For each Word
	;        WorkA[i] = OPR[i] - ACC[i]
	;
	clc					; Clear CF for subtractions
.loop60:
	mov	rax, [r11+rbp]			; Get word from OPR
	sbb	rax, [r10+rbp]			; Subtract OPR-ACC word
	mov	[r12+rbp], rax			; Store in WorkA
	rcr	rdi, 1				; Temporarily save CF
	add	rbp, BYTE_PER_WORD		; Increment pointer to next word
	rcl	rdi, 1				; Restore CF
	loop	.loop60				; Decrement RCX and loop until done
	;
	; If the result of the subtraction is positive
	;   then move mantissa of WorkA to OPR
	;   else skip
	;
	mov	rax, WORD8000			; Sign bit mask
	test	[r12+MAN_MSW_OFST], rax		; Is WorkA result negative?
	jnz	.skip65				; Yes, leave OPR same
	;
	mov	rbp, [LSWOfst]			; Point L.S.Word
	mov	rcx, [No_Word]			; Counter number of words
.loop61:
	mov	rax, [r12+rbp]			; Get word from WorkA
	mov	[r11+rbp], rax			; Store word in OPR
	add	rbp, BYTE_PER_WORD		; Increment pointer
	loop	.loop61				; Decrement RCX, loop until done
	;
	; Rotate WorkB Left 1 bit
	;
.skip65:
	mov	rsi, HAND_WORKB			; Point handle to WorkB
	call	Left1Bit			; Shift left 1 bit
	;
	; Recycle left most bit from rotation WorkA into right most bit WorkB (out left in right)
	; This is similar to a RCL looping CF in a loop, but
	; due to sign bit, it does not actually rotate out like a CF in RCL
	;
	mov	rax, WORD8000			; Sign bit mask
	test	[r12+MAN_MSW_OFST], rax		; Was result in WorkA negative:
	jnz	.skip66				; Yes, roll bit in
	;
	mov	rbp, [LSWOfst]			; Get offset to current L.S. Word
	or	qword [r13+rbp], 1		; Shift (OR) a 1 into bit0 of  WorkB
	;
	;  Rotate OPR left 1 bit
	;     Thus WorkB and OPR rotate together 1 bit at a time
	;
.skip66:
	mov	rsi, HAND_OPR			; Point handle at OPR
	call	Left1Bit			; Shift OPR left 1 bit
	;
	; Decremen bit counter, loop until all bits rotated
	;
	dec	rbx				; Decrement bit counter
	or	rbx, rbx			; Reached zero, done?
	jz	.skip67				; Yes, done, skip ahead
	jmp	.loop55				; Loop back until all bits done
	;
	; Done main loop, result is in WorkB
	;
.skip67:
	mov	rdx, [r10+EXP_WORD_OFST]	; Temporarily save Exponent
	mov	rsi, HAND_WORKB			; Point handle at WorkB
	mov	rdi, HAND_ACC			; Point handle at ACC
	call	CopyVariable			; Move WorkB --> ACC
	mov	[r10+EXP_WORD_OFST], rdx	; Restore Exponent
;
.skip70:
	mov	rsi, HAND_ACC			; Point handle at ACC
	call	FP_Normalize			; Normalize ACC
	;
	; Get original sign from memory variable
	;   and perform 2's compliment if negative
	;

	mov	rax, [DSIGN]			; Get sign
	shl	rax, 1				; Shift sign bit to CF
	jnc	.exit				; Negative? No skip
	;
	mov	rsi, HAND_ACC			; Point handle at ACC
	call	FP_TwosCompliment		; Form 2's compliment ACC
	;
	; Done! Restore registers and exit result in ACC
	;
.exit:
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
.MsgDivZero:
	db	0xD, 0xA, "FP_Long_Divison: Error: Division by Zero", 0xD, 0xA, 0


;
;-----------------------------------------
;
;  FP_Short_Division
;
;  Internal (Called from FP_Division)
;
;  Use x86-64 DIV command to build result
;
;  Assumes all divisor words are zero except
;  the most significant word (Checked in FP_Division)
;
;  Input:  OPR register is the Numerator
;          ACC register is the Denominator
;
;  Output  ACC register contains the Quotient
;-----------------------------------------
;
FP_Short_Division:
	; Preserve registers
	push	rax				; General use
	push	rbx				; Number of bits in mantissa (long division)
	push	rcx				; Loop Counting
	push	rdx				; Used DIV command
	push	rsi				; Variable handle number for function calls
	push	rdi				; Variable handle number for function calls
	push	rbp				; Variable offset address pointer
	push	r10				; Address ACC Variable
	push	r11				; Address OPR Variable
	;
	; In case profiling, increment counter for short and long methods
	;
%IFDEF PROFILE
	inc	qword [iCntFPDivShort]
%ENDIF
	;
	; Setup pointers Address Pointers
	;
	mov	r10, FP_Acc			; Address of ACC
	mov	r11, FP_Opr			; Addresss of OPR
	;
	; Check Divisior and Dividend to determine sign of Quotent
	;
	mov	rax, [r11+MAN_MSW_OFST]		; Get sign OPR
	xor	rax, [r10+MAN_MSW_OFST]		; XOR ACC sign to form result sign
	mov	[DSIGN], rax			; Save sign for later
	;
	; Check sign of ACC, if negative then call two's compliment
	;
	mov	rax, WORD8000			; Mask for sign bit
	test	[r10+MAN_MSW_OFST], rax		; Test M.S.Word of ACC
	jz	.skip1				; Positive, skip 2's comp.
	mov	rsi, HAND_ACC			; Handle number of ACC
	call	FP_TwosCompliment		; Form 2's compliment ACC
	;
	; Check ACC for zero, division by zero is fatal error, exit program
	;
.skip1:
	mov	rax, WORDFFFF			; Mask for bit test
	test	[r10+MAN_MSW_OFST], rax		; Test M.S.Word of ACC for zero
	jnz	.skip2				; Non-zero, continue
	mov	rax, .MsgDivZero
	call	StrOut
	mov	rax, 0x0			; else, Error Division by zero
	jmp	FatalError			; Print error and exit program
	;
	;Check sign of OPR, if negative then call two's compliment
	;
.skip2:
	mov	rax, WORD8000			; Mask for sign bit
	test	[r11+MAN_MSW_OFST], rax		; Test M.S.Word of OPR
	jz	.skip3				; Positive, skip 2's comp.
	mov	rsi, HAND_OPR			; Handle number of ACC
	call	FP_TwosCompliment		; Form 2's compliment ACC
	;
	; Check OPR for zero. If zero then return zero result
	;
.skip3:
	mov	rax, WORDFFFF			; Mask for bit test
	test	[r11+MAN_MSW_OFST], rax		; Test M.S.Word of OPR for zero
	jnz	.skip4				; non-zero, continue
	mov	rsi, HAND_ACC			; Case of ACC is zero
	call	ClearVariable			; Clear ACC, result is zero
	jmp	.exit				; and exit result 0/x = 0
.skip4:
	;
	; Shift number right in M.S.Word
	;
	mov	rax, [r10+MAN_MSW_OFST]		; Get M.S.Word Mantissa
	mov	rbx, [r10+EXP_WORD_OFST]	; Get Exponent
.loop15:
	clc					; Clear CF for shift right
	rcr	rax, 1				; Shift right until L.S.Bit is 1
	jc	.skip20				; 1 was rotated to CF, too far, backup
	inc	rbx				; Inc Exponent to adjust for right shift
	jmp	short .loop15			; Always taken
.skip20:
	rcl	rax, 1				; Reverse last shift, was too far
	mov	[r10+MAN_MSW_OFST], rax		; Save ACC Mantissa
	mov	[r10+EXP_WORD_OFST], rbx
						; Save ACC Exponent
	mov	rbx, [r10+MAN_MSW_OFST]		; Store ACC M.S.Word in RBX for division (rest is zero)
	;
	; Add exponents, Clear ACC, and add exponent to cleared ACC
	;
	mov	rax, [r11+EXP_WORD_OFST]	; get OPR Exponent
	sub	rax, [r10+EXP_WORD_OFST]	; Subtract ACC Exponent
	add	rax, 63				; Adjust for shifting right to LSBit
	push	rax
	mov	rsi, HAND_ACC			; Variable handle number
	call	ClearVariable			; Clear ACC
	pop	rax
	mov	[r10+EXP_WORD_OFST], rax	; Restore Exponent
	;
	; Setup loop counter and index
	;
	mov	rcx, [No_Word]			; Loop Counter
	mov	rbp, MAN_MSW_OFST		; Point index to M.S.Word
	xor	rdx, rdx			; RDX Clear High 64 bit word for first time
	;
	; This is the main division loop  RAX = RDX:RAX/RBX,  remainder in RDX
	;
.loop30:
	mov	rax, [r11+rbp]			; Get word OPR in RAX
	div	rbx				; RAX = RDX:RAX / RBX Remainder in RDX
	mov	[r10+rbp], rax			; Add low word ACC
	sub	rbp, BYTE_PER_WORD		; Point next word
	loop	.loop30				; Decrement RCX, loop until done
	;
	; Normalize Result
	;
	mov	rsi, HAND_ACC			; Point handle at ACC
	call	FP_Normalize			; Normalize ACC
	;
	; Get original sign from memory variable
	;   and perform 2's compliment if negative
	;

	mov	rax, [DSIGN]			; Get sign
	shl	rax, 1				; Shift sign bit to CF
	jnc	.exit				; Negative? No skip
	;
	mov	rsi, HAND_ACC			; Point handle at ACC
	call	FP_TwosCompliment		; Form 2's compliment ACC
	;
	; Done! Restore registers and exit result in ACC
	;
.exit:
	pop	r11
	pop	r10
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
.MsgDivZero:
	db	0xD, 0xA, "FP_Short_Divison: Error: Division by Zero", 0xD, 0xA, 0


;-----------------------------------------
;
;  FP_Register_Division
;
;  Use x86-64 DIV command
;
;  Input RSI = Handle Number
;        RAX = Register denominator (top two bit must be zero)
;
;  Output pointed to by RSI handle
;
;-----------------------------------------
;
FP_Register_Division:
	; Preserve registers
	push	rax				; General use
	push	rbx				; Variable Address
	push	rcx				; Loop Counting
	push	rdx				; Used DIV command
	push	rsi				; Variable handle number for function calls
	push	rdi				; Variable handle number for function calls
	push	rbp				; Variable offset address pointer
	push	r10 				; Denominator (copyied input value)
	;
	; In case profiling, increment counter for short and long methods
	;
%IFDEF PROFILE
	inc	qword [iCntFPDivReg]
%ENDIF
	;
	; Save input and check valid range
	;
	mov	r10, rax			; get input value, save for DIV command
	or	rax, rax			; Check for zero
	jnz	.skip1
	mov	rax, .MsgDivZero		; Div by zero message
	call	StrOut
	mov	rax, 0
	jmp	FatalError
.skip1:
	rcl	rax, 1				; top bit must be zero
	jc	.range_err
	rcl	rax, 1
	jnc	.skip2
.range_err:
	mov	rax, .MsgRange
	call	StrOut
	mov	rax, 0
	jmp	FatalError
	;
	; Setup pointers Address Pointers
	;
.skip2:
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	;
	; Check Numerator to determine sign of Quotent
	;
	mov	rax, [rbx+MAN_MSW_OFST]		; Get sign of variable
	mov	[DSIGN], rax			; Save sign for later
	;
	;Check sign, if negative then call two's compliment
	;
	rcl	rax, 1				; Rotate sign bit to CF
	jnc	.skip3				; not negative
	call	FP_TwosCompliment		; Using RSI handle, form 2's compliment
	;
	; Check for zero. If zero then return zero result
	;
.skip3:
	mov	rax, [rbx+MAN_MSW_OFST]		; Test M.S.Word for zero
	or	rax, rax			; is it zero?
	jnz	.skip4				; non-zero, continue
	mov	rsi, HAND_ACC			; Case of zero
	call	ClearVariable			; Clear variable, result is zero
	jmp	.exit				; and exit result 0/x = 0
.skip4:
	;
	; Calculate exponents
	;
	mov	rax, [rbx+EXP_WORD_OFST]	; get Exponent
	add	rax, 0
	mov	[rbx+EXP_WORD_OFST], rax	; Restore Exponent
	;
	; Setup loop counter and index
	;
	mov	rcx, [No_Word]			; Loop Counter
	mov	rbp, MAN_MSW_OFST		; Point index to M.S.Word
	xor	rdx, rdx			; RDX Clear High 64 bit word for first time
	;
	; This is the main division loop  RAX = RDX:RAX/RBX,  remainder in RDX
	;
.loop30:
	mov	rax, [rbx+rbp]			; Get word OPR in RAX
	div	r10				; RAX = RDX:RAX / RBX Remainder in RDX
	mov	[rbx+rbp], rax			; Add low word ACC
	sub	rbp, BYTE_PER_WORD		; Point next word
	loop	.loop30				; Decrement RCX, loop until done
	;
	; Normalize Result
	;
	call	FP_Normalize			; Using RSI handle call Normalize
	;
	; Get original sign from memory variable
	;   and perform 2's compliment if negative
	;

	mov	rax, [DSIGN]			; Get sign
	shl	rax, 1				; Shift sign bit to CF
	jnc	.exit				; Negative? No skip
	;
	call	FP_TwosCompliment		; Using RSI Form 2's compliment ACC
	;
	; Done! Restore registers and exit result in ACC
	;
.exit:
	pop	r10
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
.MsgDivZero:
	db	0xD, 0xA, "FP_Register_Division: Error: Division by Zero", 0xD, 0xA, 0
.MsgRange:
	db	0xD, 0xA, "FP_Register_Division: Error: Zero expected in top two bits", 0xD, 0xA, 0


;------------------------------------------------
;
;  TO DO:  !!!  at low accuracy, check if variables cleared before increase accuracy
;                    why some work and some done, junk left in low end of variables?
;          Fine tune accuracy real time
;          fix jump labels
;
;------------------------------------------------
;
;  FP Reciprocal (1/X)
;
;  Input  Variable in ACC
;
;  Working Reg
;     ACC, WORKA, WORKB, WORKC
;     if mmode 32 (0x20), FP_Reg7 destroyed.
;
;     Variable OPR not used so division can preserve
;
;  Result   Variable in ACC
;
;  Use Newton Raphson method
;
;  D = Demonimator
;
;  x = 1/D ,  make guesses for next Xn
;
;  Xn+1 =  Xn + (Xn*(1-Xn*D))
;
;       Note: according to Wikipedia, alternate
;       Xn+1 = Xn(2-XnD) is simpler, but requires
;       double precision compare to formula used.
;
;
;  ACC      WorkC   WorkA     WorkB
;   D                                ACC contains original denominator
;                              D     WorkB - move D to work B (Move)
;                    Xn        D     WorkA - has next guess   (Set)
;  Xn*D              Xn        D     ACC   = Xn*D             (Multiply)
;  Xn*D       1      Xn        D     WorkC = 1                (Set)
;           1-Xn*D   Xn        D     WorkC = 1-(Xn*D)         (Subtract)
; Xn(1-XnD)          Xn        D     ACC   = xn(1-Xn*D)       (Multiply)
; Xn+Xn( )           Xn        D     ACC   = Xn+Xn(1-XnD)     (Add)
; Xn+Xn( )           Xn        D     Compare ACC and WorkA    (Compare)
;                    Xn+1      D     WorkA next Xn+1 = P      (Move)
;                    Xn+1      D     WorkA next Xn+1 = P      (Loop back)
;
;------------------------------------------------
FP_Reciprocal:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rbp
	push	rbp
	push	r8				; holds Carry Flag CF
	push	r9				; Loop Counter
	push	r10				; Address pointer
	push	r11				; Address pointer
	push	r12				; Address pointer
	push	r13				; Used in subroutine _Sub_Reciprocal_Mult
	push	r14				; Used in subroutine _Sub_Reciprocal_Mult
	push	r15				; Used in subroutine _Sub_Reciprocal_Mult
;
%ifdef PROFILE
	inc	qword [iCntFPRecip]		; If profiling, increment
%endif
	;
	; Check for division by zero error
	;
	mov	rax, WORD4000			; M.S.Bit is used as zero flag
	test	[FP_Acc+MAN_MSW_OFST], rax	; Check Zero bit in MSW mantissa
	jnz	.found_nonzero
	mov	rax, .Msg_Error3
	call	StrOut
	mov	rax, 0
	jmp	FatalError
.found_nonzero:
	;
	; Test sign bit and save for later
	;
	mov	rax, 0
	mov	[Recip_Sign], rax
	mov	rax, [FP_Acc+MAN_MSW_OFST]	; Check sign bit in MSW mantissa
	rcl	rax, 1				; Rotate sign in to CF
	jnc	.signbit_not_set
	mov	rax, 1
	mov	[Recip_Sign], rax		; Save sign for end of routine
	mov	rsi, HAND_ACC
	call	FP_TwosCompliment		; Make positive to do reciprocal
.signbit_not_set:
	;
	; Just to be sure range 0.5-1.0 normalize
	;
	mov	rsi, HAND_ACC
	call	FP_Normalize
	;
	; Calculate new exponent
	;
	mov	rax, 0x3F			; New exponent for fixed alignment
	sub	rax, [FP_Acc+EXP_WORD_OFST]	; adjust for mantissa 0.5-1.0
	mov	[Recip_Exp], rax		; Save for later
	;
	; Input Varaible in ACC is saved in WorkB and remains unchanged in WorkB
	;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_WORKB
	call	CopyVariable
	;
	; Align to fixed format
	;
	mov	rsi, HAND_WORKB
	call	Right1Word
	call	Left1Bit
	;
	mov	rsi, HAND_ACC
	call	ClearVariable
	mov	rdi, HAND_WORKA
	call	ClearVariable
	mov	rdi, HAND_WORKC
	call	ClearVariable

	;
	; First guess 0.75
	;
	mov	rsi, HAND_WORKA
	call	ClearVariable
		;   -->FEDCBA9876543210 Ruler
	mov	rax, 0x0000000000000000
	mov	[FP_WorkA+MAN_MSW_OFST], rax
	mov	rax, 0xC000000000000000
	mov	[FP_WorkA+MAN_MSW_OFST-BYTE_PER_WORD], rax
	mov	rax, 0x3F
	mov	[FP_WorkA+EXP_WORD_OFST], rax	; = 0.75
	;
	; Initialize variable accuracy
	;
	mov	rax, 8				; initial accuracy
	mov	rbx, rax			; New value in RCX
	cmp	rax, MINIMUM_WORD		; Below minimum ?
	jge	.skip_sa01			; No, don't adjust
	mov	rbx, MINIMUM_WORD		; Else, yes, reset to minimum
.skip_sa01:
	mov	rax, [No_Word]			; Maximum mantissa size
	cmp	rax, rbx			; Over maximum size?
	jge	.skip_sa02			; No don't adjust
	mov	rbx, rax			; Else, yes, reset to maximum
.skip_sa02:
	mov	[Recip_No_Word], rbx		; Set number of words
	shl	rbx, 3				; No word x 8
	mov	rax, MAN_MSW_OFST+BYTE_PER_WORD	; Top word + 1
	sub	rax, rbx			; Subtract higest word+1 - number words
	mov	[Recip_LSWOfst], rax		; Set LSW index

	; * * * * override for debugging 2 places
	mov	rax, [MathMode]
	test	rax, 0x10			; Force full accuracy?
	jz	.skip_full_accuracy		; No, leave reduced/variable accuracy
	;
	mov	rax, [No_Word]			; Force full accuracy
	mov	[Recip_No_Word], rax
	mov	rax, [LSWOfst]
	mov	[Recip_LSWOfst], rax
.skip_full_accuracy:
	;
	; initialize main loop counter
	;
	mov	r9, 0
.main_loop:
	;------------------------------------------
	; Main iteration loop for making guesses
	;------------------------------------------
	;
	;  Formula :   Xn+1 = Xn + Xn(1-DXn)
	;
	; ---- start clip formula -----
	mov	r10, FP_WorkB			; variable address
	mov	r11, FP_WorkA			; variable address
	mov	r12, FP_Acc			; Variable address
	call	_Sub_Reciprocal_Mult		; [R12] = [R11]*[R10]
	;
	; Load WorkC with properly aligned fixed point integer value 1
	;
	mov	rsi, HAND_WORKC
	call	ClearVariable
	mov	rbx, FP_WorkC
	mov	rbp, MAN_MSW_OFST
	mov	rax, 1
	mov	[rbx+rbp], rax			; Set WorkC = 1
	;
	;  Subtract WorkC = WorkC - ACC
	;
	mov	rbx, FP_WorkC
	mov	rdx, FP_Acc
	mov	rbp, [Recip_LSWOfst]
	mov	rcx, [Recip_No_Word]
	clc
	mov	r8, 0				; Temporarily hold CF
.loop_sub2:					; Enter loop
	mov	rax, [rbx+rbp]			; Get WorkC word
	rcr	r8, 1				; Restore CF
	sbb	rax, [rdx+rbp]			; Subtract ACC workd
	rcl	r8, 1				; Save CF
	mov	[rbx+rbp], rax			; Result WorkC = WorkC - ACC
	add	rbp, BYTE_PER_WORD		; Increment pointer
	loop	.loop_sub2			; Dec RCX and loop
	;
	; If negative 2's compliment
	;
	mov	rsi, 0
	mov	[Recip_2CF], rsi		; 2's compliment flag
	rcl	rax, 1				; Get CF
	jnc	.was_positive
	;
	mov	rax, 1
	mov	[Recip_2CF], rax		; 2's compliment flag
	;
	mov	rbp, [Recip_LSWOfst]
	mov	rcx, [Recip_No_Word]
	clc
	mov	r8, 0
.loop_sub3:
	xor	rax, rax			; RAX = 0
	rcr	r8, 1				; Get CF
	sbb	rax, [rbx+rbp]			; Sub 0-x = two's compliment
	rcl	r8, 1
	mov	[rbx+rbp], rax			; Result in WorkC
	add	rbp, BYTE_PER_WORD		; Increment Index
	loop	.loop_sub3			; Dec RCX and loop
;
.was_positive:
	mov	r10, FP_WorkA			; variable address
	mov	r11, FP_WorkC			; variable address
	mov	r12, FP_Acc			; Variable address
	call	_Sub_Reciprocal_Mult		; [R12] = [R11]*[R10]
	;
	;  ADD  ACC + WorkA = ACC
	;
	mov	rbx, FP_WorkA			; Source      WorkA
	mov	rdx, FP_Acc			; Destination ACC
	mov	rbp, [Recip_LSWOfst]		; Index
	mov	rcx, [Recip_No_Word]		; Counter
	clc
	mov	r8, 0				; Temporarily hold CF
	;
	; Add or subtract depending on if 2's compliment was done
	;
	mov	rax, [Recip_2CF]		; get flag
	or	rax, rax
	jz	.loop_add3			; do standard add
.loop_add2:
	mov	rax, [rbx+rbp]			; Get WorkC word
	rcr	r8, 1				; Restore CF
	sbb	rax, [rdx+rbp]			; Subtract ACC workd
	rcl	r8, 1				; Save CF
	mov	[rdx+rbp], rax			; Result ACC = WorkC - ACC
	add	rbp, BYTE_PER_WORD		; Increment pointer
	loop	.loop_add2			; Dec RCX and loop
	jmp	.did_2s_com
.loop_add3:					; Enter loop
	mov	rax, [rbx+rbp]			; Get WorkC word
	rcr	r8, 1				; Restore CF
	adc	rax, [rdx+rbp]			; Subtract ACC workd
	rcl	r8, 1				; Save CF
	mov	[rdx+rbp], rax			; Result ACC = WorkC + ACC
	add	rbp, BYTE_PER_WORD		; Increment pointer
	loop	.loop_add3			; Dec RCX and loop
.did_2s_com:

	;
   	inc	r9				; iteration counter
	;
	; Checking to see if it is done
	;
	;
	;  Skip first few iterations
	;
	cmp	r9, 4				; Don't do first few terms, will false done
	jl	.skip02
	;
	;  Setup address pointers to variables
	;
	mov	rbx, FP_Acc			; Next guess Xn
	mov	rdx, FP_WorkA			; Last guess Xn-1
	mov	rbp, MAN_MSW_OFST		; Point at MSWord
	mov	rcx, 0				; Initialize word Counter
	;
	; loop checking if words match
	;
.loop_ck:
	;
	; This counts in rcx how many words match
	;
	mov	rax, [rbx+rbp]			; Get word from ACC
	cmp	rax, [rdx+rbp]			; Compare to WorkA
	jne	.endloop			; Not equal, exit
	sub	rbp, BYTE_PER_WORD		; point at next word
	inc	rcx				; Increment number of bytes same
	mov	rax, [Recip_LSWOfst]
	cmp	rbp, rax			; Significant words in mantissa
	jge	.loop_ck			; la
.endloop:
	;
	; If at full accuracy, check for exit
	;
	mov	rax, [No_Word]			; Get program accuracy
	cmp	rax, [Recip_No_Word]		; Compare reduced accuracy
	jne	.skip01				; Not full accuracy, don't exit
	;
	; Exit check, if matching enough word and if at full accuracy
	;
	mov	rax, [No_Word]
	sub	rax, GUARDWORDS
	;------------------------------------------------------------
	; Have set minimum 4 guard words configured in var_header.inc 14Dec14
	;------------------------------------------------------------
	add	rax, 1				; Include top guard word
	cmp	rcx, rax
	jl	.skip01			;

	; Debug always loop exit with R8 coutner
	; jmp .skip01

	jmp	.done				; End calculation, all mantissa words equial while full accuracy
.skip01:

	;
	;  RCX = count of the number of words that are the same
	;  Want accuracy to be double this. Each next calculation
	;  approximately doubles accuracy.
	;
	; Adjust accuracy, RCX = mumber of words the same
	;

	mov	rax, rcx			; Get number bytes the same
	mov	rdx, 0				; For x86 MUL command
	mov	rbx, 250 ; <-- Adjust
	mul	rbx				; RDX:RAX = (current accuracy) * 100
	mov	rbx, 100
	div	rbx				; RAX = RDB:RAX/RBX
	mov	rbx, rax			; New proposed accuracy
	cmp	rbx, [Recip_No_Word]		; Check if less, happens sometimes
	jle	.skip02				; Don't decrease, only increase or same
	;
	; Set point exceeded, double accuracy
	;
	mov	rax, [No_Word]			; Maximum mantissa size
	cmp	rax, rbx			; Over maximum size?
	jge	.skip_sa2			; No don't adjust
	mov	rbx, rax			; Else, yes, reset to maximum
.skip_sa2:
	mov	[Recip_No_Word], rbx		; Set number of words
	shl	rbx, 3				; No word x 8
	mov	rax, MAN_MSW_OFST+BYTE_PER_WORD	; Top word + 1
	sub	rax, rbx			; Subtract higest word+1 - number words
	mov	[Recip_LSWOfst], rax		; Set LSW index

	;aaa3 * * * * override for debugging (2 places)
	mov	rax, [MathMode]
	test	rax, 0x10			; Force full accuracy?
	jz	.skip_facc2			; No, leave reduced/variable accuracy
	;
	mov	rax, [No_Word]			; Force full accuracy
	mov	[Recip_No_Word], rax
	mov	rax, [LSWOfst]
	mov	[Recip_LSWOfst], rax
.skip_facc2:
.skip02:

	;
	;  Keep going, ACC becomes new guess
	;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_WORKA			; make next guess
	call	CopyVariable

  	jmp	.main_loop
	;
	;------------------------
	;  Exit to loop here
	;------------------------
.done:

	mov	rax, [Recip_Exp]		; Get Exponent
	mov	[FP_Acc+EXP_WORD_OFST], rax
	 					; Restore Exponent
	mov	rsi, HAND_ACC
	call	FP_Normalize
	;
	mov	rax, [Recip_Sign]		; Get sign
	or	rax, rax			; Was sign flag set?
	jz	.exit
	mov	rsi, HAND_ACC
	call	FP_TwosCompliment		; Result neg, perform 2's compliment
.exit:
	pop	r15
	pop	r14
	pop	r13
	pop	r12
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
.Msg_Error3:	db	"FP_Reciprocal: Error: Division by zero error!", 0xD, 0xA, 0
.Msg_Error4:	db	"FP_Reciprocal: Error: loop counter exceeded limit.", 0xD, 0xA, 0


;-----------------------------------------------
;
;   Subroutine to FP_Reciprocal
;
;   DO NOT call THIS FROM OTHER FUNCTIONS
;   Registers not preserved, non-standard word alignment
;
;   Derived from Math_Word_Multiplication (see for more info)
;
;   Input:  R10 (address #1 variable)
;           R11 (address #2 variable)
;           R12 (address #3 variable)
;           Recip_LSWOfst - pointer to LSWord (uses variable accuracy)
;           Recip_No_Word - number words in mantissa (uses variable accuracy)
;
;   [R10]*[R11] = [R12]
;
;    Fixed point number must be aligned so that
;    M.S Word of mantissa 0000000000000001 is 1
;    and  * * *  input is 0.5 to 1 range
;
;  Pseudo Code showing indexing loops
;
;  [LSWOfst]-->RSI
;  MAN_MSW_OFST -->R15
;  Loop1
;      R15->RDI
;      [LSWOfst]->R14
;      Loop2
;	    R14->RBP
;           Multiply [RSI]*[RDI]--> ADD LSW --> [RBP]
;           Inc RBP
;           From Multipl            ADD MSW --> [RBP]
;             Loop3
;		INC RBP (Exit loop 3?)
;		Add Carry Flag --> [RBP]
;             End-Loop3
;           Inc R14
;           Inc RDI (Exit Loop2?)
;      End-Loop2
;      DEC R15
;      INC RSI (Exit Loop1?)
;  End-Loop1
;
;  Conditions for trace
;
;  X = RSI
;     Y = RDI
;        L = RBP (Low 64 bit word)
;        H = RBP+1 (High 64 bit word)
;             cf = RBP (carry flag added)
;
; Trace 8 word multiplication
;
; X-56
; Y-112 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
;
; X-64
; Y-104 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-112 L-64 H-72 cf-80 cf-88 cf-96 cf-104 cf-112
;
; X-72
; Y-96 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-104 L-64 H-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-112 L-72 H-80 cf-88 cf-96 cf-104 cf-112
;
; X-80
; Y-88 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-96 L-64 H-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-104 L-72 H-80 cf-88 cf-96 cf-104 cf-112
; Y-112 L-80 H-88 cf-96 cf-104 cf-112
;
; X-88
; Y-80 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-88 L-64 H-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-96 L-72 H-80 cf-88 cf-96 cf-104 cf-112
; Y-104 L-80 H-88 cf-96 cf-104 cf-112
; Y-112 L-88 H-96 cf-104 cf-112
;
; X-96
; Y-72 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-80 L-64 H-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-88 L-72 H-80 cf-88 cf-96 cf-104 cf-112
; Y-96 L-80 H-88 cf-96 cf-104 cf-112
; Y-104 L-88 H-96 cf-104 cf-112
; Y-112 L-96 H-104 cf-112
;
; X-104
; Y-64 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-72 L-64 H-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-80 L-72 H-80 cf-88 cf-96 cf-104 cf-112
; Y-88 L-80 H-88 cf-96 cf-104 cf-112
; Y-96 L-88 H-96 cf-104 cf-112
; Y-104 L-96 H-104 cf-112
; Y-112 L-104 H-112
;
; X-112
; Y-56 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-64 L-64 H-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-72 L-72 H-80 cf-88 cf-96 cf-104 cf-112
; Y-80 L-80 H-88 cf-96 cf-104 cf-112
; Y-88 L-88 H-96 cf-104 cf-112
; Y-96 L-96 H-104 cf-112
; Y-104 L-104 H-112 ( CF = 1 is error )
; Y-112 L-112 ( [H] > 0 is error )
;
;
;-----------------------------------------------
_Sub_Reciprocal_Mult:
;
%ifdef PROFILE
	inc	qword [iCntFPRecipMul]		; If profiling, increment
%endif
	;
	;----------------------------------------------------
	;;;  Alternate multiplication using bit-wise method
	;    Warning, bitwise destroys FP_Reg7
	;
	mov	rax, [MathMode]			; Get current value of mmode
	test	rax, 32				; Bit 0x20 = FP_Reciprocal: bitwise multiplication
	jz	.skip_bitwise
	jmp	_Sub_Long_Reciprocal_Mult
	;----------------------------------------------------
	;
.skip_bitwise:

	push	r9				; Parent routine loop counter (Preserve)
	;
	; Clear output variable
	;
	mov	rax, 0
	mov	[r12+EXP_WORD_OFST], rax	; Clear exponent word
	mov	rbp, MAN_MSW_OFST		; Index to mantissa
	mov	rcx, [Recip_No_Word]		; Counter
.loopclr:
	mov	[r12+rbp], rax			; Clear word
	sub	rbp, BYTE_PER_WORD
	loop	.loopclr			; Dec RCX and loop
	;
	; Setup RSI to index input words (operand #1) for multiplicatioon
	;
	mov	rsi, [Recip_LSWOfst]		; Index for Loop-1
	mov	r15, MAN_MSW_OFST		; Used to initialize Loop-2 Index
	mov	r8, 0				; Holds carry flag during addition

%define DIxxxxVTRACE
;---------------
;  L O O P - 1
;---------------
.mult_loop_1:
; - - - T R A C E - - - -
%ifdef DIVTRACE
	call	CROut
	call	CROut
	mov	al, 'X'
	call	CharOut
	mov	al, '-'
	call	CharOut
	mov	rax, rsi
	call	PrintWordB10
	mov	al, ' '
	call	CharOut
%endif
; - - - - - - - - - - - -

	;
	; Setup RDI to index input words (operand #2) for multiplicatioon
	;
	mov	rdi, r15			; Index for Loop-2
	mov	r14, [Recip_LSWOfst]		; To initialize Loop-3
;
;---------------
;  L O O P - 2
;---------------
.mult_loop_2:
	;
	; Initialize rbp index to store output (product) of multiplication
	;
	mov	rbp, r14			; Used for save pointer and also
;
; - - - T R A C E - - - -
%ifdef DIVTRACE
	call	CROut
	mov	al, 'Y'
	call	CharOut
	mov	al, '-'
	call	CharOut
	mov	rax, rdi
	call	PrintWordB10
	mov	al, ' '
	call	CharOut
%endif
; - - - - - - - - - - - -
						; used to initialize Loop-3
	;
	; Perform X86 Multiplication RAX * RBX = RDX:RAX
	;
	mov	rbx, [r10+rsi]
	mov	rax, [r11+rdi]
	mov	rdx, 0
	mul	rbx				; Multiply RAX * RBX = RDX:RAX
	;
	;  Save Result of multiplication
	;
	;
	;  Add Low Word to Result [R12] from RBP variable handle
	;
	mov	r8, 0				; Clear previous carry flags
	add	[r12+rbp], rax			; Add L.W.Word of mult to result
	rcl	r8, 1				; Save CF

; - - - T R A C E - - - -
%ifdef DIVTRACE
	mov	al, 'L'
	call	CharOut
	mov	al, '-'
	call	CharOut
	mov	rax, rbp
	call	PrintWordB10
	mov	al, ' '
	call	CharOut
%endif
; - - - - - - - - - - - -

	;
	; Increment index to high word
	;
	add	rbp, BYTE_PER_WORD 		; Increment index to next word
	cmp	rbp, (MAN_MSW_OFST+BYTE_PER_WORD)
	jl	.not_out_range1			; Skip if above top word (should have zero data)
	or	rdx, rdx			; Throwaway nonzero?
	jz	.exit_loop_3			; This is expected, skip and move on
	;
	; Error, overflow word non zero
	;
	mov	al, ' '				; Else ... Fatal Error
	call	CharOut
	mov	rax, rdx
	call	PrintHexWord
	mov	al, ' '
	call	CharOut
	mov	rax, .Msg_Error1
	call	StrOut
	mov	rax, 0
	jmp	FatalError
	;
.not_out_range1:
	;
	; Add high word result from MUL
	;
	rcr	r8, 1				; Restore CF from low word
	adc	[r12+rbp], rdx			; Add CF and MSW of multiplication
	rcl	r8, 1				; Save CF

; - - - T R A C E - - - -
%ifdef DIVTRACE
	push	rax
	mov	al, 'H'
	call	CharOut
	mov	al, '-'
	call	CharOut
	mov	rax, rbp
	call	PrintWordB10
	mov	al, ' '
	call	CharOut
	pop	rax
%endif
; - - - - - - - - - - - -

;---------------
;  L O O P - 3
;---------------
.mult_loop_3:
	;
	; Loop 3 is to add carry flag to higher words
	;
	;
	test	r8, 1				; see if carry flag
%ifndef DIVTRACE
	jz	.exit_loop_3			; no carry to add, exit loop
%endif
	add	rbp, BYTE_PER_WORD		; Increment index to next word
	cmp	rbp, (MAN_MSW_OFST+BYTE_PER_WORD)
	 					; Check if above M.S. Word
	jl	.mult_l_3_add			; No, less, go and add carry flag
	test	r8, 1				; Was CF set? expect CF =zero
	jz	.exit_loop_3			; CF was not set, expected, exit loop
	mov	rax, .Msg_Error2		; Else CF not expected, fatal error
	call	StrOut
	mov	rax, 0
	jmp	FatalError
.mult_l_3_add:
	rcr	r8, 1				; Restore CF
	adc	qword [r12+rbp], 0		; Add CF
	rcl	r8, 1				; Save CF again

; - - - T R A C E - - - -
%IFDEF DIVTRACE
	push	rax
	mov	al, 'c'
	call	CharOut
	mov	al, 'f'
	call	CharOut
	mov	al, '-'
	call	CharOut
	mov	rax, rbp
	call	PrintWordB10
	mov	al, ' '
	call	CharOut
	pop	rax
%ENDIF
; - - - - - - - - - - - -

	;
	;  Loop until add of carry not needed
	;
	jmp	.mult_loop_3
;---------------
;  E N D - 3
;---------------
.exit_loop_3:
	;
	; Increment/Decrement index, check done, else loop
	;
	add	r14, BYTE_PER_WORD
	add	rdi, BYTE_PER_WORD
	cmp	rdi, (MAN_MSW_OFST+BYTE_PER_WORD)
	jne	.mult_loop_2
;---------------
;  E N D - 2
;---------------
	;
	; Increment/Decrement index, check done, else loop
	;
	sub	r15, BYTE_PER_WORD		; For RDI
	add	rsi, BYTE_PER_WORD
	cmp	rsi, (MAN_MSW_OFST+BYTE_PER_WORD)
						; Next ACC Word
	jne	.mult_loop_1
;---------------
;  E N D - 1
;---------------

.exit:
	pop	r9
	ret
.Msg_Error1:
	db	"FIX_Reciprocal_Mult: RAX non-zero", 0xD, 0xA, 0
.Msg_Error2:
	db	"FIX_Reciprocal_Mult: Error, loop-3 expect CF = 0 but was set", 0xD, 0xA, 0

;------------------------------------------------------------------------------------
;
;  This is a bitwise multiplication used only in reciprocal calculation
;
;  Recip_LSWOfst - pointer to LSWord (uses variable accuracy)
;  Recip_No_Word - number words in mantissa (uses variable accuracy)
;
;  [R12] = [R10] * [R11] with [R10] and [R11] preserved
;
;
;                         W A R N I N G
;
;  if mmode bit 32 x020, then Bitwise multiplication destroys FP_Reg7
;
;  TODO don't destroy FP_Reg7
;
;------------------------------------------------------------------------------------

_Sub_Long_Reciprocal_Mult:
	;
	; Preserve registers
	;
	push	rax				; Working Reg
	push	rbx				; Used for 64 bit multiplication i85 MUL
	push	rcx				; Loop Counter
	push	rdx				; Used 64 bit multiplication i86 MUL
	push	rsi				; Operand 1 Variable Handle number
	push	rdi				; Operand 2 Variable Handle number
	push	rbp				; Pointer Index
	push	r8				; Working Reg
	push	r9				; Working Reg
	push	r10				; Variable address assigned by calling program
	push	r11				; Variable address assigned by calling program
	push	r12				; Variable address assigned by calling program
	push	r13				; Pointer to FP_Reg7 as temp variable

	; ---------------
	; W A R N I N G    FP_Reg7 used as working variable pointed to by R13 (Contents Destroyed)
	;----------------
	mov	r13, FP_Reg7			; Point R13 at FP_Reg7
	;
	; Copy [R10] Variable into [r13]
	;
	mov	rbp, EXP_MSW_OFST		; RBX point at most significant Word
	mov	rcx, [Recip_No_Word]		; Current size of mantissa
	add	rcx, EXP_WSIZE			; Bytes in exponent
 .loop10:
	mov	rax, [r10+rbp]			; Read Word
	mov	[r13+rbp], rax			; Write Word
	sub	rbp, BYTE_PER_WORD		; Increment Address
	loop	.loop10				; Decrement RCX counter and loop
	;
	; Clear [R12] variable
	;
	mov	rbp, EXP_MSW_OFST		; RBX point at most significant Word
	mov	rcx, [Recip_No_Word]		; Current size of mantissa
	add	rcx, EXP_WSIZE			; Bytes in exponent
	xor	rax, rax				; Clear RAX = 0
 .loop20:
	mov	[r12+rbp], rax			; Write Word
	sub	rbp, BYTE_PER_WORD		; Increment Address
	loop	.loop20				; Decrement RCX counter and loop
	;
	; Calculate number of bits in mantissa
	;
	mov	r8, [Recip_No_Word]		; Get number of types in Mantissa
	shl	r8, 6				; X2, X4, X8, x16, x32, x64 for 64 bit/word
	sub	r8, 1				; Adjust for sign bit

	;  Loop to shift both [R12] and [R13] to right 1 bit at a time
	;  If a non-zero bit is shifted out of least significant bit
	;  then add the [R10] mantissa to the [R12] mantissa.
	;  Continue until all bits are shifted (Shift count in R8 is zero).
	;

.main_loop:
	mov	rbp, [Recip_LSWOfst]		; pointer to LS Word (use LS Bit later)
	mov	r9, [r13+rbp]			; Get L.S. Word [r13]
	;
	; Rotate [R13] right 1 bit
	;
	mov	rbp, MAN_MSW_OFST		; RBP point at most significant Word
	mov	rcx, [Recip_No_Word]		; Current size of mantissa
;
	clc					; Clear Carry before addition
.loop30:
	rcr	qword[r13+rbp], 1		; Rotate right 1 bit, CF --> word --> CF
	rcl	rax, 1				; Save CF
	sub	rbp, BYTE_PER_WORD		; RBX decrement to next word
	rcr	rax, 1				; Restore CF
	loop	.loop30
	;
	; Rotate [R12] right 1 bit
	;
	mov	rbp, MAN_MSW_OFST		; RBX point at most significant Word
	mov	rcx, [Recip_No_Word]		; Current size of mantissa
	clc					; Clear Carry before addition
.loop40:
	rcr	qword[r12+rbp], 1		; Rotate right 1 bit, CF --> word --> CF
	rcl	rax, 1				; Save CF
	sub	rbp, BYTE_PER_WORD		; RBX decrement to next word
	rcr	rax, 1				; Restore CF
	loop	.loop40

	test	r9, 1				; Was 1 rotated out of WorkA?
	jz	.skip60				; No, it was zero, skip add mantissa
	;
	; Add [r12] = [r12] + [r11]
	;
	mov	rbp, [Recip_LSWOfst]		; RBX point at most significant Word
	mov	rcx, [Recip_No_Word]		; Current size of mantissa
	clc					; Clear Carry before addition

.loop50:
	mov	rax, [r12+rbp]			; Read Word
	adc	rax, [r11+rbp]			; Add (64 bit) with carry
	mov	[r12+rbp], rax			; Write Word
	rcl	rax, 1				; Save CF
	add	rbp, BYTE_PER_WORD		; Increment Address
	rcr	rax, 1				; Restore CF
	loop	.loop50				; Decrement RCX counter and loop
;
; Loop counters
;
.skip60:
	dec	r8				; Decrement bit counter
	or	r8, r8				; All bits zero?
	jz	.done				; All bits zerom, stop
	jmp	.main_loop
	;
	;   Done! Restore registers and exit
	;
.done:
	;
	; This multiplication is performed solely on the mantissa.
	; However, the matrix multiplication assumes some exponent
	; processing inherent to the method. The following will shift
	; the mantissa 62 bits left (1 word - 2 bits).
	;
	; Rotate [R12] left 1 word
	;
	mov	rbp, EXP_MSW_OFST		; RBX point at one above MS word
	mov	rcx, [Recip_No_Word]		; initialize counter

	clc					; Clear Carry before addition
.loop70:
	mov	rax, [r12+rbp-BYTE_PER_WORD]	; get word at [R12 - 1 word]
	mov	[r12+rbp], rax			; store in [R12]
	sub	rbp, BYTE_PER_WORD		; RBX decrement to next word
	loop	.loop70

	mov	rax, 0				; clear LS Word
	mov	[r12+rbp], rax
	;
	; Rotate [R12] right 1 bit
	;
	mov	rbp, MAN_MSW_OFST		; RBX point at most significant Word
	mov	rcx, [Recip_No_Word]		; Current size of mantissa
	clc					; Clear Carry before addition
.loop80:
	rcr	qword[r12+rbp], 1		; Rotate right 1 bit, CF --> word --> CF
	rcl	rax, 1				; Save CF
	sub	rbp, BYTE_PER_WORD		; RBX decrement to next word
	rcr	rax, 1				; Restore CF
	loop	.loop80
	;
	; Rotate [R12] right 1 bit
	;
	mov	rbp, MAN_MSW_OFST		; RBX point at most significant Word
	mov	rcx, [Recip_No_Word]		; Current size of mantissa
	clc					; Clear Carry before addition
.loop90:
	rcr	qword[r12+rbp], 1		; Rotate right 1 bit, CF --> word --> CF
	rcl	rax, 1				; Save CF
	sub	rbp, BYTE_PER_WORD		; RBX decrement to next word
	rcr	rax, 1				; Restore CF
	loop	.loop90

.exit:
	pop	r13
	pop	r12
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

;------------------------
;  EOF math-div.asm
;------------------------
