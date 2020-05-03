%define PARSER
%include "var_header.inc"		; Header has global variable definitions for other modules
%include "func_header.inc"		; Header has global function definitions for other modules
;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; COMMAND PARSER MODULE MODULE
; This module contains command processing routines
;
; File:   parser.asm
; Module: parser.asm, parser.o
; Exec:   calc-pi
;
; Created:    10/15/2014
; Last Edit:  05/03/2020
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
; ParseCmd
; PrintCommandList
;-------------------------------------------------------------

SECTION         .data	align=8   ; Section containing initialized data
;
;---------------------------------------------------------------------
;
;  Command Table
;
;  8 character command for up to 7 character command zero terminated
;
;  64 bit QWord address pointer
;
;---------------------------------------------------------------------
;
Command_Table:
	db	".", 0, 0, 0, 0, 0, 0, 0
	dq	Command_print
	db	" ", 0, 0, 0, 0, 0, 0, 0
	dq	Command_vars
	db	'+', 0, 0, 0, 0, 0, 0, 0
	dq	Command_plus_symbol
	db	'-', 0, 0, 0, 0, 0, 0, 0
	dq	Command_minus_symbol
	db	'*', 0, 0, 0, 0, 0, 0, 0
	dq	Command_star_symbol
	db	'/', 0, 0, 0, 0, 0, 0, 0
	dq	Command_slash_symbol
	db	"c.e", 0, 0, 0, 0, 0
	dq	Command_c_e
	db	"c.ln2", 0, 0, 0
	dq	Command_c_ln2
	db	"c.gr", 0, 0, 0, 0
	dq	Command_c_gr
	db	"c.pi", 0, 0, 0, 0
	dq	Command_c_pi_ch
	db	"c.pi.ch", 0
	dq	Command_c_pi_ch
	db	"c.pi.ra", 0
	dq	Command_c_pi_ra
	db	"c.pi.st", 0
	dq	Command_c_pi_st
	db	"c.pi.ze", 0
	dq	Command_c_pi_ze
 	db	"c.pi.mc", 0
	dq	Command_c_pi_mc
	db	"c.sr2", 0, 0, 0
	dq	Command_c_sr2
	db	"chs", 0, 0, 0, 0, 0
	dq	Command_chs
	db	"clrall", 0, 0
	dq	Command_clrall
	db	"clrreg", 0, 0
	dq	Command_clrreg
	db	"clrstk", 0, 0
	dq	Command_clrstk
	db	"clrx", 0, 0, 0, 0
	dq	Command_clrx
	db	"cmdlist", 0
	dq	Command_cmdlist
	db	"comment", 0
	dq	Command_comment
	db	"D.comp", 0, 0
	dq	Command_D.comp
	db	"D.endi", 0, 0
	dq	Command_D.endi
	db	"D.fill", 0, 0
	dq	Command_D.fill
	db	"D.flag", 0, 0
	dq	Command_D.flag
	db	"D.init", 0, 0
	dq	Command_D.init
	db	"D.ofst", 0, 0
	dq	Command_D.ofst
	db	"desc", 0, 0, 0, 0
	dq	Command_desc
	db	"descnew", 0
	dq	Command_descnew
	db	"enter", 0, 0, 0
	dq	Command_enter
	db	"exit", 0, 0, 0, 0
	dq	Command_exit
	db	"f.asin", 0, 0
	dq	Command_f_asin
	db	"f.cos", 0, 0, 0
	dq	Command_f_cos
	db	"f.exp", 0, 0, 0
	dq	Command_f_exp
	db	"f.ipwr", 0, 0
	dq	Command_f_ipwr
	db	"f.ln", 0, 0, 0, 0
	dq	Command_f_ln_is
	db	"f.ln.rg", 0
	dq	Command_f_ln_rg
	db	"f.ln.is", 0
	dq	Command_f_ln_is
	db	"f.nroot", 0
	dq	Command_f_nroot
	db	"f.sin", 0, 0, 0
	dq	Command_f_sin
	db	"f.zeta", 0, 0
	dq	Command_f_zeta
	db	"fix", 0, 0, 0, 0, 0
	dq	Command_fix
	db	"head", 0, 0, 0, 0
	dq	Command_head
	db	"headoff", 0
	dq	Command_headoff
	db	"help", 0, 0, 0, 0
	dq	Command_help
	db	"helpall", 0
	dq	Command_help_all
	db	"hex", 0, 0, 0, 0, 0
	dq	Command_hex
	db	"int", 0, 0, 0, 0, 0
	dq	Command_int
	db	"load", 0, 0, 0, 0
	dq	Command_load
	db	"log", 0, 0, 0, 0, 0
	dq	Command_log
	db	"logoff", 0, 0
	dq	Command_logoff
	db	"mmode", 0, 0, 0
	dq	Command_mmode
	db	"mobile", 0, 0
	dq	Command_mobile
	db	"normal", 0, 0
	dq	Command_normal
%IFDEF PROFILE
	db	"profile", 0
	dq	Command_profile
%ENDIF
	db	"print", 0, 0, 0
	dq	Command_print
	db	"q", 0, 0, 0, 0, 0, 0, 0
	dq	Command_exit
	db	"quiet", 0, 0, 0
	dq	Command_quiet
	db	"rcl", 0, 0, 0, 0, 0
	dq	Command_rcl
	db	"rdown", 0, 0, 0
	dq	Command_rdown
	db	"recip", 0, 0, 0
	dq	Command_recip
	db	"rup", 0, 0, 0, 0, 0
	dq	Command_rup
	db	"sand", 0, 0, 0, 0
	dq	Command_sand
	db	"sandbox", 0
	dq	Command_sandbox
	db	"save", 0, 0, 0, 0
	dq	Command_save
	db	"sci", 0, 0, 0, 0, 0
	dq	Command_sci
	db	"sf", 0, 0, 0, 0, 0, 0
	dq	Command_sigfigs
	db	"show", 0, 0, 0, 0
	dq	Command_show
	db	"showoff", 0
	dq	Command_showoff
	db	"sigfigs", 0
	dq	Command_sigfigs
	db	"slimit", 0, 0
	dq	Command_slimit
	db	"sstep", 0, 0, 0
	dq	Command_sstep
	db	"stack", 0, 0, 0
	dq	Command_stack
	db	"sto", 0, 0, 0, 0, 0
	dq	Command_sto
	db	"vars", 0, 0, 0, 0
	dq	Command_vars
	db	"verbose", 0
	dq	Command_verbose
	db	"xonly", 0, 0, 0
	dq	Command_xonly
	db	"xy", 0, 0, 0, 0, 0, 0
	dq	Command_exchange_xy
Command_Table_End:
	db	0, 0, 0, 0, 0, 0, 0, 0
	dq	0				; End of list


TimeStr:
	db	"(Elapsed time: ", 0
TimeStr2:
	db	" Seconds ", 0
SP_Moving:
	db	0xD, 0xA, "     Warning: Stack Pointer Moving: ", 0
ACC_Error:
	db	0xD, 0xA, "     Warning: [No_Word] not equal [D_Flt_Word]", 0xD, 0xA, 0

PromptStr:
;	db	0x7				; bell character
	db	" Op Code: ", 0

