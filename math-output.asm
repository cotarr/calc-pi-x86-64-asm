
;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Floating Point Input / Output Routines
;
; File:   math-output.asm
; Module: math.asm, math.o
; Exec:   calc-pi
;
; Created:    10/20/14
; Last Edit:  05/04/20
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
;  11/28/14 - To increase speed, edited MultManByTen
;  to use DIV command instead of rotate X2, X4, X8 + X2.
;  In PrintSciNot, added variable accuracy during
;  multiply x 10 to eject digits.
;
;  12/27/14 - To increase speed, when ejecting digits
;  multiply mantissa by 1E16 to eject 16 digits into
;  one 64 bit word, then extract digits using division
;  by powers of 10 on 64 bit word.
;  Print of , 000, 000 digits 1635 sec --> 96 seconds
;
;  01/09/15 - To increase speed, divide by 10 now
;  divides 64 bit words instead of bytes.
;  If the exponent is large or small, the number
;  is pre-multiplied or pre-divided by 1E15
;
;--------------------------------------------------------------
; PrintVariable
; PrintResult:
; FP_Input:
; IntegerInput:
; MultManByTen:
; FP_MultByTen:
; FP_MultByTenE15:
; FP_DivideByTen:
; FP_DivideByTenE15:
;--------------------------------------------------------------
;
;  Print Variable
;
;  Subroutine performs radix conversion to base 10.
;
;  Input: ACC variable contains floating point word to print.
;
;         [Out_Mode] 0=Scientific Notation
;                    1=Fixed
;                    3=Integer
;
;  Output formatting performed in CharOutFmt
;
;  Variables: Out_Sign, Out_Exponent, Out_Mode
;
;--------------------------------------------------------------
;
PrintVariable:
; Save Registers
	push	rax				; Working Reg
	push	rbx				; Address pointer
	push	rcx				; Loop Counter
	push	rdx				; Used for multiplication
	push	rsi				; Operand 1 variable handle number
	push	rdi				; Operand 2 variable handle number
	push	rbp				; Pointer Index
	push	r8				; Working Reg
	push	r9				; Working Reg
	push	r10				; Working Reg
;
; Setup character formatting. Formatting done externally in CharOutFmt(AL)
;
	call	CharOutFmtInit			; initialize counters
;
; Setup Variable handle and address
;
        mov     rsi, HAND_ACC			; Handle number of accumulator
	mov	rbx, FP_Acc			; Address [RBX]
;
; =============================================
; 1) Check sign and zero bits
;      - If negative, 2's compliment
;      - I Zero, print '0.0' and exit
;
        mov     rax, [rbx+MAN_MSW_OFST]		; M.S.Byte mantissa for print sign
	mov	[Out_Sign], rax			; Save for later
        rcl	rax, 1				; Negative ? Rotate M.S. Bit to CF
        jnc	.skip1				; No, skip 2's compliment
        call    FP_TwosCompliment		; Using handle [RSI] form 2's compliment
.skip1:
	rcl	rax, 1				; Rotate zero bit into CF
        jc     .skip2				; No skip
        mov     al, ' '
        call    CharOutFmt
        mov     al, '0'				; Output ' 0.0'
        call    CharOutFmt
;
	cmp	qword[Out_Mode], 2		; Integer mode?
	je	.exit				; Yes, skip ".0"
;
	mov     al, '.'
        call    CharOutFmt
        mov     al, '0'
        call    CharOutFmt
        jmp     .exit				; Variable was zero, no further printing needed
.skip2:
;
; =============================================
; 2) Perform rounding operations
;
;
;    2A) If integer mode, round by adding 0.5 to variable
;
	cmp	qword[Out_Mode], 2
	jne	.dont_round
	mov	rsi, HAND_OPR			; Temporary RSI
	call	SetToOne			; Load OPR with 1
	mov	rsi, HAND_ACC			; Restore RSI point to ACC
	dec	qword[FP_Opr+EXP_WORD_OFST]	; Dec exponent, same as divide by 2
	call	FP_Addition			; ACC = OPR + 0.5
.dont_round:
;
;    2B) Add lower order rounding factor
;        (This avoids 1 printing as 9.99999.... E-1
;
;             R8 - holds carry between additions
;             R9 - Sued to hold rounding value
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	jmp     .skip6    ; Skip roundoff (Option)
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
	mov	rsi, HAND_ACC			; Handle to variable
        call    Right1BitAdjExp			; Rotate, room for carry
        mov     rbp, [LSWOfst]			; Point L.S.Word
	mov	rcx, [No_Word]			; Loop counter
	mov	r8, 0				; Use RBP to hold carry between additions
	clc
;          2A)  add rounding factor to L.S.Word (may be adjusted)
	mov	rax, [rbx+rbp]			; Get L.S.Word

;                     FEDCBA9876543210 <---- Ruler
	mov	r9, 0x0000000000000000		; Add value to L.S.Word
	add	rax, r9				; Add value to L.S.Word
	rcl	r8, 1				; Save the CF
	mov	[rbx+rbp], rax			; Save word
	add	rbp, BYTE_PER_WORD		; This will lose the carry flag
	dec	rcx				; For counter
	rcr	r8, 1				; Restore CF
;          2B)  add rounding factor to L.S.Word + 1 word (may be adjusted)
	mov	rax, [rbx+rbp]			; Get word

;                     FEDCBA9876543210 <---- Ruler
	mov	r9, 0x0000000000040000		; Add value to L.S.Word
	adc	rax, r9				; Add value to L.S.Word
	rcl	r8, 1				; Save the CF
	mov	[rbx+rbp], rax			; Save Word
	add	rbp, BYTE_PER_WORD		; This will lose the carry flag
	dec	rcx				; For counter
	rcr	r8, 1				; Restore CF
;          2C)  adding carry CF to L.S.Word + ... words (DO NOT ADJUST IN LOOP)
 .loop5:
	mov	rax, [rbx+rbp]			; Get next word in mantissa
	adc	rax, 0				; Add the CF
	rcl	r8, 1				; Save the CF
	mov	[rbx+rbp], rax			; Save the word
	add	rbp, BYTE_PER_WORD		; This will lose the carry flag
	rcr	r8, 1				; Restore CF
        loop    .loop5				; Loop till RCX = 0, carry not changed
        call    FP_Normalize			; Using handle [RSI] Normalize after roundoff
.skip6:						; Jump Address for skip round;
;
; =============================================
; 3) First step in printing is to output sign
;
;     Output sign
;
	mov	rax, [Out_Sign]			; Get sign of number
        rcl	rax, 1				; Negative ? Rotate M.S. Bit to CF
        jnc	.skip3				; No, skip 2's compliment
	mov	al, '-'				; Else load '-'
	jmp	short .skip4
.skip3:
	mov	al, '+'				; load '+'
.skip4:
	call	CharOutFmt			; Output sign character
;
; =============================================
; 3) Exponent alignment
;
;     The following routines will multiply or divide
;     by 10 until the binary exponent is in the range of
;     -1 to -4 before digits are rolled out the mantissa.
;     The base 10 exponent is obtained by counting the mult/div cycles
;
;           R8 Temporary counter for exponent
;
	mov	r8, -1				; Initial value from experiment
