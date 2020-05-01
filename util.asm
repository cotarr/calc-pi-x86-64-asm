%DEFINE UTIL
%include "var_header.inc"		; Header has global variable definitions for other modules
%include "func_header.inc"		; Header has global function definitions for other modules
;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Miscellaneous utility support functions
;
; File:   util.asm
; Module: util.asm, util.o
; Exec:   calc-pi
;
; Created 10/25/2014
; Edited  05/29/2015
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
; PrintAccuracy
; SetDigitAccuracy
; SetExtendedDigits
; SetWordAccuracy
; SetMaximumAccuracy
; PrintAccVerbose
; Words_2_Digits
; Digits_2_Words
; PrintWordB10
; PrintHexByte
; PrintHexWord
; PrintDDHHMMSS
; IntWordInput
;------------------------------------------------------------------------------------

section		.data   ; Section containing initialized data

section		.bss    ; Section containing uninitialized data

section		.text		; Section containing code



;
;------------------------------------------------------------------------------------
;
;  Function  PrintAccuracy
;
;  Input:   none
;
;  Output:  text send to CharOut
;
;------------------------------------------------------------------------------------
PrintAccuracy:
	push	rax

	mov	rax, .text1			; First message
	call	StrOut				; Print string
;
	mov	rax, [NoSigDig]			; Get current number significant digits
	call	PrintWordB10			; Print digits
;
	mov	rax, .text2			; First message
	call	StrOut				; Print string
	pop	rax
	ret
;
.text1:		db	"Accuracy: ", 0
.text2:		db	" Digits", 0xD, 0xA, 0


;
;------------------------------------------------------------------------------------
;
;  Function  SetDigitAccuracy
;
;  Input:   RAX number of digits to set
;
;  Output:  none
;
;------------------------------------------------------------------------------------
SetDigitAccuracy:
	push	rax
	push	rbx
	push	rcx
	push	rdx
;
; First check decimal limits and override if out of range
;
;    Digits lower limit
;
	mov	rbx, rax			; Save number of digits
	cmp	rax, MINIMUM_DIG		; Less than minimum?
	jge	.skip1
	mov	rbx, MINIMUM_DIG
;
; Digits Upper Limit
;
.skip1:
	mov	rax, VAR_WSIZE-EXP_WSIZE	; Maximum mantissa word size
	sub	rax, GUARDWORDS			; Adjust for guard words
	call	Words_2_Digits			; RAX will hold digits for maximum words
	cmp	rax, rbx			; subtract requested amount
	jge	.skip2				; if negative, request too small
	mov	rbx, rax			; Move mainimum size to RBX, use instead
;
;  Digits are ok, set the variables
;
.skip2:
	mov	rax, rbx
	mov	[NoSigDig], rax			; Set number of digits
;
; Convert digit count to word count
;
	call	Digits_2_Words			; Convert to words
	add	rax, GUARDWORDS			; Add the guard words
	mov	rbx, rax			; Save number of words
;
; Check Minimum word size
;
	cmp	rax, MINIMUM_WORD		; Minimum number of words allowed
	jge	.skip3				; Are we less?
	mov	rbx, MINIMUM_WORD		; Yes, use minimum value instead
;
; Check Maximum word size
;
.skip3:
	mov	rax, VAR_WSIZE-EXP_WSIZE	; Maximum mantissa size
	cmp	rax, rbx			; See if too big?
	jge	.skip4
	mov	rbx, rax			; use maximum word sizeinstead
.skip4:
	mov	rax, rbx			; number of words
	call	Set_No_Word			; Set variables No_Word, No_Byte.. etc

	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
;------------------------------------------------------------------------------------
;
;  Function  SetExtendedDigits
;
;  Input:   RAX number of digits to set
;
;  Output:  none
;
;------------------------------------------------------------------------------------
SetExtendedDigits:
	push	rax
	push	rbx
	push	rcx
	push	rdx
;
; First check decimal limits and override if out of range
;
;    Digits lower limit
;
	mov	rbx, rax			; Save number of digits
;
	rcl	rax, 1				; is it negative? Rotate carry to check
	jnc	.skip1				; no set to zero
	mov	rbx, 0
