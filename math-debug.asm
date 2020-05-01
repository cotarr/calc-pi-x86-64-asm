;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; F.P. SUBROUTINES
;
; File:   math-debug.asm
; Module: math.asm, math.o
; Exec:   calc-pi
;
; Created:   10/15/14
; Last Edit: 09/26/15
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
; Header_Update:
; Header_Init:
; Header_Cancel:
; ClrScr:
; Variable_Compare:
; Profile_Show:
; Profile_Show_Always:
; Profile_Init:
; ShowCalcProgress:
; PrintVar:
; PrintHex:
; PrintHexOld:
; DebugFillVariable:
; EndianCheck:
;------------------------------------------------------

; www

Header_Update:
	push	rax
	push	rbx
	mov	rax, 1
	test	[HeaderMode], rax		; Is header on?
	jz	.exit				; No, it's off skip this routine
;
	mov	rax, [OutInhibit]
	push	rax
	mov	qword[OutInhibit], 1
;
; Remember screen parameters
;
	mov	rax, .HU_Start
	call	StrOut
;
;  Line #1
;
	mov	rax, .Label_Color
	call	StrOut
	mov	rax, .HU_01
	call	StrOut
	mov	rax, .Data_Color
	call	StrOut
	mov	rax, Description
	call	StrOut
;
; Line #2
;
	mov	rax, .Label_Color
	call	StrOut
	mov	rax, .HU_01a
	call	StrOut
	mov	rax, .Data_Color
	call	StrOut
	mov	rax, [fd_echo]			; Get file descriptor
	or	rax, rax
	jnz	.skip01a1
	mov	rax, .HU_off
	call	StrOut
	jmp	.skip01a2
.skip01a1:
	mov	rax, FN_Echo
	call	StrOut
.skip01a2:
	mov	rax, .Label_Color
	call	StrOut
	mov	rax, .HU_02
	call	StrOut
	mov	rax, .Data_Color
	call	StrOut
	mov	rax, [NoSigDig]
	call	PrintWordB10
	mov	rax, .Label_Color
	call	StrOut
	mov	rax, .HU_02a
	call	StrOut
	mov	rax, .Data_Color
	call	StrOut
	mov	rax, [No_Word]
;;;;	sub	rax, GUARDWORDS
	call	PrintWordB10
;
	mov	rax, .Label_Color
	call	StrOut
	mov	rax, .HU_02b
	call	StrOut
	mov	rax, .Data_Color
	call	StrOut
	mov	rbx, [MathMode]
	test	rbx, 1
	jz	.skip2b1
	mov	rax, .HU_Long
	jmp	.skip2B2
.skip2b1:
	mov	rax, .HU_Auto
	test	rbx, 4
	jz	.skip2B2
	mov	rax, .HU_Word
.skip2B2:
	call	StrOut
	mov	rax, .Label_Color
	call	StrOut
	mov	rax, .HU_02c
	call	StrOut
	mov	rax, .Data_Color
	call	StrOut
	mov	rbx, [MathMode]
	test	rbx, 2
	jz	.skip2b3
	mov	rax, .HU_Long
	jmp	.skip2B4
.skip2b3:
	mov	rax, .HU_Auto
	test	rbx, 8
	jz	.skip2B4
	mov	rax, .HU_Recip
.skip2B4:
	call	StrOut
;
; MathMode
	test	rbx, 0x01C0			; see if extended bitwise modes
	jz	.skip2B5
	mov	rax, .Label_Color
	call	StrOut
	mov	rax, .HU_MMode
	call	StrOut
	mov	rax, .Data_Color
	call	StrOut
	mov	al, [MathMode+1]
	call	PrintHexByte
	mov	al, [MathMode]
	call	PrintHexByte

;
; Line 3
;
.skip2B5:
	mov	rax, .Label_Color
	call	StrOut
	mov	rax, .HU_03
	call	StrOut
	mov	rax, .Data_Color
	call	StrOut
	mov	rbx, [Out_Mode]
	mov	rax, .HU_030			; Sci
	cmp	rbx, 1
	jne	.skip30a
	mov	rax, .HU_031			; Fix
.skip30a:
	cmp	rbx, 2
	jne	.skip30b
	mov	rax, .HU_032
.skip30b:
	call	StrOut
	mov	rax, .Label_Color
	call	StrOut
	mov	rax, .HU_03_A
	call	StrOut
	mov	rax, .Data_Color
	call	StrOut
	mov	rax, 1
	test	[iShowCalc], rax
	jnz	.skip3A
	mov	rax, .HU_off
	call	StrOut
	jmp	.skip3A1
.skip3A:
	mov	rax, .HU_on
	call	StrOut
	mov	rax, .Label_Color
	call	StrOut
	mov	rax, .HU_03_1c
	call	StrOut
	mov	rax, .Data_Color
	call	StrOut
	mov	rax, [iShowCalcStep]
	call	PrintWordB10
.skip3A1:
	mov	rax, [DebugFlag]
	or 	rax, rax
	jz	.skip4
	mov	rax, .Label_Color
	call	StrOut
	mov	rax, .HU_03_B
	call	StrOut
	mov	rax, .Data_Color
	call	StrOut
	mov	rax, [DebugFlag]
	call	PrintWordB10

.skip4:

;
; Restore screen parameters
;
	mov	rax, .HU_End
	call	StrOut
;
	pop	rax
	mov	[OutInhibit], rax