;
;     Is binary exponent negative ?
;	- If no (zero or positive), then divide by 10 and check again
;	- Else yes, (negative),
;               In temp variable, add 4 to exponent
;		Check temp exponent, is it still negative after adding 4??
;			- If yes (negative), loop back to "3) Is Exponent Negative" above
;                       - If no (Positive), then done mult/divide by 10
;    Note: multiply and divide by 10 includes binary exponent adjustment and normalization
;
;----------
; Option for pre-division, use step of 1x10^15 , then divide by ten can follow when exponent small
;
	mov	rsi, HAND_ACC			; Variable handle for division/mult calls


;	JMP	.loop7


.loop6a:
	mov	rax, [rbx+EXP_MSW_OFST]		; Check for pre-division by 1x10^15 steps
	mov	rdi, rax
	shl	rdi, 1				; high bit to CF
	jc	.loop6b				; exponent negative, skip pre-division
	cmp	rax, 60				; 2^60 about 1.15E+18
	jle	.loop6b				; if less, then pre-divison not needed.
	call	FP_DivideByTenE15		; Divide number by 1x10^15
	add	r8, 15				; Increment exponent counter by 10^15
	jmp	short	.loop6a			; Loop, always taken
;----------
; Option for pre-multiplication, use step of 1x10^15 , then divide by ten can follow when exponent small
;
.loop6b:
	mov	rax, [rbx+EXP_MSW_OFST]		; Check for pre-division by 1x10^15 steps
	mov	rdi, rax
	shl	rdi, 1				; High bit to CF
	jnc	.loop7				; positive, don't pre-multiply
	neg	rax				; Two's compliment of exponent
	cmp	rax, 60				; 2^60 about 1.15E+18
	jle	.loop7				; if less, then pre-divison not needed.
	call	FP_MultByTenE15			; Multiply number by 1x10^15
	sub	r8, 15				; Increment exponent counter by 10^15
	jmp	short	.loop6b			; Loop, always taken
;
; Pre-divison/multiplication not needed any more,
; continue to division by 10, incrementing exponent counter.
;
.loop7:
	mov	rax, [rbx+EXP_MSW_OFST]		; Is exponent negative?
	rcl	rax, 1
	jc     .skip8				; Yes, exponent check now check if  > -4
        call    FP_DivideByTen			; Divide by 10 & normalize
	inc	r8				; Increment base 10 exponent coutner
	jmp	short .loop7			; Loop, always taken
 .skip8:
	mov	rax, [rbx+EXP_WORD_OFST]	; Use RAX as temp variable to test range
	add	rax, 4				; Add 4 to exponent
	rcl	rax, 1				; Rotate M.S.Bit into carry
	jnc	.skip9				; If CF not set then was positive, done */10
 	call	FP_MultByTen			; Else, Multiply by 10 and normalize
	dec	r8				; Decrement base 10 exponent counter
	jmp	short .loop7			; Loop back till in range
.skip9:
	mov	[Out_Exponent], r8		; Save temporarily
;
; =============================================
;  4) Rotate right 1 word (64 bits) to make room for multiplicaiton result
;           Note: this multiplication applied to mantissa, binary exponent not changed
;
	call    Right1Word			; Using handle [RSI] rotate right 64 bits
	call    MultManByTen			; Multiply mantissa only by 10
;
; =============================================
;  5) Rotate mantissa right 1 bit at a time until exponent zero
;
.loop10:
	add	qword[rbx+EXP_WORD_OFST], 1	; Increment exponent, ? ZERO ?
	jz	.skip11				; Yes, branch ahead
	call	Right1Bit			; Using handle in [RSI] Rotate right 1 bit
	jmp	.loop10				; Loop always taken
.skip11:
;
; =============================================
;  6) Multiply by 10 to eject first digit into empty word
;        If zero ejected, skip, eject another  and adjust exponent
;
	mov	al, [rbx+MAN_MSW_OFST]		; Get first digit
	or	al, al				; is it zero?
	jnz	.skip11A			; No, this is as expected
	call	MultManByTen			; Eject another digit
	dec	r8				; Decrement exponent counter
.skip11A:
	mov	[Out_Exponent], r8		; Save to print exponent later
; =============================================
;  7) Output the first digit with decimal
;        point or leading zeros (if needed)
;
;
; Initialize Digit Counter
;
	mov     r10, [NoSigDig]			; Get number sig digits
;
;   Note: Printing of the first digit is handled differently depending
;   on the conversion mode.
;   Mode 0 = Scientific Notation
;   Mode 1 = Fixed Notation
;   Mode 2 = Integer Mode
;
;---------------------------------
;  Mode 0 - Scientific notation
;---------------------------------
	cmp	qword[Out_Mode], 0
	jne	.not_mode0_01
;
;  Mode 0 - Print first base 10 digit
;
	mov	al, [rbx+MAN_MSW_OFST]		; Get M.S.Byte of mantissa
        or      al, 0x030			; Form ascii digit
        call    CharOutFmt			; Output digit
;
;  Mode 0 - Print decimal point
;
        mov     al, '.'				; Get decimal point
        call    CharOutFmt			; Output it
;
.not_mode0_01:
;-----------------------------
; Mode 1 Fixed Decimal point
;-----------------------------
	cmp	qword[Out_Mode], 1
	jne	.not_mode1_01
;
;  Mode 1 Case of base 10 exponent negative, generate leading zeros
;
	mov	rax, WORD8000
	test	[Out_Exponent], rax		; is exponent negative?
	jz	.mode1_01
	mov	al, '0'
	call	CharOutFmt
	mov	al, '.'
	call	CharOutFmt
;
	inc	qword[Out_Exponent]
	jz	.mode1_02

.mode1_loop1:
	mov	al, '0'
	call	CharOutFmt
	dec	r10				; decrement digit counter
	jz	.exit				; quit if no more digits
	inc	qword[Out_Exponent]
	jnz	.mode1_loop1
;
.mode1_02:
	mov	al, [rbx+MAN_MSW_OFST]		; Get M.S.Byte of mantissa
	or      al, 0x030			; Form ascii digit
	call    CharOutFmt			; Output digit
	dec	r10
	jz	.exit
	jmp	.not_mode1_01
;
;  Mode 1 Case of base 10 exponent zero, output first digit
;
.mode1_01:
	mov	rax, [Out_Exponent]
	or	rax, rax			; Is exponent zero?
	jnz	.mode1_10			; No, must be positive
	mov	al, [rbx+MAN_MSW_OFST]		; Get M.S.Byte of mantissa
	or      al, 0x030			; Form ascii digit
	call    CharOutFmt			; Output digit
	mov	al, '.'
	call	CharOutFmt
	jmp	.not_mode1_01
;
; Mode 1 Case of base 10 exponent is positive, decimal point will occur later
;
.mode1_10:
	mov	al, [rbx+MAN_MSW_OFST]		; Get M.S.Byte of mantissa
	or      al, 0x030			; Form ascii digit
	call    CharOutFmt			; Output digit
	inc	qword[Out_Exponent]		; Adjust for digit printed
	dec	qword[Out_Exponent]
	jnz	.not_mode1_01
	mov	al, '.'
	call	CharOutFmt
;
.not_mode1_01:
;--------------------------
;  Mode 2 - Integer Mode
;--------------------------
	cmp	qword[Out_Mode], 2
	jne	.not_mode2_01
