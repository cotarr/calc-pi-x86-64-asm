;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Calculation of Pi using Stormer Formula
;
; File:   calc-pi-st.asm
; Module: calc.asm, calc.o
; Exec:   calc-pi
;
; Created   11/13/2014
; Last Edit 05/25/2015
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
; Function_calc_pi_sto:
; Sub_Pi_ArcTan:
; Function_calc_pi_sto_FP:
;--------------------------
;-------------------------------------------------------------
;
;--------------------------
;
;  Function_calc_pi_sto
;
;  Pi = 176arctan(1/57) +
;    +  28arctan(1/239)
;    -  48arctan(1/682)
;    +  96arctan(1/12943)
;
;   ACC = Current Term
;   OPR = Sum
;   WorkA = x^(2n+1) term
;
;   REG0 = 176arctan(1/57)
;   REG1 = 28arctan(1/239) +
;   REG2 = 48arctan(1/682) +
;   REG3 = 96arctan(1/12943)
;   XReg = Result
;
;   Multi-tasking mode, run 4 copies of the program concurrently
;   Each copy can run a separate summation, using i7 cores
;   The time of calculation will be slowest sum, the first
;
;   Each result saved:  pi-st-1.num, pi-st-2.num, pi-st-3.num, pi-st-4.num
;   Series 2,3 and 4 will exit the program when done
;   Series 1 will load 3 other files and place sum in XReg
;
;   Command for multitasking:  c.pi.se <number> where number = 1,2,3 or 4
;   If number omitted or 0, then all series summed normally
;
;   For Multi-tasking, check rax on entry
;   Case rax = 0, calculate all arctan series and sum
;   Case rax = 1, calculate 176*arctan(1/57) Result Xreg
;   Case rax = 2, calcualte 28*arctan(1/239)
;   Caes rax = 3, calculate 48*arctan(1/682)
;   Case rax = 4, calculate 96*arctan(1/12943)
;   Case rax = 1234, retrieve sums from disk and add
;
;
;--------------------------------------------------------------
;
Function_calc_pi_sto:
;  jmp Function_calc_pi_sto_FP
;
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
	push 	r11				; command argument (0 to 4)
	push	r12				; sign flag
	push	r13				; 1/X
	push	r14				; 1/(X^2n-1)
	push	r15				; 2n+1
;
	mov	r11, rax			; Save command line code
;
	xor	rax, rax			; clear RAX = 0
;      						; Check for other (multitasking calls)
	or	r11, r11			; Is R11 zero?
	jnz	.skip0				; no
	mov	rax, .msg_pi			; Print calculaton description on screen
.skip0:
	cmp	r11, 1				; Argument = 1?
	jne	.skip1
	mov	rax, .msg_pi1			; Yes load message
.skip1:
	cmp	r11, 2				; Argument = 2?
	jne	.skip2
	mov	rax, .msg_pi2			; Yes load message
.skip2:
	cmp	r11, 3				; Argument = 3?
	jne	.skip3
	mov	rax, .msg_pi3			; Yes load message
.skip3:
	cmp	r11, 4				; Argument = 4?
	jne	.skip4
	mov	rax, .msg_pi4			; Yes load message
.skip4:
	cmp	r11, 1234			; Argument = 1234?
	jne	.skip1234
	mov	rax, .msg_pi1234		; Yes load message
.skip1234:
;
; check if message assigned, if not then invalid code
;
	and 	rax, rax			; Is rax zero, is command invalid?
	jz	.invalid			; it is invalid, skip to error
	call	StrOut				; Else valid, print message
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep] 		; print occasional samples
	mov	rax, 0x02000000			; set skip counter from rbx
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; If running multipart mode, then skip non-selected summations
;
	cmp	r11, 2				; Skip to part 2?
	je	.part2
	cmp	r11, 3				; Skip to part 2?
	je	.part3
	cmp	r11, 4				; Skip to part 2?
	je	.part4
	cmp	r11, 1234			; Skip forward to load sum from disk?
	je	.Code1234			; Yes, skip to disk load
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; Summation #1    176 * arctan(1/57)
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
.part1:
;
; Initialize parameters of summation
	mov	r14, (57*57)			; 1/(x^2)
	mov	r13, 57				; 1/x
; Perform Summation
	call	Sub_Pi_ArcTan			; Perform arctan summation