DoneMsg:
	db	"     Done", 00H
OpCodeErrStr:
	db	"     Input Error: Illegal Op Code. (Type: help or cmdlist)", 0xD, 0xA, 00H


SECTION         .bss    ; Section containing uninitialized data

SECTION         .text   ; Section containing code

;-----------------------------------------------------------------------------
;
;    C O M M A N D   P A R S E R
;
;    Input: none
;
;    Output: none
;
;-----------------------------------------------------------------------------
ParseCmd:
;
;  Debug: Check for memory leak
;
	mov	rax, [StackPtrSnapshot]
	or	rax, rax
	jnz	.SP_check_initialized
	mov	[StackPtrSnapshot], rsp		; Saved only at first run
.SP_check_initialized:
	mov	rax, [StackPtrSnapshot]
	cmp	rax, rsp
	je	.Stack_OK
	mov	rax, SP_Moving
	call	StrOut
	mov	rax, RSP
	call	PrintHexWord
	call	CROut
.Stack_OK:
;
; Check accuracy
;
	mov	rax, [No_Word]
	cmp	rax, [D_Flt_Word]
	je	.Acc_OK
	mov	rax, ACC_Error
	call	StrOut
.Acc_OK:
;
; Update header at top of screen
;
;;;;	call 	Header_Update
;
; Command Parser issue prompt strings
;
	call	CROut
;
; Elapsed timer display
;
	mov	rax, TimeStr
	call	StrOut
	call	ReadSysTime			; Read system clock in seconds in RAX
	mov	[CalcSTime], rax		; Save end of calculation time
	SUB	rax, [StartSTime]
	call	PrintWordB10			; Print seconds as integer
	push	rax
	mov	rax, TimeStr2			; Message 'Sec)'
	call	StrOut
	pop	rax
	call	PrintDDHHMMSS			; Print elapsed time
	mov	al, ')'
	call	CharOut
	mov	rax, PromptStr
	call	StrOut				; Print command Prompt
	call	KeyIn				; Get command string, RAX is buffer address
	push	rax
	call	CheckEchoing			; Are we echoing to file?
	or	rax, rax			; 1 = yes 0 = no
	jz	.NoEcho
	pop	rax
	push	rax
	call	StrOut
	call	CROut
.NoEcho:
	call	CROut
	pop	rax
;
; Start elapsed timer
;
	push	rax
	call	ReadSysTime			; Read system clock in seconds in RAX
	mov	[StartSTime], rax 		; Initialize System time as Calc start time
	mov	rax, 0
	mov	[iCounter01], rax
	mov	[iCounter02], rax
	mov	[iCounter03], rax
	mov	[iCounter04], rax
	mov	[iCounter05], rax
	pop	rax
;
;...............................................
;
;   (number)  - input
;
;...............................................
	;
	; Assume number start with '+' or '-' or '.' or digit '0' to '9'
	;
	; Case of '+' or '-' or '.' followed by 0x00 (string length = 1)
	; In this case, it must be addition, subtraction or print command
	;
	; check 16 bit word  '+' + 00
	cmp	[rax], word 0x002b
	je	.not_number
	; check 16 bit word  '-' + 00
	cmp	[rax], word 0x002D
	je	.not_number
	; check 16 bit word  '.' + 00
	cmp	[rax], word 0x002E
	je	.not_number
	; check 16 bit word  ' ' + 00
	cmp	[rax], word 0x0020
	je	.not_number
	;
	; Next, accept '+' or '-' as start of number
	;
	cmp	[rax], byte '+'
	je	.is_numeric
	cmp	[rax], byte '-'
	je	.is_numeric
	cmp	[rax], byte '.'
	je	.is_numeric
	cmp	[rax], byte ' '
	je	.is_numeric

	cmp	[rax], byte '0'	 		; Check first character of command
	jl	.not_number			; less than 0? then skip
	cmp	[rax], byte '9'			; greater than 9? then skip
	jg	.not_number
;
; It must be a number, convert it.
;
.is_numeric:
	; call	IntegerInput			; call input routine with RAX is buffer addresss

	call	FP_Input
	jnc	.no_input_error			; CF = 1 on error
	;
	; Error Message
	mov	rax, .message_input_error
	call	StrOut
	call	Header_Update
	ret
;
.no_input_error:
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
	call	PrintResult
	ret

.message_input_error:
	; red text
	db	27, "[31m"
	db	" Error converting string to floating point number, stack not rotated.",0xD, 0xA
	; clear red text
	db	27, "[0m", 0

.not_number:

;--------------------------------------------------------------------------------------------
;
; Parse commands from structured command table (RAX = index to null terminated command string
;
;--------------------------------------------------------------------------------------------
;
; Check alignment of command table (could be entry/code error)
;
	mov	rbx, Command_Table_End		; Check for byte alignment
	and	rbx, 0x07			; Should be zero
	jz	.Com_Tab_OK
	mov	rax, .Command_Error2
	call	StrOut
	mov	rax, 0
	jmp	FatalError
.Com_Tab_OK:
	mov	rbx, Command_Table		; Table Address
;
; Loop here for next command word check
;
.Com_Tab_Loop1:
	cmp	byte [rbx], 0			; Check for past last command in table
	je	.Com_Tab_Not_Found		; Zero marker found, end of command table
	mov	rbp, 0
;
; Loop here for next character check
;
.Com_Tab_Loop2:
	mov	DL, [rax+rbp]
	cmp	byte [rbx+rbp], DL
	jne	.Com_Tab_Next
	inc	rbp				; next character compare
	cmp	rbp, 8				; Only 7 char + zero allowed
	jne	.Com_Tab_Skip1			; 8 Found is fatal error in table
	mov	rax, .Command_Error1
	call	StrOut
	mov	rax, 0
	call	FatalError
.Com_Tab_Skip1:
	cmp	byte [rbx+rbp], 0		; No more characters?
	jne	.Com_Tab_Loop2			; Not zero, more to check
	cmp	byte [rax+rbp], 0		; Else was zero, see if command 0 or space
	je	.Com_Tab_MatchNoArg		; Command also ended zero, its a match
	cmp	byte [rax+rbp], ' '		; Space character allowed
	je	.Com_Tab_MatchWithArg		; Command trailing space, expect
	jmp	.Com_Tab_Next			; Not match zero or space on next char
.Com_Tab_MatchNoArg:
	mov	rax, 0				; No argument
	jmp	[rbx+BYTE_PER_WORD]
.Com_Tab_MatchWithArg:
	inc	rbp				; Ponint past space
	cmp	byte[rax+rbp], 0		; end of string? expect argument
	je	.Com_Tab_MatchNoArg		; Error ends after space, don't point string
	add	rax, rbp			; RAX point at argument characters
	jmp	[rbx+BYTE_PER_WORD]

.Com_Tab_Next:
	add	rbx, (BYTE_PER_WORD * 2)	; Point to next command
	jmp	.Com_Tab_Loop1
.Command_Error1:
	db	"Command Parser Error: zero end marker not found in text table", 0xD, 0xA, 0
.Command_Error2:
	db	"Command Parser Error: End of command table not QWord aligned, probably table error", 0xD, 0xA, 0
.red_text:
	db	27, "[31m", 0
.red_cancel:
	db	27, "[0m", 0
.Com_Tab_Not_Found:
		; Set text color red for error
	mov	rax, .red_text
	call	StrOut
		; Print error message
	mov	rax, OpCodeErrStr		; Error message for Illegal op coce
	call	StrOut;
		; Cancel red color
	mov	rax, .red_cancel
	call	StrOut
	ret

;
Command_plus_symbol:
	mov	rsi, HAND_XREG
	mov	rdi, HAND_ACC
	call	CopyVariable
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_OPR
	call	CopyVariable
;
	call	FP_Addition			; Add X = Y + X

	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
	mov	rsi, HAND_TREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	mov	rsi, HAND_TREG
	call	ClearVariable
;
	call	PrintResult
	ret
;
;
;
Command_minus_symbol:
	mov	rsi, HAND_XREG
	mov	rdi, HAND_ACC
	call	CopyVariable
;
	mov	rsi, HAND_ACC
	call	FP_TwosCompliment
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_OPR
	call	CopyVariable
;
	call	FP_Addition			; Subtract X = Y + (0-X)

	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
	mov	rsi, HAND_TREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	mov	rsi, HAND_TREG
	call	ClearVariable
;
	call	PrintResult
	ret
;
;
;
Command_star_symbol:
	mov	rsi, HAND_XREG
	mov	rdi, HAND_ACC
	call	CopyVariable
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_OPR
	call	CopyVariable
;
	call	FP_Multiplication		; Multiply X = Y * X

	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
	mov	rsi, HAND_TREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	mov	rsi, HAND_TREG
	call	ClearVariable
;
	call	PrintResult
	ret
;
;
;
Command_slash_symbol:
	mov	rsi, HAND_XREG
	mov	rdi, HAND_ACC
	call	CopyVariable
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_OPR
	call	CopyVariable
;
	call	FP_Division			; Divide X = Y / X
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
	mov	rsi, HAND_TREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	mov	rsi, HAND_TREG
	call	ClearVariable
;
	call	PrintResult
	ret
;
;
;
Command_c_e:
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
	or	rax, rax			; Check for argument
	jz	.no_arg				; No argument use default method
	cmp	[rax], byte '1'			; 1 use fix point
	je	.arg_1
	cmp	[rax], byte '2'			; 2 use register method
	je	.arg_2
	cmp	[rax], byte '3'			; 3 use full floating point
	je	.arg_3
	cmp	[rax], byte '4'			; 4 use function exp(1)
	je	.arg_4
.no_arg:
.arg_1:
	call	Function_calc_e_Fix		; fixed (non-normalized) method
	call	CROut
	call	PrintResult
	ret
.arg_2:
	call	Function_calc_e_Reg		; Register division
	call	CROut
	call	PrintResult
	ret
.arg_3:
	call	Function_calc_e_FP		; Full floating point
	call	CROut
	call	PrintResult
	ret
.arg_4:
	mov	rax, .calcestr			; get message
	call 	StrOut
	mov	rsi, HAND_XREG			; set XReg = 1
	call	SetToOne
	call	Function_exp_x			; calc exp(xreg)  ... exp(1)
	call	PrintResult
	ret
.calcestr:
	db	"Function_exp_x: Calculating e using function exp(XReg) with XReg=1", 0xD, 0XA, 0xA, 0
;
;
;
Command_c_ln2:
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
	call	Function_calc_ln2
	call	CROut
	call	PrintResult
	ret
;
;
;
Command_c_pi_st:
	mov	rbx, rax				; Save Argument
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
;
; Arguments to c.pi.st
;	(no argument) - calculate pi to Stormer method
;	1 - calculate first term to pi-st-1.num
;	2 - calculate first term to pi-st-2.num
;	3 - calculate first term to pi-st-3.num
;	4 - calculate first term to pi-st-4.num
;       1234 - Combine all 4 filnames, sum the results as pi
;
	mov	rax, rbx			; Restore RAX
	or	rax, rax			; Check RAX for valid argument
	jz	.No_arg				; RAX = zero, no argument found
	cmp	byte [rax], '1' 		; Check first character of command
	jl	.Not_num			; less than 0? then skip
	cmp	byte [rax], '4'			; greater than 9? then skip
	jg	.Not_num
	call	IntWordInput			; RAX in binary 64 bit data
	jmp	.pi_st_w_num			; cotinue to Stormer method RAX = argument
.Not_num:
.No_arg:
.pi_st: ; ****** case of Stormer method
	mov	rax, 0				; Case of no argument, use 0
						; Stormer codes with RAX = 0 perform all 4 arctan series
						; RAX = 1,2,3,4 perform each arctan sum separately
.pi_st_w_num:
	call	Function_calc_pi_sto		; Calculate Pi Stormer formula
	call	CROut
	call	PrintResult
	ret
;
;
;
Command_c_pi_ch: ; ****** case of Chudnovsky Formula
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
	;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
	;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable

	mov	rax, .pi_ch_str			; Description line
	call	StrOut
	mov	rsi, HAND_XREG			; Place 10005 in XReg
	mov	rax, 10005
	call	FP_Load64BitNumber		; X-Reg = 10005
	mov	rax, 2				; for 2 root (square root)
	call	Function_nth_root_x		; Calculate nth root (N in RAX, A in ACC)

	call	Function_calc_pi_chud		; Calculate Pi Ramanujan formula
	call	CROut
	call	PrintResult
	ret
.pi_ch_str:
	db "Functon_calc_pi_chud: Calculation of pi using Chudnovsky formula.", 0xD, 0xA
	db "Calculation square root 10005", 0xD, 0xA, 0
;
;
;
Command_c_pi_ra: ; ****** case of Ramanujan Formula
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
	;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
	;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable

	mov	rax, .pi_ra_str			; Description line
	call	StrOut
	call	Function_calc_sr2		; First calculate SR 2
	call	Function_calc_pi_ram		; Calculate Pi Ramanujan formula
	call	CROut
	call	PrintResult
	ret
.pi_ra_str:	db "Functon_calc_pi_ram: Calculation of pi using Ramanujan formula.", 0xD, 0xA, 0xA, 0
;
;
;
Command_c_pi_ze: ; ****** case of zeta2 sum 1/n^2 = (pi^2)/6
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
	;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
	;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable

	mov	rax, .pi_ze_str			; Description line
	call	StrOut
	call	Function_calc_pi_zeta2
	call	CROut
	call	PrintResult
	ret
.pi_ze_str:
	db "Functon_calc_pi_zeta: Calculation of pi using zeta(2)", 0xD, 0xA, 0xA, 0
;
;
;
Command_c_pi_mc:
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
	;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
	;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable

		; ****** case of Monte Carlo statistical method
	mov	rax, .pi_mc_str			; Description line
	call	StrOut
	call	Function_calc_pi_monte_carlo
	call	CROut
	call	PrintResult
	ret
.pi_mc_str:	db "Functon_calc_pi_monte_carlo: Monte Carlo method for pi.", 0xD, 0xA, 0xA, 0
;
;
;
Command_c_sr2:
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
;	mov	rax, 2				; A = 2 for N root of A
;	mov	rsi, HAND_XREG
;	call	FP_Load64BitNumber		; X-Reg = 2.00000...
;	mov	rax, 2				; N = 2 for N root of A
;	call	Function_nth_root_x		; Calculate SQRT(2) into X-Reg

	call	Function_calc_sr2

	call	CROut
	call	PrintResult
	ret
;
; Golden Ratio = (1 + sqrt(5)) / 2
;
Command_c_gr:
	mov	rax, .gr_str
	call	StrOut

	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
	;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
	;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable
	;
	mov	rax, 5				; A = 5 for N root of A
	mov	rsi, HAND_XREG
	call	FP_Load64BitNumber		; X-Reg = 2.00000...
	mov	rax, 2				; N = 2 for N root of A
	call	Function_nth_root_x		; Calculate SQRT(2) into X-Reg
	;
		; Add 1
	mov	rsi, HAND_XREG
	mov	rdi, HAND_ACC
	call	CopyVariable

	mov	rax, 1
	mov	rsi, HAND_OPR
	call	FP_Load64BitNumber
	call	FP_Addition
	;
		; Divide by 2
	;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_OPR
	call	CopyVariable

	mov	rax, 2
	mov	rsi, HAND_ACC
	call	FP_Load64BitNumber
	call	FP_Division

	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable

	call	CROut
	call	PrintResult
	ret
.gr_str:
	db "Calculate Golden Ratio.", 0xD, 0xA, 0

;
;
;
Command_chs:
	mov	rsi, HAND_XREG
	call	FP_TwosCompliment
	call	PrintResult
	ret
;
;
;
Command_clrall:
	mov	rsi, HAND_ACC
.loop:
	call	ClearVariable
	inc	rsi
	cmp	rsi, TOPHAND
	jle	.loop
	mov	rax, .Msg
	call	StrOut
	call	PrintResult
	ret
.Msg:	db	"All Varaibles Cleared.", 0xD, 0xA, 0xA, 0
;
;
;
Command_clrreg:
	mov	rsi, HAND_REG0
.loop:
	call	ClearVariable
	inc	rsi
	cmp	rsi, TOPHAND
	jle	.loop
	mov	rax, .Msg
	call	StrOut
	call	PrintResult
	ret
.Msg:	db	"Registers Reg0 and greater Cleared.", 0xD, 0xA, 0xA, 0
;
;
;
Command_clrstk:
	mov	rsi, HAND_XREG
	call	ClearVariable
	mov	rsi, HAND_YREG
	call	ClearVariable
	mov	rsi, HAND_ZREG
	call	ClearVariable
	mov	rsi, HAND_TREG
	call	ClearVariable
	call	CROut
	call	PrintResult
	ret
;
;
;
Command_clrx:
	mov	rsi, HAND_XREG
	call	ClearVariable
	call	CROut
	call	PrintResult
	ret
;
;
;
Command_cmdlist:
	cmp	rax, 0				; is there a search key?
	je	.skip1
	mov	rbx, rax			; point to input string
	mov	al, [rbx]			; Get the character
.skip1:
	push	rax
	mov	rax, .Msg
	call	StrOut
	pop	rax
	call	PrintCommandList		; Call with AL search key
	ret
.Msg:	db	"cmdlist <x> <-- search first letter of command.", 0xD, 0xA
	db	"Command List:", 0xD, 0xA, 0xA, 0
;
;
;
Command_comment:
	or	rax, rax			; Check valid argument
	jnz	.skip1
	mov	rax, .Msg_error
	call	StrOut				; print error message
	ret
.skip1:
	call	StrOut				; Print the comment into console/file output
	call	CROut
	ret
.Msg_error:
	db	"Command Parser: Error, invalid comment argument", 0xD, 0xA
	db	"        Usage: comment <comment string>", 0xD, 0xA, 0
;
;
;
Command_D.comp:
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	Variable_Compare
	ret

;
;
;
Command_D.endi:
	call	EndianCheck
	ret

;
;
;
Command_D.fill:
	or	rax, rax			; Check for argument
	jz	.Error1				; No argument
	cmp	byte [rax], '0' 		; Check first character of command
	jl	.Error1				; less than 0? then skip
	cmp	byte [rax], '9'			; greater than 9? then skip
	jg	.Error1
	call	IntWordInput			; RAX in binary 64 bit data
	cmp	rax, TOPHAND			; Check for highest register
	jg	.Error1
	mov	rsi, rax			; Variable handle number
	call DebugFillVariable			; Execute subroutine
	mov	rax, .Msg1
	call	StrOut
	ret
.Error1:
	mov	rax, .Msg_error
	call	StrOut
	ret
.Msg_error:
	db	"Command Parser: D.Fill argument out of range", 0xD, 0xA
	db	"        Usage: hex <integer> (given variable handle)", 0xD, 0xA, 0
.Msg1:
	db	"Variable filled with incremental byte data", 0xD, 0xA, 0
;
;
;
Command_D.flag:
	or	rax, rax			; Check for argument
	jz	.no_arg				; No argument
	cmp	byte [rax], '0' 		; Check first character of command
	jl	.no_arg				; less than 0? then skip
	cmp	byte [rax], '9'			; greater than 9? then skip
	jg	.no_arg
	call	IntWordInput			; RAX in binary 64 bit data
	mov	[DebugFlag], rax
.no_arg:
	mov	rax, .Msg1
	call	StrOut
	mov	rax, [DebugFlag]
	call	PrintWordB10
	call	CROut
	call	Header_Update
	ret
.Msg1:	db	"Debug Flag = ", 0
;
;
;
Command_D.init:
	call	FP_Initialize
	call	Header_Update
	mov	rax, .Msg
	call	StrOut
	call	PrintResult
	ret
.Msg:	db	"Called FP_Initialize", 0xD, 0xA, 0xA, 0
;
;
;
Command_D.ofst:
;
	mov	rax, .Msg0
	call	StrOut
	mov	rax, [No_Word]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .Msg0a
	call	StrOut
	mov	rax, [D_Flt_Word]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .Msg1
	call	StrOut
	mov	rax, [LSWOfst]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .Msg1a
	call	StrOut
	mov	rax, [D_Flt_LSWO]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .Msg2
	call	StrOut
	mov	rax, MAN_MSW_OFST
	call	PrintWordB10
	call	CROut
;
	mov	rax, .Msg3
	call	StrOut
	mov	rax, EXP_WORD_OFST
	call	PrintWordB10
	call	CROut
;
	mov	rax, .Msg4
	call	StrOut
	mov	rax, [Shift_Count]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .Msg4a
	call	StrOut
	mov	rax, [Last_Shift_Count]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .Msg5
	call	StrOut
	mov	rax, [No_Byte]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .Msg5a
	call	StrOut
	mov	rax, [D_Flt_Byte]
	call	PrintWordB10
	call	CROut
;
	mov	rax, .Msg6
	call	StrOut
	mov	rax, MAN_MSB_OFST
	call	PrintWordB10
	call	CROut
;
	ret

;
.Msg0:		db	"[No_Word]          = ", 0
.Msg0a:		db	"[D_Flt_Word]       = ", 0
.Msg0b:		db	"[D_Flt_Word]       = ", 0
.Msg0c:		db	"[D_Flt_Word]       = ", 0
.Msg1:		db	"[LSWOfst]          = ", 0
.Msg1a:		db	"[D_Flt_LSWO]       = ", 0
.Msg2:		db	"MAN_MSW_OFST       = ", 0
.Msg3:		db	"EXP_WORD_OFST      = ", 0
.Msg4:		db	"Shift_Count        = ", 0
.Msg4a:		db	"Last_Shift_Count   = ", 0
.Msg5:		db	"[No_Byte]          = ", 0
.Msg5a:		db	"[D_Flt_Byte]       = ", 0
.Msg6:		db	"MAN_MSB_OFST       = ", 0

;Shift_Count
;Nearly_Zero
;Last_Shift_Count
;Last_Nearly_Zero
;
;
;
Command_desc:
	mov	rax, .Msg1
	call	StrOut
	mov	rax, Description
	call	StrOut
	call	CROut
	ret
.Msg1:	db	"File Description: ", 0


Command_descnew:
	call	EnterFileDescription
	call	CROut
	mov	rax, .Msg1
	call	StrOut
	mov	rax, Description
	call	StrOut
	call	CROut
	call	Header_Update
	ret
.Msg1:	db	"File Description: ", 0
;
;
;
Command_enter:
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
	call	PrintResult
	ret
;
;
;
Command_exit:
	jmp	ProgramExit			; Exit program
;
;
;
Command_f_asin:
	mov	rax, .Msg1
	call	StrOut
	call	Function_arcsin_x		; Calculate Sin(x))
	call	PrintResult
	ret
