;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Fixed precision format calculations
;
; M.S.Word = digits left of decimal point less two top bits
;
; File:   math-fixed.asm
; Module: math.asm, math.o
; Exec:   calc-pi
;
; Created 11/24/14
; Edited  06/26/15
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
; FIX_Load64BitNumber:
; FIX_TwosCompliment:
; FIX_VA_Addition:
; FIX_Addition:
; FIX_Subtraction:
; FIX_US_Multiplication:
; FIX_US_VA_Division:
; FIX_US_Division:
; FIX_Check_Sum_Done:
; Conv_FIX_to_FP:
; Conv_FP_to_FIX:
;-----------------------------------------
;
;   FIX_Load64BitNumber from RAX
;
;   Input: RAX = number to add, top 2 bits should be zero
;          RSI = variable handle number
;
;   Output: none
;
;-----------------------------------------
;
FIX_Load64BitNumber:
	push	rax				; Input value, general use
	push	rbx				; Address pointer
	push	rdx				; Temproarily hold input value
	push	rbp				; Index into number
;
; Check in range
;
	mov	rdx, rax			; Save the input value
	rcl	rax, 1				; Top bit set?
	jc	.error1				; Yes, error
	rcl	rax, 1				; Next to top bet set?
	jc	.error1				; Yes, error
;
; Address pointers
;
	mov	rbx, [RegAddTable+(rsi*WSCALE)]
						; RSI (index) --> RBX (address)
	mov	rbp, MAN_MSW_OFST		; RBP point at M.S.Word
;
; Fill in the number
;
	call	ClearVariable			; Use RSI, clear variable memory
	mov	[rbx+rbp], rdx			; Fill in the word
	mov	rax, 0x3F			; Exponent, not used until convert back to FP
	mov	rbp, EXP_WORD_OFST
	mov	[rbx+rbp], rax			; Set exponent word 0x3F, not used during fixed math
;
	pop	rbp
	pop	rdx
	pop	rbx
	pop	rax
	ret

.error1:
	mov	rax, .errMsg1			; Addr of error message
	call	StrOut				; Print message
	mov	rax, 0
	jmp	FatalError
.errMsg1:	db	0xD, 0xA, "FIX_Load64BitNumber - The two most significant bits of RAX are not zero.", 0xD, 0xA, 0


;-----------------------------------------
;
;   FIX_TwosCompliment
;
;   Input:  RSI = variable handle number
;
;   Output: none
;
;-----------------------------------------
;
FIX_TwosCompliment:
	push	rax				; Working Variable
	push	rbx				; Variable Address
	push	rcx				; Counter
	push	rdx				; Holds CF during calculations
	push	rsi				; Handle number of Variable
	push	rbp				; Index offset pointer
;
%ifdef PROFILE
	inc	qword [iCntFixTwoComp]
%endif
;
; Setup address and counter
;
	mov	rbx, [RegAddTable+(rsi*WSCALE)]	; RSI (index) --> RBX (address)
	mov	rbp, [LSWOfst]			; RBP point at L.S.Word
	mov	rcx, [No_Word]			; Counter for number of words
	mov	rdx, 0				; RDX will hold carry
	clc
;
; Main loop
;
.loop1:
	mov	rax, 0				; Load zero as first number
	sbb	rax, [rbx+rbp]			; Subtract CF and hex digit
	mov	[rbx+rbp], rax			; Store result
	rcl	rdx, 1				; Save CF
	add	rbp, BYTE_PER_WORD		; Increment Index
	rcr	rdx, 1				; Restore CF
	loop	.loop1				; Decrement RCX counter and loop back
;
; Done
;
.exit:
	pop	rbp
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
;-----------------------------------------
;
;   FIX_Addition
;
;   Input:  RSI = variable handle number
;   Input:  RDI = variable handle number
;
;   Output: RSI Operand contains result
;
;   [RSI] = [RSI] + [RDI]
;
;-----------------------------------------
;
; VA = variable accuracy version
;
FIX_VA_Addition:
	push	rax				; Working Variable
	push	rbx				; Address Operand 1
	push	rcx				; Counter
	push	rdx				; Address Operand 2
	push	rsi				; Operand 1 handle
	push	rdi				; Operand 2 handle
	push	rbp				; Index pointer
	push	r8				; Holds Carry