; Sum factor from formula
	mov	rsi, HAND_OPR
	mov	rax, 176
	call	FIX_US_Multiplication
; Save result of 1st  summation
	mov	rsi, HAND_OPR
	call	Conv_FIX_to_FP			; Return X = last 1/n! term
;
	cmp	r11, 1				; Only performing partial calculation?
	je	.MultiPart			; Yes, skip other 3 parts
;
	mov	rsi, HAND_OPR
	mov	rdi, HAND_REG0
	call	CopyVariable			; Reg0 = first summation
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; Summation #2    28 * arctan(1/239)
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
.part2:
;
; Initialize parameters of summation
	mov	r14, (239*239)			; 1/(x^2)
	mov	r13, 239			; 1/x
; Perform Summation
	call	Sub_Pi_ArcTan			; Perform arctan summation
; Sum factor from formula
	mov	rsi, HAND_OPR
	mov	rax, 28
	call	FIX_US_Multiplication
; Save result of 1st  summation
	mov	rsi, HAND_OPR
	call	Conv_FIX_to_FP			; Return X = last 1/n! term
;
	cmp	r11, 2				; Only performing partial calculation?
	je	.MultiPart			; Yes, skip other 3 parts
;
	mov	rsi, HAND_OPR
	mov	rdi, HAND_REG1
	call	CopyVariable			; Reg1 = second summation
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; Summation #3    48 * arctan(1/682)
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
.part3:
;
; Initialize parameters of summation
	mov	r14, (682*682)			; 1/(x^2)
	mov	r13, 682			; 1/x
; Perform Summation
	call	Sub_Pi_ArcTan			; Perform arctan summation
; Sum factor from formula
	mov	rsi, HAND_OPR
	mov	rax, 48
	call	FIX_US_Multiplication
; Save result of 1st  summation
	mov	rsi, HAND_OPR
	call	Conv_FIX_to_FP			; Return X = last 1/n! term
	call	FP_TwosCompliment		; OPR = ( - Series 3)
;
	cmp	r11, 3				; Only performing partial calculation?
	je	.MultiPart			; Yes, skip other 3 parts
;
	mov	rsi, HAND_OPR
	mov	rdi, HAND_REG2
	call	CopyVariable			; Reg2 = third summation
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; Summation #4    96 * arctan(1/12943)
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
.part4:
;
; Initialize parameters of summation
	mov	r14, (12943*12943)		; 1/(x^2)
	mov	r13, 12943			; 1/x
; Perform Summation
	call	Sub_Pi_ArcTan			; Perform arctan summation
; Sum factor from formula
	mov	rsi, HAND_OPR
	mov	rax, 96
	call	FIX_US_Multiplication
; Save result of 1st  summation
	mov	rsi, HAND_OPR
	call	Conv_FIX_to_FP			; Return X = last 1/n! term
;
	cmp	r11, 4				; Only performing partial calculation?
	je	.MultiPart			; Yes, skip other 3 parts
;
	mov	rsi, HAND_OPR
	mov	rdi, HAND_REG3
	call	CopyVariable			; Reg3 = fourth summation
;
; Done collect summation of 4 registers
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = Series 1
	mov	rsi, HAND_REG1
	mov	rdi, HAND_ACC
	call	CopyVariable			; ACC = Series 2
	call	FP_Addition			; ACC = Series 1+2
	mov	rsi, HAND_REG2
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = Series 3
	mov	rsi, HAND_OPR
;	call	FP_TwosCompliment		; OPR = ( - Series 3)
	call	FP_Addition			; ACC = Series 1+2-3
	mov	rsi, HAND_REG3
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = Series 3
	call	FP_Addition			; ACC = Series 1+2-3+4
;
; Save result in XREg
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable			; X = sum (value of e)
;
; Clear temporary variables
;
;	mov	rsi, HAND_REG0
;	call	ClearVariable
;	mov	rsi, HAND_REG1
;	call	ClearVariable
;	mov	rsi, HAND_REG2
;	call	ClearVariable
;	mov	rsi, HAND_REG3
;	call	ClearVariable


	jmp	.Not_Multi			; calculation of all 4, skip

;-------------------------------------------
; Endi fo single calculation part
; next sections is  cleanup from multi-part
;-------------------------------------------

;
; Case of calculate only 1 part, result in XReg
;

.MultiPart:
	mov	rsi, HAND_OPR
	mov	rdi, HAND_XREG
	call	CopyVariable			; Move to XReg to save to disk