;
; Mode 2 Case of base 10 exponent negative, output 0 as result
;
	mov	rax, WORD8000
	test	[Out_Exponent], rax		; is exponent negative?
	jz	.mode2_01			; no
	mov	al, '0'				; else print zero
	call	CharOutFmt
	jmp	.exit
;
; Mode 2 Case of base 10 exponent zero, output single digit as result
;
.mode2_01:
	mov	rax, [Out_Exponent]		; is exponent zero?
	or	rax, rax
	jnz	.mode2_02
	mov	al, [rbx+MAN_MSW_OFST]		; Get M.S.Byte of mantissa
	or      al, 0x030			; Form ascii digit
	call    CharOutFmt			; Output digit
	jmp	.exit				; and exit with only 1 digit
;
; Mode 3 Case of base 10 exponent greater than zero, output first digit, rest later
;
.mode2_02:
	mov	al, [rbx+MAN_MSW_OFST]		; Get M.S.Byte of mantissa
	or      al, 0x030			; Form ascii digit
	call    CharOutFmt			; Output digit
.not_mode2_01:
;
; =============================================
;   8) Loop to extract 64 bit words containing
;           16 digits each and convert bast 10
;
	mov	rax, 0
	mov	[rbx+MAN_MSW_OFST], rax		; Clear previous digit before looping
	cmp	r10, 16				; need at least 16 digits
 	jle	.skip_groups			; less than 16, do single digits
	sub	r10, 16				; First group of 16 digits
;------------
; Main loop
;------------
.loop12:
;
;   8a) Use variable accuracy technique to improve speed
;
;       Adjust accuracy variable [No_Word] to optimize printing speed and time.
;       The size of the mantissa shrinks as digits are printed.
;
	mov	rax, r10			; Number of digits remaining to print
	add	rax, 16				; Adjust for number digits in group
	call	Digits_2_Words			; Digits --> Words
	cmp	rax, MINIMUM_WORD		; Less than minimum?
	jge	.skip12a			; No , skip to keep value
	mov	rax, MINIMUM_WORD		; Set to minimum
.skip12a:
	cmp	rax, [D_Flt_Word]		; Greater than maximum?
	jle	.skip12b			; if negative, request too small
	mov	rax, [D_Flt_Word]		; Move mainimum size to RBX, use instead
.skip12b:
;
;  27Dec14 Notes: Accuracy testing at 100, 000 digits
;   Divide 1/3 and print, looking for 0.333333....
;   Using a setting with 4 guard bytes
;   Fixed accuracy shows +60 digits accurate
;   Add 0 words: -22 digits
;   Add 1 word2: -3 digits
;   Add 2 words: +16 digits
;   Add 3 words: +36 digits
;   Add 4 words: +55 digits
;   Add 5 words: +60 digits (same as non-ajusted)
;   Will add 6 for now to be conservative
;
	add	rax, 6				; Add words for cumulative errors
	call	Set_No_Word_Temp		; Set accuracy
;
;   8b) Print mantissa digits, 16 digits at a time per loop iteration
;
;                      Multiply mantissa by 1E16 to move 16 digits beyond radix point
;
;                      RAX, RDX, and R8 used in x86 multiply
;                      R9 holds high word been loops
;                      rdi temporarily hold carry flag
;                      RCX is counter
;
	mov	rax, 0
	mov	[rbx+MAN_MSW_OFST], rax		; Clear last data from previous
	mov	rbp, [LSWOfst]			; RBP point at L.S.Word
	mov	rcx, [No_Word]			; Counter for number of words
	dec	rcx				; Stop with high word in M.S.Word
	xor 	r9, r9				; R9 will carry high word between loops
	mov	r8, 10000000000000000		; 1E16 as a 64 bit data value
;
.loop12f:
	xor	rdx, rdx			; clear high word
	mov	rax, [rbx+rbp]			; Load first number
	mul	r8				; RDX:RAX = RAX * R8
	add	rax, r9				; Add high qword from previous
	rcl	rdi, 1				; Save CF temporarily in RDI
	mov	[rbx+rbp], rax			; Store result (low qword)
	xor	r9, r9				; Clear before adding CF and high word
	rcr	rdi, 1				; Restore CF from RDI
	adc	r9, rdx				; Add CF + high qword to R8 for next time.
	add	rbp, BYTE_PER_WORD		; Increment Index
	loop	.loop12f			; Decrement RCX counter and loop back
;
	mov	[rbx+rbp], r9			; Save final remainder, this is the digits
;
;  8c) Extract 10 digits as a group from 64 bit word
;
;             Loop 10 times to...
;                Recursively divide by power of 10 to get digits
;                    and form ASCII digits and print
;
;                   R9 = Input value
;                   R8 = decade divisor to form digits
;                   RCX = Counter
;                   RDX, RAX used for x86 DIV command
;
	mov	r9, [rbx+MAN_MSW_OFST]		; Get next set of 16 digits digit
	mov	r8, 1000000000000000		; Set dividend for 1st of 16 digits
	mov	rcx, 16				; Counter
;
;              Loop printing characters
;
.loop12h:
	xor	rdx, rdx			; RDX = 0
	mov	rax, r9				; Original number, or remainder in later terms
	div	r8				; DIV by power of 10, RAX = RDX:RAX / R8 , Remainder = RDX
	mov	r9, rdx				; Remainder for next time
	or	al, 0x30			; Form ascii
	call	CharOutFmt			; Output character
	xor	rdx, rdx			; RDX = 0
	mov	rax, r8				; last power of 10
	mov	rbp, 10				; for DIV command
	div	rbp				; Reduce 1 power of 10 RAX = RDX:RAX / 10
	mov	r8, rax				; Save next power of 10
;
; Mode 1 - Fixed mode special processing
;
	cmp	qword[Out_Mode], 1		; Printing fixed notation?
	jne	.skip12i			; No, skip
	cmp	qword[Out_Exponent], 0		; Is exponent > zero?
	je	.skip12i			; No, skip
	dec	qword[Out_Exponent]		; Then, decrement exponent
	jnz	.skip12i			; Did it reach zero? No, Skip
	mov	al, '.'				; Else, exponent reach zero
	call	CharOutFmt			; Print decimal point
.skip12i:
;
; Mode 2 - Integer mode special processing
;
	cmp	qword[Out_Mode], 2		; integer mode?
	jne	.skip12n			; Loop until RCX is zero
	dec	qword[Out_Exponent]		; Decrement exponent, last printed?
	jz	.exit				; Yes, zero, done printing
.skip12n:
	loop	.loop12h
;
; Decrement digit counter and see if another group of 16 is needed, else print single digits
;
	sub	r10, 16				; Will next group of 10 drop below zero?
	jg	.loop12				; No, continue to loop until R10 < 1
;
; Setup for single digit printing
;
	add	r10, 16				; Restore the 10 subtracted
.skip_groups:
	mov	rcx, r10			; Move to RCX for use wutg LOOP command
	mov	rax, 0
	mov	[rbx+MAN_MSW_OFST], rax		; Clear any bits form 64 bit work, byte only next
;
; =============================================
;   9) Print remaining single digits
;
;         This consists of remaining digits less than 16 digits
;
.skip12aa:
	or	rcx, rcx			; is counter zero?
	jz	.skip12bb			; yes no more digits