;
; Digits Upper Limit
;
.skip1:
	mov	rax, 1000			; Arbitrary check for 1000 digits
	cmp	rax, rbx			; subtract requested amount
	jge	.skip2				; if negative, request too small
	mov	rbx, rax			; Move mainimum size to RBX, use instead
;
;  Digits are ok, set the variables
;
.skip2:
	mov	rax, rbx
	mov	[NoExtDig], rax			; Set number of digits
;						; Done... easy!
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret


;
;------------------------------------------------------------------------------------
;
;  Function  SetWordAccuracy
;
;  Input:   RAX number of 64 bit words to set
;
;  Output:  none
;
;------------------------------------------------------------------------------------
SetWordAccuracy:
	push	rax
	push	rbx
	push	rcx
	push	rdx
;
;  Add guard words
;
	add	rax, GUARDWORDS
;
; First check word limits and override if out of range
;
;    Words lower limit
;
	mov	rbx, rax			; Save number of words
	cmp	rax, MINIMUM_WORD		; Less than minimum?
	jge	.skip1
	mov	rbx, MINIMUM_WORD
;
; Word  Upper Limit
;
.skip1:
	mov	rax, VAR_WSIZE-EXP_WSIZE	; Maximum mantissa word size
	cmp	rax, rbx			; subtract requested amount
	jge	.skip2				; if negative, request too small
	mov	rbx, rax			; Move mainimum size to RBX, use instead
;
;  Word limits are ok, set the variables
;
.skip2:
	mov	rax, rbx			; number of words
	call	Set_No_Word			; Set No_Word, No_Byte ... etc
;
; Now we can convert to digits
;
	mov	rax, rbx
	sub	rax, GUARDWORDS			; Take guard words back off
	call	Words_2_Digits			; convert RAX to number of digits
;
;    Digits lower limit
;
	mov	rbx, rax			; Save number of digits
	cmp	rax, MINIMUM_DIG		; Less than minimum?
	jge	.skip3
	mov	rbx, MINIMUM_DIG
;
; Digits Upper Limit
;
.skip3:
;-----------------
; NOT CHECKING UPPER AT PRESENT
;----------------
;	mov	rax, VAR_WSIZE-EXP_WSIZE	; Maximum mantissa word size
;	sub	rax, GUARDWORDS			; Adjust for guard words
;	call	Words_2_Digits			; RAX will hold digits for maximum words
;	cmp	rax, rbx			; subtract requested amount
;	jge	.skip4				; if negative, request too small
;	mov	rbx, rax			; Move mainimum size to RBX, use instead
;
;  Digits are ok, set the variables
;
.skip4:
	mov	rax, rbx
	mov	[NoSigDig], rax			; Set number of digits
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
;------------------------------------------------------------------------------------
;
;  Function  SetMaximumAccuracy
;
;  Input:   none
;
;  Output:  none
;
;------------------------------------------------------------------------------------
SetMaximumAccuracy:
	push	rax
	push	rbx
	push	rcx
	push	rdx

	mov	rax, VAR_WSIZE-EXP_WSIZE	; Maximum mantissa word size
	call	Set_No_Word			; Set No_Word, No_Byte... etc
	sub	rax, GUARDWORDS			; Take guard words back off
	call	Words_2_Digits			; Convert 64 bit words to decimal digits
	mov	[NoSigDig], rax			; Set number of digits

	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
;------------------------------------------------------------------------------------
;
;  Function  PrintAccuracy
;
;  Input:   none
;
;  Output:  text send to CharOut
;
;------------------------------------------------------------------------------------
PrintAccVerbose:
	push	rax
	push	r15
;
;      DECIMAL SECTIONS
;
;  Digits that print
	mov	rax, .text1			; First message
	call	StrOut				; Print string
	mov	rax, [NoSigDig]			; Digits
	call	PrintWordB10			; Print digits
; Extended Digits
	mov	rax, .text2			; First message
	call	StrOut				; Print string
	mov	rax, [NoExtDig]			; Digits
	call	PrintWordB10			; Print digits
