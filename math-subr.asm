;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; F.P. SUBROUTINES
;
; File:   math-sub.asm
; Module: math.asm, math.o
; Exec:   calc-pi
;
;  Created:   10/15/14
;  Last RDIt: 12/22/14
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
; GetVarNameAdd:
; ClearVariable:
; SetToOne:
; SetToTwo:
; CopyVariable:
; ExchangeVariable:
; FP_TwosCompliment:
; AddMantissa:
; FP_Load64BitNumber:
;--------------------------------------------------------------
;   Convert Variable Handle to Variable Name (String) address
;
;   Input:  RSI = Handle number of variable
;
;   Output: RAX = Address of string (name of variable)
;
;   Data comes from lookup table at: GetVarNameAddr
;
;--------------------------------------------------------------
GetVarNameAdd:
	push	rbx
	push	rsi
	mov	rax, rsi			; get file handle number
.skip2:	mov	rbx, RegNameTable		; Point to start of address table
	shl	rax, 3				; Mult by 8 byte per name
	add	rax, rbx			; Now point to address table value
	pop	rsi
	pop	rbx
	ret					; Return with RAX = address

;--------------------------------------------------------------
;  Clear F.P. Variable to all zero's,
;
;  Input:   RSI = handle number of variable
;
;  Output:  none
;
;--------------------------------------------------------------
ClearVariable:
;  Save registers
	push	rax				; Working Reg
	push	rbx				; Address Pointer
	push	rcx				; Loop counter
	push	rsi				; Handle number
	push	rbp
;
%ifdef PROFILE
	inc	qword [iCntClear]
%endif
;
;  Source Address
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rbp, EXP_MSW_OFST		; RBP point at highest Word (top exponent word)
	mov	rax, 0				; zero value to write
;  Setup Counter
	mov	rcx, [No_Word]			; current size of mantissa
	add	rcx, EXP_WSIZE			; bytes in exponent
;  Clear Data (Mantissa and Exponent together)
.loop1:	mov	[rbx+rbp], rax			; clean Word
	sub	rbp, BYTE_PER_WORD		; next lower Word
	loop	.loop1				; decrement RCX and loop
; Restore registers
	pop	rbp
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax
	ret
;--------------------------------------------------------------
;  Set Variable to 1.0 (integer value)
;
;  Input:   RSI = handle number of variable
;
;  Output:  none
;
;--------------------------------------------------------------
SetToOne:
	push	rax
	push	rbx
	push	rsi
;
	call	ClearVariable			; Using Handle in RSI, Clear variable
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)

;                      FEDCBA9876543210 <-- Ruler
	mov	rax, 0x4000000000000000		; Mantissa
	mov	[rbx+MAN_MSW_OFST], rax
	mov	rax, 1				; Exponent
	mov	[rbx+EXP_WORD_OFST], rax
;
	pop	rsi
	pop	rbx
	pop	rax
	ret
;--------------------------------------------------------------
;  Set Variable to 2.0 (integer value)
;
;  Input:   RSI = handle number of variable
;
;  Output:  none
;
;--------------------------------------------------------------
SetToTwo:
	push	rax
	push	rbx
	push	rsi
;
	call	ClearVariable			; Using Handle in RSI, Clear variable
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)

;                      FEDCBA9876543210 <-- Ruler
	mov	rax, 0x4000000000000000		; Mantissa
	mov	[rbx+MAN_MSW_OFST], rax
	mov	rax, 2				; Exponent
	mov	[rbx+EXP_WORD_OFST], rax
;
	pop	rsi
	pop	rbx
	pop	rax
	ret
;
;--------------------------------------------------------------
;  Move (Copy) F.P. Variable
;
;  Input:   RSI = Source Variable Handle Number
;           RDI = Destination Variable Handle Number
;
;          [RDI] = [RSI]     (handle numbers)
;
;  Output:  none
;
;--------------------------------------------------------------
CopyVariable:
; Save registers
	push	rax				; Working Reg
	push	rbx				; Source Address
	push	rcx				; Loop Counter
	push	rdx				; Destination Address
	push	rbp				; Pointer Index
;
; In case profiling, increment counter
;
%ifdef PROFILE
	inc	qword [iCntMove]
%endif
;
;  Source Address
	mov	rbx, [RegAddTable+rsi*WSCALE]
						; RSI (index) --> RBX (address)
	mov	rbp, EXP_MSW_OFST		; RBX point at most significant Word
