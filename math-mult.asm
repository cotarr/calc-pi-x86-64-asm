;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Arithmetic functions:  Multiplication
;
; File:   math-mult.asm
; Module: math.asm, math.o
; Exec:   calc-pi
;
; Created:     10/22/14
; Last edit:   12/26/14
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
; FP_Multiplication:
; FP_Long_Multiplication:
; FP_Short_Multiplication:
; FP_Word_Multiplication:
;-------------------------------------------------------------
;  Floating Point Multiplication Routine
;
;  Input:    OPR contains one term
;            ACC contains one term.
;
;            For short division, the term less than 1 word
;            must be in the ACC term
;
;  Output:   ACC register contains the Product
;
;--------------------------------------------------------------
;
;
;-------------------------------------------------------------
;
;  FP_Multiplication algorithm selector
;
;  Check ACC and check if short multiplication can be used
;
;---------------------------------------------------------------

FP_Multiplication:
;
;
; Preserve registers
	push	rax				; Working Reg
	push	rcx				; Loop Counter
	push	rbp				; Pointer Index
	push	r10				; Pointer Address to FP_Acc
;
; Check mode, skip auto-select short multiplication
;
	mov	rax, [MathMode]
	test	rax, 4
	jnz	.go_full_mult
;
; Check if capable of using short multiplication
;
	mov	r10, FP_Acc			; Address of ACC
	mov	rbp, MAN_MSW_OFST-BYTE_PER_WORD	; Check if all ACC words below MSW are zero
	mov	rcx, [No_Word]			; Loop Counter
	dec	rcx				; Adjust for 1 word down
	; OPTION sub	rcx, GUARDWORDS		; Don't check guard words
.loop1:
	mov	rax, [r10+rbp]			; Get word from ACC
	or	rax, rax			; is it zero
	jnz	.go_full_mult			; Not zero, must do full multiplication
	sub	rbp, BYTE_PER_WORD		; Decrement index
	loop	.loop1				; Dec RCX, loop until all words checked
;
	pop	r10
	pop	rbp
	pop	rcx
	pop	rax
	jmp	FP_Short_Multiplication
;
.go_full_mult:
;
	mov	rax, [MathMode]
	test	rax, 1
	jnz	.long
;
.word:
	pop	r10
	pop	rbp
	pop	rcx
	pop	rax
	jmp	FP_Word_Multiplication
.long:
	pop	r10
	pop	rbp
	pop	rcx
	pop	rax
	jmp	FP_Long_Multiplication
;
;-----------------------------------------
;
;  FP_Long_Multiplication
;
;  Perform full binary long mmltiplication
;
;    Bits shift --> CF? --> Add
;
;-----------------------------------------
;
FP_Long_Multiplication:
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
	push	r9				; WOrking REg
	push	r10				; Pointer Address to FP_Acc
	push	r11				; Pointer Address to FP_Opr
	push	r12				; Pointer Address to FP_WorkA
;
; In case profiling, increment counter for short and long methods
;
%ifdef PROFILE
	inc	qword [iCntFPMultLong]
%endif
;
; Setup pointers
;
	mov	r10, FP_Acc			; Address of ACC
	mov	r11, FP_Opr			; Addresss of OPR
	mov	r12, FP_WorkA			; Address of WorkA
;
; Check multiplicands and determine sign of Product
;
	mov	rax, [r10+MAN_MSW_OFST]		; Get sign
	xor	rax, [r11+MAN_MSW_OFST]		; Form result sign
	mov	[DSIGN], rax			; Save sign for later
;
; Check sign of ACC, two's compliment if negative
;
	mov	rax, WORD8000			; Is ACC negative?
	test	[r10+MAN_MSW_OFST], rax		; Test M.S.Word of ACC
	jz	.skip1				; Positive, skip 2's comp.
	mov	rsi, HAND_ACC			; Handle number of ACC
	call	FP_TwosCompliment		; Form 2's compliment ACC