;
; Print elapsed time of part before jmp ProgramExit
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x000F0000 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	cmp	r11, 1				; part 1 ?
	jne	.notFN1				; Yes, case of 2nd sum
	mov	rax, .fname1
	call	SaveVariable			; Save the result in binary
	jmp	ProgramExit			; Exit the program
.notFN1:
	cmp	r11, 2				; part 1 ?
	jne	.notFN2				; Yes, case of 2nd sum
	mov	rax, .fname2
	call	SaveVariable			; Save the result in binary
	jmp	ProgramExit			; Exit the program
.notFN2:
	cmp	r11, 3				; part 3 ?
	jne	.notFN3
	mov	rax, .fname3
	call	SaveVariable			; Save the result in binary
	jmp	ProgramExit			; Exit the program
.notFN3:
	cmp	r11, 4				; part 4 ?
	jne	.notFN4
	mov	rax, .fname4
	call	SaveVariable			; Save the result in binary
	jmp	ProgramExit			; Exit the program
.notFN4:
.invalid:
	mov	rax, .ferrormsg2		; get error message
	call	StrOut
	call	CROut
	jmp	.exit
.ferror:
	mov	rax, .ferrormsg			; get error message
	call	StrOut
	call	CROut
	jmp	.exit

.ferrormsg:
	db	0xD, 0xA, "Error: c.pi.st loaded zero result, possible file error", 0xD, 0xA, 0
.ferrormsg2:
	db	0xD, 0xA, "Error: c.pi.st invalid option code.", 0xD, 0xA, 0
	jmp	.exit				; should not reach this
;
; Case of rax code = 1234, tetrieve sum
;
;
; Get result #1
;
.Code1234:
        mov     rsi, HAND_ACC			; Clear ACC for input buffer
        call    ClearVariable			; Call clear variable
	mov	rax, .fname1			; Get filename
        call    LoadVariable			; Load variable into ACC from file
        mov     rax, [FP_Acc+MAN_MSB_OFST]	; M.S.Byte
        or      rax, rax			; Error check, is MSByte zero?
        jz     .ferror				; No, non-zero number assumed valid
;
; Add result 2
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable

        mov     rsi, HAND_ACC			; Clear ACC for input buffer
        call    ClearVariable			; Call clear variable
	mov	rax, .fname2			; Get filename
        call    LoadVariable			; Load variable into ACC from file
        mov     rax, [FP_Acc+MAN_MSB_OFST]	; M.S.Byte
        or      rax, rax			; Error check, is MSByte zero?
        jz     .ferror				; No, non-zero number assumed valid
	call	FP_Addition			; Add ACC + OPR

	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; ACC --> OPR

        mov     rsi, HAND_ACC			; Clear ACC for input buffer
        call    ClearVariable			; Call clear variable
	mov	rax, .fname3			; Get filename
        call    LoadVariable			; Load variable into ACC from file
        mov     rax, [FP_Acc+MAN_MSB_OFST]	; M.S.Byte
        or      rax, rax			; Error check, is MSByte zero?
        jz     .ferror				; No, non-zero number assumed valid
	call	FP_Addition			; Add ACC + OPR

	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; ACC --> OPR

        mov     rsi, HAND_ACC			; Clear ACC for input buffer
        call    ClearVariable			; Call clear variable
	mov	rax, .fname4			; Get filename
        call    LoadVariable			; Load variable into ACC from file
        mov     rax, [FP_Acc+MAN_MSB_OFST]	; M.S.Byte
        or      rax, rax			; Error check, is MSByte zero?
        jz     .ferror				; No, non-zero number assumed valid
	call	FP_Addition			; Add ACC + OPR

	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable			; Final result ACC --> XREG
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x000F0000 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	jmp	.exit



.Not_Multi:

;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00033333 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



.exit:
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
.msg_pi:	db	"Function_calc_pi_sto: Calculating pi Stormer method.", 0xD, 0xA, 0
.msg_pi1:	db	"Part 1 of 4 --> 176 * arctan(1/57)", 0xD, 0xA, 0
.msg_pi2:	db	"Part 2 of 4 -->  28 * arctan(1/239)", 0xD, 0xA, 0
.msg_pi3:	db	"Part 3 of 4 -->  48 * arctan(1/682)", 0xD, 0xA, 0
.msg_pi4:	db	"Part 4 of 4 -->  96 * arctan(1/12943)", 0xD, 0xA, 0
.msg_pi1234:	db	"c.pi.st loading sum from disk", 0xD, 0xA, 0