.exit:
	pop	rbx
	pop	rax
	ret

.HU_Start:
;		db	27, "[s"		; Save cursor ESC[s
		db	27, "7"			; Save cursor ESC7
		db	0
.HU_End:
		db	27, "[0m"		; Default color
		db	27, "8"			; Restore Saved Cursor ESC8
;		db	27, "[u"		; Restore Saved Cursor ESC[u
		db	0
.Label_Color:
		db	27, "[36m"		; Foreground color
		db	27, "[22m"		; Regular bright
		db	0
.Data_Color:
		db	27, "[36m"		; Foreground color
		db	27, "[1m"		; Bold (bright)
		db	0

.HU_01:		db	27, "[1;1H", 27, "[K"	;Line #, Clear to EOL
		db	" Description: ", 0
.HU_01a:	db	"   Capture: ", 0
.HU_02:		db	27, "[2;1H", 27, "[K"	;Line #, Clear to EOL
		db	" Digits: ", 0
.HU_02a:	db	"   Words: ", 0
.HU_02b:	db	"   Mult: ", 0
.HU_02c:	db	"   Div: ", 0
.HU_Long:	db	"Long", 0
.HU_Auto:	db	"Auto", 0
.HU_Word:	db	"Word", 0
.HU_Recip:	db	"Mult*Recip.", 0	; <??? didn't have 0
.HU_MMode:	db	"   MathMode: ", 0


.HU_03:		db	27, "[3;1H", 27, "[K"	; Line #, Clear to EOL
		db	" Out: ", 0
.HU_030:	db	"Sci", 0
.HU_031:	db	"Fix", 0
.HU_032:	db	"Int", 0

.HU_03_A:	db	" Show: ", 0
.HU_03_1c:	db	"   SStep: ", 0
.HU_03_B:	db	"   D.Flag: ", 0

.HU_on:		db	"On", 0
.HU_off:	db	"Off", 0

Header_Init:
	push	rax
	mov	rax, [OutInhibit]
	push	rax
	mov	qword[OutInhibit], 1
	mov	rax, .Normal_String
	call	StrOut
	mov	qword[HeaderMode], 1		; header is on
	pop	rax
	mov	[OutInhibit], rax
	pop	rax
	ret


.Normal_String:
;	db	27, "[s"			; Save cursor ESC[s
	db	27, "7"				; Save cursor ESC7
;	db	27, "[2J"			; Clear whole screen
	db	27, "[5r"			; Freeze rows at top
	db	27, "[1;1H", 27, "[K"		; Erase to end of line
	db	27, "[2;1H", 27, "[K"		; Erase to end of line
	db	27, "[3;1H", 27, "[K"		; Erase to end of line
	db	27, "[4;1H", 27, "[K"		; Erase to end of line
;	db	27, "[5;1H", 27, "[K"		; Erase to end of line
;	db	27, "[4;1H"			; Move cursor to top
	db	27, "[0m"			; Default colorse
	db	27, "8"				; Restore saved cursor ESC8
;	db	27, "[u"			; Restore saved cursor ESC[u
	db	0				; End marker

Header_Cancel:
	push	rax
	mov	rax, [OutInhibit]
	push	rax
	mov	qword[OutInhibit], 1
	mov	rax, .Cancel_String
	call	StrOut
	mov	qword[HeaderMode], 0		; header is off
	pop	rax
	mov	[OutInhibit], rax
	pop	rax
	ret
.Cancel_String:
;	db	27, "[s"			; Save cursor ESC[s
	db	27, "7"				; Save cursor ESC7
	db	27, "[1;1H", 27, "[K"		; Erase to end of line
	db	27, "[2;1H", 27, "[K"		; Erase to end of line
	db	27, "[3;1H", 27, "[K"		; Erase to end of line
	db	27, "[4;1H", 27, "[K"		; Erase to end of line
;	db	27, "[5;1H", 27, "[K"		; Erase to end of line
	db	27, "[r"			; Cancel scroll line freeze
	db	27, "[0m"			; Reset attributes
	db	27, "8"				; Restore saved cursor ESC8
;	db	27, "[u"			; Restore saved cursor ESC[u
	db	0				; End of string
ClrScr:
	push	rax
	mov	rax, [OutInhibit]
	push	rax
	mov	qword[OutInhibit], 1
	mov	rax, .Clear_String
	call	StrOut
	mov	qword[HeaderMode], 0		; header is off
	pop	rax
	mov	[OutInhibit], rax
	pop	rax
	ret
.Clear_String:
	db	27, "[2J"			; Clear Screen
	db	27, "[H"			; Home Cursor
	db	0				; End of string

;------------------------------------------------------
;
;	Compare 2 variables
;
;	Input:	RSI - Variable 1
; 		RDI - Variable 2
;
;------------------------------------------------------
Variable_Compare:
	push	rax				; Working Variable
	push	rbx				; Address Operand 1
	push	rcx				; Counter
	push	rdx				; Address Operand 2
	push	rsi				; Operand 1 handle
	push	rdi				; Operand 2 handle
	push	rbp				; Index pointer
	push	r8				; Holds Counter

;
; Setup address and counter
;
	mov	rbx, [RegAddTable+(rsi*WSCALE)]	; RSI (index) --> RBX (address)
	mov	rdx, [RegAddTable+(rdi*WSCALE)]	; RDI (index) --> RBX (address)
;
; Check Exponents
;
	mov	rbp, EXP_WORD_OFST		; Exponent index
	mov	rax, [rbx+rbp]			; get exponent 1
	cmp	rax, [rdx+rbp]			; compare exponent 2
	je	.exp_equal
	mov	rax, .Msg_DiffExp
	call	StrOut
	mov	rax, [rbx+rbp]			; Get exponent 1
	call	PrintHexWord			; print it
	mov	al, " "
	call	CharOut
	mov	rax, [rdx+rbp]			; Get exponent 1
	call	PrintHexWord			; print it
	call	CROut
	jmp	.exit
.exp_equal:
	mov	rbp, MAN_MSW_OFST		; RBP point at L.S.Word
	mov	rcx, [No_Word]			; Counter for number of words
	mov	r8, 0
;
; Main loop
;
.loop1:
	inc	r8
	mov	rax, [rbx+rbp]			; Load first number
	cmp	rax, [rdx+rbp]			; Add CF and hex digit
	jne	.not_equal
	sub	rax, BYTE_PER_WORD
	loop	.loop1				; Decrement RCX counter and loop back
;
	mov	rax, .Msg_Match
	call	StrOut
	jmp	.exit

.not_equal:
	mov	rax, .Msg_Diff1
	call	StrOut
	mov	rax, r8
	call	PrintWordB10
	mov	rax, .Msg_Diff2
	call	StrOut
	mov	rax, [No_Word]
	call	PrintWordB10
	mov	rax, .Msg_Diff3
	call	StrOut
	mov	rax, [rbx+rbp]
	call	PrintHexWord
	mov	al, ' '
	call	CharOut
	mov	rax, [rdx+rbp]
	call	PrintHexWord
	call	CROut
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
.Msg_Match:	db 	"    Variables match", 0xD, 0xA, 0
.Msg_DiffExp:	db	"Exponents different. Words: ", 0
.Msg_Diff1:	db	"Word ", 0
.Msg_Diff2:	db	" of ", 0
.Msg_Diff3:	dB	" words different. Words: ", 0


%ifdef PROFILE
;------------------------------------------------------
;
;   Profile_Show
;
;   Print results of profile counters
;
;------------------------------------------------------
Profile_Show:
	push	rax
	mov	rax, [iVerboseFlags]
	test	rax, 0x02			; Should we show this?
	jnz	.yes_verbose			; Yes, show report
	pop	rax				; Else, no, exit
	ret
;
.yes_verbose:
	pop	rax
; alternate entry
Profile_Show_Always:
	push	rax
;
	mov	rax, .msg01
	call	StrOut				; print header message
;
	mov	rax, .msg_Move
	call	StrOut
	mov	rax, [iCntMove]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_Clear
	call	StrOut
	mov	rax, [iCntClear]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_Rotate1Bit
	call	StrOut
	mov	rax, [iCntRotate1Bit]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_Rotate1Byte
	call	StrOut
	mov	rax, [iCntRotate1Byte]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_Rotate1Word
	call	StrOut
	mov	rax, [iCntRotate1Word]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FPTwoCom
	call	StrOut
	mov	rax, [iCntFPTwoCom]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FPNorm
	call	StrOut
	mov	rax, [iCntFPNorm]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FPAdd
	call	StrOut
	mov	rax, [iCntFPAdd]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FPMultShort
	call	StrOut
	mov	rax, [iCntFPMultShort]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FPMultWord
	call	StrOut
	mov	rax, [iCntFPMultWord]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FPMultLong
	call	StrOut
	mov	rax, [iCntFPMultLong]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FPDivShort
	call	StrOut
	mov	rax, [iCntFPDivShort]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FPDivReg
	call	StrOut
	mov	rax, [iCntFPDivReg]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FPDivLong
	call	StrOut
	mov	rax, [iCntFPDivLong]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FPRecip
	call	StrOut
	mov	rax, [iCntFPRecip]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FPRecipMul
	call	StrOut
	mov	rax, [iCntFPRecipMul]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FixTwoComp
	call	StrOut
	mov	rax, [iCntFixTwoComp]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FixAdd
	call	StrOut
	mov	rax, [iCntFixAdd]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FixSub
	call	StrOut
	mov	rax, [iCntFixSub]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FixMult
	call	StrOut
	mov	rax, [iCntFixMult]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .msg_FixDiv
	call	StrOut
	mov	rax, [iCntFixDiv]
	call	PrintWordB10
	call	CROut
;
	pop	rax
	ret
.msg01:	db	0xD, 0xA, 0xD, "Program Profiling Counters", 0xD, 0xA, 0
.msg_Clear:		db	"iCntClear:       ", 0
.msg_Move:		db	"iCntMove:        ", 0
.msg_Rotate1Bit:	db	"iCntRotate1Bit   ", 0
.msg_Rotate1Byte:	db	"iCntRotate1Byte  ", 0
.msg_Rotate1Word:	db	"iCntRotate1Word  ", 0
.msg_FPTwoCom:		db	"iCntFPTwoCom:    ", 0
.msg_FPNorm:		db	"iCntFPNorm:      ", 0
.msg_FPAdd:		DD	"iCntFPAdd:       ", 0
.msg_FPMultShort:	db	"iCntFPMultShort: ", 0
.msg_FPMultWord: 	db	"iCntFPMultWord:  ", 0
.msg_FPMultLong:	db	"iCntFPMultLong:  ", 0
.msg_FPDivReg:		db	"iCntFPDivReg:    ", 0
.msg_FPDivShort:	db	"iCntFPDivShort:  ", 0
.msg_FPDivLong:		db	"iCntFPDivLong:   ", 0
.msg_FPRecip:		db	"iCntFPRecip:     ", 0
.msg_FPRecipMul:	db	"iCntFPRecipMul:  ", 0
.msg_FixTwoComp:	db	"iCntFixTwoComp:  ", 0
.msg_FixAdd:		db	"iCntFixAdd:      ", 0
.msg_FixSub:		db	"iCntFixSub:      ", 0
.msg_FixMult:		db	"iCntFixMult:     ", 0
.msg_FixDiv:		db	"iCntFixDiv:      ", 0

;------------------------------------------------------
;
;   Profile_Init
;
;   Initialize profile counters
;
;------------------------------------------------------
Profile_Init:
	push	rax
;
	mov	rax, 0
	mov	[iCntClear], rax
	mov	[iCntMove], rax
	mov	[iCntRotate1Bit], rax
	mov	[iCntRotate1Byte], rax
	mov	[iCntRotate1Word], rax
	mov	[iCntFPTwoCom], rax
	mov	[iCntFPNorm], rax
	mov	[iCntFPAdd], rax
	mov	[iCntFPMultShort], rax
	mov	[iCntFPMultWord], rax
	mov	[iCntFPMultLong], rax
	mov	[iCntFPDivReg], rax
	mov	[iCntFPDivShort], rax
	mov	[iCntFPDivLong], rax
	mov	[iCntFPRecip], rax
	mov	[iCntFPRecipMul], rax
	mov	[iCntFixTwoComp], rax
	mov	[iCntFixAdd], rax
	mov	[iCntFixSub], rax
	mov	[iCntFixMult], rax
	mov	[iCntFixDiv], rax
;
	pop	rax
	ret
%endif ;IFDEF PROFILE
;
;------------------------------------------------------
;
;  Function  ShowCalcProgress
;
;  Input:   RAX - bits as listed
;           RBX - skip count
;           [iShowCalcMask] used to block modes, i.e. phone disply
;
;
;  Output:  text send to CharOut
;
;  RAX Bits
;  0x0000 (all zero) initialize at start of calculation
;   iCounter01
;  0x00000001 Print Value
;  0x00000002 Print Name
;  0x00000004 Increment Counter
;  0x00000008 Reset to Zero
;   iCounter02
;  0x00000010 Print Value
;  0x00000020 Print Name
;  0x00000040 Increment Counter
;  0x00000080 Reset to Zero
;   iTimer01
;  0x00000100 Print Value
;  0x00000200 Print Name
;  0x00000400 Reset to Zero during Print Update (Skip counter)
;  0x00000800 Reset to Zero
;   iTimer02
;  0x00001000 Print Value
;  0x00002000 Print Name
;  0x00004000 Reset to Zero during Print Update (skip counter)
;  0x00008000 Reset to Zero
;    Command Timer
;  0x00010000 Print Value
;  0x00020000 Print Name
;  0x00040000 Print Value in Seconds
;  0x00080000 Print Name
;    Shift_Count
;  0x00100000 Print Value
;  0x00200000 Print Name
;  0x00400000 (not used)
;  0x00800000 (not used)

;  0x01000000 Print mantissa nibble sample
;  0x02000000 Initialize skip count from RBX value
;  0x04000000 Print mantissa nibble ruler
;  0x08000000 (not used)

;  0x10000000 Print Leading CR/LF
;  0x20000000 Print Tailing LF
;  0x40000000 Obey skip counter?
;  0x80000000 Suppress Printing to File

;
;------------------------------------------------------------------------------------
ShowCalcProgress:
;
; If not verbose, don't process this
;
	push	rdi
	mov	rdi, [iShowCalc]
	test	rdi, 1
	jnz	.yes_verbose
	pop	rdi
	ret
;
.yes_verbose:
	push	rax				; input command, then working variable
	push	rbx				; input skip counter, then address pointer
	push	rcx				; loop variable
	push	rdx				; for DIV command
	push	rbp				; Pointer index
	push	r8				; Holds skip flag
;
; Preserve command bits
;
	mov	edi, eax			; RAX (low part of EAX) contains input command bits
	mov	rax, 0x8200CCCC			; various bits can ot be filtered
	or	rax, [iShowCalcMask]
	and	edi, eax			; remove any bits, (i.e. mobile phone mode?)
;
; Inhibit capture to file if requested
;
	test	edi, 0x80000000			; Suppress capture to file?
	jz	.skip00
	mov	rax, 1				; Non zero to inhibit
	mov	[OutInhibit], rax		; Inhibit capture to file
;
; Case of initialize, EDI = 0x00000000 or 0x06000000
;
.skip00:
	test	edi, 0xFFFFFFFF-0x06000000
						; Zero? (except init skip counter, ruler)  Reset all?
	jnz	.skip02				; No, not a reset
	call	ReadSysTime			; Get UNIX time in seconds
	mov	[iTimer01], rax			; Initialize timers
	mov	[iTimer02], rax  		; Initialize timers
	mov	rax, 0
	mov	[iCounter01], rax 		; Initialize counters
	mov	[iCounter02], rax 		; Initialize counters
	mov	[iPrintSumCount], rax		; Initialize skip counter
	mov	rax, 1				; Default print every line
	mov	[iPrintSumCountLimit], rax
	TEST	EDI, 0x02000000			; do we have an override value?
	JZ	.skip01				; No we are done
	mov	[iPrintSumCountLimit], RBX
						; Else use skip limit from RBX
.skip01:
	mov	rax, .msg01
	call	StrOut				; Show initialization message
;
; Print Ruler
;
	TEST	EDI, 0x04000000			; Show Ruler?
	JZ	.skip01a
	mov	rax, .msgR
	call	StrOut				; Show Ruler
.skip01a:
	JMP	.exit
;--------------------------------
;
; Not initializing, do the loop
;
; Print ruler
;
.skip02:
;
; Update skip counter if needed
;
	test	edi, 0x02000000			; do we have an override value?
	jz	.skip03				; No we are done
	mov	[iPrintSumCountLimit], RBX	; Input parameter from calling function
;
; Prepare the printout skip flag set or clear
;
.skip03:
	mov	r8, 0				; Set print flag to NO
	mov	rax, [iPrintSumCount]		; Last counter
	inc	rax				; Increment
	mov	[iPrintSumCount], rax		; Store result
	cmp	rax, [iPrintSumCountLimit]
						; Is it over limit,
	jl	.skip04				; No so don't print
	mov	rax, 0
	mov	[iPrintSumCount], rax		; Reset counter to zero
	mov	r8, 1				; Set print to YES
.skip04:
	test	edi, 0x40000000			; Use the skip counter as set?
	jnz	.skip05				; Yes, use previous skip counter
	mov	r8, 1				; No, Always print
.skip05:
;
	or	r8, r8				; Print flag set?
	jz	.skip10				; Not printing, skip
;
; Print Ruler
;
	test	edi, 0x04000000			; Show Ruler?
	jz	.skip06
	mov	rax, .msgR
	call	StrOut				; Show Ruler
.skip06:
;
; Print leading carriage return
;
	test	edi, 0x10000000			; Print CR/LF?
	jz	.skip10				; suppressing, skip
	call	CROut
;
; Print Mantissa Sample of spaced nibbles
;
.skip10:
	or	r8, r8				; Is the skip flag set?
	jz	.skip20				; Yes, don't print
	test	edi, 0x01000000			; requested?
	jz	.skip20				; no skip
;
; Print check if need to space out bytes to see whole word
; If there are more than 64 bytes, the sample nibbles will be
; spaced out over the mantissa.
;
	mov	rdx, 0
	mov	rax, [D_Flt_Byte]
	cmp	rax, 32				; **** IF CHANGE --> 3 places
	jl	.skip11
;
; Large mantissa, case greater than 64 bytes, use evenly spaced sample nibbles
;
	mov	rbx, 32				; number of nibble to print
	div	rbx				; RDX:RAX/RBX --> RAX = byte per interval
	mov	rdx, rax			; RDX = byte per interval
	mov	rbx, FP_Acc			; Address FP_Acc
	mov	rbp, MAN_MSB_OFST		; Point MS Byte
	mov	rcx, 32				; Counter for nibble prints
	jmp	.loop				; Skip next section for small mantissa
;
; Small mantissa, less than 64 bytes, use nibble from each word in mantissa
;
.skip11:
	mov	rbx, FP_Acc			; Address FP_Acc
	mov	rbp, MAN_MSB_OFST		; Point MS Byte
	mov	rcx, [D_Flt_Byte]		; use number of bytes
	mov	rdx, 1				; 1 byte at a time
;
; This is looping to print evenly spaced nibbles
;
.loop:
	mov	al, [rbx+rbp]			; Get byte
	and	al, 0xF				; Get first nibble
	cmp	al, 09h				; Number or A-F?
	jg	.skip12				; It's A-F branch
	or	al, 0x030			; Form ASCII 0-9
	jmp	.skip13				; Always taken
.skip12:
	sub	al, 09H				; Adjust and
	or	al, 0x040			; form ASCII A-F
.skip13:
	call	CharOut				; output character
	sub	rbp, rdx			; add interval
	loop	.loop				; Dec RCX and loop back
;
	mov	al, ' '				; Formatting Spaces
	call	CharOut
	call	CharOut
	call	CharOut

.skip20:
;
; Increment Counters
;
	test	edi, 0x00000004			; Increment iCounter01?
	jz	.skip21				; No skip
	mov	rax, [iCounter01]		; Get counter
	inc	rax				; Increment
	mov	[iCounter01], rax		; Move back
.skip21:
	test	edi, 0x00000040			; Increment iCounter02?
	jz	.skip22				; No skip
	mov	rax, [iCounter02]		; Get counter
	inc	rax				; Increment
	mov	[iCounter02], rax		; Move back
;
; Print iCounters
;
.skip22:
	or	r8, r8				; Skip printing?
	jz	.skip24				; yes, skip all
;
	test	edi, 0x00000002			; print iCounter01 label
	jz	.skip23				; no skip
	mov	rax, .msg02
	call	StrOut
.skip23:
	test	edi, 0x00000001			; print iCounter01 value?
	jz	.skip23a			; no skip
	mov	rax, [iCounter01]
	call	PrintWordB10
	mov	al, ' '
	call	CharOut
.skip23a:
	test	edi, 0x00000020			; print iCounter02 label
	jz	.skip23b			; no skip
	mov	rax, .msg03
	call	StrOut
.skip23b:
	test	edi, 0x00000010			; print iCounter02 value?
	jz	.skip24				; no skip
	mov	rax, [iCounter02]
	call	PrintWordB10
	mov	al, ' '
	call	CharOut
;
; Clear Counters
;
.skip24:
	mov	rax, 0				; Clear RAX
	test	edi, 0x00000008			; Clear iCounter01?
	jz	.skip25				; No, skip
	mov	[iCounter01], rax		; Clear iCounter01
.skip25:
	test	edi, 0x00000080			; Clear Counter 02?
	jz	.skip30				; No, skip
	mov	[iCounter02], rax		; Clear iCounter02
;
; Read Timers
;
.skip30:
	test	edi, 0x000FFF00			; any timer running?
	jz	.skip31				; no don't read time
	call	ReadSysTime			; Get system RAX=seconds unix time
	mov	rbx, rax			; Save in RBX
;
; Print timers
;
.skip31:
	or	r8, r8				; Skip printing?
	jz	.skip34				; yes
;
	test	edi, 0x00020000			; Command Timer Label?
	jz	.skip32				; no skip
	mov	rax, .msg06
	call	StrOut				; Print Label
.skip32:
	test	edi, 0x00010000			; Command Timer Value?
	jz	.skip32a			; no skip
	mov	rax, rbx			; System time now
	sub	rax, [StartSTime]		; Subtract start time
	call	PrintDDHHMMSS			; Print time
	mov	al, ' '
	call	CharOut
.skip32a:
	test	edi, 0x00080000			; Command Seconds Label?
	jz	.skip32b			; no skip
	mov	rax, .msg09
	call	StrOut				; Print Label
.skip32b:
	test	edi, 0x00040000			; Command Timer Value?
	jz	.skip32c			; no skip
	mov	rax, rbx			; System time now
	sub	rax, [StartSTime]		; Subtract start time
	call	PrintWordB10			; Print time
	mov	al, ' '
	call	CharOut
.skip32c:
	test	edi, 0x00000200			; Print iTimer01 label?
	jz	.skip32d			; no skip
	mov	rax, .msg04
	call	StrOut				; Print lable
.skip32d:
	test	edi, 0x00000100			; Print iTimer01 Value?
	jz	.skip33				; no skip
	mov	rax, rbx			; System time now
	sub	rax, [iTimer01]			; Subtract start time
	call	PrintDDHHMMSS			; Print time
	mov	al, ' '
	call	CharOut
.skip33:
	test	edi, 0x00002000			; Print iTimer02 Label
	jz	.skip33a			; no skip
	mov	rax, .msg05
	call	StrOut				; Print lable
.skip33a:
	test	edi, 0x00001000			; Print iTimer02 Value
	jz	.skip34				; no skip
	mov	rax, rbx			; System time now
	sub	rax, [iTimer02]			; Subtract start time
	call	PrintDDHHMMSS			; Print time
	mov	al, ' '
	call	CharOut
;
; Reset Timers
;
.skip34:
	test	edi, 0x00000800			; Clear iTimer01?
	jz	.skip35				; no skip
	mov	[iTimer01], rbx			; Save current unix time
.skip35:
	test	edi, 0x00008000			; lear iTimer02?
	jz	.skip36				; no skip
	mov	[iTimer02], rbx			; Save current unix time
;
; Reset timers if printing update (don't reset if print is skipped)
;  This gives time per update, i.e. 100, then time for 100 terms
;
.skip36:
	or	r8, r8				; Reset timer concurrent with print?
	jz	.skip40
	test	edi, 0x00000400			; Reset iTimer01?
	jz	.skip37
	mov	[iTimer01], rbx			; Save current unix time
.skip37:
	test	edi, 0x00004000			; Reset iTimer02?
	jz	.skip40
	mov	[iTimer02], rbx			; Save current unix time


;
; Shift counter
;
.skip40:
	or	r8, r8
	jz	.skip41

	test	edi, 0x00200000			; Print the [Shift_Count] label ?
	jz	.skip40a
	mov	rax, .msg07
	call	StrOut
.skip40a:
	test	edi, 0x00100000			; Print the [Shift_Count] value ?
	jz	.skip40b
	mov	rax, [Last_Shift_Count]
	call	PrintWordB10
	mov	al, ' '
	call	CharOut
.skip40b:
	test	edi, 0x00200000			; Print the [Shift_Count] label ?
	jz	.skip40c
	mov	rax, .msg08
	call	StrOut
.skip40c:
	test	edi, 0x00100000			; Print the [Shift_Count] value ?
	jz	.skip41
	mov	rax, [No_Word]
	call	PrintWordB10
	mov	al, ' '
	call	CharOut
;
; Output carriage return, line feed unless suppressed
;
.skip41:
	or	r8, r8				; Skip print flag set?
	jz	.exit				; Bit not set, nothing to print
	test	edi, 0x01333333			; Did anyting print?
	jz	.exit				; No, nothing printed
	mov	al, 0x0D			; Carriage Return
	call	CharOut				; Print character
	test	edi, 0x20000000			; Print tailing line feed?
	jz	.exit				; No suppress it
	mov	al, 0x0A			; Line feed
	call	CharOut				; Print character
.exit:
	mov	rax, 0				; Non zero to inhibit
	mov	[OutInhibit], rax		; Clear so other function can  capture to file
	pop	r8
	pop	rbp
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	pop	rdi
	ret
;
.msgR:
;;;	db	0xD, 0xA, "...............|...............|"
	db	0xD, 0XA, "...............|...............| <-- Ruler.", 0xD, 0xA, 0
.msg01:	db	0xD, 0xA, "Calculation Status variables initialized.", 0xD, 0xA, 00
.msg02:	db	" iCounter01=", 0
.msg03:	db	" iCounter02=", 0
.msg04:	db	" iTimer01: ", 0
.msg05:	db	" iTimer02: ", 0
.msg06:	db	" Command: ", 0
.msg07:	db	" Shift: ", 0
.msg08: db	" No_Word: ", 0
.msg09:	db	" Seconds: ", 0
;--------------------------------------------------------------
;   Print specified variable in HEX format
;
;   Input:  RSI = variable handle number
;
;   Output: none
;
;--------------------------------------------------------------
PrintVar:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
;
	call	GetVarNameAdd			; RSI (index) --> RAX (address)
	call	StrOut				; Print variable name
	mov	al, ' '
	call 	CharOut
	mov	al, '('
	call	CharOut
	mov	rax, rsi			; get variable handle
	call	PrintWordB10
	mov	al, ')'
	call	CharOut
	call	CROut
;
; Print all of mantissa in words
;
	mov	rdx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RDX (address)
	add     rdx, MAN_MSW_OFST		; Point to address of mantissa MS Word
	mov     rcx, [No_Word]			; Print all the words (CAUTION!)
	mov	rbx, 0				; for line feeds
.loop1:	mov     rax, [rdx]			; get byte
	call    PrintHexWord			; output hex byte
	mov     al, ' '				; print space
	call    CharOut
	inc	rbx				; counter for line feed
	mov	rax, RBX
	and	rbx, 0x07
	jnz	.skip1
	call	CROut
.skip1:
	sub	rdx, BYTE_PER_WORD		; address next word
	loop	.loop1  			; decrement RCX and loop

;
; Next print exponent word
;
	mov     al, 'E'
	call    CharOut				; print E for exponent
	mov     al, ' '				; Print space
	call    CharOut
	mov	rdx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RDX (address)
	add     rdx, EXP_MSW_OFST		; point to MS Word of exponent
	mov	rax, [rdx]			; get double word data
	call    PrintHexWord			; print byte in hex


	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret

;--------------------------------------------------------------
;   Print all variables in HEX format
;
;   Input:  none
;
;   Output: none
;
;--------------------------------------------------------------
PrintHex:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
;
; print heading
;
	mov	rax, .HexTabString		; print table headings
	call	StrOut
	call	CROut
;
	mov	rsi, 0				; point at first variable handle

; loop to here for each register, first print register name

.loop1:
	call	GetVarNameAdd			; RSI (index) --> RAX (address)
	call	StrOut				; Print variable name
	mov	al, '('
	call	CharOut
	cmp	rsi, 9
	jg	.skip_space
	mov	al, ' '
	call	CharOut
.skip_space:
	mov	rax, rsi			; Getr handle number
	call	PrintWordB10
	mov	al, ')'
	call	CharOut
	mov	al, ' '
	call	CharOut
;
; Print word values Mantissa
;
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RDX (address)
	mov     rbp, MAN_MSW_OFST		; Point to address of mantissa MS Word
	mov     rcx, 3				; how many words to print
.loop2:	mov     rax, [rbx+rbp]			; get word
	call    PrintHexWord			; output hex byte
	mov     al, ' '				; print space
	call    CharOut
	sub	rbp, BYTE_PER_WORD		; address next word
	loop	.loop2  			; decrement RCX and loop
;
;  Print L.S.Word
;
	mov	al, '.'
	call	CharOut
	call	CharOut
	mov	al, ' '
	call	CharOut
	mov	rbp, [LSWOfst]
	add	rbp, GUARDBYTES
	mov	rax, [rbx+rbp]
	call	PrintHexWord
	mov	al, ' '
	call	CharOut
;
; Next print exponent  word
;
	mov	al, ' '
	call	CharOut
	call	CharOut
        mov     al, 'E'
        call    CharOut				; print E for exponent
        mov     al, ' '				; Print space
        call    CharOut
	mov	rbx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RDX (address)
        mov     rbp, EXP_MSW_OFST		; point to MS Word of exponent
	mov	rax, [rbx+rbp]			; get double word data
        call    PrintHexWord			; print byte in hex
	call	CROut
;
;  increment counter and  loop back
;
	inc	rsi				; Increment handle to next variable
	cmp	rsi, TOPHAND			; shall we do all?
	jle	.loop1
;
;  return, we are done
;
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
.HexTabString:	db	"REG   Hand M.S. Word                                             L.S.W  not guard   Exponent", 00h

;--------------------------------------------------------------
;   Print all variables in HEX format
;
;   Input:  none
;
;   Output: none
;
;--------------------------------------------------------------
PrintHexOld:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
;
; print heading
;
	mov	rax, HexTabString		; print table headings
	call	StrOut
%define ENDIANCHECK
%ifdef ENDIANCHECK
	mov	rax, HexTabString2
	call	StrOut
%endif
	call	CROut
;
	mov	rsi, 0				; point at first variable handle

; loop to here for each register, first print register name

.loop1:
	call	GetVarNameAdd			; RSI (index) --> RAX (address)
	call	StrOut				; Print variable name
;
; next print the mantissa bytes, MSB on left
;
	mov	rdx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RDX (address)
	add	rdx, MAN_MSB_OFST		; Point to address of mantissa MSB
	mov	rcx, 16				; how many bytes to print
.loop2:	mov	al, [rdx]			; get byte
	call	PrintHexByte			; output hex byte
	mov	al, ' '				; print space
	call	CharOut				; output character
	dec	rdx				; point next byte
	loop	.loop2				; decrmenet RCX and loop
;
; Next print exponent with MSB on left;
;
	mov	al, ' '
	call	CharOut
	call	CharOut
	mov	al, 'E'
	call	CharOut				; print E for exponent
	mov	al, ' '				; Print space
	call	CharOut
	mov	rdx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RDX (address)
	add	rdx, EXP_MSB_OFST		; point to MSB of exponent
	mov	rcx, EXP_BSIZE			; counter # bytes in exponent
.loop3:	mov	al, [rdx]			; get data byte
	call	PrintHexByte			; print byte in hex
	mov	al, ' '				; print space
	call	CharOut
	dec	rdx
	loop	.loop3				; decrement EXC and loop

;
; Print word values to check Endian-ness (32_64_CHECK print quad word?)
;
%ifdef ENDIANCHECK
	mov	al, ' '
	call	CharOut
	call	CharOut
	mov	al, '('
	call	CharOut
	mov	rdx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RDX (address)
	add     rdx, MAN_MSW_OFST		; Point to address of mantissa MS Word
	mov     rcx, 2				; how many words to print
.loop4:	mov     rax, [rdx]			; get word
	call    PrintHexWord			; output hex byte
	mov     al, ' '				; print space
	call    CharOut
	sub	rdx, BYTE_PER_WORD		; address next word
	loop	.loop4  			; decrement RCX and loop
;
; Next print exponent  word
;
	mov     al, 'E'
	call    CharOut				; print E for exponent
	mov     al, ' '				; Print space
	call    CharOut
	mov	rdx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RDX (address)
	add     rdx, EXP_MSW_OFST		; point to MS Word of exponent
	mov	rax, [rdx]			; get double word data
	call    PrintHexWord			; print byte in hex
	mov	al, ')'
	call	CharOut
%endif
	call	CROut
;
;  increment counter and  loop back
;
	inc	rsi				; Increment handle to next variable
	cmp	rsi, 8				; shall we do 8?
	jne	.loop1
;
;  return, we are done
;
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
HexTabString:	db	"REG   Mantissa MSByte on Left                           Exponent MSBbyte on Left    ", 00h
HexTabString2:	db	"(64 bit Word for Endian check)", 00h

;
;--------------------------------------------------------------
;   DEBUG - Fill variable with sequential numbers
;
;   MSB = 1 (higher address), then increment value 2, 3, 4  as approach LSB (lower address)
;
;   Input:  RSI = handle of variable
;
;   Output: none
;
;--------------------------------------------------------------
DebugFillVariable:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
;
; first fill exponent
;
	mov	rdx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RDX (address)
	add	rdx, EXP_MSB_OFST		; RDX point to top exponent
	mov	rcx, EXP_BSIZE			; Size in bytes of exponent
	mov	al, 1				; value to insert
.loop1:	mov	[rdx], al			; insert value
	inc	al
	dec	rdx
	loop	.loop1				; decrement RCX and loop
;
; fill mantissa
;
	mov	rdx, [RegAddTable+rsi*WSCALE]	; RSI (index) --> RDX (address)
	add	rdx, MAN_MSB_OFST		; add mantissa size
	mov	rcx, MAN_BSIZE
	mov	al, 010h			; value to insert
.loop2:	mov	byte [rdx], al			; insert value
	inc	al
	dec	rdx
	loop	.loop2				; decrement RCX and loop
;-------------------------------SET SIGN BIT---------------
	mov	rdx, [RegAddTable+rsi*WSCALE] ; RSI (index) --> RDX (address)
	mov	rax, [rdx+MAN_MSW_OFST]
	rcl	rax, 1
	stc
	rcr	rax, 1
;	mov	[rdx+MAN_MSW_OFST], rax
;-------------------------------SET SIGN BIT---------------

	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret

;
;--------------------------------------------------------------
;
;   EndianCheck - Check for Little Endianess
;
;   Input:  none
;
;   Output: none
;
;--------------------------------------------------------------
EndianCheck:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi

	mov	rax, .endian_word_msg0
	call	StrOut
	mov	rax, [.endian_word]
	call	PrintHexWord
	call	CROut

	mov	rax, .endian_word_msg1
	call	StrOut
	mov	al, [.endian_word]
	call	PrintHexByte

	mov	rax, .endian_word_msg2
	call	StrOut
	mov	al, [.endian_word+1]
	call	PrintHexByte

	mov	rax, .endian_word_msg8
	call	StrOut
	mov	al, [.endian_word+7]
	call	PrintHexByte

	call	CROut

	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
.endian_word:
	DQ	0x0807060504030201
.endian_word_msg0:
	db	"Check for Little Endian", 0xD, 0xA
	db	"QWord: [mem]=0x", 0
.endian_word_msg1:
	db	"Byte: [mem]=0x", 0
.endian_word_msg2:
	db	"  [mem+1]=0x", 0
.endian_word_msg8:
	db	"  [mem+7]=0x", 0
;------------------------
; math-debug.asm - EOF
;------------------------