;
%ifdef PROFILE
	inc	qword [iCntFixAdd]
%endif
;
; Setup address and counter
;
	mov	rbx, [RegAddTable+(rsi*WSCALE)]	; RSI (index) --> RBX (address)
	mov	rdx, [RegAddTable+(rdi*WSCALE)]	; RDI (index) --> RBX (address)
	mov	rbp, [LSWOfst]			; RBP point at L.S.Word
	mov	rcx, [No_Word]			; Counter for number of words

	sub	rcx, [Last_Shift_Count]		; limit accuracy

	mov	r8, 0				; R8 will hold carry
	CLC
;
; Main loop
;
.loop1:
	mov	rax, [rbx+rbp]			; Load first number
	adc	rax, [rdx+rbp]			; Add CF and hex digit
	mov	[rbx+rbp], rax			; Store result
	rcl	r8, 1				; Save CF
	add	rbp, BYTE_PER_WORD		; Increment Index
	rcr	r8, 1				; Restore CF
	loop	.loop1				; Decrement RCX counter and loop back

	mov	rcx, [Last_Shift_Count]
	or	rcx, rcx
	jz	.exit				; no more words to check

.loop2:
	mov	rax, [rbx+rbp]			; Load first number
	adc	rax, [rdx+rbp]			; Add CF and hex digit
; check for carry
	jnc	.exit
;
	mov	[rbx+rbp], rax			; Store result
	rcl	r8, 1				; Save CF
	add	rbp, BYTE_PER_WORD		; Increment Index
	rcr	r8, 1				; Restore CF
	loop	.loop2				; Decrement RCX counter and loop back
;
; Done
;
.exit:
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
; fixed accuracy
;
FIX_Addition:
	push	rax				; Working Variable
	push	rbx				; Address Operand 1
	push	rcx				; Counter
	push	rdx				; Address Operand 2
	push	rsi				; Operand 1 handle
	push	rdi				; Operand 2 handle
	push	rbp				; Index pointer
	push	r8				; Holds Carry
;
%ifdef PROFILE
	inc	qword [iCntFixAdd]
%endif
;
; Setup address and counter
;
	mov	rbx, [RegAddTable+(rsi*WSCALE)]	; RSI (index) --> RBX (address)
	mov	rdx, [RegAddTable+(rdi*WSCALE)]	; RDI (index) --> RBX (address)
	mov	rbp, [LSWOfst]			; RBP point at L.S.Word
	mov	rcx, [No_Word]			; Counter for number of words
	mov	r8, 0				; R8 will hold carry
	clc
;
; Main loop
;
.loop1:
	mov	rax, [rbx+rbp]			; Load first number
	adc	rax, [rdx+rbp]			; Add CF and hex digit
	mov	[rbx+rbp], rax			; Store result
	rcl	r8, 1				; Save CF
	add	rbp, BYTE_PER_WORD		; Increment Index
	rcr	r8, 1				; Restore CF
	loop	.loop1				; Decrement RCX counter and loop back
;
; Done
;
.exit:
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
;   FIX_Subtraction
;
;   Input:  RSI = variable handle number
;   Input:  RDI = variable handle number
;
;   Output: RSI Operand contains result
;
;   [RSI] = [RSI] - [RDI]
;
;-----------------------------------------
;
FIX_Subtraction:
	push	rax				; Working Variable
	push	rbx				; Address Operand 1
	push	rcx				; Counter
	push	rdx				; Address Operand 2
	push	rsi				; Operand 1 handle
	push	rdi				; Operand 2 handle
	push	rbp				; Index pointer
	push	r8				; Holds Carry
;
%ifdef PROFILE
	inc	qword [iCntFixSub]