.fname1:	db	"pi-st-1", 0
.fname2:	db	"pi-st-2", 0
.fname3:	db	"pi-st-3", 0
.fname4:	db	"pi-st-4", 0

;------------------------------
; Subroutine for Arctan summation
;------------------------------
;
Sub_Pi_ArcTan:
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x04000000 | 0x00008808 | 0x00000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Initialize FIX Variables
;
	mov	r15, 1				; n = 1
	mov	r12, 0				; sign counter

	mov	rsi, HAND_ACC
	mov	rax, 0
	call	FIX_Load64BitNumber		; ACC = 1
;
	mov	rsi, HAND_WORKA
	mov	rax, 1
	call	FIX_Load64BitNumber		; ACC = 1
	mov	rax, r13
	call	FIX_US_Division			; ACC = 1/57 (or next value)
;
	mov	rsi, HAND_OPR
	mov	rax, 1
	call	FIX_Load64BitNumber		; ACC = 1
	mov	rax, r13
	call	FIX_US_Division			; ACC = 1/57 (or next value)
;
; Main loop
;
.loop:
;
; Increment n and check for limits
;
	inc	r12				; Sign counter
	inc	r15				; Increment (2n+1)
	inc	r15
	mov	rax, r15
	rcl	rax, 1				; Bit 63 not allowed
	jc	.n_overflow_error
	rcl	rax, 1				; Bit 62 not allowed
	jc	.n_overflow_error
;
; Calculate next X^(2n+1) numerator
;
	mov	rax, r14			; Pass to division routine
	mov	rsi, HAND_WORKA
	call	FIX_US_Division			; Divide for numerator

; Calculate divide (2n+1)
;
	mov	rsi, HAND_WORKA
	mov	rdi, HAND_ACC
	call	CopyVariable			; Acc = X^(2n+1)
	mov	rax, r15			; RAX = (2n+1)
	mov	rsi, HAND_ACC
	call	FIX_US_Division			; ACC = x^(2n+1)/(2n+1)

; Add term to summation
;
	mov	rax, r12			; get sign counter
	test	rax, 1				; L.S. bit 1?
	jnz	.skip_add
	mov	rsi, HAND_OPR
	mov	rdi, HAND_ACC
	call	FIX_Addition			; OPR = OPR + ACC
	jmp	.skip_sub
.skip_add:
	mov	rsi, HAND_OPR
	mov	rdi, HAND_ACC
	call	FIX_Subtraction			; OPR = OPR - ACC
.skip_sub:
;
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01311111 | 0x00000444 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Check if done
;
	mov	rsi, HAND_ACC
	call	FIX_Check_Sum_Done
	or	rax, rax			; Result = RAX, 1 = done
	jz	.loop
;www
;	cmp	r12, 1
;	jl	.loop
;
;  Loop is finished because last term added not significant
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00033333 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	ret
.n_overflow_error:
	mov	rax, .errorMsg1			; Print the error message
	call	StrOut
	mov	rax, 0				; Error message already printed
	jmp	FatalError			; Unrecoverble, exit program
.errorMsg1:	db	"Error: Summation error, n overflow", 0xD, 0xA, 0




;--------------------------------------------------------------
;  Floating Point Method
;
;  Pi = 176arctan(1/57) +
;       28arctan(1/239) +
;       48arctan(1/682) +
;       96arctan(1/12943)
;
;   XREG = Sum
;   YREG = Term
;   ZREG = n
;   REG0 = 176arctan(1/57)
;   REG1 = 28arctan(1/239) +
;   REG2 = 48arctan(1/682) +
;   REG3 = 96arctan(1/12943)
;
;--------------------------------------------------------------
;
Function_calc_pi_sto_FP:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rbp
	push	rsi
	push	rdi
	push	r8				; Used as (-1)^n counter

	mov	rax, .msg_title			; Print calculaton on screen
	call	StrOut
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	rbx, [iShowCalcStep] 		; print each 100 term
	mov	rax, 0x02000000			; set skip counter from RBX
	call	ShowCalcProgress		; initialize
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Clear Registers REG0, REG1, REG2, and REG3
;
	mov	rsi, HAND_REG0
	call	ClearVariable
	mov	rsi, HAND_REG1
	call	ClearVariable
	mov	rsi, HAND_REG2
	call	ClearVariable
	mov	rsi, HAND_REG3
	call	ClearVariable