;
	mov     byte[rbx+MAN_MSW_OFST], 0	; Clear last data
	call	MultManByTen			; Multiply mantissa by 10
	mov	al, [rbx+MAN_MSW_OFST]		; Get next digit
	or	al, 0x30			; Form ascii character
	call	CharOutFmt			; Output character
;
; Mode 1 - Fixed mode special processing
;
	cmp	qword[Out_Mode], 1		; Printing fixed notation?
	jne	.loop12kk			; No, skip
	cmp	qword[Out_Exponent], 0		; Is exponent > zero?
	je	.loop12kk			; No, skip
	dec	qword[Out_Exponent]		; Then, decrement exponent
	jnz	.loop12kk			; Did it reach zero? No, Skip
	mov	al, '.'				; Else, exponent reach zero
	call	CharOutFmt			; Print decimal point
.loop12kk:
;
; Mode 2 - Integer mode special processing
;
	cmp	qword[Out_Mode], 2		; integer mode?
	jne	.skip12p			; Loop until RCX is zero
	dec	qword[Out_Exponent]		; Decrement exponent, last printed?
	jz	.exit				; Yes, exponent zero, done printing
.skip12p:
;
; End of digit printing loop, loop back, next check if extra digits needed?
;
	loop	.skip12aa			; Loop till CX = 0
.skip12bb:
;
; =============================================
;  10) Check for overflow
;
;      When printing fixed or integer mode, it
;      is possible the specified number of digits
;      may not be sufficient to print the number.
;      A warning is printed when overflow occurs.
;
; Mode 1 - Case of Fixed notation, check for overflow
;
	cmp	qword[Out_Mode], 1
	jne	.not_mode1_20
;
	mov	rax, [Out_Exponent]
	or	rax, rax			; Exponent should have reached zero and printed decimal point
	jz	.not_mode1_20			; Yes, zero, all is OK
	mov	rax, .Msg_Fix_Overflow
	call	StrOut				; Print error message
	jmp	.exit
.not_mode1_20:
;
;  Mode 2 - Case of Integer notation, check for overflow
;
	cmp	qword[Out_Mode], 2
	jne	.not_mode2_50
;
	mov	rax, [Out_Exponent]
	or	rax, rax			; Exponent should have reached zero and printed decimal point
	jz	.not_mode2_50			; Yes, zero, all is OK
	mov	rax, .Msg_Int_Overflow
	call	StrOut				; Print error message
	jmp	.exit
.not_mode2_50:
;
; =============================================
;   11) If requested, print additional digits to see past end
;
	cmp	qword[Out_Mode], 2		; Is it integer mode?
	je	.exit				; Yes, then skip extra digits
;
	mov	rcx, [NoExtDig]			; Get extended digits
	or	rcx, rcx			; Extended digits needed?
	jz	.skip14				; NO, skip extended digits
	mov	rdx, [fd_echo]			; File descriptor,
	or	rdx, rdx			; Capture to file?
	jnz	.skipcolor1			; Yes, no color codes
	mov	rax, .red_text
	call	StrOut
.skipcolor1:
	mov	al, ' '				; Space character
	call	CharOutFmt			; Output it
	mov	al, '('				; '(' for roundoff digit
	call	CharOutFmt			; Output it
.skip13:
	mov     byte [rbx+MAN_MSW_OFST], 0	; Clear last data
	call	MultManByTen			; Multiply mantissa by 10
	mov	al, [rbx+MAN_MSW_OFST]		; Get next digit
	or	al, 0x30			; Form ascii character
	call	CharOutFmt			; Output character
	loop	.skip13				; Loop till CX = 0
	mov	al, ')'				; ')' for end of roundoff
	call	CharOutFmt			; Output character
	or	rdx, rdx			; Out capture to file?
	jnz	.skipcolor2			; Yes, don't change colors
	mov	rax, .red_cancel
	call	StrOut
.skipcolor2:
.skip14:
	call	RestoreFullAccuracy		; Accuracy reduced for printing
;
;
; =============================================
;  10) Print base 10 exponent (Mode 0 only)
;
	cmp	qword[Out_Mode], 0
	jne	.not_mode0_02
;
;       Print exponent "E" and sign + or -
;
        mov     al, ' '
        call    CharOutFmt			; Output space character
        mov     al, 'E'
        call    CharOutFmt			; Output 'E' for sci notation
	mov	rax, [Out_Exponent]		; Get base 10 exponent
	rcl	rax, 1				; Rotate sign into carry
	jnc	.skip15				; Exponent is positive, skip to + sign
 	neg	qword [Out_Exponent]		; Calculate 2's compliment of base 10 exponent
	mov	al, '-'				; Negative minus sign
	jmp	short .skip16
.skip15:
	mov	al, '+'				; positive plus sign
.skip16:
	call	CharOutFmt			; output sign
;
;  Print exponent in base 10
;
	mov	rax, [Out_Exponent]		; Exponent in Base 10 moved to RAX for printing
	call	PrintWordB10			; Print positive word in decimal format to CharOutFmt
;
.not_mode0_02:

.exit:
	call	RestoreFullAccuracy		; one more time to be sure
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
.Msg_Fix_Overflow:	db	" [Fixed Point Overflow!] ", 0
.Msg_Int_Overflow:	db	" [Integer Overflow!] ", 0
.red_text:	db	27, "[31m", 0
.red_cancel:	db	27, "[0m", 0


;--------------------------------------------------------------
;
;  Print Calculation Result (abbreviated format)
;
;  During command input, this routine is intended
;  to show the user an abbreviated view of the stack
;
;--------------------------------------------------------------
PrintResult:
;	NOP
;	ret

	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

        mov     rax, [iVerboseFlags]
	test	rax, 0x10
	jz	.quiet_mode
;
; Save existing accuracy
;
	mov	rax, [No_Byte]
	push	rax
	mov	rax, [No_Word]
	push	rax
	mov	rax, [LSWOfst]
	push	rax
	mov	rax, [NoSigDig]
	push	rax
	mov	rax, [NoExtDig]
	push	rax
	mov	rax, [D_Flt_Word]
	push	rax
	mov	rax, [D_Flt_Byte]
	push	rax
	mov	rax, [D_Flt_LSWO]
	push	rax
	mov	rax, [Out_Mode]
	push	rax
;
; Configure temporary accuracy
;
	mov	rax, 6				; Set accuracy words
	call	Set_No_Word			; Set accuracy for printing result
	mov	rax, 50
	cmp	rax, [NoSigDig]			; is 50 less than current
	jl	.skip00
	mov	rax, [NoSigDig]
.skip00:
	mov	[NoSigDig], rax
	mov	rax, 0
	mov	[NoExtDig], rax
;
; Setup For Loop
;
	mov	rbx, HAND_XREG
	mov	rcx, 1
        mov     rax, [iVerboseFlags]
	test	rax, 0x20
	jz	.skip1
	mov	rcx, 4
.skip1:
	test	rax, 0x40
	jz	.skip2
	mov	rcx, (TOPHAND-HAND_XREG+1)
.skip2:
;
; Copy Reg for printing
;
.loop1:
	mov	rsi, rbx
	mov	rdi, HAND_ACC
	call	CopyVariable
;
; Configure Printing Formatting
;
        mov     rax, 0				; unformatted
        mov     [OutCountActive], rax
	mov	rsi, rbx			; Handle number
	call	GetVarNameAdd
	call	StrOut
