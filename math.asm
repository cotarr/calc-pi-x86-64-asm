%define MATH
%include "var_header.inc"		; Header has global variable definitions for other modules
%include "func_header.inc"		; Header has global function definitions for other modules
;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; math.asm - Floating Point Arithmetic Routines
;
; File:   math.asm
; Module: math.asm, math.o
; Exec:   calc-pi
;
; Created:    10/15/2014
; Last Edit:  08/23/2015
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
; FP_Initialize
; CheckWordAlignment
; CheckInitRanges
; Set_No_Word
; Set_No_Word_Temp
; GrabSeriesAccuracy
; ClearGrabAccuracy
; ReduceSeriesAccuracy
; RestoreFullAccuracy
;-------------------------------------------------------------
section         .data   ; Section containing initialized data
;
; Pointers to variables  (word address table)
;
RegAddTable:
	dq	FP_Acc				; Handle = 0
	dq	FP_Opr				; Handle = 1
	dq	FP_WorkA			; Handle = 2
	dq	FP_WorkB			; Handle = 3
	dq	FP_WorkC			; Handle = 4
	dq	FP_X_Reg			; Handle = 5
	dq	FP_Y_Reg			; Handle = 6
	dq	FP_Z_Reg			; Handle = 7
	dq	FP_T_Reg			; Handle = 8
	dq	FP_Reg0				; handle = 9
	dq	FP_Reg1				; Handle = 10
	dq	FP_Reg2				; Handle = 11
	dq	FP_Reg3				; Handle = 12
	dq	FP_Reg4				; Handle = 13
	dq	FP_Reg5				; Handle = 14
	dq	FP_Reg6				; Handle = 15
	dq	FP_Reg7				; Handle = 16
;
; Register names (8 bytes per name, ASCII null terminated)
; Handle is converted to name address in GetVarNameAdd
;
RegNameTable:
	db	"ACC   ", 00h, 00h
	db	"OPR   ", 00h, 00h
	db	"WORKA ", 00h, 00h
	db	"WORKB ", 00h, 00h
	db	"WORKC ", 00h, 00h
	db	"XREG  ", 00H, 00H
	db	"YREG  ", 00H, 00H
	db	"ZREG  ", 00H, 00H
	db	"TREG  ", 00H, 00H
	db	"REG0  ", 00H, 00H
	db	"REG1  ", 00H, 00H
	db	"REG2  ", 00H, 00H
	db	"REG3  ", 00H, 00H
	db	"REG4  ", 00H, 00H
	db	"REG5  ", 00H, 00H
	db	"REG6  ", 00H, 00H
	db	"REG7  ", 00H, 00H

section         .bss    align=8			; Section containing uninitialized data

FP_Acc:		resq	VAR_WSIZE		; (32_64_CHECK) RESD vs resq
FP_Opr:		resq	VAR_WSIZE
FP_WorkA:	resq	VAR_WSIZE
FP_WorkB:	resq	VAR_WSIZE
FP_WorkC:	resq	VAR_WSIZE
FP_X_Reg:	resq	VAR_WSIZE
FP_Y_Reg:	resq	VAR_WSIZE
FP_Z_Reg:	resq	VAR_WSIZE
FP_T_Reg:	resq	VAR_WSIZE
FP_Reg0:	resq	VAR_WSIZE
FP_Reg1:	resq	VAR_WSIZE
FP_Reg2:	resq	VAR_WSIZE
FP_Reg3:	resq	VAR_WSIZE
FP_Reg4:	resq	VAR_WSIZE
FP_Reg5:	resq	VAR_WSIZE
FP_Reg6:	resq	VAR_WSIZE
FP_Reg7:	resq	VAR_WSIZE		; If changing, must adjust --> TOPHAND

;
;  Miscellaneous program variables
;
No_Byte:		resq	1		; Number of bytes in mantissa (32_64_CHECK align and RESD vs DQ)
No_Word:		resq	1		; Number of words in mantissa
LSWOfst:		resq	1		; Offset address of MS Word at No_Word accuracy
D_Flt_Byte:		resq	1		; Default number of bytes in mantissa
D_Flt_Word:		resq	1		; Default number of words in mantissa
D_Flt_LSWO:		resq	1		; Default Offset address of MS Word
File_Last_Word: 	resq	1		; When loading file, remember last
File_Last_Byte: 	resq	1
File_Last_LSWO:		resq	1

