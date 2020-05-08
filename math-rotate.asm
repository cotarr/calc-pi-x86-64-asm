;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; F.P. SUBROUTINES
;
; File:   math-rotate.asm
; Module: math.asm, math.o
; Exec:   calc-pi
;
; Created:   10/18/14
; Last Edit: 06/06/15
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
; Left1BitAdjExp
; Left1Bit
; Right1BitAdjExp
; Right1Bit
; Left1ByteAdjExp
; Left1Byte
; Right1ByteAdjExp
; Right1Byte
; Left1WordAdjExp
; Left1Word
; Right1WordAdjExp
; Right1Word
; FP_Normalize
; FP_Long_Normalize
;--------------------------------------------------------------
;  Rotate Mantissa left 1 bit and/or adjust exponent (2 entry points)
;
;  Input:   RSI = Handle Number of Variable
;
;  Output:  none
;
;--------------------------------------------------------------
Left1BitAdjExp:
;  Entry point #1
;  Case of rotate and adjust exponent
	push	rbx				; Address Pointer
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	dec	qword[rbx+EXP_WORD_OFST]	; Decrement exponent word
	pop	rbx
;  Entry Point #2
;  Case of rotate mantissa only
Left1Bit:
;   Save Registers
	push	rax				; Working Reg
	push	rbx				; Address Pointer
	push	rcx				; Loop Counter
	push	rbp				; Pointer Index
;
%ifdef PROFILE
	inc	qword [iCntRotate1Bit]
%endif
;
;  Source Address
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rbp, [LSWOfst]			; Offset to L.S. Word
	mov	rcx, [No_Word]			; RCX contains word count
	xor	rax, rax			; Will hold carry flag
	clc					; Clear carry flag
.loop1:
	rcl	qword [rbx+rbp], 1		; Rotate left 1 bit, CF --> word --> CF
	rcr	rax, 1				; Save CF
	add	rbp, BYTE_PER_WORD		; RBX increment to next word
	rcl	rax, 1				; Restore CF
	loop	.loop1				; Decrement RCX and loop until finished
;  Restore Registers
	pop	rbp
	pop	rcx
	pop	rbx
	pop	rax
	ret
;--------------------------------------------------------------
;  Rotate Mantissa Right 1 bit and/or adjust exponent (2 entry points)
;
;  Input:   RSI = Handle Number of Variable
;
;  Output:  none
;
;--------------------------------------------------------------
Right1BitAdjExp:
;  Entry point #1
;  Case of rotate and adjust exponent
	push	rbx
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	inc	qword[rbx+EXP_WORD_OFST]	; Decrement exponent word
	pop	rbx
;  Entry Point #2
;  Case of rotate mantissa only
Right1Bit:
;  Save Regsiters
	push	rax				; Working Reg
	push	rbx				; Address Pointer
	push	rcx				; Loop Counter
	push	rbp				; Pointer Index
;
%ifdef PROFILE
	inc	qword [iCntRotate1Bit]
%endif
;
;  Source Address
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rbp, MAN_MSW_OFST		; RBX point at mantissa M.S. Word
;  Setup Counter
	mov	rcx, [No_Word]			; RCX contains word count
;  Mantissa Operations
	mov	rax, [rbx+rbp]			; Get M.S.WOrd mantissa
	rcl	rax, 1				; Sign bit into CF
.loop1:
	rcr	qword[rbx+rbp], 1		; Rotate right 1 bit, CF --> word --> CF
	rcl	rax, 1				; Save CF
	sub	rbx, BYTE_PER_WORD		; RBX decrement to next word
	rcr	rax, 1				; Restore CF
	loop	.loop1				; Decrement RCX and loop until finished
;  Restore Registers
	pop	rbp
	pop	rcx
	pop	rbx
	pop	rax
	ret;