;
; Print the Update
;
	call	PrintVariable
	call	CROut
;
; Increment and loop
;
	inc	rbx				; Handle of next variable
	loop	.loop1
;
; Restore old accuracy
;
	pop	rax
	mov	[Out_Mode], rax
 	pop	rax
	mov	[D_Flt_LSWO], rax
	pop	rax
	mov	[D_Flt_Byte], rax
	pop	rax
	mov	[D_Flt_Word], rax
	pop	rax
	mov	[NoExtDig], rax
	pop	rax
	mov	[NoSigDig], rax
	pop	rax
	mov	[LSWOfst], rax
	pop	rax
	mov	[No_Word], rax
	pop	rax
	mov	[No_Byte], rax
;
.quiet_mode:
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
.ACC_string:	db	"X-Reg = ", 0
;
;----------------------------------------------------
;
; Floating Point Input
;
; Convert ASCII string to floating point number
;
;    Input:    RAX = Address of null terminated character buffer
;
;    Output:   (none)
;
;    Valid number syntax

;    Leading +, -
;      12
;      +12
;      -12
;    Exponent E or e
;      12E34
;      12e34
;    Exponent signs
;      12E34
;      12E+34
;      12E-34
;    Decimal Point
;      .12
;      1.2
;      12.
;      0.12
;      12.34
; ------------------------------------------------------
;
;  InFlags bits
;  0x0001 0 = Accepting leading + or - in mantissa, 1=done
;  0x0002 0 = positive sign 1 = negative sign need 2's compliment
;  0x0004 0 = Accepting integer part before decimal point, 1=done
;  0x0008 0 = Accepting fraction part after dcimal point, 1=done
;  0x0010 0 = Accepting exponent + - sign characters, 1=done
;  0x0020 0 = positive exponent sign, 1 = negative exponent sign
;  0x0080 1 = Not Zero
;  0x0100 1 = mantissa integer part has digits
;  0x0200 1 = mantissa fraction part has digits
;  0x0400 1 = exponent part has valid digits
;
; -------------------------------------------------------
FP_Input:
	push	rax
	push	rbx				; Pointer to start of text string
	push	rcx				; CL = input character from stream
	push	rdx				; Offset into input string buffer
	push	rsi
	push	rdi
	push	rbp
	push	r8				; counter for exponent adjustment
	push	r9				; binary exponent queue

	; Initialize input flag bits and registers
	mov	qword [InFlags], 0
	mov	rbx, rax			; pointer to input string
	mov	rdx, 0				; pointer to next character
	mov	r8, 0				; exponent adjust counter
	mov	r9, 0				; accumulator for exponent
	;
	; Clear ACC, used to hold number
	;
	mov	rsi, HAND_ACC
	call	ClearVariable			; Clear ACC due to error

; -----------------------------------------------------
;  Main character input loop for mantissa an exponent
; -----------------------------------------------------
.loop:
	call	_GetNextValidInputCharacter	; CL = input character
	jc	.error_exit			; CF = 1 for invalid character
	jz	.end_of_string			; ZF = 0 for end of string, no process string conversion

	;
	; skip to relevant part of input code
	;
	test	qword [InFlags], 0x0010		; Exponent sign character input done?
	jnz	.skip_exponent_sign		; Yes, skip input of exponent sign chaaracter
	;
	test	qword [InFlags], 0x0008		; Mantissa characters after deciaml point done?
	jnz	.skip_mantissa_fraction_digit	; Yes, skip mantissa digit input
	;
	test	qword [InFlags], 0x0004		; mantissa characters before decimal point done?
	jnz	.skip_mantissa_integer_digit	; Yes, skip mantissa digits before decimal point
	;
	test	qword [InFlags], 0x0001		; Mantissa sign character input done?
	jnz	.skip_mantissa_sign		; Yes, skip input of mantissa sign character
	;
	; -------------------------------------------------------
	; (1) Get optional sign character at start of mantissa
	; -------------------------------------------------------
	cmp	cl, byte "+"
	jne	.not_mantissa_plus
	or	qword [InFlags], 0x0001		; set flag for sign recieved
	jmp	.loop				; ignore + sign
.not_mantissa_plus:
	cmp	cl, byte "-"
	jne	.not_mantissa_minus
	or	qword [InFlags], 0x0001		; set flag for sign recieved
	or	qword [InFlags], 0x0002		; set flag number is negative, need 2's compliment later
	jmp	.loop				; ignore the - sign and get next digits
.not_mantissa_minus:
	; once a numeric character is input, no longer accept + or -
	call	_CheckValidInputNumber		; see if 0-9, if so, + and - no longer valid
	jc	.skip_mantissa_sign		; not valid, keep parsing
	or	qword [InFlags], 0x0001		; set flag for no longer accepting sign character
.skip_mantissa_sign:
	; -------------------------------------------------------
	; (2) Get mantissa digits before decimal point
	; -------------------------------------------------------
	call	_CheckValidInputNumber
	jc	.not_valid_mantissa_digit	; continue parsing digits as long as in range 0-9
	;
	or	qword [InFlags], 0x0100		; set flag for mantissa integer digits exist
	;
	mov	al, cl
	and	al, 0x0F			; Is this a non-zero digit?
	jz	.integer_part_character_zero
	or	qword [InFlags], 0x0080		; Yes, non-zero number, set non-zero flag
.integer_part_character_zero:
	; -------------------------------------------------------
	; Digits are added to the integer part
	; of the number by taking the previous mantissa,
	; multiply by 10, then add the next digit.
	; -------------------------------------------------------

	; multiply integer part of mantissa from previous digits by 10
	mov	rsi, HAND_ACC
	call	FP_MultByTen

	; convert ASCII to binary in OPR, note 8 bit to 64 bit operation with ASCII and AND
	mov	al, cl
	;            --fedcba9876543210 <-- ruler
	and	rax, 0x000000000000000f
	mov	rsi, HAND_OPR
	call	FP_Load64BitNumber

	; Add OPR to ACC with result in  ACC
	call	FP_Addition

	jmp	.loop				; Loop back and get next character
.not_valid_mantissa_digit:
	;
	; check decimal point
	;
	cmp	cl, byte '.'			; is decimal point
	jne	.not_mantissa_decimal_pt
	or	qword [InFlags], 0x0004		; set flag for done integer part
	jmp	.loop				; ignore decimal point and get next character
.not_mantissa_decimal_pt:
	;
	; check decimal exponent symbol
	;
	cmp	cl, byte 'e'			; is e for exponent?
	jne	.not_integer_exponent_e
	or	qword [InFlags], 0x0004		; set flag for done integer part
	or	qword [InFlags], 0x0008		; set flag for done fraction part
	jmp	.loop				; ignore e and get next character
.not_integer_exponent_e:
	cmp	cl, byte 'E'			; is E for exponent?
	jne	.not_integer_exponent_E
	or	qword [InFlags], 0x0004		; set flag for done integer part
	or	qword [InFlags], 0x0008		; set flag for done fraction part
	jmp	.loop				; ignore E and get next character
.not_integer_exponent_E:
	jmp	.error_exit			; Case not "." "e" "E" must be error