;  Destination address
	mov	rdx, [RegAddTable+rdi*WSCALE]
						; RSI (index) --> RDX (address)
;  Setup counter
	mov	rcx, [No_Word]			; Current size of mantissa
	add	rcx, EXP_WSIZE			; Bytes in exponent
;  Copy data (Mantissa and Exponent)
 .loop1:
	mov	rax, [rbx+rbp]			; Read Word
	mov	[rdx+rbp], rax			; Write Word
	sub	rbp, BYTE_PER_WORD		; Increment Address
	loop	.loop1				; Decrement RCX counter and loop
; Restore Registers
	pop	rbp
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
;--------------------------------------------------------------
;  Exchange F.P. Variable
;
;  Input:   RSI = Operand 1 Handle Number
;           RDI = Operand 2 Handle Number
;
;  Output:  none
;
;--------------------------------------------------------------
ExchangeVariable:
; Save registers
	push	rax				; Working Reg
	push	rbx				; Source Address
	push	rcx				; Loop counter
	push	rdx				; Destination Address
	push	rsi				; Operand 1 Handle Number
	push	rdi				; Operand 2 Handle Number
	push	rbp				; Pointer Index
	push	r8				; Working Reg
;  Source Address
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rdx, [RegAddTable+rdi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rbp, EXP_WORD_OFST		; Top of variable
	mov	rcx, [No_Word]			; Counter for num words
	inc	rcx				; Adjust for exponent size
.loop:
	mov	r8, [rbx+rbp]			; Get OPR word
	mov	rax, [rdx+rbp]			; Get ACC word
	mov	[rbx+rbp], rax			; Save switched word to OPR
	mov	[rdx+rbp], r8			; Save switched word to ACC
	sub	rbp, BYTE_PER_WORD		; Increment new address
	loop	.loop				; Decrement RXC and loop until done
; Restore Registers
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
;  Perform Floating Point 2's Compliment on Variable
;
;  Input:    RSI = Handle Number of Variable
;
;  Output:   none
;
;  To get a 2's complement number do the following binary
;  subtraction:
;
;   000000000000
;  -original num.
;  ==============
;   two's comp.
;
;  However, there is a catch. The floating point mantissa
;  has designated sign and zero bits.
;
;  Normalized Positive number 01xxxxxx
;  Normalized Negative number 110xxxxx
;
;  After forming the 2's complement some rotation may be needed
;
;     Floating point mantissa
;     Number    Before          2's comp.      final mantissa
;	1	01000000 (0x40) 11000000 (0xC0) (ok)
;	3	01100000 (0x60)	10100000 (0xA0) (right) 11010000 (0xD0)
;	5	01010000 (0x50) 10110000 (0xB0) (right) 11011000 (0xD8)
;	7	01110000 (0x70) 10010000 (0x90) (right) 11001000 (0xC8)
;	-1	11000000 (0xC0) 01000000 (0x40) (ok)
;	-3	11010000 (0xD0) 00110000 (0x50) (left) 011000000 (0x60)
;	-5	11011000 (0xD8) 00101000 (0x48) (left) 010100000 (0x50)
;	-7	11001000 (0xC8) 00111000 (0x38) (left) 011100000 (0x70)
;
;--------------------------------------------------------------
;
FP_TwosCompliment:
;   Save Registers
	push	rax				; Working Reg
	push	rbx				; Address Pointer
	push	rcx				; Loop Counter
	push	rdx				; Variable to hold sign bit
	push	rbp				; Pointer Index
	push	r8				; Working Reg
	push	r9				; Working Reg
;
; In case profiling, increment counter
;
%IFDEF PROFILE
	inc	qword [iCntFPTwoCom]
%ENDIF
;
;  Source Address
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	test	byte[rbx+MAN_MSB_OFST], 0x0FF	;  Is it zero ?
	jz	.skip4				; yes, don't 2's compliment
	mov	r8, [rbx+MAN_MSW_OFST]		; Save MSW for sign bit (used later)
	mov	rbp, [LSWOfst]			; RBX+RBP point at mantissa L.S. Word
;  Setup Counter
	mov	rcx, [No_Word]			; RCX contains word count
;  Mantissa Operations
	mov	r9, 0				; Will be used to save CF
	clc					; Clear carry flag
.loop1:
	mov	rax, 0				; Load zero value into RAX
	sbb	rax, [rbx+rbp]			; Subtract to get 2's Compliment
	mov	[rbx+rbp], rax			;    and Save result
	rcl	r9, 1				; Save CF
	add	rbp, BYTE_PER_WORD		; Increment to next word
	rcr	r9, 1				; Restore CF
	loop	.loop1				; Decrement RCX and loop until finished
;
;  Two's compliment may leave mantissa left or right 1 bit, this can be fixed in next section
;
	rcl	r8, 1				; Rotate original Sign bit (MSBit) into carry
	jnc	.skip3				; No, original number was positive, skip ahead
;
; Case of negative number becoming positive
;
	test	byte[rbx+MAN_MSB_OFST], 0x40	; Check for first bit mantissa too far right
	jnz	.skip4 				; 01xxxx as expected?
	call	Left1BitAdjExp			; 001xxxxx --> left -->  01xxxxxxx
	jmp	short .skip4			; Done
;
; Case of positve number becoming negative
;
.skip3:
	mov	al, [rbx+MAN_MSB_OFST]		; Get M.S. Byte Mantissa
	and	al, 0x0C0			; Save only top 3 bits
	cmp	al, 0x0C0			; expect 110xxxx
	je	.skip4				;  as expected
	call	Right1BitAdjExp			; Rotate right 1 bit, adjust exponent
	or byte[rbx+MAN_MSB_OFST], 0x080	; Set sign bit that was rotated out
.skip4:
; Exponent Operations ; (none)
; Restore Registers
	pop	r9
	pop	r8
	pop 	rbp
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
;--------------------------------------------------------------
;  Add Mantissas of variables
;
;  Input:   RSI = Operand 1 handle number of variable
;           RDI = Operand 2 handle number of varaible
;
;  Output:  RSI Operand 1 contains result
;
;          [RSI]=[RSI]+[RDI] (handle numbers)
;
;  Note:    Calling routine must provide room for overflow
;           as normalized bits may overflow.
;
;
;--------------------------------------------------------------
;
AddMantissa:
;   Save Registers
	push	rax				; Working Reg
	push	rbx				; Address Pointer
	push	rcx				; Loop Counter
	push	rdx				; Address Pointer
	push	rsi				; Operand 1 Variable Handle Number
	push	rdi				; Operand 2 Variable Handle Number
	push	rbp				; Pointer Index
	push	r8				; To hold Carry Flag
;  Address Pointers
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rdx, [RegAddTable+rdi*WSCALE]	; RDI (index) --> RDX (address)
	mov	rbp, [LSWOfst]			; RBP offset to one word below mantissa L.S. Word
;  Setup Counter
	mov	rcx, [No_Word]			; RCX contains word count
;  Mantissa Operations
	mov	r8, 0				; need this to hold CF
	clc					; Clear carry flag
;
; This is the main loop for addition
;
.loop1:
	mov	rax, [rdx+rbp]			; Get source word
	adc	[rbx+rbp], rax			; Add destination word
	rcr	r8, 1				; Save CF
	add	rbp, BYTE_PER_WORD		; RBX increment to next word
	rcl	r8, 1				; Restore CF
	loop	.loop1				; Decrement RCX and loop until finished
;
;  Restore Registers
	pop	r8
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;--------------------------------------------------------------
; Load 64 bit positive integer into variable
;
; Input:    RSI = Handle number of variable
;           RAX = 64 bit ( n > 0 ) value to load
;
; Output:   none
;
;-------------------------------------------------------------
FP_Load64BitNumber:
;   Save Registers
	push	rax				; 64 bit input value
	push	rbx				; Address Pointer
;  Clear variable
	call	ClearVariable			; Using Index in RSI, clear the variable
;  Address Pointers
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
;
; PLace registers into memory 1 word from top (32_64_CHECK)
;
	mov	[rbx+MAN_MSW_OFST-BYTE_PER_WORD], rax
;
; Set Exponent for 1 word down (1 word is amost 2 words MSBit-LSBit)
;
	mov	qword[rbx+EXP_WORD_OFST], ((BIT_PER_WORD*2)-1)
;
	call 	FP_Normalize			; Using RSI index, normalize number
;
; Restore Registers
	pop	rbx
	pop	rax
	ret

;-------------------------------------
; math-subr.asm - Include file - EOF
;-------------------------------------