;
;-------------------------------
;
;  1st Summation starts here  176 * arctan(1/57)
;
;-------------------------------
;
; Used to reduce accuracy during divisions
;
	call	ClearGrabAccuracy		; initialize reduced accuracy variables
;
; Load 1/57 to XREG, YREG

	mov	rsi, HAND_OPR
	call	SetToOne			; OPR = 1
	mov	rsi, HAND_ACC
	call	ClearVariable			; ACC = 0
	mov	rbx, FP_Acc+MAN_MSW_OFST
	mov	rax, 0x7200000000000000		; Mantissa for 57
	mov	[rbx], rax
	mov	rbx, FP_Acc+EXP_WORD_OFST
	mov	rax, 0x0000000000000006		; Exponient for 57
	mov	[rbx], rax
	call	FP_Division			; ACC = 1/57
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable			; XREG = 1/57 (sum)
	mov	rdi, HAND_YREG
	call	CopyVariable			; YREG = 1/57 (term)
;
;  Set n counter in ZREG to 1, for 1,3,5 ...
;
	mov	rsi, HAND_ZREG
	call	SetToOne			; ZREG = 1 (n counter)
;
; Init sign counter for (-1)^n
;
	mov	r8, 0
;
; * * * * * * * * * * * * * * * * * * * * * * * * * *
;
;  M A I N    L O O P    1   176 * arctan(1/57)
;
; * * * * * * * * * * * * * * * * * * * * * * * * * *
;
.loop1:
;
; Get last term and multiply by X^2
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
	mov	rsi, HAND_ACC
	call	ClearVariable			; ACC = 0
	mov	rbx, FP_Acc+MAN_MSW_OFST
	mov	rax, 0x6588000000000000		; Mantissa X*X
	mov	[rbx], rax
	mov	rbx, FP_Acc+EXP_WORD_OFST
	mov	rax, 0x000000000000000C		; Exponient X*X
	mov	[rbx], rax			; ACC = ((57*57)=3249
	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (x*x)
	call	RestoreFullAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_YREG
	call	CopyVariable			; YREG = (n+1) term
;
;  Add 2 to n
;
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last n
	mov	rsi, HAND_ACC
	call	SetToTwo			; ACC = 2
	call	FP_Addition			; ACC = n+1
	mov	rsi, HAND_ACC
	mov	rdi, HAND_ZREG
	call	CopyVariable			; ZREG = n+1
;
; Move last term and divide by n+2
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (2n-1)
	call	RestoreFullAccuracy
;
; If odd term change sign
;
	inc	r8				; sign counter
	test	r8, 1				; is bit 1 positive
	jz	.skip1
	mov	rsi, HAND_ACC
	call	FP_TwosCompliment 		; Change sign
;
; get sum and add term
;
.skip1:
	mov	rsi, HAND_XREG
	mov	rdi, HAND_OPR
	call	CopyVariable
	call	FP_Addition
	call	GrabSeriesAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01311101 | 0x00000844 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Check if last term was not significant
;


	mov	rax, [Nearly_Zero]		; Check for done
	or	rax, rax
	jnz	.done1				; Done go exit
	jmp	.loop1				; Else loop back
;------------------------------------------------------------------
;
;       E X I T   L O O P 1
;
;------------------------------------------------------------------
.done1:
;
; Mult by 176 and save in REG0
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = completed sum
	mov	rsi, HAND_ACC
	call	ClearVariable			; ACC = 0
	mov	rbx, FP_Acc+MAN_MSW_OFST
	mov	rax, 0x5800000000000000		; Mantissa X*X
	mov	[rbx], rax
	mov	rbx, FP_Acc+EXP_WORD_OFST
	mov	rax, 0x0000000000000008		; Exponient X*X
	mov	[rbx], rax			; ACC = 176
	call	FP_Multiplication		; ACC = sum * 176
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG0			; REG0 = first result
	call	CopyVariable

;-------------------------------
;
;  2nd Summation Starts here  28arctan(1/239)
;
;-------------------------------
;
; Used to reduce accuracy during divisions
;
	call	ClearGrabAccuracy		; initialize reduced accuracy variables
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00033303 | 0x00008808 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Load 1/239 to XREG, YREG

	mov	rsi, HAND_OPR
	call	SetToOne			; OPR = 1
	mov	rsi, HAND_ACC
	call	ClearVariable			; ACC = 0
	mov	rbx, FP_Acc+MAN_MSW_OFST
	mov	rax, 0x7780000000000000		; Mantissa for X
	mov	[rbx], rax
	mov	rbx, FP_Acc+EXP_WORD_OFST
	mov	rax, 0x0000000000000008		; Exponient for X
	mov	[rbx], rax
	call	FP_Division			; ACC = 1/239
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable			; XREG = 1/X (sum)
	mov	rdi, HAND_YREG
	call	CopyVariable			; YREG = 1/X (term)
;
;  Set n counter in ZREG to 1, for 1,3,5 ...
;
	mov	rsi, HAND_ZREG
	call	SetToOne			; ZREG = 1 (n counter)
;
; Init sign counter for (-1)^n
;
	mov	r8, 0
;
; * * * * * * * * * * * * * * * * * * * * * * * * *
;
;  M A I N    L O O P   2   28*arctan(1/239)
;
; * * * * * * * * * * * * * * * * * * * * * * * * *
;
.loop2:
;
; Get last term and multiply by X^2
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
	mov	rsi, HAND_ACC
	call	ClearVariable			; ACC = 0
	mov	rbx, FP_Acc+MAN_MSW_OFST
	mov	rax, 0x6F90800000000000		; Mantissa X*X
	mov	[rbx], rax
	mov	rbx, FP_Acc+EXP_WORD_OFST
	mov	rax, 0x0000000000000010		; Exponient X*X
	mov	[rbx], rax			; ACC = ((239*239)=56882
	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (x*x)
	call	RestoreFullAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_YREG
	call	CopyVariable			; YREG = (n+1) term
;
;  Add 2 to n
;
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last n
	mov	rsi, HAND_ACC
	call	SetToTwo			; ACC = 2
	call	FP_Addition			; ACC = n+1
	mov	rsi, HAND_ACC
	mov	rdi, HAND_ZREG
	call	CopyVariable			; ZREG = n+1
;
; Move last term and divide by n+2
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (2n-1)
	call	RestoreFullAccuracy
;
; If odd term change sign
;
	inc	r8				; sign counter
	test	r8, 1				; is bit 1 positive
	jz	.skip2
	mov	rsi, HAND_ACC
	call	FP_TwosCompliment		; Change sign
;
; get sum and add term
;
.skip2:
	mov	rsi, HAND_XREG
	mov	rdi, HAND_OPR
	call	CopyVariable
	call	FP_Addition
	call	GrabSeriesAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01311101 | 0x00000844 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Check if last term was not significant
;


	mov	rax, [Nearly_Zero]		; Check for done
	or	rax, rax
	jnz	.done2				; Done go exit
	jmp	.loop2				; Else loop back
;------------------------------------------------------------------
;
;       E X I T   L O O P   2
;
;------------------------------------------------------------------
.done2:
;
; Mult by 28 and save in REG1
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = completed sum
	mov	rsi, HAND_ACC
	call	ClearVariable			; ACC = 0
	mov	rbx, FP_Acc+MAN_MSW_OFST
	mov	rax, 0x7000000000000000		; Mantissa X*X
	mov	[rbx], rax
	mov	rbx, FP_Acc+EXP_WORD_OFST
	mov	rax, 0x0000000000000005		; Exponient X*X
	mov	[rbx], rax			; ACC = 176
	call	FP_Multiplication		; ACC = sum * 176
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG1			; ACC REG1 = second result
	call	CopyVariable
;
;
;
;
;-------------------------------
;
;  3rd Summation starts here -48 * arctan(1/682)
;
;-------------------------------
;
; Used to reduce accuracy during divisions
;
	call	ClearGrabAccuracy		; initialize reduced accuracy variables
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00033303 | 0x00008808 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Load 1/682 to XREG, YREG

	mov	rsi, HAND_OPR
	call	SetToOne			; OPR = 1
	mov	rsi, HAND_ACC
	call	ClearVariable			; ACC = 0
	mov	rbx, FP_Acc+MAN_MSW_OFST
	mov	rax, 0x5540000000000000		; Mantissa for X
	mov	[rbx], rax
	mov	rbx, FP_Acc+EXP_WORD_OFST
	mov	rax, 0x000000000000000A		; Exponient for X
	mov	[rbx], rax
	call	FP_Division			; ACC = 1/682
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable			; XREG = 1/X (sum)
	mov	rdi, HAND_YREG
	call	CopyVariable			; YREG = 1/X (term)
;
;  Set n counter in ZREG to 1, for 1,3,5 ...
;
	mov	rsi, HAND_ZREG
	call	SetToOne			; ZREG = 1 (n counter)
;
; Init sign counter for (-1)^n
;
	mov	r8, 0
;
; * * * * * * * * * * * * * * * * * * * * * * * * *
;
;  M A I N    L O O P   3   -48 * arctan(1/682)
;
; * * * * * * * * * * * * * * * * * * * * * * * * *
;
.loop3:
;
; Get last term and multiply by X^2
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
	mov	rsi, HAND_ACC
	call	ClearVariable			; ACC = 0
	mov	rbx, FP_Acc+MAN_MSW_OFST
	mov	rax, 0x718E400000000000		; Mantissa X*X
	mov	[rbx], rax
	mov	rbx, FP_Acc+EXP_WORD_OFST
	mov	rax, 0x0000000000000013		; Exponient X*X
	mov	[rbx], rax			; ACC = ((682*682)=465124
	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (x*x)
	call	RestoreFullAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_YREG
	call	CopyVariable			; YREG = (n+1) term
;
;  Add 2 to n
;
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last n
	mov	rsi, HAND_ACC
	call	SetToTwo			; ACC = 2
	call	FP_Addition			; ACC = n+1
	mov	rsi, HAND_ACC
	mov	rdi, HAND_ZREG
	call	CopyVariable			; ZREG = n+1
;
; Move last term and divide by n+2
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (2n-1)
	call	RestoreFullAccuracy
;
; If odd term change sign
;
	inc	r8				; sign counter
	test	r8, 1				; is bit 1 positive
	jz	.skip3
	mov	rsi, HAND_ACC
	call	FP_TwosCompliment		; Change sign
;
; get sum and add term
;
.skip3:
	mov	rsi, HAND_XREG
	mov	rdi, HAND_OPR
	call	CopyVariable
	call	FP_Addition
	call	GrabSeriesAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01311101 | 0x00000844 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Check if last term was not significant
;


	mov	rax, [Nearly_Zero]		; Check for done
	or	rax, rax
	jnz	.done3				; Done go exit
	jmp	.loop3				; Else loop back
;------------------------------------------------------------------
;
;       E X I T   L O O P   3
;
;------------------------------------------------------------------
.done3:
;
; Mult by -48 and save in REG2
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = completed sum
	mov	rsi, HAND_ACC
	call	ClearVariable			; ACC = 0
	mov	rbx, FP_Acc+MAN_MSW_OFST
	mov	rax, 0xD000000000000000		; Mantissa X*X
	mov	[rbx], rax
	mov	rbx, FP_Acc+EXP_WORD_OFST
	mov	rax, 0x0000000000000007		; Exponient X*X
	mov	[rbx], rax			; ACC = -48
	call	FP_Multiplication		; ACC = sum * -48
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG2			; ACC REG2 = second result
	call	CopyVariable
;
;
;
;
;-------------------------------
;
;  4th Summation starts here 96 * arctan(1/12943)
;
;-------------------------------
;
; Used to reduce accuracy during divisions
;
	call	ClearGrabAccuracy		; initialize reduced accuracy variables
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00033303 | 0x00008808 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Load 1/12943 to XREG,  YREG

	mov	rsi, HAND_OPR
	call	SetToOne			; OPR = 1
	mov	rsi, HAND_ACC
	call	ClearVariable			; ACC = 0
	mov	rbx, FP_Acc+MAN_MSW_OFST
	mov	rax, 0x651E000000000000		; Mantissa for X
	mov	[rbx], rax
	mov	rbx, FP_Acc+EXP_WORD_OFST
	mov	rax, 0x000000000000000E		; Exponient for X
	mov	[rbx], rax
	call	FP_Division			; ACC = 1/12943
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable			; XREG = 1/X (sum)
	mov	rdi, HAND_YREG
	call	CopyVariable			; YREG = 1/X (term)
;
;  Set n counter in ZREG to 1, for 1,3,5 ...
;
	mov	rsi, HAND_ZREG
	call	SetToOne			; ZREG = 1 (n counter)
;
; Init sign counter for (-1)^n
;
	mov r8, 0
;
; * * * * * * * * * * * * * * * * * * * * * * * * *
;
;     M A I N   L O O P   4   96 * arctan(1/12943)
;
; * * * * * * * * * * * * * * * * * * * * * * * * *
;
.loop4:
;
; Get last term and multiply by X^2
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
	mov	rsi, HAND_ACC
	call	ClearVariable			; ACC = 0
	mov	rbx, FP_Acc+MAN_MSW_OFST
	mov	rax, 0x4FE15F0800000000		; Mantissa X*X
	mov	[rbx], rax
	mov	rbx, FP_Acc+EXP_WORD_OFST
	mov	rax, 0x000000000000001C		; Exponient X*X
	mov	[rbx], rax			; ACC = ((12943*12943)=167521249
	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (x*x)
	call	RestoreFullAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_YREG
	call	CopyVariable			; YREG = (n+1) term
;
;  Add 2 to n
;
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last n
	mov	rsi, HAND_ACC
	call	SetToTwo			; ACC = 2
	call	FP_Addition			; ACC = n+1
	mov	rsi, HAND_ACC
	mov	rdi, HAND_ZREG
	call	CopyVariable			; ZREG = n+1
;
; Move last term and divide by n+2
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = last term
	call	ReduceSeriesAccuracy
	call	FP_Division			; ACC = term / (2n-1)
	call	RestoreFullAccuracy
;
; If odd term change sign
;
	inc	r8				; sign counter
	test	r8, 1				; is bit 1 positive
	jz	.skip4
	mov	rsi, HAND_ACC
	call	FP_TwosCompliment		; Change sign
;
; get sum and add term
;
.skip4:
	mov	rsi, HAND_XREG
	mov	rdi, HAND_OPR
	call	CopyVariable
	call	FP_Addition
	call	GrabSeriesAccuracy
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x01311101 | 0x00000844 | 0x60000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; Check if last term was not significant
;


	mov	rax, [Nearly_Zero]		; Check for done
	or	rax, rax
	jnz	.done4				; Done go exit
	jmp	.loop4				; Else loop back
;------------------------------------------------------------------
;
;       E X I T   L O O P   4
;
;------------------------------------------------------------------
.done4:
;
; Mult by -48 and save in REG2
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = completed sum
	mov	rsi, HAND_ACC
	call	ClearVariable			; ACC = 0
	mov	rbx, FP_Acc+MAN_MSW_OFST
	mov	rax, 0x6000000000000000		; Mantissa X*X
	mov	[rbx], rax
	mov	rbx, FP_Acc+EXP_WORD_OFST
	mov	rax, 0x0000000000000007		; Exponient X*X
	mov	[rbx], rax			; ACC = 96
	call	FP_Multiplication		; ACC = sum * 96
	mov	rsi, HAND_ACC
	mov	rdi, HAND_REG3			; ACC REG2 = second result
	call	CopyVariable
;
; Here are no more summations to calculate
; Each result can be retrieved and added
; to form the final result.
;
;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00033303 | 0x00000800 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
	mov	rsi, HAND_REG0
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = result 1st series
	mov	rsi, HAND_REG1
	mov	rdi, HAND_ACC
	call	CopyVariable			; ACC = result 2nd series
	call	FP_Addition			; ACC = results 1+2
	mov	rsi, HAND_REG2
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR = result 3rd series
	call	FP_Addition			; ACC = result 1+2+3
	mov	rsi, HAND_REG3
	mov	rdi, HAND_OPR
	call	CopyVariable			; OPR =  result 4th series
	call	FP_Addition			; ACC = result 1+2+3+4
;
; Move result back to XReg
;
.debug:
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable

;^^^^^^^^^^^^^^^^^^^^^^ Watch Progress  ^^^^^^^^^^^^^^^^^^^
;                      -Print--     Inc/Rset     -Format-
	mov	rax, (0x00033033 | 0x00000000 | 0x30000000 )
	call	ShowCalcProgress
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.exit:
	pop	r8
	pop	rdi
	pop	rsi
	pop	rbp
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret

.msg_title:	db	0xD, 0xA, 0xA, "Calculatin Pi using Stormer Formula", 0xD-0xA, 0

;------------------
;  End calc-pi-st.asm
;------------------