.skip_mantissa_integer_digit:
	; -------------------------------------------------------
	; (3) Get mantissa digits after decimal point
	; -------------------------------------------------------
	call	_CheckValidInputNumber		; continue parsing digits as long as in range 0-9
	jc	.not_valid_fraction_digit
	;
	or	qword [InFlags], 0x0200		; set flag for mantissa fraction digits exist
	;
	mov	al, cl
	and	al, 0x0F			; Is this a non-zero digit?
	jz	.fraction_part_character_zero
	or	qword [InFlags], 0x0080		; Yes, non-zero number, set non-zero flag
.fraction_part_character_zero:
	; -------------------------------------------------------
	; Digits are added to the fraction part
	; of the number by taking the previous mantissa,
	; multiply by 10, decrement exponent adjustment counter
	; -------------------------------------------------------
	; multiply integer part of mantissa from previous digits by 10
	mov	rsi, HAND_ACC
	call	FP_MultByTen

	; convert ASCII to binary in OPR, note 8 bit to 64 bit operation with ASCII and AND
	mov	al, cl
	;            --fedcba9876543210 <-- ruler
	and	rax, 0x000000000000000f
	mov	rsi, HAND_OPR
	call	FP_Load64BitNumber

	; Add OPR to ACC with result in  ACC
	call	FP_Addition

	; Divide by 10 because fraction part should not change exponent
	mov	rsi, HAND_ACC

	; Decrement exponent counter.
	; At the end, we will divide by 10 for this many times in r8
	dec	r8

	jmp	.loop				; Loop back and get next character
.not_valid_fraction_digit:
	;
	; check exponent
	;
	cmp	cl, byte 'e'			; is e for exponent/
	jne	.not_fraction_exponent_e
	or	qword [InFlags], 0x0008		; set flag for done fraction part
	jmp	.loop				; ignore e and get next character
.not_fraction_exponent_e:
	cmp	cl, byte 'E'			; is E for exponent?
	jne	.not_fraction_exponent_E
	or	qword [InFlags], 0x0008		; set flag for done fraction part
	jmp	.loop				; ignore E and get next character
.not_fraction_exponent_E:
	jmp	.error_exit			; Case not "e" "E" must be error

.skip_mantissa_fraction_digit:
	;
	; --------------------------------------------
	; (4) Get Exponent leading "+" or "-"
	; --------------------------------------------
	cmp	cl, byte "+"
	jne	.not_exponent_plus
	or	qword [InFlags], 0x0010		; set flag for exponent sign recieved
	jmp	.loop				; ignore + sign
.not_exponent_plus:
	cmp	cl, byte "-"
	jne	.not_exponent_minus
	or	qword [InFlags], 0x0010		; set flag exponent sign recieved
	or	qword [InFlags], 0x0020		; set flag exponent is negative, need 2's compliment later
	jmp	.loop				; ignore the - sign and get next digits
.not_exponent_minus:
	; once a numeric character is input, no longer accept + or -
	call	_CheckValidInputNumber		; see if 0-9, if so, + and - no longer valid
	jc	.skip_exponent_sign		; not valid, keep parsing
	or	qword [InFlags], 0x0010		; set flag for no longer accepting exponent sign characters

.skip_exponent_sign:
	; -------------------------------------------------------
	; (5) Get Exponent digits
	; -------------------------------------------------------
	;
	; Register R9 will hold running value of exponent
	; For each numeric character, previous R9 will be multiplied
	; by 10 and then binary value from character added.
	;
	call	_CheckValidInputNumber
	jc	.error_exit
	or	qword [InFlags], 0x0400		; set flag for exponent digits exist
	; Multiply the ongoing exponent in r9 by 10 before adding next digit
	push	rdx				; save offset to input string
	mov	rax, r9				; get binary exponent
	mov	rbp, 10				; Need to use register for this type of MUL
	mul	rbp				; Multiply RAX * R9 = RDX:RAX
	mov	r9, rax				; Return mutipled value back to R9
	mov	rax, rdx
	pop	rdx
	or	rax, rax			; overflow?
	jnz	.error_exit			; overflow into next 64 bit word
	mov	rax, r9
	rcl	rax, 1
	jc	.error_exit			; overflow into sign bit.

	; Convert the next character to binary, then add to exponent, chcking for overflow
	; Note 8 bit to 64 bit cast
	mov	al, cl				; get next character
	;            --fedcba9876543210 <-- ruler
	and	rax, 0x000000000000000f
	add	r9, rax				; add binary number to exponent
	jc	.error_exit			; don't overflow past 64 bits
	mov	rax, r9
	rcl	rax, 1				; don't overflow into negative number bit
	jc	.error_exit			; overflow into sign bit.
	;
	jmp	.loop				; done, get next character of exponent


.end_of_string:
	; -------------------------------------------------------
	; (6) General syntax error checking
	; -------------------------------------------------------
	; check for no numeric digits in mantissa, then error
	mov	rax, [InFlags]			; FP Input status word
	and	rax, 0x0300			; integer digits exist and fraction digits exist
	jz	.error_exit			; no valid digits in mantissa, error
	; check for no digits after e in exponent
	mov	rax, [InFlags]			; Check for e or E but no valid digits in exponent
	and	rax, 0x0408			; exponent digits exists and "e" was issued
	xor	rax, 0x0008
	jz	.error_exit
	;
	; Case of mantissa zero, simply return zero in ACC
	;
	mov	rax, [InFlags]
	and	rax, 0x0080
	jnz	.mantissa_not_zero
	;
	; return zero
	mov	rsi, HAND_ACC
	call	ClearVariable			; Clear ACC due to error
	jmp	.exit				; and exit without error

.mantissa_not_zero:
	; ---------------------------------------------------------------------------------
	; (7) Determine power of 10 offset due to fracton digits and exponent number
	; ---------------------------------------------------------------------------------
	; combine R8 and R8 to get shift from fracction digits and exponent shift
	test	qword [InFlags], 0x0020		; is exponent negative flag set?
	jz	.exponent_sign_positive		; No, exponent positive,
	sub	r8, r9				; Else, Yes, subtract R8 = R8 - R9
	jmp	short .adjust_exponent
.exponent_sign_positive:
	add	r8, r9				; Exponent positive, add R8 = R8 + R9

.adjust_exponent:

	; -----------------------------------------------------------------------------------
	; (8) Multiply X 10 or divide / 10 to account for fraction digits and exponent number
	; -----------------------------------------------------------------------------------
	mov	rax, r8				; Is exponent zero?
	or	rax, rax			; is it zero?
	jz	.fix_number_sign		; Yes, no adjustment needed

	rcl	rax, 1				; Is exponent negative?
	jnc	.positive_exponent_adjustment	; No, multiply by 10
.negative_exponent_adjustment:
	; this next part is to save time by reducing number multiplications
	; First check exponent adjustment can accommodate of 1E+15 steps
	; If able, use subroutine to divide number by 1E+15
	; This makes use of i7 DIV command
	mov	rax, r8				; Get curent exponet adjusment
	neg	rax				; 2's compliment of ACC
	cmp	rax, 15				; Can it accommodate large step times 1E+15
	jl	.skip_large_div			; No, skip to single steps times 10
	mov	rsi, HAND_ACC
	call	FP_DivideByTenE15		; Multiply number by 10
	add	r8, 15				; Decrement exponent counter
	jz	.fix_number_sign		; If zero, done, skip steps of divide by 10
	jmp	short .negative_exponent_adjustment
						; else, not done, loop back