;
;--------------------------------------------------------------
;  Rotate Mantissa left 1 byte and/or adjust exponent (2 entry points
;
;  Input:   RSI = Handle Number of Variable
;
;  Output:  none
;
;--------------------------------------------------------------
Left1ByteAdjExp:
;  Entry point #1
;  Case of rotate and adjust exponent
	push	rbx
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	sub	qword[rbx+EXP_WORD_OFST], 8	; Decrement exponent word for 8 bit rotate
	pop	rbx
;  Entry Point #2
;  Case of rotate mantissa only
Left1Byte:
;   Save Registers
	push	rax				; Working Reg
	push	rbx				; Address Pointer
	push	rcx				; Loop Counter
	push	rdx				; Address Pointer (shifted with offset)
	push	rbp				; Pointer Index
;
%ifdef PROFILE
	inc	qword [iCntRotate1Byte]
%endif
;
;  Source Address
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rdx, rbx
	add	rdx, 1
	mov	rbp, MAN_MSB_OFST-1		; RBX point at mantissa M.S. Byte
;  Setup Counter
	mov	rcx, [No_Byte]			; RCX contains word count
	dec	rcx				; Decrement because moving bytes
;  Mantissa Operations
.loop1:
	mov	al, [rbx+rbp]			; Read byte data from lower address
	mov	[rdx+rbp], al			; Write byte data to next up (memory + 1)
	dec	rbp				; RBX decrement to next word
	loop	.loop1				; Decrement RCX and loop until finished

	mov	rbp, [LSWOfst]
	mov	byte[rbx+rbp], 0		; Zero into low byte
;  Restore Registers
	pop	rbp
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
;--------------------------------------------------------------
;  Rotate Mantissa Right 1 byte and adjust exponent and/or
;
;  Input:   RSI = Handle Number of Variable
;
;  Output:  none
;
;--------------------------------------------------------------
Right1ByteAdjExp:
;  Entry point #1
;  Case of rotate and adjust exponent
	push	rbx
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	add	qword[rbx+EXP_WORD_OFST], 8	; Decrement exponent word for 8 bit rotate
	pop	rbx
;  Entry Point #2
;  Case of rotate mantissa only
Right1Byte:
;   Save Registers
	push	rax				; WOrking Reg
	push	rbx				; Address Pointer
	push	rcx				; Loop Counter
	push	rdx				; Address Pointer (shifted with offset)
	push	rbp				; Pointer index
;
%ifdef PROFILE
	inc	qword [iCntRotate1Byte]
%endif
;
;  Source Address
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rdx, rbx			; Address pointer
	add	rdx, 1				; Offset by 1 byte
	mov	rbp, [LSWOfst]			; RBP L.S.Word is also L.S.Byte
;  Setup Counter
	mov	rcx, [No_Byte]			; RCX contains word count
	dec	rcx				; Decrement because moving bytes
;  Mantissa Operations
.loop1:
	mov	al, [rdx+rbp]			; Read byte data from higher memory byte
	mov	[rbx+rbp], al			; Write byte data to next down (memory - 1)
	inc	rbp				; Increment to next word
	loop	.loop1				; Decrement RCX and loop until finished
;
	mov	al, 0FFH			; Value if negative
	test	byte[rbx+MAN_MSB_OFST-1], 0x080	; Check sign of number (32_64_CHECK)
	jnz	.skip1
	mov	al, 00H				; Zero if positive
.skip1:
	mov	byte[rbx+MAN_MSB_OFST], al	; Zero into low byte
;  Restore Registers
	pop	rbp
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
;--------------------------------------------------------------
;  Rotate Mantissa left 1 word and/or adjust exponent (two entry point)
;
;  Input:   RSI = Handle Number of Variable
;
;  Output:  none
;
;--------------------------------------------------------------
Left1WordAdjExp:
;  Entry point #1
;  Case of rotate and adjust exponent
	push	rbx
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	sub	qword[rbx+EXP_WORD_OFST], BIT_PER_WORD
						; Decrement exponent word for 8 bit rotate
	pop	rbx
;  Entry Point #2
;  Case of rotate mantissa only
Left1Word:
;   Save Registers
	push	rax				; Working Reg
	push	rbx				; Address Pointer
	push	rcx				; Loop Counter
	push	rdx				; Address Pointer (offset with  shift)
	push	rbp				; Pointer Index
;
%ifdef PROFILE
	inc	qword [iCntRotate1Word]
%endif
;
;  Source Address
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rdx, rbx			; Address ponter
	add	rdx, BYTE_PER_WORD		; Offset pointer
	mov	rbp, MAN_MSW_OFST-BYTE_PER_WORD	; RBX point at mantissa M.S. Word
;  Setup Counter
	mov	rcx, [No_Word]			; RCX contains word count
	dec	rcx				; Decrement because moving words
;  Mantissa Operations
.loop1:
	mov	rax, [rbx+rbp]			; Read byte data from lower address memory
	mov	[rdx+rbp], rax			; Write byte data to next up (memory + 8)
	sub	rbp, BYTE_PER_WORD		; RBP decrement to next word
	loop	.loop1				; Decrement RCX and loop until finished
	mov	qword[rdx+rbp], 0		; Zero into low word
;  Exponent Operations
;       (none, see alternate entry above)
;  Restore Registers
	pop	rbp
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
;--------------------------------------------------------------
;  Rotate Mantissa Right 1 word and/or adjust exponent (2 entry point)
;
;  Input:   RSI = Handle Number of Variable
;
;  Output:  none
;
;--------------------------------------------------------------
Right1WordAdjExp:
;  Entry point #1
;  Case of rotate and adjust exponent
	push	rbx
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	add	qword[rbx+EXP_WORD_OFST], BIT_PER_WORD
						; Decrement exponent word for 8 bit rotate
	pop	rbx
;  Entry Point #2
;  Case of rotate mantissa only
Right1Word:
;   Save Registers
	push	rax				; Working Reg
	push	rbx				; Address Pointer
	push	rcx				; Loop Counter
	push	rdx				; Address Pointer (offset with  shift)
	push	rbp				; Pointer Index
;
%ifdef PROFILE
	inc	qword [iCntRotate1Word]
%endif
;
;  Source Address
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rdx, rbx			; Address pointer
	add	rdx, BYTE_PER_WORD		; Offset address
	mov	rbp, [LSWOfst]		;
;  Setup Counter
	mov	rcx, [No_Word]			; RCX contains word count
	dec	rcx				; Decrement because moving bytes
;  Mantissa Operations
.loop1:
	mov	rax, [rdx+rbp]			; Read byte data from upper memory word
	mov	[rbx+rbp], rax			; Write byte data to next down word (memory - 1 word)
	add	rbp, BYTE_PER_WORD		; Increment to next word
	loop	.loop1				; Decrement RCX and loop until finished
;
	mov	rax, [rbx+MAN_MSW_OFST-BYTE_PER_WORD]
	 					; Get M.S. WOrd -1 owrd
	rcl	rax, 1				; Rotate sign flag to CF
	jc	.skip1				; Case of negative, jump
	mov	rax, 0				; Else positive
	jmp	short .skip2
.skip1:						; Case of negative
	mov	rax, WORDFFFF
.skip2:
	mov	[rbx+MAN_MSW_OFST], rax		; Write top word in mantissa
;  Restore Registers
	pop	rbp
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
;--------------------------------------------------------------
;
;  Floating Point Normalization Routine
;
;  Input:   RSI = Handle Number of Variable
;
;  Output:  none
;
;--------------------------------------------------------------
FP_Normalize:
;
;   Save Registers
;
	push	rax				; Working Reg
	push	rbx				; Address Pointer (does not change)
	push	rcx				; Loop Counter
	push	rdx				; Byte Shift Count (R9 x 8)
	push	rsi				; Operand 1 Variable handle number (Input)
	push	rdi
	push	rbp				; Pointer Index
	push	r8				; Save Sign Flag
	push	r9				; Word Shift Count (counter)
;
; In case profiling, increment counter
;
%ifdef PROFILE
	inc	qword [iCntFPNorm]
%endif
;===========================================
; bitwise operation for benchmark testing
	mov	rax, [MathMode]			; check if bitwise rotation requested
	test	rax, 0x080			; 0x80 = FP_Normalization: Force bitwise alignment
	jz	.not_long_mode
	jmp	FP_Long_Normalize_pushed
;===========================================
;
;  Address Pinters
;
.not_long_mode:
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rbp, MAN_MSW_OFST		; Point to M.S.Word
;
;  Perform 2's compliment if negative
;  normalization requires positive number
;
	mov	r8, [rbx+rbp]			; Save sign flag in R8 for later
	mov	rax, r8				; Sign flag (M.S.Word)
	rcl	rax, 1				; Rotate sign bit into CF
	jnc	.skip1				; CF=0, positive skip 2's compliment
	call	FP_TwosCompliment		; 2'S compliment of variable
;
;  Setup counters to determine byte shift count
;
.skip1:
	mov	rbp, MAN_MSB_OFST		; M.S.Byte offset
	mov	rcx, [No_Byte]			; Loop Counter for words in mantissa
	xor	r9, r9				; Clear R9. This will be word shift counter
;
; Check M.S.Byte zero?
;
	mov	al, [rbx+rbp]			; Get M.S. Byte
	or	al, al				; Is it zero?
	jnz	.skip5				; No, shifting words not needed
	dec	rbp				; Point to next word down
	dec	rcx				; Decrement loop counter
	inc	r9				; Increment counter, rotate at least 1 byte
;
;  Loop testing all words for zero
;
.loop2:
	mov	al, [rbx+rbp]			; Get Byte to test
	or	al, al				; Is it zero?
	jnz	.skip3				; No, don't need to check any more
	dec	rbp				; Point next word down
	inc	r9				; Increment counter
	loop	.loop2				; Dec RCX and loop until RCX = 0
;
;------------------------------------
; Special case of normalizing zero
; All Mantissa words=0 clear exponent
;------------------------------------
	mov	qword[rbx+EXP_WORD_OFST], 0	; Clear Exponent
        jmp	short .exit			; And exit
;-------------------------
; At this point the mantissa must be shifted R9 number
; of bytes to the left
; RDX is address offset of words to shift
;-------------------------
;
; Calcuate address pointers
.skip3:
	mov	rdx, rbx			; Set RDX to base address variable
	add	rdx, r9				; RDX = base adddress plus shift offset
	mov	rbp, MAN_MSB_OFST		; RBX+RBP point to M.S.Byte
	sub	rbp, r9				; RBX+RBP point to lower address to shift
						;     RDX+RBP point to upper address to shift
						;     therefore RDX+RBP point to M.S.byte
;
;  Setup Counter
;
	mov	rcx, [No_Byte]			; Number of bytes in mantissa
	sub	rcx, r9				; Subtract shift count
;
; Shift bytes
;
.loop4:
	mov	al, [rbx+rbp]			; Get Byte at lower address
	mov	[rdx+rbp], al			; Move to higher address
	dec	rbp				; Adjust pointer
	loop	.loop4
;
; Fill trailing zeros
;
	mov	rcx, r9
	mov	al, 0
.loop4a:
	mov	[rdx+rbp], al
	dec	rbp
	loop	.loop4a

;
; Now exponent needs adjustment
;
;
	mov	rax, r9				; Get shift count (words 64 bit)
	shl	rax, 3				; multiply x 8 (32_64_CHECK)
	sub	[rbx+EXP_WORD_OFST], rax	; decrease exponent for word moves
;
;  Rotate bits left until MSBit is non-zero, while adjusting exponent
;
.skip5:
	test	byte[rbx+MAN_MSB_OFST], 0x80	; is M.S.Byte  1xxxxxxx ?
	jz	.loop5				; No, don't need rotate right
	call	Right1BitAdjExp			; Else rotate 1 bit right
	mov	al, [rbx+MAN_MSB_OFST]		; Right1Bit will left justify sign bit
	and	al, 0x7F				; So it must be cleared
	mov	[rbx+MAN_MSB_OFST], al		; And move it back to M.S.Byte mantissa
.loop5:
	test	byte[rbx+MAN_MSB_OFST], 0x40	; is M.S.Byte  010000xxx ?
	jnz	.skip6				; Yes, done rotating
	call	Left1BitAdjExp			; Rotate to left and adjust exponent
	jmp	short .loop5			; Always taken (careful about infinit loop)
.skip6:
	rcl	r8, 1				; Rotate sign bit into CF
	jnc	.exit				; no, exit
	call	FP_TwosCompliment		; Two's compliment
.exit:
; Restore Registers
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
;--------------------------------------------------------------
;
;  Floating Point Long Normalization Routine
;
;  This is only to perform benchmarking.
;  This used bit rotation only.
;
;  Input:   RSI = Handle Number of Variable
;
;  Output:  none
;
;--------------------------------------------------------------
FP_Long_Normalize:
;   Save Registers
	push	rax				; Working Reg
	push	rbx				; Address Pointer (does not change)
	push	rcx				; Loop Counter
	push	rdx				; Byte Shift Count (R9 x 8)
	push	rsi				; Operand 1 Variable handle number (Input)
	push	rdi
	push	rbp				; Pointer Index
	push	r8				; Save Sign Flag
	push	r9				; Word Shift Count (counter)

; Alternate entry with registers pushed from FP_Normalize above
FP_Long_Normalize_pushed:

	;  Address Pointers
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rbp, MAN_MSW_OFST		; Point to M.S.Word
	;
	;  Perform 2's compliment if negative
	;  normalization requires positive number
	;
	mov	r8, [rbx+rbp]			; Save sign flag in R8 for later
	mov	rax, r8				; Sign flag (M.S.Word)
	rcl	rax, 1				; Rotate sign bit into CF
	jnc	.number_is_positive		; CF=0, positive skip 2's compliment
	call	FP_TwosCompliment		; 2'S compliment of variable
.number_is_positive:
	;
	; Check of mantissa is negative before rotating bits
	;
	mov	rbp, [LSWOfst]			; Offset to L.S. Word
	mov	rcx, [No_Word]			; Loop Counter for words in mantissa
.loop10:
	mov	rax, [rbx+rbp]			; Get Byte to test
	or	rax, rax			; Is it zero?
	jnz	.found_non_zero			; No, don't need to check any more
	add	rbp, BYTE_PER_WORD		; Point next word
	loop	.loop10				; Dec RCX and loop until RCX = 0
	;
	; All mantissa words are zero, clear exponent and exit
	;
	mov	qword[rbx+EXP_WORD_OFST], 0	; Clear Exponent
        jmp	short .exit			; And exit
;
;  Rotate bits left until MSBit is non-zero, while adjusting exponent
;
.found_non_zero:
	test	byte[rbx+MAN_MSB_OFST], 0x80	; is M.S.Byte  1xxxxxxx ?
	jz	.loop20				; No, don't need rotate right
	call	Right1BitAdjExp			; Else rotate 1 bit right
	mov	al, [rbx+MAN_MSB_OFST]		; Right1Bit will left justify sign bit
	and	al, 0x7F			; So it must be cleared
	mov	[rbx+MAN_MSB_OFST], al		; And move it back to M.S.Byte mantissa
.loop20:
	test	byte[rbx+MAN_MSB_OFST], 0x40	; is M.S.Byte  010000xxx ?
	jnz	.done_rotating			; Yes, done rotating
	call	Left1BitAdjExp			; Rotate to left and adjust exponent
	jmp	short .loop20			; Always taken (assumes checked for zero previously)
.done_rotating:
	rcl	r8, 1				; Rotate sign bit into CF
	jnc	.exit				; no, exit
	call	FP_TwosCompliment		; Two's compliment

.exit:
; Restore Registers
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
;-------------------------------------
; math-rotate.asm include file - EOF
;-------------------------------------
