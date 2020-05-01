;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Arithmetic functions:  Addition

; File:   math-add.asm
; Module: math.asm, math.0
; Exec:   calc-pi
;
; Created:     10/23/2014
; Last edit:   06/07/2015
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
;  FP_Addition
;  FP_Long_Addition (force bitwise alignment)
;-------------------------------------------------------------
;  Floating Point Addition Routine
;
;  Add OPR to ACC and leave the result in ACC
;
;  Input:  MathMode bit 0x40, used to call bitwise alignment
;
;  Output: Shift_Count: contains number of bytes rotated to align mantissas
;          Nearly_Zero: this is set when one number is insignificant
;                       so the series summation can be terminated.
;
;--------------------------------------------------------------
FP_Addition:
;
	push	rax				; Working Reg
	push	rbx
	push	rcx				; Loop counter
	push	rdx
	push	rsi				; Operand 1 Variable handle number
	push	rdi				; Operand 2 Variable handle number
	push	rbp				; Pointer Index
	push	r8
	push	r9
	push	r10				; Address Pointer to FP_Acc
	push	r11				; Address Pointer to FP_Opr
;
; In case profiling, increment counter
;
%ifdef PROFILE
	inc	qword [iCntFPAdd]
%endif
;===========================================
; bitwise operation for benchmark testing
	mov	rax, [MathMode]			; check if bitwise rotation requested
	test	rax, 0x040
	jz	.not_long_mode
	jmp	FP_Long_Addition_pushed
;===========================================
;
.not_long_mode:
	xor	rax, rax			; initial shift count zero
	mov	[Shift_Count], rax
	mov	[Nearly_Zero], rax
;
	mov	r10, FP_Acc			; Point to ACC Regiser
	mov	r11, FP_Opr			; Point to OPR register
;
; Check if one or the other is zero
;
	mov	rax, [r11+MAN_MSW_OFST]		; is OPR = 0.0? Then done, result in ACC
	or	rax, rax
	jnz	.skip01
        jmp     .exit				; then exit with result in ACC
.skip01:
	mov	rax, [r10+MAN_MSW_OFST]		; is ACC = 0.0? Then done, return with ACC
	or	rax, rax
	jnz	.skip10				; No, continue with full addition
	mov	rsi, HAND_OPR			; Else ACC = 1, return OPR as result
	mov	rdi, HAND_ACC
	call	CopyVariable			; Move OPR --> ACC
	jmp	.exit
.skip10:
;
; Which needs to shift for alignment? Check exponents to which is a smaller number
;
	mov	r8, [r10+EXP_WORD_OFST]		; Get ACC Exponent
	sub	r8, [r11+EXP_WORD_OFST]		; Subtract OPR Exponent
	jnz	.skip20				; Equal? No, branch ahead
;
; Exponents are equal, add mantissas and exit
;
; Rotate 1 bit to make room for overflow
	mov	rsi, HAND_OPR			; Handle number for OPR
	call	Right1BitAdjExp			; Rotate OPR right 1 bit
	mov	rsi, HAND_ACC			; Handle number for ACC
	call	Right1BitAdjExp			; Rotate ACC right 1 bit
	mov	rsi, HAND_ACC			; ACC... operand 1 (result)
	mov	rdi, HAND_OPR			; OPR... operand 2
	call	AddMantissa			; Addition ACC[RSI] = ACC[RSI] + OPR[RDI]
	call	FP_Normalize			; Using handle [RSI] call normalize ACC
	jmp	.exit				; Done, exit
;
;  Check exponents if ACC < OPR
.skip20:
	rcl	r8, 1				; Sign bit into CF
	jc	.skip50				; Sign Neg,  OPR > ACC, go right shift ACC
						; else, switch ACC and OPR
;
;  Exchange OPR and ACC
;
	mov	rsi, HAND_OPR			; Operand 1 OPR
	mov	rdi, HAND_ACC			; Operand 2 ACC
	call	ExchangeVariable		; Exchange OPR and ACC
;
; Make room for overflow
;
.skip50:
	mov	rsi, HAND_OPR			; Handle number for OPR
	call	Right1BitAdjExp			; Rotate OPR right 1 bit
	mov	rsi, HAND_ACC			; Handle number for ACC
	call	Right1BitAdjExp			; Rotate ACC right 1 bit