%endif
;
; Setup address and counter
;
	mov	rbx, [RegAddTable+(rsi*WSCALE)]	; RSI (index) --> RBX (address)
	mov	rdx, [RegAddTable+(rdi*WSCALE)]	; RDI (index) --> RBX (address)
	mov	rbp, [LSWOfst]			; RBP point at L.S.Word
	mov	rcx, [No_Word]			; Counter for number of words
	mov	r8, 0				; R8 will hold carry
	clc
;
; Main loop
;
.loop1:
	mov	rax, [rbx+rbp]			; Load first number
	sbb	rax, [rdx+rbp]			; Subtract CF and hex digit
	mov	[rbx+rbp], rax			; Store result
	rcl	r8, 1				; Save CF
	add	rbp, BYTE_PER_WORD		; Increment Index
	rcr	r8, 1				; Restore CF
	loop	.loop1				; Decrement RCX counter and loop back
;
; Done
;
.exit:
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
;   FIX_US_Multiplication (unsigned)
;
;   Input:  RSI = variable handle number
;   Input:  RAX = 64 bit word data
;
;   Output: RSI Operand contains result
;
;   [RSI] = [RSI] * RAX   (RAX is 64 bit unsigned data)
;
;   Input register must be 0x7FFFFFFFFFFFFFFF or less (high bit = 0)
;   This allows tight loop without need to ripple add CF to higher words
;
;   Show ripple carry not needed:
;      First multiply register with maximum value of word in mantissa
;      mov RBX 7FFFFFFFFFFFFFFF <-- highest possible register value sign bit = 0
;      mov RAX FFFFFFFFFFFFFFFF <-- highest possible word in mantissa
;      MUL RGX  <--  RDX:RAX = 7FFFFFFFFFFFFFFE:8000000000000001
;
;      Next add RAX from current index to RDX from index-1
;      MOV RAX 8000000000000001
;      MOV RDX 7FFFFFFFFFFFFFFE
;      ADD RAX, RDX <-- RAX = FFFFFFFFFFFFFFFF CF = 0
;
;-----------------------------------------
;
FIX_US_Multiplication:
	push	rax				; 64 Bit data input value / x86-64 MUL command
	push	rbx				; Address of variable
	push	rcx				; Counter
	push	rdx				; x86-64 MUL command
	push	rsi				; Operand 1 handle number
	push	rdi				; 64 bit data  (copy from input to function)
	push	rbp				; Offset pointer
	push	r8				; Temporarily hold previous MUL high result
	push	r9				; Temporarily holds CF
;
%ifdef PROFILE
	inc	qword [iCntFixMult]
%endif
;
; Setup address and counter
;
	mov	rdi, rax			; Copy 64 bit input data from RAX
	mov	rbx, [RegAddTable+(rsi*WSCALE)]	; RSI (index) --> RBX (address)
	mov	rbp, [LSWOfst]			; RBP point at L.S.Word
	mov	rcx, [No_Word]			; Counter for number of words
	xor 	r8, r8				; Clear previous high word
;
; Check input range
;
	rcl	rax, 1				; is high bit set?
	jnc	.loop1				; if no, expected result, skip error
	mov	rax, .errorMsg3			; CF not zero, fatal error
	call	StrOut
	mov	rax, 0
	jmp	FatalError
;
; Main loop
;
.loop1:
	xor	rdx, rdx			; Clear high word
	mov	rax, [rbx+rbp]			; Load first number
	mul	rdi				; RAX * RDI --> RDX:RAX
	add	rax, r8				; Add high qword from previous
	rcl	r9, 1				; Save CF
	mov	[rbx+rbp], rax			; Store result (low qword)
	xor	r8, r8				; Clear before adding CF and high word
	rcr	r9, 1				; Restore CF
	adc	r8, rdx				; Add CF + high qword to R8 for next time.
	jnc	.no_overflow			; Final CF zero is expected
;
; Handle error
;
	mov	rax, .errorMsg2			; CF not zero, fatal error
	call	StrOut
	mov	rax, 0
	jmp	FatalError
;
.no_overflow:
	add	rbp, BYTE_PER_WORD		; Increment Index
	loop	.loop1				; Decrement RCX counter and loop back
;
; After last work, check for overflow fixed format
;
	or	r8, r8				; R8 (MUL high word), expect zero, ok?
	jz	.exit				; Yes, exit