; Useable Digits
	mov	rax, .text3			; First message
	call	StrOut				; Print string
	mov	rax, [No_Word]			; Digits
	sub	rax, GUARDWORDS			; Less guard words
	call	Words_2_Digits			; Convert words to digits
	call	PrintWordB10			; Print digits
;  Total Digits
	mov 	rax, .text4	 		; First message
	call	StrOut				; Print string
	mov	rax, [No_Word]			; Digits
	call	Words_2_Digits			; Convert words to digits
	call	PrintWordB10			; Print digits
;  Available Digits
	mov 	rax, .text5	 		; First message
	call	StrOut				; Print string
	mov	rax, VAR_WSIZE			; Total size variable
	sub	rax, EXP_WSIZE			; Less exponent size
	sub	rax, GUARDWORDS			; Less guard words
	call	Words_2_Digits			; Convert words to digits
	call	PrintWordB10			; Print digits

	mov 	rax, .text6	 		; First message
	call	StrOut				; Print string

;
;        BINARY SECTION
;
;  Mantissa Words
	mov	rax, .text10			; First message
	call	StrOut				; Print string
	mov	rax, [No_Word]			; number of binary words in Mantissa
	sub	rax, GUARDWORDS			; minus gard words
	mov	r15, rax			; Save for page formating
	call	PrintWordB10			; Print digits
	mov	rax, .text20			; "Words"
	call	StrOut
	cmp	r15, 1000000			; number to avoid going to next tab
	jnc	.skip1
	mov	rax, 9				; Tab character
	call	CharOut
.skip1:
; Mantissa Btyes (same line)
	mov	rax, [No_Byte]			; number of bytes in mantissa
	sub	rax, GUARDBYTES			; minus gard words
	call	PrintWordB10

;  Guard Words
	mov	rax, .text10a			; First message
	call	StrOut				; Print string
	mov	rax, GUARDWORDS			; Number of words set in var_header.inc
	call	PrintWordB10			; Print digits
	mov	rax, .text20			; "Words"
	call	StrOut
	mov	rax, 9				; Tab character, assume always needed
	call	CharOut
; Mantissa Btyes (same line)
	mov	rax, GUARDBYTES			; number of guard bytes
	call	PrintWordB10


; Total Words
	mov	rax, .text11			; First message
	call	StrOut				; Print string
	mov	rax, [No_Word]			; Total words
	mov	r15, rax			; save for page formatting
	call	PrintWordB10
	mov	rax, .text20			; "Words"
	call	StrOut
	cmp	r15, 1000000
	jnc	.skip2
	mov	rax, 9				; Tab character
	call	CharOut