;&&&&&&&&&&&&&&&&&&
%define BYxxWORD
%ifdef BYWORD
;  Defined = 28 sec - shift by word
;  Not Def = 15 sec - shift by byte
;&&&&&&&&&&&&&&&&&&
;
; Rotate right until aligned to nearest word
;
.loop55:
	mov	rsi, HAND_ACC			; Handle number for ACC
	call	Right1BitAdjExp			; Rotate ACC right 1 bit
	mov	rax, [r11+EXP_WORD_OFST]	; Get OPR Exponent
	sub	rax, [r10+EXP_WORD_OFST]	; Subtract ACC Exponent
	and	rax, 0x03F			; and for 64 bit alignment check (32_64_Check)
	jnz	.loop55				; Loop until exponent word aligned
;
;  Subtract exponets after bit rotations to get number of words to rotate
;
	mov	rax, [r11+EXP_WORD_OFST]	; Get OPR Exponent
	sub	rax, [r10+EXP_WORD_OFST]	; Subtract ACC Exponent
	jz	.skip80				; Equal now, go do add
	shr	rax, 6				; Divide by 6 to get words (32_64_Check)
	mov	r8, rax				; Save word shift count
;
; See if word count would rotate one number completely past the other
;
;  To avoid large loop count RCX < 1, then [No_Word]-R8 must be greater than zero
;
	mov	rax, [No_Word]			; Get no words in mantissa
	sub	rax, r8				; Subtract word shift count
	jc	.skip57				; Shift count R8 > Number of words, exit with OPR
	jz	.skip57				; Sift count = Number of words, exit with OPR
	jmp	.skip60				; Else, at least 1 word will remain
;
;  Else, would rotate out, skip
;
.skip57:
	inc	qword [Nearly_Zero]		; Used to end summation when terms too small
	mov	rsi, HAND_OPR			; ... Source
	mov	rdi, HAND_ACC			; ... Destination
	call	CopyVariable			; Move OPR --> ACC
	mov	rsi, HAND_ACC
	call	FP_Normalize			; Normalize ACC with result
	jmp	.exit				; and exit
;
;  Now R8 holds bytes to shift.
; Calculate Shift_Count in words for used in summing
; power series calculations
;
.skip60:
	mov	rax, r8				; Get byte shift count in bytes
	shr	rax, 3				; Divide by 8 to get words
	mov	[Shift_Count], rax		; Save word shift count use outside this procedure
;
; Determinte vyrw fill type
;
	mov	r9, 0				; Store zero in R9 if positive
	mov	rax, [r10+MAN_MSW_OFST]		; Get ACC M.S. Word to check sign
	rcl	rax, 1				; Rotate sign flag to CF
	jnc	.skip63				; Number positive, keep 0 value
	mov	r9, -1				; Fill with 0x0FFFFFFFFFFFFFFFF
;
; Shift ACC by words to align
;
.skip63:
	mov	rbp, MAN_MSW_OFST+BYTE_PER_WORD	; Offset Point M.S.Word + 1 word
	sub	rbp, [No_Byte]			; Offset Point to L.S.Word
;
	mov	rsi, r10			; RSI is now address pointer to ACC
	mov	rax, r8				; Get shift count in words
	shl	rax, 3				; X 8 = Convert words to bytes for address
	add	rsi, rax			; Point higher to offset for shift
;
	mov	rcx, [No_Word]			; Get number words in mantissa
	sub	rcx, r8				; Subtract the shift count
.loop65:
	mov	rax, [rsi+rbp]			; Get higher address word to shift
	mov	[r10+rbp], rax			; Save into lower address shifted position
	add	rbp, BYTE_PER_WORD		; Increment pointer
	loop	.loop65				; Decrement RCX and loop  until zero
;
	mov	rcx, r8				; Reset counter for shift count to back fill words
.loop68:
	mov	[r10+rbp], r9			; Add fill value to upper significant words
	add	rbp, BYTE_PER_WORD		; Increment pointer
	loop	.loop68				; Decrement RCX until done
;
; Copy exponent to ACC
;
	mov	rax, [r11+EXP_WORD_OFST]	; Get OPR exponent
	mov	[r10+EXP_WORD_OFST], rax	; Store into shifted ACC exponent
;&&&&&&&&&&&&&&&&&&
%else
;&&&&&&&&&&&&&&&&&&
;
;
; Rotate right until aligned to nearest byte
;
.loop55:
	mov	r8, [r11+EXP_WORD_OFST]		; Get OPR Exponent
	sub	r8, [r10+EXP_WORD_OFST]		; Subtract ACC Exponent
	and	r8, 0x07			; and for 64 bit alignment check
	jz	.loop55_exit
;
	mov	rsi, HAND_ACC			; Handle number for ACC
	call	Right1BitAdjExp			; Rotate ACC right 1 bit
	jmp	.loop55				; Loop until exponent word aligned