.Msg1	db	"Arcsine valid range -1 <= Xreg <= 1 (not checked)", 0xD, 0xA
	db	"Calculation time increases when Xreg near |1|", 0xD, 0xA, 0xA, 0
;
;
;
Command_f_cos:
	call	Function_cos_x			; Calculate Sin(x))
	call	PrintResult
	ret
;
;
;
Command_f_exp:
	call	Function_exp_x
	call	PrintResult
	ret
;
;
;
Command_f_ipwr:
	or	rax, rax			; Check RAX for valid argument
	jz	.Error1				; RAX = zero, no argument found
	cmp	byte [rax], '0' 		; Check first character of command
	jl	.Error1				; less than 0? then skip
	cmp	byte [rax], '9'			; greater than 9? then skip
	jg	.Error1
	call	IntWordInput			; RAX in binary 64 bit data
	call	Function_int_power_x		; Calculate nth root (N in RAX, A in ACC)
	call	CROut
	call	PrintResult
	ret
.Error1:
	mov	rax, .Msg_error
	call	StrOut
	ret
.Msg_error:
	db	0xD, 0xA, "Command Parser: Error, f.ipwr (X-Reg to the integer power) invalid argument.", 0xD, 0xA
	db	"        Usage: f.ipwr <integer>", 0xD, 0xA, 0