.skip_large_div:
	mov	rsi, HAND_ACC
	call	FP_DivideByTen			; In loop, divide entire number by 10
 	inc	r8
	jnz	.negative_exponent_adjustment
	jmp	short .fix_number_sign

.positive_exponent_adjustment:
	; First check if the exponent adjustment can accommodate of 1E+15 steps
	; If able, use subroutine to multiply 1E+15
	; This makes use of i7 MUL command
	mov	rax, r8				; Get curent exponet adjusment
	cmp	rax, 15				; Can it accommodate large step times 1E+15
	jl	.skip_large_mult		; No, skip to single steps times 10
	mov	rsi, HAND_ACC
	call	FP_MultByTenE15			; Multiply number by 10
	sub	r8, 15				; Decrement exponent counter
	jz	.fix_number_sign		; If zero, done, skip steps to multiply by 10
	jmp	short .positive_exponent_adjustment
						; else, not done, loop back
.skip_large_mult:
	mov	rsi, HAND_ACC
	call	FP_MultByTen			; In loop, mutiply entire number by 10
	dec	r8
	jnz	.skip_large_mult

.fix_number_sign:
	; ------------------------------------------------------------------------
	; (9) If minus sign before mantissa, then perform 2's compliment to negate
	; ------------------------------------------------------------------------
	test	qword [InFlags], 0x0002		; Was minus sign received, then negataive
	jz	.exit
	;
	; Chanage sign
	mov	RSI, HAND_ACC
	call	FP_TwosCompliment		; Negate the number due to - sign
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
	; Set CF = 0 for no error
	clc
	ret
.error_exit:
	mov	rsi, HAND_ACC
	call	ClearVariable			; Clear ACC due to error

	pop	r9
	pop	r8
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; Set CF = 1 for error condition
	stc
	ret


;--------------------------------
; _GetNextValidInputCharacter
;
; Internal subroutine
;
; Input:
;    RBX = address of text buffer
;    RDX = pointer into current character in buffer
;          (RDX will be incremented)
;
; Output:
;    CL = Next character from input string, 0 end of string
;    ZF = Zero flag set to 1 at end of string
;    CF = carry set to 1 for invalid character
;
; Flags should be preserved with CALL/RET because there is no task switch
;
; Valid: 0123456789+-.eE
;
; Return CF = 0 Character was valid
;--------------------------------
_GetNextValidInputCharacter:
	;
	; Ignore whitespace
	;
	jmp	short .gnc02			; Skip pointer increment, only used in loop
.gnc01:
	inc	rdx				; Advance pointer to skip whitespace
.gnc02:
	mov	cl, [rbx+rdx]			; Next character in CL
	cmp	cl, 0x20			; Is it a space character
	je	.gnc01				; Yes, ignore whitespace
	cmp	cl, 0x09			; Is it a tab character
	je	.gnc01				; Yes, ignore whitespace
	cmp	cl, 0x0A			; Is it a new line character
	je	.gnc01				; Yes, ignore whitespace
	cmp	cl, 0x0D			; Is it a return character
	je	.gnc01				; Yes, ignore whitespace
	;
	; Check for end of string
	;
	or	cl, cl				; Check for zero terminated string
	jnz	.gnc03				; if current character zero, end of string, don't increment
	xor	cl, cl				; ZF set to zero, CL set to 0x00
	clc					; CF = 0 for no error
	ret					; return CL zero for end of string
.gnc03:
	inc	rdx				; move pointer to next character, for next request
	;
	; Check valid characters
	;
	cmp	cl, byte '.'
	je	.valid_character
	cmp	cl, byte 'E'
	je	.valid_character
	cmp	cl, byte 'e'
	je	.valid_character
	cmp	cl, byte '+'
	je	.valid_character
	cmp	cl, byte '-'
	je	.valid_character
	cmp	cl, byte '0'
	jl	.invalid_characer
	cmp	cl, byte '9'
	jg	.invalid_characer
.valid_character:
	or	cl, cl				; ZF to non-zero to show not end of sting
	clc					; CF = 0 to show no error
	ret					; return with CL = character
.invalid_characer:
	xor	cl, cl				; Set ZF = 0 to show end of string
	stc					; Set CF = 1 for error
	ret					; return with CL = 0x00

;--------------------------------
; Check input
;
; CL = input character
;
; Valid: 0123456789
;
; Return CF = 0 Character was valid
;
; Flags should be preserved with CALL/RET because there is no task switch
;
;--------------------------------
_CheckValidInputNumber:
	cmp	cl, byte '0'
	jl	.invalid_characer
	cmp	cl, byte '9'
	jg	.invalid_characer
	clc
	ret
.invalid_characer:
	stc
	ret
;
;--------------------------------------------------------------
; Integer input routine
;
; This routine will put an integer value from terminal input
; and then normalize the number
;
;    Input:    RAX = Address of null terminated character buffer
;
;    Output:   (none)
;
;--------------------------------------------------------------
IntegerInput:
; Save Registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
	push	r10
;
; Source Address (where number is to go)
;
	mov	r10, rax			; R10 Address to input buffer
	mov	rbx, FP_Acc			; RBX point to ACC
	mov	rdx, FP_WorkA			; RDX point to WorkA
;
;  Clear workspace
;
	mov	rsi, HAND_ACC			; Handle number of ACC
	call	ClearVariable			; Pointing with RSI, clear output variable;
	mov	rsi, HAND_WORKA		;
	call	ClearVariable			; Using RSI clear WorkA
;
; read characters from buffer
;
.loop1:
	mov	al, [r10]			; Get next character from buffe4
	inc	r10				; Point at next character
	cmp	al, '9'+1			; Digit > ascii '9'
	jnc	.skip2				; Yes convert input
	cmp	al, '0'				; Digit < ascii '0'
	jc	.skip2				; Yes convert input
		; call	CharOut				; Echo to screen
	and	al, 0FH				; Mask to BCD bits
	mov	rsi, HAND_ACC
	call	MultManByTen			; Using Multiply mantissa by 10
	mov	rsi, HAND_WORKA		;
	call	ClearVariable			; Using RSI clear WorkA
	mov	rbp, MAN_MSB_OFST+1		; Point at MSWord + 1 byte
	sub	rbp, [No_Byte]			; Point at L.S.byte
	mov	[rdx+rbp], al			; Put BCD number in WORKA
	mov	rsi, HAND_ACC
	mov	rdi, HAND_WORKA
	call	AddMantissa			; Pointing with RDX (WorkA)
;						; add mantissa, result pointer RSI
	test	byte[rbx+MAN_MSB_OFST], 0FFH	; Overflow yet?
	jnz	.skip2				; Yes stop input
	jmp	.loop1				; Loop for next digit
;
;
; At this point the
; exponent must be pre loaded
; with the number of bits in the
; mantissa so that the normalize
; routine will convert the input
;
;
.skip2:
	mov     rax, [No_Byte]			; Get number of bytes
	shl	rax, 3				; Times 8 for 8 bits
	add	[rbx+EXP_WORD_OFST], rax	; Adjust exponent
	sub	dword[rbx+EXP_WORD_OFST], 1	; Compensate for sign bit
;
	call	FP_Normalize			; Using RSI Normalize Input
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
;