;
; handle error
;
	mov	rax, .errorMsg1
	call	StrOut
	mov	rax, 0
	jmp	FatalError
;
; Done
;
.exit:
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
.errorMsg1:	db	"FIX_US_Multiplication: Error overflow, high word not zero.", 0xD, 0xA, 0
.errorMsg2:	db	"FIX_US_Multiplication: Error overflow, CF flag not zero at end", 0xD, 0xA, 0
.errorMsg3:	db	"FIX_US_Multiplication: Error, input register high bit must be zero (sign bit)", 0xD, 0xA, 0
;
;-----------------------------------------
;
;   FIX_US_Division (unsigned)
;
;   Input:  RSI = variable handle number
;   Input:  RAX = 64 bit word data
;
;   Output: RSI Operand contains result
;
;   [RSI] = [RSI] / RAX   (RAX is 64 bit unsigned data)
;
;-----------------------------------------
;
; VA = variable accuracy version
;
FIX_US_VA_Division:
	push	rax				; 64 Bit data input value / x86-64 DIV command
	push	rbx				; Address of variable
	push	rcx				; Counter
	push	rdx				; x86-64 DIV command
	push	rsi				; Operand 1 handle number
	push	rdi				; 64 bit data  (copy from input to function)
	push	rbp				; Offset pointer
;
%ifdef PROFILE
	inc	qword [iCntFixDiv]
%endif
;
; Check for division by zero
;
	mov	rdi, rax				; Get 64 bit data value from RAX
	or	rax, rax				; Is the number zero?
	jz	.error1				; Division by zero is fatal error
;
; Setup address and counter
;
	mov	rbx, [RegAddTable+(rsi*WSCALE)]	; RSI (index) --> RBX (address)
	mov	rbp, MAN_MSW_OFST		; RBP point at M.S.Word
	mov	rax, [Last_Shift_Count]		; Number of words to skip
	shl	rax, 3				; X 8 for byte per word
	sub	rbp, rax			; adjust pointer to skip ahead
	mov	rcx, [No_Word]			; Counter for number of words
	sub	rcx, [Last_Shift_Count]		; Adjust counter for skip ahead
	mov	rdx, 0				; used as first remainder
;
; Pre Loop, skip words containing zero
;www
.loop1:
	mov	rax, [rbx+rbp]			; Load first number
	or	rax, rax			; Check for zero
	jnz	.non_zero			; Non-zero, do full division from here on
	sub	rbp, BYTE_PER_WORD		; Decrement Index pointer to next word
	loop	.loop1				; Decrement RCX counter and loop back
;
	inc	qword[Last_Nearly_Zero]		; Flag as done

	jmp	.exit				; All zero, exit leaving zero as result
.non_zero:
	mov	rax, [No_Word]			; Get number words (accuracy)
	sub	rax, rcx			; [No_Word] - (down counter)= shift word count
	mov	[Last_Shift_Count], rax
;
; Main loop
;
.loop2:						; Loop starts RDX with previous remainder
	mov	rax, [rbx+rbp]			; Load first number
	div	rdi				; RAX = RDX:RAX / RDI Remainder in RDX
	mov	[rbx+rbp], rax			; Store result
	sub	rbp, BYTE_PER_WORD		; Decrement Index pointer to next word
	loop	.loop2				; Decrement RCX counter and loop back
;
; Done
;
.exit:
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
.error1:
	mov	rax, .errorMsg1
	call	StrOut
	mov	rax, 0
	jmp	FatalError

.errorMsg1:	db	"FIX_US_Division - Error: Division by zero", 0xD, 0xA, 0
;
; Fixed accuracy version version (no Shift_Count)
;
FIX_US_Division:
	push	rax				; 64 Bit data input value / x86-64 DIV command
	push	rbx				; Address of variable
	push	rcx				; Counter
	push	rdx				; x86-64 DIV command
	push	rsi				; Operand 1 handle number
	push	rdi				; 64 bit data  (copy from input to function)
	push	rbp				; Offset pointer