;
;
;
Command_f_ln_rg:
	mov	rax, .Msg1
	call	StrOut
	call	Function_ln_x_by_guess
	call	PrintResult
	ret
	.Msg1:	db	"Calc natural log by recursive guesses", 0xD, 0xA, 0
;
;
;
Command_f_ln_is:
	mov	rax, .Msg1
	call	StrOut
	call	Function_ln_x_series
	call	PrintResult
	ret
.Msg1:	db	"Calc natural log by infinite series", 0xD, 0xA, 0
;
;
;
Command_f_nroot:
	or	rax, rax			; Check RAX for valid argument
	jz	.Error1				; RAX = zero, no argument found
	cmp	byte [rax], '0' 		; Check first character of command
	jl	.Error1				; less than 0? then skip
	cmp	byte [rax], '9'			; greater than 9? then skip
	jg	.Error1
	call	IntWordInput			; RAX in binary 64 bit data
	call	Function_nth_root_x		; Calculate nth root (N in RAX, A in ACC)
;
;	push	rax				; then nth root number (2=square root, 3=cube root
;	mov	rax, .Msg_1			; (temporarily set at top of file)
;	call	StrOut
;	pop	rax
;	call	PrintWordB10
;	mov	rax, .Msg_2			; (temporarily set at top of file)
;	call	StrOut
;
	call	CROut
	call	PrintResult
	ret
.Error1:
	mov	rax, .Msg_error
	call	StrOut
	ret
.Msg_1:
	db	0xD, 0xA, 0xA, "Calculated ", 0
.Msg_2:
	db	" root of X-Reg", 0xD, 0xA, 0
.Msg_error:
	db	0xD, 0xA, "Command_nroot: Error, invalid argument." , 0xD , 0xA
	db	"        Usage: nroot <integer>", 0xD, 0xA
	db	"        Calculates integer root of X-Reg", 0xD, 0xA
	db	"        Valid for integers 2 or greater.", 0xD, 0xA, 0
;
;
;
Command_f_sin:
	call	Function_sin_x			; Calculate Sin(x))
	call	PrintResult
	ret
;
;
;
Command_f_zeta:
	or	rax, rax			; Check RAX for valid argument
	jz	.Error1				; RAX = zero, no argument found
	cmp	byte [rax], '0' 		; Check first character of command
	jl	.Error1				; less than 0? then skip
	cmp	byte [rax], '9'			; greater than 9? then skip
	jg	.Error1
	call	IntWordInput			; RAX in binary 64 bit data
	cmp	rax, 2				; Check for < 2 error
	jl	.Error1
	push	rax				; SAVE FOR FUNCTION
;
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
	pop	rax
	call	Function_calc_zeta

	call	CROut
	call	PrintResult
	ret
.Error1:
	mov	rax, .ErrorMsg
	call	StrOut
	ret
.ErrorMsg:
	db	"Error: argument must be integer >= 2." , 0xD , 0xA , 0
;
;
;
Command_fix:
	mov	qword[Out_Mode], 1		; Print with fixed notation
	call	CROut
	call	PrintResult
	call	Header_Update
	ret
;
;
;
Command_head:
	call	Header_Init
	call	Header_Update
	ret
;
;
;
Command_headoff:
	call	Header_Cancel
;;	call	ClrScr
	ret
;
;
;
Command_help:
	call	Help				; Address passed in RAX
	ret
;
;
;
Command_help_all:
	call	PrintAllHelp
	ret
;
;
;
Command_hex:
	or	rax, rax			; Check for argument
	jz	.no_arg				; No argument
	cmp	byte [rax], '0' 		; Check first character of command
	jl	.Error1				; less than 0? then skip
	cmp	byte [rax], '9'			; greater than 9? then skip
	jg	.Error1
	call	IntWordInput			; RAX in binary 64 bit data
	cmp	rax, TOPHAND			; Check for highest register
	jg	.Error1
	mov	rsi, rax			; Variable handle number
	call	PrintVar
	call	CROut
	ret
.no_arg:
	call	PrintHex
	ret
.Error1:
	mov	rax, .Msg_error
	call	StrOut
	ret
.Msg_error:
	db	"Command Parser: hex argument out of range", 0xD, 0xA
	db	"        Usage: hex (without argument shows all registers", 0xD, 0xA
	db	"        Usage: hex <integer> (given variable handle 0-16)", 0xD, 0xA, 0