;--------------------------------------------------------------
;   Multiply Mantissa by 10
;
;   Input:  RSI = address of Variable   DS:AX
;
;   Output: none
;
;--------------------------------------------------------------
MultManByTen:
	push	rax				; x86-64 MUL command
	push	rbx				; Address of variable
	push	rcx				; Counter
	push	rdx				; x86-64 MUL command
	push	rsi				; Operand 1 handle number
	push	rdi				; 64 bit data  (input to function)
	push	rbp				; Offset pointer
	push	r8
	push	r9
;
; Setup address and counter
;
	mov	rdi, 10				; 10 as a 64 bit data value
	mov	rbx, [RegAddTable+(rsi*WSCALE)]	; RSI (index) --> RBX (address)
	mov	rbp, [LSWOfst]			; RBP point at L.S.Word
	mov	rcx, [No_Word]			; Counter for number of words
	xor 	r8, r8				; Clear previous high word
;
; Pre-Loop to clear zero bytes
;
; * * * * this seems to make it longer, comment out for now
;
;.loop1:
;	mov	rax, [rbx+rbp]			; Load first number
;	or	rax, rax			; Check for zero
;	jnz	.loop2				; Non zero begin regular mult.
;	add	rbp, BYTE_PER_WORD		; Increment Index
;	loop	.loop1				; Decrement RCX counter and loop back
;	jmp	.exit				; All zero, result remains zero
;
; Main loop
;
.loop2:
	xor	rdx, rdx			; clear high word
	mov	rax, [rbx+rbp]			; Load first number
	mul	rdi				; RDX:RAX = RAX * RDI
	add	rax, r8				; Add high qword from previous
	rcl	r9, 1				; Save CF
	mov	[rbx+rbp], rax			; Store result (low qword)
	xor	r8, r8				; Clear before adding CF and high word
	rcr	r9, 1				; Restore CF
	adc	r8, rdx				; Add CF + high qword to R8 for next time.
	add	rbp, BYTE_PER_WORD		; Increment Index
	loop	.loop2				; Decrement RCX counter and loop back
;
; After last work, check for overflow fixed format
;
	or	r8, r8				; is R8 zero (expected result)?
	jz	.exit				; Yes, exit
;
; handle error
;
	mov	rax, .errorMsg1
	call	StrOut
	mov	rax, 0				; Code for error already printerd
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
.errorMsg1	db	"MultManByTen overflow, top word not zero after last work saved", 0xD, 0xA, 0

;
;--------------------------------------------------------------
;   Multiply Variable by 10
;
;   Input:   RSI = Wariable handle
;
;   Output:  none
;
;   Notes:  Uses WorkA register
;
;--------------------------------------------------------------
FP_MultByTen:
	call	Right1ByteAdjExp		; Make room for Mult
	call	MultManByTen			; Multiply mantissa x 10
	call	FP_Normalize			; Normalize result
	ret


;------------------------------------------
;  Same routine but multiply by 1x10E15
;
;   Input:  RSI = address of Variable   DS:AX
;
;   Output: none
;
;------------------------------------------
FP_MultByTenE15:
	push	rax				; x86-64 MUL command
	push	rbx				; Address of variable
	push	rcx				; Counter
	push	rdx				; x86-64 MUL command
	push	rsi				; Operand 1 handle number
	push	rdi				; 64 bit data  (input to function)
	push	rbp				; Offset pointer
	push	r8
	push	r9
;
; Make room for overflow
;
	call	Right1WordAdjExp		; Shift, room to hold result
;
; Setup address and counter
;
	mov	rdi, 1000000000000000		; 1x10^15
	mov	rbx, [RegAddTable+(rsi*WSCALE)]	; RSI (index) --> RBX (address)
	mov	rbp, [LSWOfst]			; RBP point at L.S.Word
	mov	rcx, [No_Word]			; Counter for number of words
	xor 	r8, r8				; Clear previous high word
;
; Main loop
;
.loop2:
	xor	rdx, rdx			; clear high word
	mov	rax, [rbx+rbp]			; Load first number
	mul	rdi				; RDX:RAX = RAX * RDI
	add	rax, r8				; Add high qword from previous
	rcl	r9, 1				; Save CF
	mov	[rbx+rbp], rax			; Store result (low qword)
	xor	r8, r8				; Clear before adding CF and high word
	rcr	r9, 1				; Restore CF
	adc	r8, rdx				; Add CF + high qword to R8 for next time.
	add	rbp, BYTE_PER_WORD		; Increment Index
	loop	.loop2				; Decrement RCX counter and loop back
;
; After last word, check for overflow fixed format
;
	or	r8, r8				; is R8 zero (expected result)?
	jz	.norm				; Yes, exit
;
; handle error
;
	mov	rax, .errorMsg1
	call	StrOut
	mov	rax, 0
	jmp	FatalError

.norm:
	call	FP_Normalize			; using RSI to normalize result
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
.errorMsg1	db	"MultByTenE15 overflow, top word not zero after last word saved", 0xD, 0xA, 0


;
;--------------------------------------------------------------
;   Divide Variable by 10
;
;   Input:   RSI = Variablel Handle
;
;   Output:  none
;
;   Note:    Variable must be >= 0
;--------------------------------------------------------------
FP_DivideByTen:
;   Save Registers
	push	rax				; Working Reg
	push	rbx				; Address Pointer
	push	rcx				; Loop Counter
	push	rdx				; Address Pointer
	push	rsi				; Operand 1 handle number (Input)
	push	rdi				; Used in DIV command
;  Source Address
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rbp, MAN_MSW_OFST		; Point at mantissa M.S.Byte
	mov	rcx, [No_Word]			; Get number of bytes
	xor	rdx, rdx			; Clear top of 128 bit numerator
	mov	rdi, 10				; Number to divide = 10
.loop1:
	mov	rax, [rbx+rbp]			; Get Byte to Divide
	div	rdi				; RDX:RAX Divide by RDX
	mov	[rbx+rbp], rax			; Save quotent, remainder in RDX
	sub	rbp, BYTE_PER_WORD		; Decrement address pointer
	loop	.loop1				; decrement RCX and loop until done
;
	call	FP_Normalize			; Using handle RSI call normalize
; Restore Registers
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret

;---------------------------------------
;  Same function but divide by 1x10E15
;
;  Input RSI is variable handle
;
;---------------------------------------
FP_DivideByTenE15:
;   Save Registers
	push	rax				; Working Reg
	push	rbx				; Address Pointer
	push	rcx				; Loop Counter
	push	rdx				; Address Pointer
	push	rsi				; Operand 1 handle number (Input)
	push	rdi				; Used in DIV command
;  Source Address
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RBX (address)
	mov	rbp, MAN_MSW_OFST		; Point at mantissa M.S.Byte
	mov	rcx, [No_Word]			; Get number of bytes
	xor	rdx, rdx			; Clear top of 128 bit numerator
	mov	rdi, 1000000000000000		; Number to divide = 10^15
.loop1:
	mov	rax, [rbx+rbp]			; Get Byte to Divide
	div	rdi				; RDX:RAX Divide by RDX
	mov	[rbx+rbp], rax			; Save quotent, remainder in RDX
	sub	rbp, BYTE_PER_WORD		; Decrement address pointer
	loop	.loop1				; decrement RCX and loop until done
;
	call	FP_Normalize			; Using handle RSI call normalize
; Restore Registers
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
;-----------------------
; EOF math-output.asm
;-----------------------