;
; Check ACC for zero, if zero then return zero result
;
.skip1:
	mov	rax, WORDFFFF			; Is ACC zero?
	test	[r10+MAN_MSW_OFST], rax		; Test M.S.Word of ACC for zero
	jnz	.skip2
	mov	rsi, HAND_ACC			; Case of ACC is zero
	call	ClearVariable			; Clear ACC, result is zero
	jmp	.exit				; and exit
;
;Check sign of OPR, two's compliment if negative
;
.skip2:
	mov	rax, WORD8000			; Is OPR negative?
	test	[r11+MAN_MSW_OFST], rax		; Test M.S.Word of OPR
	jz	.skip3				; Positive, skip 2's comp.
	mov	rsi, HAND_OPR			; Handle number of ACC
	call	FP_TwosCompliment		; Form 2's compliment ACC
;
; Check OPR for zero. If zero then return zero result
.skip3:
	mov	rax, WORDFFFF			; Is OPR zero?
	test	[r11+MAN_MSW_OFST], rax		; Test M.S.Word of OPR for zero
	jnz	.skip4
	mov	rsi, HAND_ACC			; Case of ACC is zero
	call	ClearVariable			; Clear ACC, result is zero
	jmp	.exit				; and exit
;
;   Copy variable ACC to WorkA
;
.skip4:
	mov	rsi, HAND_OPR			; Point handle to OPR
	call	Right1Bit			; Make room for overflow
	mov	rsi, HAND_ACC			; Point handle to ACC
	mov	rdi, HAND_WORKA			; Point handle to WorkA
	call	CopyVariable			; Copy ACC to WorkA
;
; Add exponents
;
	mov	rax, [r11+EXP_WORD_OFST]
						; Get exponet OPR
	add	rax, [r10+EXP_WORD_OFST]
						; Add exponent ACC
	push	rax				; Save temporarily
;
; Clear ACC variable and store exponent
;
	mov	rsi, HAND_ACC			; Point handle to ACC
	call	ClearVariable			; Clear ACC
	pop	rax
	mov	[r10+EXP_WORD_OFST], rax
						; Save exponent to cleared ACC
;
; Calculate number of bits in mantissa
;
	mov	r8, [No_Byte]			; Get number of types in Mantissa
	shl	r8, 3				; X2, X4, X8 for 8 bit/byte
	sub	r8, 1				; Adjust for sign bit
						; Now R8 holds bit count
;
;  Shift mantissa toward right by words until first non zero word found
;  Decrement the bit counter for each shift
;
	mov	rbp, MAN_MSW_OFST+BYTE_PER_WORD
						; Mantissa M.S.W + 1 WORD offset
	sub	rbp, [No_Byte]			; Address L.S. Word
.loop55	mov	rax, [r12+rbp]			; Get word starting with MSW
	or	rax, rax			; is it zero?
	jnz	.skip59				; No, escape loop
	mov	rsi, HAND_WORKA			; Point handle workA
	call	Right1Word			; Rotate WorkA right 1 word
	sub	r8, BIT_PER_WORD 		; Subtract bits per workA
	jmp	SHORT .loop55			; Loop, always taken
.skip59:
						; non zero word must exist
						; because zero mantissa
						; was already checked for