NoSigDig:		resq	1		; Number of Significant Digits
File_Last_SDig:		resq	1		; When loading file, remember last
NoExtDig:		resq	1		; Number of Extended Digits
;
MathMode:		resq	1		; 1=long mult, 2=long division, 4=disable auto short mult 8=disable auto short div
;
; Command Level Timers
;
ProgSTime:		resq	1		; System time of program start
StartSTime:		resq    1		; System time at start of calculation
CalcSTime:		resq	1		; System time of calculation
;
; Profiling Counter
;
%ifdef PROFILE
iCntClear:		resq	1
iCntMove:		resq	1
iCntRotate1Bit:		resq	1
iCntRotate1Byte:	resq	1
iCntRotate1Word:	resq	1
iCntFPTwoCom:		resq	1
iCntFPNorm:		resq	1
iCntFPAdd:		resq	1
iCntFPMultShort:	resq	1
iCntFPMultLong:		resq	1
iCntFPMultWord:		resq	1
iCntFPDivShort:		resq	1
iCntFPDivReg:		resq	1
iCntFPDivLong:		resq	1
iCntFPRecip:		resq	1
iCntFPRecipMul:		resq	1
iCntFixTwoComp:		resq	1
iCntFixAdd:		resq	1
iCntFixSub:		resq	1
iCntFixMult:		resq	1
iCntFixDiv:		resq	1

%endif
;
; Debug Flags
;
DebugFlag:		resq	1
StackPtrSnapshot:	resq	1
StackPtrEntry:		resq	1
;
; Calculation Timers
;
iTimer01:		resq	1
iTimer02:		resq	1
iTimer03:		resq	1
iTimer04:		resq	1
iTimer05:		resq	1
;
; Calculations  Counters
;
iCounter01:		resq	1
iCounter02:		resq	1
iCounter03:		resq	1
iCounter04:		resq	1
iCounter05:		resq	1
iPrintSumCount:		resq	1
iPrintSumCountLimit:	resq	1
iVerboseFlags:		resq	1		; 0x10 print result on, 0x20 print 4 x-t reg, 0x40 all regs, 0x02 show profile (not used?)
iShowCalc:		resq	1
iShowCalcMask:		resq	1		; When show progress, command mobile can mask bits FFFF... is print all
iShowCalcStep:		resq	1
;
; Variables for infinite serires summations
;
Shift_Count:		resq	1		; Set In FPAddition, holds shift count
Nearly_Zero:		resq	1		; Set in FPAddition, shows shift out range
Last_Shift_Count:	resq	1		; Used in case multiple additions are needeed
Last_Nearly_Zero:	resq	1		; Used in case mutiple additions are needed
Sum_Limit:		resq	1		; For series with fixed number terms
;
;  Internal temporary variables
;
DSIGN:			resq	1		; In Multiplication/Division, holds sign
InFlags:		resq	1		; Various FP_Input flags such as decimal point found
Out_Mode:		resq	1		; 0=sci, 1=fix, 2=integer
Out_Sign:		resq	1		; Holds sign in output routine
Out_Exponent:		resq	1		; Holds exponent in output routine
Mult_CF_Index: 		resq	1		; Used in FP_Word_Multiply
Recip_CF_Index:		resq	1		; Used in Sub_Reciprocal_Multc
Recip_Exp:		resq	1		; Used in FP_Reciprocal
Recip_Sign:		resq	1		; Used in FP_Reciprocal
Recip_2CF:		resq	1		; Two's compliment flag
Recip_No_Word:		resq	1		; Temporary accuracy changes
Recip_LSWOfst:		resq	1		; Temporary accuracy changes
INT_Remainder:		resq	1		; Remainder from division
FIX_Remainder:		resq	1		; Remainder from division
f_ln_noword_exp:	resq	1		; used for variable accuracy in LN calculaton newton method
f_ln_noword_newton:	resq	1		; Used for variable accuracy in LN calculation exp series
LCG_Seed:		resq	1		; Used for Pseudorandom number generator
LFSR_Seed1:		resq	1		; Used for Pseudorandom number generator
LFSR_Seed2:		resq	1		; Used for Pseudorandom number generator
RNG_LastN:		resq	1		; Used to assess N-1 random numbers
;