;
%ifdef PROFILE
	inc	qword [iCntFixDiv]
%endif
;
; Check for division by zero
;
	mov	rdi, rax			; Get 64 bit data value from RAX
	or	rax, rax			; Is the number zero?
	jz	.error1				; Division by zero is fatal error
;
; Setup address and counter
;
	mov	rbx, [RegAddTable+(rsi*WSCALE)] ; RSI (index) --> RBX (address)
	mov	rbp, MAN_MSW_OFST		; RBP point at M.S.Word
	mov	rcx, [No_Word]			; Counter for number of words
	mov	rdx, 0				; used as first remainder
;
; Pre Loop, skip words containing zero
;
;.loop1:
;	mov	rax, [rbx+rbp]			; Load first number
;	OR	rax, rax				; Check for zero
;	jnz	.loop2				; Non-zero, do full division from here on
;	sub	rbp, BYTE_PER_WORD		; Decrement Index pointer to next word
;	loop	.loop1				; Decrement RCX counter and loop back
;	jmp	.exit				; All zero, exit leaving zero as result
;
; Main loop
;
.loop2:						; Loop starts RDX with previous remainder
	mov	rax, [rbx+rbp]			; Load first number
	div	rdi				; RAX = RDX:RAX / RDI Remainder in RDX
	mov	[rbx+rbp], rax			; Store result
	sub	rbp, BYTE_PER_WORD		; Decrement Index pointer to next word
	loop	.loop2				; Decrement RCX counter and loop back
;
; Done
;
.exit:
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
.error1:
	mov	rax, .errorMsg1
	call	StrOut
	mov	rax, 0
	jmp	FatalError

.errorMsg1:	db	"FIX_US_Division - Error: Division by zero", 0xD, 0xA, 0

;
;-----------------------------------------
;
;   FIX_Check_Sum_Done
;
;   Input:  RSI = variable handle number
;
;   Output: RAX  1 = Done, else 0
;
;-----------------------------------------
;
FIX_Check_Sum_Done:
	push	rbx
	push	rcx
	push	rsi
	push	rbp
;
; Setup address pointers
;
	mov	rbx, [RegAddTable+(rsi*WSCALE)]	; Address of variable
	mov	rbp, [LSWOfst]			; Index to LSW
	mov	rcx, [No_Word]			; Initialize counter
;
; Loop checking for all zero
;
.loop:
	mov	rax, [rbx+rbp]			; Get Word
	or	rax, rax				; Is it Zero?
	jnz	.not_done			; No, don't check others
	add	rbp, BYTE_PER_WORD		; Increment index
	loop	.loop				; Dec RCX and loop until done
;
	mov	rax, 1				; All words are zero
	jmp	SHORT .exit			; Return with 1 - all are zero
.not_done:
	mov	rax, 0				; Return with 0 - at least 1 non-zero
;
; Done
;
.exit:
	pop	rbp
	pop	rsi
	pop	rcx
	pop	rbx
	ret
;
;-----------------------------------------
;
;   Conv_FIX_to_FP
;
;   Input:  RSI = variable handle number
;
;   Output: none
;
;-----------------------------------------
;
Conv_FIX_to_FP:
	push	rax
	push	rbx
	push	rsi
	push	rbp
;
; Setup address pointers
;
	mov	rbx, [RegAddTable+(rsi*WSCALE)]	; Address of variable
	mov	rbp, EXP_WORD_OFST		; Index to Exponent
;
; Check Exponent for expected 0x3F value
;
	mov	rax, 0x3F			; Expected value
	cmp	[rbx+rbp], rax			; Equal?
	jne	.error1				; No error
;
; Using handle in RDI, call floating point normalize
;
	call	FP_Normalize			; Using RDI, normalize and return
;
; Done
;
.exit:
	pop	rbp
	pop	rsi
	pop	rbx
	pop	rax
	ret
.error1:
	mov	rax, .errorMsg0
	call	StrOut
	mov	rax, 0
	jmp	FatalError


.errorMsg0	db	"Conv_FIX_to_FP - Error: Exponent value not 0x3F as expected", 0xD, 0xA, 0

