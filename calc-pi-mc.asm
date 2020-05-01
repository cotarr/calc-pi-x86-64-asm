;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Calculation of Monte Carlo functions by summation
;
; File:   calc-pi-mc.asm
; Module: calc.asm, calc.o
; Exec:   calc-pi
;
; Created   08/13/2015
; Last Edit 04/24/2020
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

;-------------------------------------------------------------
; Function_calc_pi_monte_carlo
;-------------------------------------------------------------
;
;--------------------------------------------------------
;
; Function_calc_pi_monte_carlo
;
; Input: [Sum_Limit] number of random number cycles
;
; Output: XReg = pi
;
;--------------------------------------------------------
Function_calc_pi_monte_carlo:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
	push	r8				; Sum of x, y squared (low word)
	push	r9				; Sum of x, y squared (high word)
	push	r10				; RandomMax^2 (low word)
	push	r11				; RandomMax^2 (high word)
	push	r12				; randomMax (64 bit)
;
; Check if CPU supports random number generator
;
	mov	rax, 0x01			; Set's EAX code 01H to querry x86 processor
	cpuid					; Get processor's features
	test	ecx, 0x40000000			; Check if RDRAND instruction supported
	jnz	.skip1				; Yes, continue
	mov	rax, .CPU_RNG_NotSupportMsg
	call	StrOut
	call	ClearVariable			; Clear variable using RSI handle
	xor	rax, rax			; RAX 0=return code for not supported
	jmp	.exit
;
; Setup ACC and OPR as counters in integer mode
;
.skip1:
	xor	rax, rax			; RAX = 0
	mov	rsi, HAND_ACC
	call	FIX_Load64BitNumber		; initialize ACC
	mov	rsi, HAND_OPR
	call	FIX_Load64BitNumber		; initialize ACC
	mov	rsi, HAND_WORKC
	call	FIX_Load64BitNumber		; initialize ACC

;
; Calculate maximum random squared
;
;            Ruler -->FEDCBA9876543210
	mov	rax, 0xFFFFFFFFFFFFFFFF		; 64 Bit Random number maximum
	mov	r12, rax
	mul	rax				; RAX = RAX*RAX
	mov	r10, rax
	mov	r11, rdx			; R11:R10 = max squared

	mov	rax, .randmaxMsg
	call	StrOut
	mov	rax, r12			; Maximum random mumber
	call	PrintWordB10			; Print base 10
	mov	rax, .randmaxMsg2
	call	StrOut
	mov	rax, r12
	call	PrintHexWord			; Print in hex
	mov	al, ')'
	call	CharOut
	call	CROut

	; Point [RPB] at the integer 64 bit word in fixed point number format
	mov	rbp, MAN_MSW_OFST
	mov	rcx, [Sum_Limit]

.loop:
	rdrand	rax				; get pseudorandom number from CPU
	jnc	.loop				; CF=1 successful, otherwise call again
	and	rax, r12			; mask high bits (reduce accuracy)
	mul	rax				; RDX:RAX = RAX * RAX
	mov	r8, rax
	mov	r9, rdx

.again:
	rdrand	rax				; get pseudorandom number from CPU
	jnc	.again				; CF=1 successful, otherwise call again
	and	rax, r12			; mask high bits (reduce accuracy)
	mul	rax				; RDX:RAX = RAX * RAX
	add	rax, r8				; Add X^2 + Y^2
	adc	rdx, r9
	mov	rbx, 0
	adc	rbx, 0				; Add 0 + CF
	sub	rax, r10			; R10, R11 preserved
	sbb	rdx, r11
	sbb	rbx, 0
	jc	.inside				; Inside circle?
	inc	qword[FP_Acc+rbp]		; Increment ACC for outside count
	jmp	short .nextloop
.inside:
	inc	qword[FP_Opr+rbp]		; Increment Opr for inside count
.nextloop:
	loop	.loop
;
; Print counter values
;
	mov	rax, .insideMsg
	call	StrOut
	mov	rax, [FP_Opr+rbp]
	call	PrintWordB10			; print inside count
	mov	rax, .outsideMsg
	call	StrOut
	mov	rax, [FP_Acc+rbp]
	call	PrintWordB10			; print outside count
	mov	rax, .skippedMsg
	call	StrOut
	mov	rax, [FP_WorkC+rbp]
	call	PrintWordB10
	call	CROut
;
; Acc is now total counts (inside+outside)
;
	mov	rax, [FP_Acc+rbp]
	add	rax, [FP_Opr+rbp]
	mov	[FP_Acc+rbp], rax
;
; Convert counter from INT format to FP format
	mov	rsi, HAND_ACC
	call	Conv_FIX_to_FP
	mov	rsi, HAND_OPR
	call	Conv_FIX_to_FP
;
; Divide inside point count / total point count
;
	call	FP_Division
;
; Multiply by 4, pi = 4*P where P = fracton points inside circle
	inc	qword[FP_Acc+EXP_WORD_OFST]	; times 2
	inc	qword[FP_Acc+EXP_WORD_OFST]	; times 4
;
; Result pi moved back to XREG for disply
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
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
.CPU_RNG_NotSupportMsg:
	db	0xD, 0xA, "Error: Hardware support for RDRAND instruction not available in this CPU", 0xD, 0xA, 0xA, 0
.insideMsg:
	db	"Result Counters: Inside=", 0
.outsideMsg:
	db	"   Outside=", 0
.skippedMsg:
	db	"   Invalid=", 0
.randmaxMsg:
	db	"Maximum Random Number: ", 0
.randmaxMsg2:
	db	" (0x", 0
;--------------------
; End calc-pi-mc.asm
;--------------------