OutCountActive:		resq	1
OutPreCount:		resq	1
OutPreCountLimit:	resq	1
OutCharCount:		resq	1		; These are used by CharOutFmt to format printing
OutWordCount:		resq	1
OutLineCount:		resq	1
OutLineCountLimit:	resq	1
OutParaCount:		resq	1
OutInhibit:		resq	1		; Inhibit character output to file
ConInhibit:		resq	1		; Inhibit character output to console

DescriptionLen	equ	32
Description:	resq	DescriptionLen+100 	; Save to file with variables
HeaderMode:	resq	1

section         .text		; Section containing code
;
; To make editing easier, these are broken into smaller files
; They are compiled into one module to keep addressing more local
;
%include "math-subr.asm"
%include "math-output.asm"
%include "math-debug.asm"
%include "math-rotate.asm"
%include "math-add.asm"
%include "math-mult.asm"
%include "math-div.asm"
%include "math-fixed.asm"

;--------------------------------------------------------------
;  Floating Point Initialize
;
;  Input:   none
;
;  Output:  none
;
;--------------------------------------------------------------
FP_Initialize:
;  Save registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
;
; First set timer so init work can be timed
;
	call	ReadSysTime			; Read system clock
	mov	[StartSTime], rax
	mov	[CalcSTime], rax
;-------
	mov	[LCG_Seed], rax			; Random number generator
	and	qword[LCG_Seed], 0x7FFFFFFF
;-------
	mov	[LFSR_Seed1], rax		; Random number generator
	rol	qword[LFSR_Seed1], 16
	xor	qword[LFSR_Seed1], rax
	rol	qword[LFSR_Seed1], 16
	xor	qword[LFSR_Seed1], rax
	rol	qword[LFSR_Seed1], 16
	xor	qword[LFSR_Seed1], rax

	mov	[LFSR_Seed2], rax		; Random number generator
	rol	qword[LFSR_Seed2], 20
	xor	qword[LFSR_Seed2], rax
	rol	qword[LFSR_Seed2], 8
	xor	qword[LFSR_Seed2], rax
	rol	qword[LFSR_Seed2], 19
	xor	qword[LFSR_Seed2], rax
;-------
;
	mov	rax, 0
	mov	[iTimer01], rax
	mov	[iTimer02], rax
	mov	[iTimer03], rax
	mov	[iTimer04], rax
	mov	[iTimer05], rax
	mov	[iCounter01], rax
	mov	[iCounter02], rax
	mov	[iCounter03], rax
	mov	[iCounter04], rax
	mov	[iCounter05], rax
	mov	[iPrintSumCount], rax
	mov	[iPrintSumCountLimit], rax
	mov	[MathMode], rax
;
	mov	rax, 0
	mov	[Shift_Count], rax
	mov	[Nearly_Zero], rax
	mov	[Last_Shift_Count], rax
	mov	[Last_Nearly_Zero], rax
;
	mov	[DebugFlag], rax
;
	mov	rax, 1
	mov	[OutCountActive], rax		; start with formatted output


	call	CheckWordAlignment		; Make sure compiled align=8
	call	CheckInitRanges
%ifdef PROFILE
	call	Profile_Init
%endif
;
;  Initialize variables
;
	mov	QWORD [NoSigDig], INIT_SIG_DIG	; Number of Significant Digits
	mov	QWORD [NoExtDig], INIT_EXT_DIG	; Number of extended digits
;
	mov	rax, INIT_NO_WORD		; Initial accuracy number words mantissa
	call	Set_No_Word			; Set No_Word, No_Byte, D_Flt_No_Word,
						; D_Flt_No_Btye, and  MSWOfst
	mov	rax, 0
	mov	[File_Last_Word], rax		; When loading file, these remember last
	mov	[File_Last_Byte], rax
	mov	[File_Last_LSWO], rax
	mov	[File_Last_SDig], rax