;-----------------------------------------
;
;   Conv_FP_to_FIX
;
;   Input:  RSI = variable handle number
;
;   Output: none
;
;-----------------------------------------
;
Conv_FP_to_FIX:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
	push	r8
;
; Setup address pointers
;
	mov	rbx, [RegAddTable+(rsi*WSCALE)]	; Address of variable
	mov	rbp, MAN_MSW_OFST		; Index to MSWord
;
; Check if zero, result will be zero
;
	mov	rax, WORD4000			; Test for zero bit
	test	[rbx+rbp], rax			; Is FP variable zero?
	jnz	.skip1				; M.S. bit is zero, FP number is zero
	call	ClearVariable			; Using RSI handle Clear variable
	jmp	.exit
.skip1:
;
; Remember sign bit as fill value
;
	mov	r8, 0				; fill value if positive
	mov	rax, WORD8000			; sign bit in FP variable
	test	[rbx+rbp], rax			; check M.S.Word
	jz	.skip1a				; positive, keep R8=0
	mov	r8, 0xFF			; for use in 8 bit value later
;
;  Check exponent in range
;  Binary exponent 0x3F --> Decimal 3.46 E+18
;  0x2FFFFFFFFFFFFFFF E0x000000000000003F
;
.skip1a:
	mov	rbp, EXP_WORD_OFST		; index to exponent
	mov	rax, [rbx+rbp]			; Get exponent
	sub	rax, 0x3E			; Word value 0x02?????? or less
	jg	.error1
;
;  Rotate right to make even byte alignment
;
.loop1:
	call	Right1BitAdjExp			; Rotate right 1 bit adjusting exponent
	mov	rbp, EXP_WORD_OFST		; Point to exponent
	mov	rax, [rbx+rbp]			; Get Exponent
	inc	rax				; Adjust for proper alignment
	mov	rdi, rax			; Temp get for sign check
	rcl	rdi, 1				; rotate sign bit into CF
	jnc	.skip2				; positive, skip
	neg	rax
.skip2:
	and	rax, 0x7			; Even multiple of 8?
	jnz	.loop1				; No keep rotating.
;jmp .exit
;
;  Calculate byte shift count
;
	mov	rax, [rbx+rbp]			; Get exponent
	sar	rax, 3				; div / 8, there are 8 bit per byte
	mov	rdi, 7				; shift to align words
	sub	rdi, rax			; RDI = number of bytes to shift
	jz	.exit				; if zero, no rotating needed
;
	mov	rdx, rbx			; variablel base address
	add	rdx, rdi			; Add offset
	mov	rbp, [LSWOfst]			; LSWord address = LSBtye address
	mov	rcx, [No_Byte]			; Counter to number of bytes
	sub	rcx, rdi			; Adjust for number of bytes in shift
;
; Shift bytes with data
;
.loop2:
	mov	al, [rdx+rbp]			; Get higher byte
	mov	[rbx+rbp], al			; Move down 1
	inc	rbp				; Point to next up byte index
	loop	.loop2				; Dec RCX and loop
;
; Fill in zero for upper bytes
;
	mov	rax, r8				; fill value, 0x00 (postive) or 0xFF (negative)
	mov	rcx, rdi			; Counter is shifted bytes
.loop3:
	mov	[rbx+rbp], al			; zero the byte
	inc	rbp				; Increment index
	loop	.loop3				; Dec RCX and loop
;
; Adjust exponent (NOTE: exponent will always be 0x3F)
;
	mov	rax, rdi			; Get byte count shifted right
	shl	rax, 3				; multiply x 8
	add	rax, [rbx+EXP_WORD_OFST]	; add to current exponent value
	mov	[rbx+EXP_WORD_OFST], rax
.exit:
	pop	r8
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
.error1:
	mov	rax, .errorMsg1
	call	StrOut
	mov	rax, 0
	jmp	FatalError

.errorMsg1:	db	"Conv_FP_to_FIX - Error: Exponent too big to convert to fixed format.", 0xD, 0xA, 0

;---------------------
; End math-fixed.asm
;---------------------