;
;
;
Command_int:
	mov	qword[Out_Mode], 2		; Print integer format
	call	CROut
	call	PrintResult
	call	Header_Update
	ret
;
;
;
Command_load:
	push	rax				; Save argument pointer
	mov	rsi, HAND_ACC			; Clear ACC for input buffer
	call	ClearVariable			; Call clear variable
	pop	rax				; Restore argument (filename) pointer
	call	LoadVariable			; Load variable into ACC from file
	mov	rax, [FP_Acc+MAN_MSB_OFST]	; M.S.Byte
	or	rax, rax			; Error check, is MSByte zero?
	jnz	.fl_NoErr			; No, non-zero number assumed valid
	mov	rax, .Msg_error1		; message, stack not rotated
	call	StrOut
	call	Header_Update
	ret
.fl_NoErr:
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
;
	call	CROut
	mov	rax, .Msg2
	call	StrOut
;
	call	CROut
	call	PrintResult
;
	call	Header_Update
	ret
.Msg_error1:
	db	0xD, 0xA, "Command Parser: Variable is zero. Assume I/O error. X-Reg preserved, Stack not rotated", 0xD, 0xA, 0
.Msg2:
	db	"Command Parser: File data copied from ACC to X-Reg, stack rolled", 0xD, 0xA, 0
;
;
;
Command_log:
	call	StartEcho
	call	Header_Update
	ret
;
;
;
Command_logoff:
	call	StopEcho
	call	Header_Update
	ret
;
;
;
Command_mmode:
	or	rax, rax			; Check for argument
	jz	.no_arg				; No argument
	cmp	byte [rax], '0' 		; Check first character of command
	jl	.no_arg				; less than 0? then skip
	cmp	byte [rax], '9'			; greater than 9? then skip
	jg	.no_arg
	call	IntWordInput			; RAX in binary 64 bit data
	mov	[MathMode], rax
.no_arg:
	mov	rax, .Msg1
	call	StrOut
	mov	rax, [MathMode]
	call	PrintWordB10
	mov	rax, .Msg1a
	call	StrOut
	mov	al, [MathMode+1]
	call	PrintHexByte
	mov	al, [MathMode]
	call	PrintHexByte
	mov	rax, ')'
	call	CharOut
	call	CROut


	call	CROut
;
	mov	rbx, [MathMode]			; get mode
	mov	rax, .Mode_N1			; bit 0 = 0 i86 word mult
	test	rbx, 1
	jz	.sk01
	mov	rax, .Mode_1			; bit 0 = 1 long mult
.sk01:	call	StrOut

	test	rbx, 4
	jnz	.sk02
	mov	rax, .Mode_N4			; bit 4 = 0 single word mult enabled
	call	StrOut
.sk02:
	mov	rax, .Mode_N2			; bit 2 = 0  normal (reciprocal) division
	test	rbx, 2
	jz	.sk03
	mov	rax, .Mode_2			; bit 1 = 1 long div
.sk03:	call	StrOut

	test	rbx, 0x10			; 0x10 = 1 Disable reciprocal variable accuracy
	jz	.sk10
	mov	rax, .Mode_10
	call	StrOut
.sk10:
	test	rbx, 0x20			; 0x10 = 1 reciprocal with bitwise mult.
	jz	.sk20
	mov	rax, .Mode_20
	call	StrOut
.sk20:
	test	rbx, 8
	jnz	.sk04
	mov	rax, .Mode_N8			; bit 3 = 0 single word div enabled
	call	StrOut
.sk04:
	test	rbx, 0x40
	jz	.sk40
	mov	rax, .Mode_40			; 0x40 = 1 FP_Addition use bitwise alignment
	call	StrOut
.sk40:
	test	rbx, 0x80
	jz	.sk80
	mov	rax, .Mode_80			; 0x80 = 1 FP_Normalization use bitwise alignment
	call	StrOut
.sk80:
	test	rbx, 0x100
	jz	.sk100
	mov	rax, .Mode_100			; 0x100 = 1 disable function ReduceSeriesAccuracy
	call	StrOut
.sk100:
	mov	rax, .Msg2
	call	StrOut
	call	Header_Update
	ret
.Msg1:		db	"   MathMode = ", 0
.Msg1a:		db	" (0x", 0
.Mode_N1:	db	"   Multiplication: 64 bit x86 MUL matrix multiplicaiton", 0xD, 0xA, 0
.Mode_1:	db	"   Multiplication: Binary long multiplication, shift and add bitwise.", 0xD, 0xA, 0
.Mode_N2: 	db	"   Division: Newton-Raphson reciprocal with i86 MUL matrix multiplication", 0xD, 0xA, 0
.Mode_2:	db	"   Division: Binary long division, subtraction and rotate bitwise", 0xD, 0xA, 0
.Mode_N4:	db	"      Enable: Single word x86 MUL register multiplication where possible", 0xD, 0xA, 0
.Mode_N8:	db	"      Enable: Single word x86 DIV register division where possible", 0xD, 0xA, 0
.Mode_10:	db	"      Disable: Reciprocal variable accuracy (used in FP_Division).", 0xD, 0xA, 0
.Mode_20:	db	"      Disable: Reciprocal 64bit word mult (used in FP_Division).", 0xD, 0xA, 0
.Mode_40:	db	"   Addition: Force bitwise alignment", 0xD, 0xA, 0
.Mode_80:	db	"   Normalize: Force bitwise alignment", 0xD, 0xA, 0
.Mode_100:	db	"   Summation: Function ReduceSeriesAccuracy is disabled", 0xD, 0xA, 0
.Msg2:		db	0xD, 0xA, "   So see list of modes type: help mmode", 0xD, 0xA, 0
;
;
;
Command_mobile:
	mov	rax, 0x30
	mov	[iVerboseFlags], rax		; 1 = print loop updates
	mov	rax, 0xF700CCCC
	mov	[iShowCalcMask], rax
	ret
;
;
;
SetNormal:		; <--- Global command
Command_normal:
	push	rax
	mov	rax, 0x30
	mov	[iVerboseFlags], rax		; 1 = print loop updates
	mov	rax, 0xFFFFFFFF
	mov	[iShowCalcMask], rax
	pop	rax
	ret
;
;
;
Command_print:
	or	rax, rax			; Check for argument
	jz	.no_arg				; No argument
	cmp	[rax], byte 's'			; s for short lines
	jne	.not_dots
	mov	rsi, HAND_XREG			; Handle number X-Reg
	mov	rdi, HAND_ACC			; Handle number ACC (for printing)
	call	CopyVariable			; Move RegX to Acc
	mov	qword [OutCountActive], 0x2+0x1
	call	PrintVariable			; Convert base 10 and print
	call	CROut
	ret
.not_dots:
	cmp	[rax], byte 'u'			; u = unformatted
	jne	.not_dotu
	mov	rsi, HAND_XREG			; Handle number X-Reg
	mov	rdi, HAND_ACC			; Handle number ACC (for printing)
	call	CopyVariable			; Move RegX to Acc
	mov	qword [OutCountActive], 0
	call	PrintVariable			; Convert base 10 and print
	call	CROut
	ret