;
	mov	[OutInhibit], rax
	mov	[ConInhibit], rax
;
	mov	QWORD[iShowCalc], 0
	mov	QWORD[iShowCalcStep], 1000
	call	SetNormal			; set display masks
;
	mov	QWORD[Sum_Limit], 1000000	; limit for sum of fixed term count
;
;  Zero variables
;
	mov	rsi, TOPHAND			; Highest handle number
.loop2:
	mov	rax, 0x0			; Zero value to write
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RBX points to low word of variable
	mov	rcx, VAR_WSIZE			; Number of words to clear
.loop3:
	mov	[rbx], rax			; Clear word
	add	rbx, BYTE_PER_WORD		; Decrement pointer
	loop	.loop3				; Decrement RCX and loop
	dec	rsi				; Decrement varible handle number
	jnl	.loop2
;
; Initialize description text string
;
	mov	rbx, InitDescription		; Source Pointer
	mov	rdx, Description		; Destination Pointer
	mov	rcx, InitDescLen		; Counter
	mov	rbp, 0				; Pointer Index
.loop4:
	mov	AL, [rbx+rbp]
	mov	[rdx+rbp], AL
	inc	rbp
	loop	.loop4

;  Restore registers
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret

CheckWordAlignment:
	push	rdx
		; OR together the last 2 LSB of address to check memory alignment
	mov	rdx, FP_Acc
	or	rdx, FP_Opr
	or	rdx, FP_WorkA
	or	rdx, FP_WorkB
	or	rdx, FP_WorkC
	or	rdx, FP_X_Reg
	or	rdx, FP_Y_Reg
	or	rdx, FP_Z_Reg
	or	rdx, FP_T_Reg
	or	rdx, FP_Reg0
	or	rdx, FP_Reg1
	or	rdx, FP_Reg2
	or	rdx, FP_Reg3
	or	rdx, FP_Reg4
	or	rdx, FP_Reg5
	or	rdx, FP_Reg6
	or	rdx, FP_Reg6
	or	rdx, FP_Reg7
	and	rdx, 00007h			; mask the last 3 bits (32_64_CHECK)
	jz	.skip1
;
	mov	rax, .Msg_Error
	call	StrOut
	mov	rax, 0
	jmp	FatalError
.skip1:
	pop	rdx
	ret
.Msg_Error:	db	0xD, 0xA, "CheckWordAlignment: Error, program variables not properly word aligned", 0xD, 0xA, 0
;
InitDescription:	db	"Floating Point Variable", 0
InitDescLen		equ	$-InitDescription
;
CheckInitRanges:
	push	rax
	push	rbx
	mov	rax, MINIMUM_WORD
	sub	rax, 3
	jge	.skip1
	mov	rax, .Msg_Error1
	call	StrOut
	mov	rax, 0
	jmp	FatalError
.skip1:
	mov	rax, MINIMUM_WORD
	dec	rax			;One less
	sub	rax, GUARDWORDS		;Guard words must be less than allcocated words
	jge	.skip2
	mov	rax, .Msg_Error1
	call	StrOut
	mov	rax, 0
	jmp	FatalError
.skip2:
	pop	rbx
	pop	rbx
	ret
.Msg_Error1:	db	0xD, 0xA, "CheckInitRanges: Error improper initial accuracy", 0xD, 0xA, 0
;
;--------------------------------------------------------------
;  Set Number of Words Variables
;
;  Input:   rax - Number of words
;
;  Output:  none
;
;--------------------------------------------------------------
Set_No_Word:
	push	rax
	mov	[No_Word], rax			; Current number words in mantissa
	mov	[D_Flt_Word], rax		; Initialize Default mantissa size
	shl	rax, 3				; Multiply by 8 bytes per word
	mov	[No_Byte], rax			; Current number words in mantissa
	mov	[D_Flt_Byte], rax		; Initialize Default mantissa size
	mov	rax, MAN_MSW_OFST+BYTE_PER_WORD	; Offset to M.S.Word + 1 word
	sub	rax, [No_Byte]			; Offset to L.S.Word
	mov	[LSWOfst], rax			; Safe current offset
	mov	[D_Flt_LSWO], rax		; Safe default offset
	pop	rax
	ret