.loop55_exit:
;
;  Subtract exponets after bit rotations to get number of bytes to rotate
;
	mov	r8, [r11+EXP_WORD_OFST]		; Get OPR Exponent
	sub	r8, [r10+EXP_WORD_OFST]		; Subtract ACC Exponent
	jz	.skip80				; Equal now, go do add
;
; Error check, make sure shift count is positive
;
	mov	rax, r8				; Get byte shift count
	rcl	rax, 1				; Was count negative?
	jnc	.skip56
	mov	rax, .Msg_Error1
	call	StrOut
	mov	rax, 0
	jmp	FatalError
.skip56:
	shr	r8, 3				; Divide by 8 to get byte count
;
; See if word count would rotate one number completely past the other
;
	mov	rax, [No_Byte]			; Get no bytes in mantissa
	cmp	rax, r8				; Subtract word shift count
	jg	.skip60				; number of bytes > shift count, go add
;
;  Else, would rotate out, skip
;
.skip57:
	inc	qword [Nearly_Zero]		; Used to end summation when terms too small
	mov	rsi, HAND_OPR			; ... Source
	mov	rdi, HAND_ACC			; ... Destination
	call	CopyVariable			; Move OPR --> ACC
	mov	rsi, HAND_ACC
	call	FP_Normalize			; Normalize ACC with result
	jmp	.exit				; and exit
;
; Now R8 holds bytes to shift.
; Calculate Shift_Count (Byte-->Word) for use in summing
; power series calculations
;
.skip60:
	mov	rax, r8				; Get shift count in bytes
	shr	rax, 3				; Divide by 8 to get word count
	mov	[Shift_Count], rax		; Save shift count use outside this procedure
;
; Determinte word fill type
;
	mov	r9b, 0				; Store zero in R9 if positive
	mov	rax, [r10+MAN_MSW_OFST]		; Get ACC M.S. Word to check sign
	rcl	rax, 1				; Rotate sign flag to CF
	jnc	.skip63				; Number positive, keep 0 value
	mov	r9b, 0xFF			; Fill with 0x0FF
;
; Shift ACC by bytes to align
;
.skip63:
	mov	rbp, MAN_MSB_OFST+1		; Offset Point M.S.By + 1 word
	sub	rbp, [No_Byte]			; Offset Point to L.S.Word
;
	mov	rsi, r10			; RSI is now address pointer to ACC
	add	rsi, r8				; Add byte shift count to get pointer
;
	mov	rcx, [No_Byte]			; Get number words in mantissa
	sub	rcx, r8				; Subtract the shift count
.loop65:
	mov	AL, [rsi+rbp]			; Get higher address word to shift
	mov	[r10+rbp], AL			; Save into lower address shifted position
	inc	rbp				; Increment pointer
	loop	.loop65				; Decrement RCX and loop  until zero
;
	mov	rcx, r8				; Reset counter for shift count to back fill words
.loop68:
	mov	[r10+rbp], r9b			; Add fill value to upper significant words
	inc	rbp				; Increment pointer
	loop	.loop68				; Decrement RCX until done
;
; Copy exponent to ACC
;
	mov	rax, [r11+EXP_WORD_OFST]	; Get OPR exponent
	mov	[r10+EXP_WORD_OFST], rax	; Store into shifted ACC exponent
;&&&&&&&&&&&&&&&&&&
%endif
;&&&&&&&&&&&&&&&&&&
;
;  Add the two aligned mantissa
;
.skip80:
	mov	rsi, HAND_ACC			; Operand 1 (result)
	mov	rdi, HAND_OPR			; Operand 2
	call	AddMantissa			; Add the OPR to the ACC, result in ACC
;
; Normalize result and exit
;
	call	FP_Normalize			; Normalize the result in ACC
.exit:
; Restore registers
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
.Msg_Error1:	db	"FP_Addition: Error, shift count negative when aligning mantissa", 0xD, 0xA, 0
;
;--------------------------------------------------------------
;  FP_Long_Addition:
;
;  This is only intended for benchmark purposes
;  It is also an example of simple shift (bit by bit)
;  mantissa alignment.
;
;--------------------------------------------------------------
;  Floating Point Addition Routine
;
;  Add OPR to ACC and leave the result in ACC
;
;  Input:  none
;
;  Output: none
;
;  Note:   Shift_Count set to zero
;
;--------------------------------------------------------------
FP_Long_Addition:
	push	rax				; Working Reg
	push	rbx
	push	rcx				; Loop counter
	push	rdx
	push	rsi				; Operand 1 Variable handle number
	push	rdi				; Operand 2 Variable handle number
	push	rbp				; Pointer Index
	push	r8
	push	r9
	push	r10				; Address Pointer to FP_Acc
	push	r11				; Address Pointer to FP_Opr