;
;  Beginning with first non-zero word in WorkA,
;  Loop to shift both WorkA and ACC right 1 bit at a time
;  If a non-zero bit is shifted out of least significant bit
;  then add the OPR mantissa to the ACC mantissa.
;  Continue until all bits are shifted (Shift count in R8 is zero.
;
.loop60:
	mov	r9, [r12+rbp]			; Get L.S. Word WorkA
	mov	rsi, HAND_WORKA			; Point handle to WorkA
	call	Right1Bit			; Rotate workA right 1 bit
	mov	rsi, HAND_ACC			; Point handle to ACC
	call	Right1Bit			; Rotate ACC right 1 bit
	test	r9, 1				; Was 1 rotated out of WorkA?
	jz	.skip65				; No, it was zero, skip add mantissa
	mov	rsi, HAND_ACC			; Point to ACC (result)
	mov	rdi, HAND_OPR			; Point to WorkA (source)
	call	AddMantissa			; Add, result in ACC
.skip65:
	dec	r8				; Decrement bit counter
	or	r8, r8				; All bits zero?
	jz	.skip70				; All bits zerom, stop
	jmp	.loop60
;
; Normalize result in ACC
;
.skip70:
	mov	rsi, HAND_ACC			; Point handle ACC
	call	FP_Normalize			; Normalize ACC
;
; Obtain original sign and if negative, perform Two's Compliment of ACC
;
	mov	rax, [DSIGN]			; get sign bits
	rcl	rax, 1				; Rotate sign into CF
	jnc	.exit				; No CF, it was positivbe
	mov	rsi, HAND_ACC			; Point handle to ACC
	call	FP_TwosCompliment		; 2's compliment ACC
;
;   Done! Restore registers and exit
;
.exit:
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
;
;-----------------------------------------
;
;  FP_Short_Multiplication
;
;  Use x86-64 DIV command to build result
;
;-----------------------------------------
;
FP_Short_Multiplication:
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
	push	r9				; WOrking REg
	push	r10				; Pointer Address to FP_Acc
	push	r11				; Pointer Address to FP_Opr
;
; In case profiling, increment counter for short and long methods
;
%ifdef PROFILE
	inc	qword [iCntFPMultShort]
%endif
;
; Setup pointers
;
	mov	r10, FP_Acc			; Address of ACC
	mov	r11, FP_Opr			; Addresss of OPR
;
; Check multiplicands and determine sign of Product
;
	mov	rax, [r10+MAN_MSW_OFST]		; Get sign
	xor	rax, [r11+MAN_MSW_OFST]		; Form result sign
	mov	[DSIGN], rax			; Save sign for later
;
; Check sign of ACC, two's compliment if negative
;
	mov	rax, WORD8000			; Is ACC negative?
	test	[r10+MAN_MSW_OFST], rax		; Test M.S.Word of ACC
	jz	.skip1				; Positive, skip 2's comp.
	mov	rsi, HAND_ACC			; Handle number of ACC
	call	FP_TwosCompliment		; Form 2's compliment ACC
;
; Check ACC for zero, if zero then return zero result
;
.skip1:
	mov	rax, WORDFFFF			; Is ACC zero?
	test	[r10+MAN_MSW_OFST], rax		; Test M.S.Word of ACC for zero
	jnz	.skip2
	mov	rsi, HAND_ACC			; Case of ACC is zero
	call	ClearVariable			; Clear ACC, result is zero
	jmp	.exit				; and exit
;
;Check sign of OPR, two's compliment if negative
;
.skip2:
	mov	rax, WORD8000			; Is OPR negative?
	test	[r11+MAN_MSW_OFST], rax		; Test M.S.Word of OPR
	jz	.skip3				; Positive, skip 2's comp.
	mov	rsi, HAND_OPR			; Handle number of ACC
	call	FP_TwosCompliment		; Form 2's compliment ACC
;
; Check OPR for zero. If zero then return zero result
.skip3:
	mov	rax, WORDFFFF			; Is OPR zero?
	test	[r11+MAN_MSW_OFST], rax		; Test M.S.Word of OPR for zero
	jnz	.skip4
	mov	rsi, HAND_ACC			; Case of ACC is zero
	call	ClearVariable			; Clear ACC, result is zero
	jmp	.exit				; and exit
.skip4:
;
; Setup for i86-64 multiplication
;
	mov	rbp, [LSWOfst]			; Index to L.S.Word
	mov	r8, [r11+rbp]			; Get L.S. Word for later
	mov	rsi, HAND_OPR			; Variable handle number
	call	Right1WordAdjExp		; Room for overflow
;
; Shift number right to get 1 in L.S. Bit of high word
;
	mov	rax, [r10+MAN_MSW_OFST]		; Get M.S.Word Mantissa
	mov	rbx, [r10+EXP_WORD_OFST]	; Get Exponent
.loop11A:
	clc					; Clear CF for shift right
	shr	rax, 1				; Shift right until L.S.Bit is 1
	jc	.skip11B			; 1 was rotated to CF, too far, backup
	inc	rbx				; Inc Exponent to adjust for right shift
	jmp	SHORT .loop11A			; Always taken
.skip11B:
	rcl	rax, 1				; Reverse last shift, was too far
	mov	[r10+MAN_MSW_OFST], rax		; Save ACC Mantissa
	mov	[r10+EXP_WORD_OFST], rbx
						; Save ACC Exponent
	mov	rbx, [r10+MAN_MSW_OFST]		; Store ACC M.S.Word in RBX for multiplication (rest is zero)
;
; Add exponents, Clear ACC, and add exponent to cleared ACC

	mov	rax, [r10+EXP_WORD_OFST]	; get ACC Exponent
	add	rax, [r11+EXP_WORD_OFST]	; Add OPR Exponent
	sub	rax, 63
	push	rax
	mov	rsi, HAND_ACC			; Variable handle number
	call	ClearVariable			; Clear ACC
	pop	rax
	mov	[r10+EXP_WORD_OFST], rax	; Restore Exponent
;
; Setup loop counter and index
;
	mov	rcx, [No_Word]			; Loop Counter
	dec	rcx				; Dec because one word shifted
	mov	rbp, [LSWOfst]			; Point index to L.S.WOrd
;
; We previously saved L.S.Word in R8 before shifting the word out of mantissa
; Multiply this word first, but only overflow word is added mantissa
;
	xor	rdx, rdx			; Clear High 64 bit word
	mov	rax, r9				; Get rotated out L.S. Word
	mul	rbx				; Multiply, rax (L.S.Word discarded, out of range)
	mov	[r10+rbp], rdx			; RDX, M.S. word is start (L.S. word) of result
;
; This is the main multiplication loop  RAX * R9 = RDX:RAX
;
.loop12:
	xor	rdx, rdx			; Clear High 64 bit word
	mov	rax, [r11+rbp]			; Get word OPR in RAX
	mul	rbx				; RDX:RAX = RAX * RBX
	add	[r10+rbp], rax			; Add low word ACC
	rcr	r9, 1				; Save CF temporarily in r9
	add	rbp, BYTE_PER_WORD		; Point next word
	rcl	r9, 1				; Restore CF
	adc	[r10+rbp], rdx			; Add high word to ACC
	jnc	.no_overflow			; Assume no carry
;
	mov	rax, .Msg_Err1
	call	StrOut
	mov	rax, 0
	jmp	FatalError
;
.no_overflow:
	loop	.loop12				; Decrement RCX, loop [No_Word]-1 times until done
;
; Normalize result in ACC
;
	mov	rsi, HAND_ACC			; Point handle ACC
	call	FP_Normalize			; Normalize ACC
;
; Obtain original sign and if negative, perform Two's Compliment of ACC
;
	mov	rax, [DSIGN]			; get sign bits
	rcl	rax, 1				; Rotate sign into CF
	jnc	.exit				; No CF, it was positivbe
	mov	rsi, HAND_ACC			; Point handle to ACC
	call	FP_TwosCompliment		; 2's compliment ACC
;
;   Done! Restore registers and exit
;
.exit:
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
.Msg_Err1:	db	"FP_Short_Multiplication: Carry flag not zero as expected", 0xD, 0xA, 0

;
;-----------------------------------------
;
;  FP_Word_Multiplication
;
;  Use x86-64 DIV command to build result
;
;-----------------------------------------
;
FP_Word_Multiplication:
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
	push	r9				; WOrking REg
	push	r10				; Pointer Address to FP_Acc
	push	r11				; Pointer Address to FP_Opr
	push	r12				; Pointer Address to FP_WorkA
	push	r13				; Pointer Address to FP_WorkB
	push	r14
	push	r15
;
; In case profiling, increment counter for short and long methods
;
%ifdef PROFILE
	inc	qword [iCntFPMultWord]
%endif
;
; Setup pointers
;
	mov	r10, FP_Acc			; Address of ACC
	mov	r11, FP_Opr			; Address of OPR
	mov	r12, FP_WorkA			; Address of WorkA
;
; Check multiplicands and determine sign of Product
;
	mov	rax, [r10+MAN_MSW_OFST]		; Get sign
	xor	rax, [r11+MAN_MSW_OFST]		; Form result sign
	mov	[DSIGN], rax			; Save sign for later
;
; Check sign of ACC, two's compliment if negative
;
	mov	rax, WORD8000			; Is ACC negative?
	test	[r10+MAN_MSW_OFST], rax		; Test M.S.Word of ACC
	jz	.skip1				; Positive, skip 2's comp.
	mov	rsi, HAND_ACC			; Handle number of ACC
	call	FP_TwosCompliment		; Form 2's compliment ACC
;
; Check ACC for zero, if zero then return zero result
;
.skip1:
	mov	rax, WORDFFFF			; Is ACC zero?
	test	[r10+MAN_MSW_OFST], rax		; Test M.S.Word of ACC for zero
	jnz	.skip2
	mov	rsi, HAND_ACC			; Case of ACC is zero
	call	ClearVariable			; Clear ACC, result is zero
	jmp	.exit				; and exit
;
;Check sign of OPR, two's compliment if negative
;
.skip2:
	mov	rax, WORD8000			; Is OPR negative?
	test	[r11+MAN_MSW_OFST], rax		; Test M.S.Word of OPR
	jz	.skip3				; Positive, skip 2's comp.
	mov	rsi, HAND_OPR			; Handle number of ACC
	call	FP_TwosCompliment		; Form 2's compliment ACC
;
; Check OPR for zero. If zero then return zero result
.skip3:
	mov	rax, WORDFFFF			; Is OPR zero?
	test	[r11+MAN_MSW_OFST], rax		; Test M.S.Word of OPR for zero
	jnz	.skip4
	mov	rsi, HAND_ACC			; Case of ACC is zero
	call	ClearVariable			; Clear ACC, result is zero
	jmp	.exit				; and exit
.skip4:
;
; Rotate right, room for overflow
;
	mov	rsi, HAND_OPR
	call	Right1ByteAdjExp
;
; Add exponents, Clear WorkB, and add exponent to cleared WorkB
;
	mov	rax, [r10+EXP_WORD_OFST]	; get ACC Exponent
	add	rax, [r11+EXP_WORD_OFST]	; Add OPR Exponent
	add	rax, 1				; Fudge factor, makes it right
	push	rax
	mov	rsi, HAND_WORKA
	call	ClearVariable
	pop	rax
	mov	[r12+EXP_WORD_OFST], rax	; Restore Exponent
	mov	r13, 0				; LSW extension to WorkA
;
;----------------------------------------
; Setup for i86-64 multiplication
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
;           Multiply [RSI]*[RDI]
;           Add LSW --> [RBP-1] and save CF
;             or LSW --> R13 if under range, and save CF
;           Add MSW --> [RBP]
;             Loop3B
;		INC RBP (Exit loop 3?)
;		Add Carry Flag --> [RBP]
;             End-Loop3B
;           Inc R14
;           Inc RDI (Exit Loop2?)
;      End-Loop2
;      DEC R15
;      INC RSI (Exit Loop1?)
;  End-Loop1
;
;
;  X = RSI
;     Y = RDI
;        L = RBP-1  Addition of low word
;            or ur = under range word added R13
;        H = RBP Addition of high word
;             cf = RBP+ (carry flag added)
;
;  Trace 8 word loop index values
;
; X-56
; Y-112 ur H-56 cf-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
;
; X-64
; Y-104 ur H-56 cf-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-112 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
;
; X-72
; Y-96 ur H-56 cf-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-104 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-112 L-64 H-72 cf-80 cf-88 cf-96 cf-104 cf-112
;
; X-80
; Y-88 ur H-56 cf-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-96 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-104 L-64 H-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-112 L-72 H-80 cf-88 cf-96 cf-104 cf-112
;
; X-88
; Y-80 ur H-56 cf-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-88 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-96 L-64 H-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-104 L-72 H-80 cf-88 cf-96 cf-104 cf-112
; Y-112 L-80 H-88 cf-96 cf-104 cf-112
;
; X-96
; Y-72 ur H-56 cf-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-80 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-88 L-64 H-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-96 L-72 H-80 cf-88 cf-96 cf-104 cf-112
; Y-104 L-80 H-88 cf-96 cf-104 cf-112
; Y-112 L-88 H-96 cf-104 cf-112
;
; X-104
; Y-64 ur H-56 cf-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-72 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-80 L-64 H-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-88 L-72 H-80 cf-88 cf-96 cf-104 cf-112
; Y-96 L-80 H-88 cf-96 cf-104 cf-112
; Y-104 L-88 H-96 cf-104 cf-112
; Y-112 L-96 H-104 cf-112
;
; X-112
; Y-56 ur H-56 cf-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-64 L-56 H-64 cf-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-72 L-64 H-72 cf-80 cf-88 cf-96 cf-104 cf-112
; Y-80 L-72 H-80 cf-88 cf-96 cf-104 cf-112
; Y-88 L-80 H-88 cf-96 cf-104 cf-112
; Y-96 L-88 H-96 cf-104 cf-112
; Y-104 L-96 H-104 cf-112
; Y-112 L-104 H-112
;
;---------------------------------------------------------------------------------------------------------
;
%define MUsssLTTRACE
;www

	mov	rsi, [LSWOfst]			; Index for Loop-1
	mov	r15, MAN_MSW_OFST		; Used to initialize Loop-2 Index

;---------------
;  Pre-Loop 0
;---------------
.pre_loop_0:
	mov	rax, [r10+rsi]			; Get word
	or	rax, rax				; Is it zero?
	jnz	.mult_loop_1			; No, begin multipications
;
; Decrement index and loop
;
	sub	r15, BYTE_PER_WORD		; For RDI
	add	rsi, BYTE_PER_WORD
	cmp	rsi, (MAN_MSW_OFST+BYTE_PER_WORD)
						; Next ACC Word
	jne	.pre_loop_0
; Should not have fallen through
	mov	rax, .Msg_Error1
	call	StrOut
	mov	rax, 0
	jmp	FatalError
;
; Setup RSI to index input words from ACC for multiplicatioon
;
	mov	rsi, [LSWOfst]			; Index for Loop-1
	mov	r15, MAN_MSW_OFST		; Used to initialize Loop-2 Index
	mov	r8, 0				; Holds carry flag during addition
;---------------
;  L O O P - 1
;---------------
.mult_loop_1:
;
%define MULxxxxTTRACE
%ifdef MULTTRACE
; - - - - Trace Code  - - - -
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
; - - - - - - - - - - - - - -
;
; Setup RDI to index input words from OPr for multiplicatioon
;
	mov	rdi, r15			; Index for Loop-2
	mov	r14, [LSWOfst]			; To initialize Loop-3
;
;---------------
;  L O O P - 2
;---------------
.mult_loop_2:
;
; Initialize RBP index to store output of multiplication into WorkA
;
	mov	rbp, r14			; Used for save pointer and also
						;    used to initialize Loop-3
; - - - - Trace Code  - - - -
%ifdef MULTTRACE
	push	rax
	call	CROut
	mov	al, 'Y'
	call	CharOut
	mov	al, '-'
	call	CharOut
	mov	rax, rdi
	call	PrintWordB10
	mov	al, ' '
	call	CharOut
	pop	rax
%endif
; - - - - - - - - - - - - - -

;
; Perform X86 Multiplication RAX * RBX = RDX:RAX
;mmm
	mov	rbx, [r10+rsi]
	mov	rax, [r11+rdi]
	mov	rdx, 0
	mul	rbx				; Multiply RAX * RBX = RDX:RAX
;
;  Save Result of multiplication
;
	cmp	rbp, [LSWOfst]
	je	.index_under_range
;
; Add Low Word to Work A
;
	add	[r12+rbp-BYTE_PER_WORD], rax	; Add LSW of multiplication
	rcl	r8, 1				; Save CF
;
; - - - - Trace Code  - - - -
%ifdef MULTTRACE
	push	rax
	mov	al, 'L'
	call	CharOut
	mov	al, '-'
	call	CharOut
	mov	rax, rbp
	sub	rax, BYTE_PER_WORD
	call	PrintWordB10
	mov	al, ' '
	call	CharOut
	pop	rax
%endif
; - - - - - - - - - - - - - -
	jmp	.index_in_range
.index_under_range:
	add	r13, rax			; R13 holds under range word
	rcl	r8, 1				; Save CF
; - - - - Trace Code  - - - -
%ifdef MULTTRACE
	push	rax
	mov	al, 'u'
	call	CharOut
	mov	al, 'r'
	call	CharOut
	mov	al, ' '
	call	CharOut
	pop	rax
%endif
; - - - - - - - - - - - - - -
.index_in_range:
;
; Add High word
;
	rcr	r8, 1				; Restore carry
	adc	[r12+rbp], rdx			; Add CF and MSW of multiplication
	rcl	r8, 1				; Save CF

; - - - - Trace Code  - - - -
%ifdef MULTTRACE
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
; - - - - - - - - - - - - - -

;-----------------
;  L O O P - 3
;-----------------
.mult_loop_3:
;
; Loop 3 is to add carry flag to higher words
;
;   Increment pointer to next work, check if done
;
	test	r8, 1				; see if carry flag
%ifndef MULTTRACE
	jz	.exit_loop_3			; no carry to add, exit loop
%endif
	add	rbp, BYTE_PER_WORD
	cmp	rbp, (MAN_MSW_OFST+BYTE_PER_WORD)
						; Check if above M.S.Word
	jl	.mult_go_add			; No, less, go add carry flag
	test	r8, 1				; Check Carry, expect CF = 0
	jz	.exit_loop_3			; CD was not set, expected, exit loop
	mov	rax, .Msg_Error2
	call	StrOut
	mov	rax, 0
	call	FatalError
.mult_go_add:
	rcr	r8, 1				; Restore CF
	adc	qword [r12+rbp], 0		; Add CF
	rcl	r8, 1				; Save CF again
;
; - - - - Trace Code  - - - -
%ifdef MULTTRACE
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
%endif
; - - - - - - - - - - - - - -
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
; Check that no CF = 1 condition is left, zero is expected
;
	test	r8, 1				; What is the CF value?
	jnc	.no_carry			; CF = 0, good, as expected
	mov	rax, .Msg_Error2		; Else is error
	call	StrOut
	mov	rax, 0
	jmp	FatalError
.no_carry:
; - - - - Trace Code  - - - -
%ifdef MULTTRACE
	call	CROut
%endif
; - - - - - - - - - - - - - -
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
;
; Move result back to ACC
;
	mov	rsi, HAND_WORKA
	mov	rdi, HAND_ACC
	call	CopyVariable
;
; Normalize result in ACC
;
	mov	rsi, HAND_ACC			; Point handle ACC
	call	FP_Normalize			; Normalize ACC
;
; Obtain original sign and if negative, perform Two's Compliment of ACC
;
	mov	rax, [DSIGN]			; get sign bits
	rcl	rax, 1				; Rotate sign into CF
	jnc	.exit				; No CF, it was positivbe
	mov	rsi, HAND_ACC			; Point handle to ACC
	call	FP_TwosCompliment		; 2's compliment ACC
;
;   Done! Restore registers and exit
;
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
.Msg_Error1:	db	"FP_Word_Multiplication: Error, pre-loop exit without non-zero word", 0xD, 0xA, 0
.Msg_Error2:	db	"FP_Word_Multiplication: Error, CF not zero above M.S.Word", 0xD, 0xA, 0
;
;------------------------
;  EOF math-mult.asm
;------------------------