;
;--------------------------------------------------------------
;  Set Number of Words Variables at temporary accuracy
;
;  Input:   RAX - Number of words
;
;  Output:  none
;
;--------------------------------------------------------------
Set_No_Word_Temp:
	push	rax
	mov	[No_Word], rax			; Current number words in mantissa
	shl	rax, 3				; Multiply by 8 bytes per word
	mov	[No_Byte], rax			; Current number words in mantissa
	mov	rax, MAN_MSW_OFST+BYTE_PER_WORD	; Offset to M.S.Word + 1 word
	sub	rax, [No_Byte]			; Offset to L.S.Word
	mov	[LSWOfst], rax			; Safe current offset
	pop	rax
	ret
;
;
;--------------------------------------------------------------
;  Grab Shift Count - And also nearly zero
;
;  Input:   [Shift_Count]
;
;  Output:  none, updates Last_Shift_Count and Last_Nearly_Zero
;
;  In case multiple additions are needed, this is inserted after
;  the FP addition to save the status until needed
;
;  Uses: MINIMUM_WORD, [D_Flt_Word]
;--------------------------------------------------------------
GrabSeriesAccuracy:
	push	rax
	mov	rax, [MathMode]			; check if enabled
	test	rax, 0x100
	jnz	.disabled
	mov	rax, [Shift_Count]		; Save for use in series sum
	mov	[Last_Shift_Count], rax
	mov	rax, [Nearly_Zero]		; Save for use in series sum
	mov	[Last_Nearly_Zero], rax
.disabled:
	pop	rax
	ret
;
ClearGrabAccuracy:
	push	rax
	mov	rax, 0
	mov	[Last_Shift_Count], rax
	mov	[Last_Nearly_Zero], rax
	pop	rax
	ret
;--------------------------------------------------------------
;  Set Number of Words Variables at temporary accuracy
;
;  Input:   [Last_Shift_Count]
;
;  Output:  none
;
;  Uses: MINIMUM_WORD, [D_Flt_Word]
;--------------------------------------------------------------
ReduceSeriesAccuracy:
	push	rax
	mov	rax, [MathMode]			; check if enabled
	test	rax, 0x100
	jnz	.disabled
;
	mov	rax, [D_Flt_Word]		; Get non-adjusted word count
	sub	rax, [Last_Shift_Count]		; Subtract number of words
	inc	rax				; Add extra word for safety
	mov	rbx, rax				; Save temporarily
;
; Check upper limit (could be negative)
;
	mov	rax, [D_Flt_Word]		; Maximum allowed
	cmp	rax, rbx				; Subtract Proposed
	jge	.skip1				; >= Zero, in range
	mov	rbx, [D_Flt_Word]		; Else out of range, use default
.skip1:
	mov	rax, rbx				; Get Proposed
	cmp	rax, MINIMUM_WORD		; Minimum word count
	jge	.skip2				; >- Zero, in range
	mov	rbx, MINIMUM_WORD
.skip2:
	mov	rax, rbx				; Move proposed value to RAX
	mov	[No_Word], rax			; Current number words in mantissa
	shl	rax, 3				; Multiply by 8 bytes per word
	mov	[No_Byte], rax			; Current number words in mantissa
	mov	rax, MAN_MSW_OFST+BYTE_PER_WORD	; Offset to M.S.Word + 1 word
	sub	rax, [No_Byte]			; Offset to L.S.Word
	mov	[LSWOfst], rax			; Safe current offset
.disabled:
	pop	rax
	ret
;
;--------------------------------------------------------------
;  Set Number of Words Variables
;
;  Input:   RAX - Number of words
;
;  Output:  none
;
;--------------------------------------------------------------
RestoreFullAccuracy:
	push	rax
	mov	rax, [MathMode]			; check if enabled
	test	rax, 0x100
	jnz	.disabled
;
	mov	rax, [D_Flt_Word]
	mov	[No_Word], rax
;
	mov	rax, [D_Flt_Byte]
	mov	[No_Byte], rax
;
	mov	rax, [D_Flt_LSWO]
	mov	[LSWOfst], rax
;
.disabled:
	pop	rax
	ret


;---------------
; math.asm EOF
;---------------