.not_dotu:
	cmp	[rax], byte 'f'			; u = unformatted
	jne	.not_dotf
	mov	rsi, HAND_XREG			; Handle number X-Reg
	mov	rdi, HAND_ACC			; Handle number ACC (for printing)
	call	CopyVariable			; Move RegX to Acc
	mov	qword [OutCountActive], 1	; Formatted
	call	PrintVariable			; Convert base 10 and print
	call	CROut
	ret
.not_dotf:
	cmp	[rax], byte 'q'			; q = quiet, stop console echo
	jne	.no_arg
	mov	rsi, HAND_XREG			; Handle number X-Reg
	mov	rdi, HAND_ACC			; Handle number ACC (for printing)
	call	CopyVariable			; Move RegX to Acc

	mov	qword [OutCountActive], 1
	mov	qword [ConInhibit], 1		; Inhibit console characters
	call	PrintVariable			; Convert base 10 and print
	mov	rax, 0
	mov	[ConInhibit], rax		; Restore console output
	ret
.no_arg:
	mov	rsi, HAND_XREG			; Handle number X-Reg
	mov	rdi, HAND_ACC			; Handle number ACC (for printing)
	call	CopyVariable			; Move RegX to Acc
	mov	qword [OutCountActive], 0	; Default - unformatted
	call	PrintVariable			; Convert base 10 and print
	call	CROut
	ret
;
;
;
;
;
;
%IFDEF PROFILE
Command_profile:
	or	rax, rax			; Is there argument?
	jz	.no_arg				; No argument
	cmp	[rax], byte 'i'			; i = initialize profile
	jne	.no_arg
	call	Profile_Init			; Initialize profile counters
	mov	rax, .Msg1
	call	StrOut
.no_arg:
	call	Profile_Show_Always
	ret
.Msg1:	db	0xD, 0xA, "Profile counters initialized", 0xD, 0xA, 0
%ENDIF  ;IFDEF PROFILE
Command_quiet:
	mov	rax, 0
	mov	[iVerboseFlags], rax
	mov	rax, 0xFFFFFFFF
	mov	[iShowCalcMask], rax
	mov	rax, .Msg
	call	StrOut
	ret
.Msg:	db	"Set Quiet", 0xD, 0xA, 0
;
;
;
Command_rcl:
	or	rax, rax			; Check for valid argument
	jnz	.arg_present
.Error1:
	mov	rax, .Msg_error
	call	StrOut
	ret
.arg_present:
	cmp	byte [rax], '0' 		; Check first character of command
	jl	.Error1				; less than 0? then skip
	cmp	byte [rax], '9'			; greater than 9? then skip
	jg	.Error1
	call	IntWordInput			; RAX in binary 64 bit data
	cmp	rax, (TOPHAND-HAND_REG0)
	jg	.Error1
;
	push	rax
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable
	pop	rax

	mov	rsi, rax			; Get register number starting 0
	add	rsi, HAND_REG0			; Add lowest handle
	mov	rdi, HAND_XREG
	call	CopyVariable
	call	PrintResult
	ret
.Msg_error:
	db	"Command Parser: Invalid argument for rcl (recall register).", 0xD, 0xA
	db	"        Usage: rcl <integer>  (enter register number 0-7)", 0xD, 0xA, 0
;
;
;
Command_recip:
	mov	rsi, HAND_XREG
	mov	rdi, HAND_ACC
	call	CopyVariable
;
	call	FP_Reciprocal
;
	mov	rsi, HAND_ACC
	mov	rdi, HAND_XREG
	call	CopyVariable
	call	CROut
	call	PrintResult
	ret
;
;
;
Command_rdown:
	mov	rsi, HAND_TREG
	mov	rdi, HAND_WORKB
	call	CopyVariable
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_TREG
	call	CopyVariable
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_XREG
	call	CopyVariable
;
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
	mov	rsi, HAND_WORKB
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	call	PrintResult
	ret
;
;
;
Command_rup:
	mov	rsi, HAND_TREG
	mov	rdi, HAND_WORKB
	call	CopyVariable
;
	mov	rsi, HAND_ZREG
	mov	rdi, HAND_TREG
	call	CopyVariable
;
	mov	rsi, HAND_YREG
	mov	rdi, HAND_ZREG
	call	CopyVariable
;
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	CopyVariable
;
	mov	rsi, HAND_WORKB
	mov	rdi, HAND_XREG
	call	CopyVariable
;
	call	PrintResult
	ret
;
;
;
Command_sci:
	mov	qword [Out_Mode], 0
	call	CROut
	call	PrintResult
	call	Header_Update
	ret
;
;
;
Command_show:
	mov	qword[iShowCalc], 1
	call	Header_Update
	mov	rax, .msg1
	call	StrOut
	mov	rax, [iShowCalcStep]
	call	PrintWordB10
	call	CROut
	ret
.msg1:	db	"Show Progress: On, Step = ", 0
;
;
;
Command_showoff:
	mov	qword[iShowCalc], 0
	call	Header_Update
	mov	rax, .msg1
	call	StrOut
	ret
.msg1:	db	"Show Progress: Off", 0xD, 0xA, 0
;
;
;
Command_sand:
	call	Sand
	call	CROut
;;;	call	PrintResult
	ret
;
;
;
Command_sandbox:
	or	rax, rax			; Check for argument
	jz	.no_arg				; No argument
	cmp	byte [rax], '0' 		; Check first character of command
	jl	.no_arg				; less than 0? then skip
	cmp	byte [rax], '9'			; greater than 9? then skip
	jg	.no_arg
	call	IntWordInput			; RAX in binary 64 bit data
.no_arg:
	call	SandBox				; If argument present, it will be 64 bit value in RAX
	call	CROut
	call	PrintResult

	ret
;
;
;
Command_save:
	call	SaveVariable
	ret
;
;
;
;
Command_sigfigs:
	or	rax, rax			; Is argument present?
	jnz	.has_arg
	call	PrintAccuracy			; Print accuracy number to output
;	call	PrintAccVerbose			; Print accuracy number to output
	call	Header_Update
	ret
.has_arg:
	cmp	[rax], byte 'v'			; Verbose
	jne	.skip_sf1			; No, other accuracy commands?
	call	PrintAccVerbose			; Print accuracy information to output
	call	Header_Update
	ret
.skip_sf1:
	cmp	[rax], byte 'x'			; Set Maximum Accuracy
	jne	.skip_sf2			; No, other accuracy commands?
	call	SetMaximumAccuracy		; Set all accuracy variables to maximum
	call	PrintAccVerbose			; Print accuracy information to output
	call	Header_Update
	ret
.skip_sf2:
	cmp	[rax], byte 'e'			; Input extended digits
	jne	.skip_sf3			; No, other accuracy commands?
	cmp	[rax+1], byte ' '		; Space character
	jne	.Error1				; Error, space expected
	cmp	[rax+2], byte '0' 		; Check first character of command
	jl	.Error1	 			; less than 0? then skip
	cmp	[rax+2], byte '9'		; greater than 9? then skip
	jg	.Error1
	add	rax, 2				; increment for 2  command letters
	call	IntWordInput			; RAX in binary 64 bit data
	call 	SetExtendedDigits		; Set digits to value in RAX
	call	PrintAccVerbose			; Print accuracy information to output
	call	Header_Update
	ret