;
; Alternate entry from above with registers pushed.
FP_Long_Addition_pushed:
;
; Initialize gloval variables
;
	xor	rax, rax			; initial shift count zero
	mov	[Shift_Count], rax
	mov	[Nearly_Zero], rax
;
; And address poitners
;
	mov	r10, FP_Acc			; Point to ACC Regiser
	mov	r11, FP_Opr			; Point to OPR register
;
; Check if one or the other is zero
;
	mov	rax, [r11+MAN_MSW_OFST]		; is OPR = 0.0? Then done, result in ACC
	or	rax, rax
	jnz	.skip01
        jmp     .exit				; then exit with result in ACC
.skip01:
	mov	rax, [r10+MAN_MSW_OFST]		; is ACC = 0.0? Then done, return with ACC
	or	rax, rax
	jnz	.skip10				; No, continue with full addition
	mov	rsi, HAND_OPR			; Else ACC = 1, return OPR as result
	mov	rdi, HAND_ACC
	call	CopyVariable			; Move OPR --> ACC
	jmp	.exit
.skip10:
;
; Which needs to shift for alignment? Check exponents to which is a smaller number
;
	mov	r8, [r10+EXP_WORD_OFST]		; Get ACC Exponent
	sub	r8, [r11+EXP_WORD_OFST]		; Subtract OPR Exponent
	jnz	.skip20				; Equal? No, branch ahead
;
; Exponents are equal, add mantissas and exit
;
; Rotate 1 bit to make room for overflow
	mov	rsi, HAND_OPR			; Handle number for OPR
	call	Right1BitAdjExp			; Rotate OPR right 1 bit
	mov	rsi, HAND_ACC			; Handle number for ACC
	call	Right1BitAdjExp			; Rotate ACC right 1 bit
	mov	rsi, HAND_ACC			; ACC... operand 1 (result)
	mov	rdi, HAND_OPR			; OPR... operand 2
	call	AddMantissa			; Addition ACC[RSI] = ACC[RSI] + OPR[RDI]
	call	FP_Normalize			; Using handle [RSI] call normalize ACC
	jmp	.exit				; Done, exit
;
;  Check exponents if ACC < OPR
;
.skip20:
	rcl	r8, 1				; Sign bit into CF
	jc	.skip50				; Sign Neg,  OPR > ACC, go right shift ACC
						; else, switch ACC and OPR
;
;  Exchange OPR and ACC
;
	mov	rsi, HAND_OPR			; Operand 1 OPR
	mov	rdi, HAND_ACC			; Operand 2 ACC
	call	ExchangeVariable		; Exchange OPR and ACC
;
; Check in range, this serves to stop summation when term is insignificant
; The flag Nearly_Zero is used by summations and is needed.
;www
.skip50:
	mov	r8, [r11+EXP_WORD_OFST]		; Get OPR Exponent
	sub	r8, [r10+EXP_WORD_OFST]		; Subtrace ACC Exponent R8 = bits different
;
	mov	rax, r8				; Get bits difference
	shr	rax, 6				; Divide by 64 to get words
	mov	[Shift_Count], rax		; Save number of words for ReduceSeriesAccuracy
;
	mov	rax, [No_Word]			; number 64 bit words in current accuracy
	shl	rax, 6				; x 64 for bits
	cmp	rax, r8				; Subtract bits shifted from bits in number
	jge	.skip54				; Rotation bits less than number size, skip
	inc	qword [Nearly_Zero]		; Else, smaller number not significant, set flag
;
; Make room for overflow
;
.skip54:
	mov	rsi, HAND_OPR			; Handle number for OPR
	call	Right1BitAdjExp			; Rotate OPR right 1 bit
	mov	rsi, HAND_ACC			; Handle number for ACC
	call	Right1BitAdjExp			; Rotate ACC right 1 bit

;
; Rotate right until aligned to nearest word
;
.loop55:
	mov	rsi, HAND_ACC			; Handle number for ACC
	call	Right1BitAdjExp			; Rotate ACC right 1 bit
	mov	rax, [r11+EXP_WORD_OFST]	; Get OPR Exponent
	sub	rax, [r10+EXP_WORD_OFST]	; Subtract ACC Exponent
	jnz	.loop55				; Loop until exponent word aligned
;
;  Add the two aligned mantissa
;
.skip80:
	mov	rsi, HAND_ACC			; Operand 1 (result)
	mov	rdi, HAND_OPR			; Operand 2
	call	AddMantissa			; Add the OPR to the ACC, result in ACC
;
; Normalize result and exit
;
	call	FP_Normalize			; Normalize the result in ACC
.exit:
; Restore registers
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
;  EOF math-add.asm
;------------------------