.skip2:
; Total Bytes (same Line
	mov	rax, [No_Byte]			; Total bytes
	call	PrintWordB10


; Exponent Words
	mov	rax, .text12			; First message
	call	StrOut				; Print string
	mov	rax, EXP_WSIZE			; Total sords
	call	PrintWordB10
	mov	rax, .text20			; "Words"
	call	StrOut
	mov	rax, 9				; Tab character, assume always needed
	call	CharOut
; Total Bytes (same Line
	mov	rax, EXP_BSIZE			; Total bytes
	call	PrintWordB10


;
; Variable sizes
	mov	rax, .text13			; First message
	call	StrOut				; Print string
	mov	rax, VAR_WSIZE			; Variable size
	call	PrintWordB10
	mov	r15, rax			; save for page formatting
	mov	rax, .text20			; "Words"
	call	StrOut
	cmp	r15, 1000000
	jnc	.skip3
	mov	rax, 9				; Tab character
	call	CharOut
.skip3:
; Variable Bytes (same Line
	mov	rax, VAR_BSIZE			; varaiable size
	call	PrintWordB10
;
	mov	rax, .text14			; First message
	call	StrOut				; Print string



;
	pop	r15
	pop	rax
	ret
.text1:	db	0xD, 0xA, "Decimal (base 10) Accuracy:", 0xD, 0xA
	dd	"  Printed Digits:    ", 0
.text2:	db					" ", 9, "(Configurable)", 0xD, 0xA
	db      "  Extended Digits:   ", 0
.text3: db 					" ", 9, 9, "(Shows extra digits)", 0xD, 0xA
	db	"  Useable Digits:    ", 0
.text4:	db					" ", 9, "(Theoretical)", 0xD, 0xA
	db	"  Total Calc Digits: ", 0
.text5:	db					" ", 9, "(With Guard Words)", 0xD, 0xA
	db	"  Available Digits:  ", 0
.text6:	db					" ", 9, "(Useable digits)", 0xD, 0xA, 0


.text10:
	db	0xD, 0xA,
	db	"Binary Accuracy:      ", 0xD, 0xA
	db	"  Mantissa Words: ", 0

.text10a:
	db					" Bytes", 0xD, 0xA
	db	"  Guard Words:    ", 0

.text11:
	db					" Bytes", 0xD, 0xA
	db	"  Total Words:    ", 0
.text12:
	db					" Bytes", 0xD, 0xA
	db	"  Exponent Size:  ", 0
.text13:
	db					" Bytes", 0xD, 0xA
	db	"  Available Size: ", 0
.text14:
	db					" Bytes", 0xD, 0xA, 0

.text20:
	db	" Words ", 9, 0 ; includes 9=tab
;
;
;------------------------------------------------------------------------------------
;
;  Function  Words_2_Digits
;
;  Input:   RAX = number of binary words in mantissa
;
;  Output:  RAX = number of decimal digits
;
;------------------------------------------------------------------------------------
Words_2_Digits:
	push	rcx
	push	rdx
;
;  this is a */ operation with 128 bit intermediate
;
;  Multiply number of words x (19.2659... x 1 billion)  digits per word
;  19.2659197224948 digit/QWord = log_base10(2^64)
;
						; RAX = number of words (Input value)
	mov	rcx, 192659197224948		; 19.2659197224948 digits per word
	mul	rcx				; Multiply RDX:RAX(128 bit) = RAX(64 bit) * RBX (64 bit)
;
;  Divide by 1 billion
;
;
	mov	rcx, 10000000000000		; RCX = 1 billion
	div	rcx				; RAX(64 bit) = RDX:RAX(128 bit) / RCX (64 bit)
;
	pop	rdx
	pop	rcx
	ret					; Return result = RAX
;
;
;
;------------------------------------------------------------------------------------
;
;  Function  Digits_2_Words
;
;  Input:   RAX = number of decimal digits
;
;  Output:  RAX = number of binary words
;
;------------------------------------------------------------------------------------
Digits_2_Words:
	push	rcx
	push	rdx
;
;  this is a */ operation with 128 bit intermediate
;
;  Multiply number of digits x 1 billion
;
						; RAX = number of words (Input value)
	mov	rcx, 10000000000000		; RCX = 1 billion
	mul	rcx				; Multiply RDX:RAX(128 bit) = RAX(64 bit) * RBX (64 bit)
;
;  Divide by digits x 1 billion by 19.266... digit/QWord
;  19.2659197224948 = log_base10(2^64)
;
	mov	rcx, 192659197224948		; 19.2659197224948 digits per word
	div	rcx				; RAX(64 bit) = RDX:RAX(128 bit) / RCX (64 bit)
;
	inc	rax				; This adjustment is because division truncates
;						; 1 to 19 digits returns 0 words if not incremented
;
	pop	rdx
	pop	rcx
	ret					; Return result = RAX
;

;
;------------------------------------------------------------------------------------
;
;  Function  PrintWordB10
;
;  Input:   RAX  positive unsigned integer
;
;  Output:  text send to CharOut
;
;  All 64 bits may be printed from 0 to 18446744073709551615 (1.844E+19)
;
;------------------------------------------------------------------------------------
PrintWordB10:
;
	push	rax				; For DIV command
	push	rbx				; For DIV command
	push	rcx				; Loop Counter
	push	rdx				; For DIV command
	push	rsi				; Power of 10 counter
	push	rdi				; Holds original number
	push	rbp				; For DIV command
;
;
	mov	rdi, rax			; Original Number
;
	mov	rcx, 20				; Loop counter
	mov	rsi, 1				; Counter
	mov	rbx, 1
.loop1:
	xor	rdx, rdx			; RDX = 0
	mov	rax, rdi			; Get number
	div	rbx				; RAX = RDX:RAX/RBX RDX = Remainder
	cmp	rax, 10				; Is result of division less than 10?
	jc	.done_counting			; Yes, less than 10, done counting
;
	shl	rbx, 1				; X 2
	mov	rax, rbx			; Save X 2 value
	shl	rbx, 2				; X 2 X 2 --> X 8
	add	rbx, rax			; Add (_X8) + (_X2) = ( _X10)
	inc	rsi				; Increment digit counter
	loop	.loop1			;
; if loop counter reaches 20, something is broken
.error21:
	mov	rax, .errmsg2
	call	StrOut
	mov	rax, 0				; Error code
	jmp	FatalError			; Stop due to error
;
.done_counting:
;
;  Recursively divide by power of 10 to get digits
;
	mov	rcx, rsi			; Counter
.loop2:
	xor	rdx, rdx			; RDX = 0
	mov	rax, rdi			; Original number, or remainder in later terms
	div	rbx				; DIV by power of 10, RAX = RDX:RAX / RBX , Remainder = RDX
	mov	rdi, rdx				; Remainder for next time
	and	al, 0x00F
	or	al, 0x030			; Form ascii
	call	CharOut				; Output character
	xor	rdx, rdx			; RDX = 0
	mov	rax, rbx			; last power of 10
	mov	rbp, 10				; for DIV command
	div	rbp				; Reduce 1 power of 10 RAX = RDX:rax / 10
	mov	rbx, rax			; Save next power of 10
	loop	.loop2
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
.errmsg2:	db	0xD, 0xA, "PrintWordB10 - Error, no exit from loop", 0xD, 0xA, 0
;
;--------------------------------------------------------------
;  Print HEX valjue of byte
;
;  Input:   AL byte to print
;
;  Output:  none
;
;--------------------------------------------------------------
PrintHexByte:
	push	rax				; preserve for exit
	push	rax				; save for second nibble
;
;  First print MS nibble
;
	and	al, 0F0H			; Get first nibble
	shr	al, 04H				; Shift 4 bits to align nibble
	cmp	al, 09h				; Number or A-F?
	jg	.skip1				; It's A-F branch
	or	al, 0x030			; Form ASCII 0-9
	jmp	.skip2				; Always taken
.skip1:
	sub	al, 09H				; Adjust and
	or	al, 0x040			; form ASCII A-F
.skip2:
	call	CharOut				; output character
;
; Then print L.S. Nibble
;
	pop	rax				; get L.S. Nibble
	and	al, 0x0F			; Mask to first nibble
	cmp	al, 0x09			; Number or A-F?
	jg	.skip3				; It's A-F branch
	or	al, 0x030			; Else make ASCII
	jmp	.skip4				; Always taken
.skip3:
	sub	al, 0x09			; Adjust and
	or	al, 0x040			; and for ASCII
.skip4:
	call	CharOut				; Output character
	pop	rax				; register preserved
	ret

;--------------------------------------------------------------
;  Print HEX value of word
;
;  Input:   RAX byte to print
;
;  Output:  none
;
;--------------------------------------------------------------
PrintHexWord:
;  JMP test11
	push	rax
	push	rbx
	push	rcx
	push	rdx
 ;
	mov 	rdx, 16				; Count to print 16 nibbles (4 bit)
	mov	rbx, rax			; Save original word in RBX
.loop1:
	mov	rax, rbx			; Get un-rotated word
	mov	rcx, rdx			; Set rotation counter
	dec	rcx				; Print 8 nibbles, only 7 need rotation
	jz	.skip3				; Lasat nibble, don't rotate
.loop2:
	shr	rax, 4				; Rotate until nibble in place
	loop	.loop2				; Decrement RCX and loop until done
;
.skip3:
	and	rax, 0x0F			; Get first nibble by ANDing other bits
	cmp     al, 0x09     			; Number or A-F?
        jg      .skip4          		; It's A-F branch
	or      al, 0x030      			; Form ASCII 0-9
	jmp     .skip5         			; Always taken
.skip4:
	sub	al, 0x09			; Adjust and
	or	al, 0x040			; form ASCII A-F
.skip5:
        call	CharOut				; Output character
	dec	rdx				; one less nibble next time
;	cmp	rdx, 0
	jg	.loop1

	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret

;--------------------------------------------------------------
;
;  Print Time HH:MM:SS
;
;  Input  RAX = seconds
;
;  Output none
;
;---------------------------------------------------------------
PrintDDHHMMSS:
	push	rax
	push	rbx
	push	rcx
	push	rdx

	mov	rdx, 00
	mov	rcx, 24*60*60			; seconds per day
	div	rcx				; RDX:RAX / RCX = RAX (days)
	or	rax, rax			; Any days?
	jz	.skip1
	call	PrintWordB10			; print days
	mov	rax, DateStr			; Pointer to string
	call	StrOut				; Print string
.skip1:
	mov	rax, rdx			; Remainder
	mov	rdx, 0				; clear high word
	mov	rcx, 10*60*60			; 10's of hours
	div	rcx				; RAX = 10's of hours
	or	rax, '0'			; Form ascii
	call	CharOut				; Output the character
;
	mov	rax, rdx			; Remainder
	mov	rdx, 0				; clear high word
	mov	rcx, 60*60			; hours
	div	rcx				; RAX = hours
	or	rax, '0'			; Form ascii
	call	CharOut				; Output the character
;
	mov	al, ':'
	call	CharOut
;
	mov	rax, rdx			; Remainder
	mov	rdx, 0				; clear high word
	mov	rcx, 10*60			; 10's of minutes
	div	rcx				; RAX = 10's of minutes
	or	rax, '0'			; Form ascii
	call	CharOut				; Output the character
;
	mov	rax, rdx			; Remainder
	mov	rdx, 0				; clear high word
	mov	rcx, 60				; minutes
	div	rcx				; RAX = minutes
	or	rax, '0'			; Form ascii
	call	CharOut				; Output
;
	mov	al, ':'
	call	CharOut
;
	mov	rax, rdx			; Remainder
	mov	rdx, 0				; clear high word
	mov	rcx, 10				; 10's of seconds
	div	rcx				; RAX = 10's of seconds
	or	rax, '0'			; Form ascii
	call	CharOut				; Output the character
;
	mov	rax, rdx			; Remainder is seconds
	or	rax, '0'			; Form ascii
	call	CharOut				; Output the character

	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret

DateStr:	db	" Days ", 0

;--------------------------------------------------------------
; Integer input routine
;
; This routine will put an integer value from terminal input
; and convert ASCII to binary, returning 64 bit RAX
;
;    Input:    RAX address of input buffer
;
;    Output:   RAX contains 64 bit positive integer
;
;--------------------------------------------------------------
IntWordInput:
; Save Registers
	push	rbx
	push	rcx
	push	rdx

	mov	rbx, 0				; Accumulate number here
	mov	rdx, rax			; Address to input buffer

.loop1:
	mov	al, [rdx]			; Get next character from buffe4
	inc	rdx				; Point at next character
	cmp	al, '9'+1			; Digit > ascii '9'
        jnc     .exit				; Yes convert input
        cmp     al, '0'				; Digit < ascii '0'
        jc      .exit				; Yes convert input
        and     al, 0FH				; Mask to BCD bits
	shl	rbx, 1				; x 2
	mov	rcx, rbx			; Save x 2
	shl	rbx, 2				; x 8
	add	rbx, rcx			;  add X 2 value to X 8 value for X 10
	mov	rcx, 0				; Clear for accept digit into 64 bit value
	or	cl, al				; OR the bits into RCX
	add	rbx, rcx			; Add the digit
	jmp	short .loop1			; Always taken
.exit:
	mov	rax, rbx			; Result = RAX
	pop	rdx
	pop	rcx
	pop	rbx
	ret					; Result in RAX

;------------------------
;  EOF util.asm
;------------------------