.skip_sf3:
	cmp	[rax], byte 'w'			; Input number of words
	jne	.skip_sf4			; No, other accuracy commands?
	cmp	[rax+1], byte ' '		; Space character
	jne	.Error1				; Error, space expected
	cmp	[rax+2], byte '0' 		; Check first character of command
	jl	.Error1				; less than 0? then skip
	cmp	[rax+2], byte '9'		; greater than 9? then skip
	jg	.Error1
	add	rax, 2				; increment for 2  command letters
	call	IntWordInput			; RAX in binary 64 bit data
	call 	SetWordAccuracy			; Set digits to value in RAX
	call	PrintAccVerbose			; Print accuracy information to output
	call	Header_Update
	ret
.skip_sf4:
	cmp	[rax], byte 'K'			; Input number of words
	jne	.skip_sf5			; No, other accuracy commands?
	mov	rax, 1000			; 1K digits
	call 	SetDigitAccuracy		; Set digits to value in RAX
	call	PrintAccVerbose			; Print accuracy information to output
	call	Header_Update
	ret
.skip_sf5:
	cmp	[rax], byte 'M'			; Input number of words
	jne	.skip_sf6			; No, other accuracy commands?
	mov	rax, 1000000			; 1M digits
	call 	SetDigitAccuracy		; Set digits to value in RAX
	call	PrintAccVerbose			; Print accuracy information to output
	call	Header_Update
	ret
.skip_sf6:
	cmp	[rax], byte '0'	 		; Check first character of command
	jl	.Error1				; less than 0? then skip
	cmp	[rax], byte '9'			; greater than 9? then skip
	jg	.Error1
	call	IntWordInput			; RAX in binary 64 bit data
	call 	SetDigitAccuracy		; Set digits to value in RAX
	call	PrintAccuracy			; Print accuracy information to output
	call	Header_Update
	ret
.Error1:
	mov	rax, .Msg_Error1
	call	StrOut
	mov	rax, Help_sigfigs		; Text located in help.asm
	call	StrOut
	call	CROut
	ret
.Msg_Error1:	db	"Command Parser: sigfigs command invalid argument", 0xD, 0xA, 0xA, 0
;
;
;
Command_slimit:
	or	rax, rax			; Check for argument
	jz	.no_arg				; No argument
	cmp	byte [rax], '1' 		; Check first character of command
	jl	.no_arg				; less than 0? then skip
	cmp	byte [rax], '9'			; greater than 9? then skip
	jg	.no_arg
	call	IntWordInput			; RAX in binary 64 bit data
	mov	[Sum_Limit], rax
.no_arg:
	mov	rax, .Msg1
	call	StrOut
	mov	rax, [Sum_Limit]
	call	PrintWordB10
	call	CROut
	call	Header_Update
	ret
.Msg1:	db	"[Sum_Limit] = ", 0
;
;
;
Command_sstep:
	or	rax, rax			; Check for argument
	jz	.no_arg				; No argument
	cmp	byte [rax], '0' 		; Check first character of command
	jl	.no_arg				; less than 0? then skip
	cmp	byte [rax], '9'			; greater than 9? then skip
	jg	.no_arg
	call	IntWordInput			; RAX in binary 64 bit data
	mov	[iShowCalcStep], rax
.no_arg:
	mov	rax, .Msg1
	call	StrOut
	mov	rax, [iShowCalcStep]
	call	PrintWordB10
	call	CROut
	call	Header_Update
	ret
.Msg1:	db	"[iShowCalcStep] = ", 0
;
;
;
Command_stack:
	mov	rbx, [iVerboseFlags]
	push	rbx
	mov	rbx, 0x30			; code for all registers
	mov	[iVerboseFlags], rbx
	call	PrintResult
	pop	rbx
	mov	[iVerboseFlags], rbx
	ret
;
;
;
Command_sto:
	or	rax, rax			; Check for valid argument
	jnz	.arg_present
.Error1:
	mov	rax, .Msg_error
	call	StrOut
	ret
.arg_present:
	cmp	byte [rax], '0' 		; Check first character of command
	jl	.Error1				; less than 0? then skip
	cmp	byte [rax], '9'			; greater than 9? then skip
	jg	.Error1
	call	IntWordInput			; RAX in binary 64 bit data
	cmp	rax, (TOPHAND-HAND_REG0)
	jg	.Error1
	mov	rsi, HAND_XREG
	mov	rdi, rax			; Get register number starting 0
	add	rdi, HAND_REG0			; Add lowest handle
	call	CopyVariable
	call	PrintResult
	ret
.Msg_error:	db	"Command Parser: Invalid argument for sto (recall register).", 0xD, 0xA
		db	"        Usage: sto <integer>  (enter register number 0-7)", 0xD, 0xA, 0
;
;
;
Command_vars:
	mov	rbx, [iVerboseFlags]
	push	rbx
	mov	rbx, 0x70			; code for all registers
	mov	[iVerboseFlags], rbx
	call	PrintResult
	pop	rbx
	mov	[iVerboseFlags], rbx
	ret
;
;
;
Command_verbose:
	mov	rax, 0x70
	mov	[iVerboseFlags], rax
	mov	rax, 0xFFFFFFFF
	mov	[iShowCalcMask], rax
	mov	rax, .Msg
	call	StrOut
	ret
.Msg:	db	"Set Verbose", 0xD, 0xA, 0
;
;
;
Command_xonly:
	push	rax
	mov	rax, 0x10
	mov	[iVerboseFlags], rax		; 10 = print on
	mov	rax, 0xFFFFFFFF
	mov	[iShowCalcMask], rax
	pop	rax
	ret
;
;
;
Command_exchange_xy:
	mov	rsi, HAND_XREG
	mov	rdi, HAND_YREG
	call	ExchangeVariable
	call	PrintResult
	ret

;
;
;
;----------------------------------------------
;
; Print Command List
;
; Input:  AL = 0, print all commands
;         AL = (character), print commands
;               starting with character
;
;----------------------------------------------

PrintCommandList:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	r15

	mov	r15, 0				; initialize line feed counter
	mov	CL, al				; Get search character
	mov	rbx, Command_Table		; Address of command table
.loop1:
	mov	rax, rbx			; Get pointer
	mov	DL, [rax]			; Get character to see if done
	or	DL, DL				; Is it zero, then done
	jz	.done
	or	CL, CL				; Is CL zero, is there a search?
	jz	.skip1				; It is zero, print all
	cmp	DL, CL				; Does character match?
	jne	.skip2				; Does not match skip
.skip1:
	call	StrOut				; Print command
	mov	al, ' '
	call	CharOut
	inc	r15				; increment line feed counter
	cmp	r15, 8				; limit value
	jc	.skip2
	mov	r15, 0
	call	CROut				; line return + feed
.skip2:
	add	rbx, (BYTE_PER_WORD * 2)
	jmp	.loop1
.done:
	call	CROut

	pop	r15
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
;--------------------
; parser.asm - EOF
;--------------------
