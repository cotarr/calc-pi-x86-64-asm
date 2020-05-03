%define HELP4334
%include "var_header.inc"			; Header has global variable definitions for other modules
%include "func_header.inc"			; Header has global function definitions for other modules
;--------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; This module contains user help
;
; File:   help.asm
; Module: help.asm, help.o
; Exec:   calc-pi
;
; Created:    12/21/2014
; Last Edit:  04/29/2020
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
; Help_Welcome:
; Help:
; PrintHelpList:
; PrintAllHelp:
;-------------------------------------------------------------

SECTION	.data	align=8		; Section containing initialized data
;
;---------------------------------------------------------------------
;
;  Help Table
;
;  8 character command for up to 7 character command zero terminated
;
;  64 bit QWord address pointer
;
;---------------------------------------------------------------------
;
Help_Table:
	db	".", 0, 0, 0, 0, 0, 0, 0
	dq	Help_print
	db	" ", 0, 0, 0, 0, 0, 0, 0
	dq	Help_vars
	db	"+", 0, 0, 0, 0, 0, 0, 0
	dq	Help_plus_symbol
	db	"-", 0, 0, 0, 0, 0, 0, 0
	dq	Help_minus_symbol
	db	"*", 0, 0, 0, 0, 0, 0, 0
	dq	Help_star_symbol
	db	"/", 0, 0, 0, 0, 0, 0, 0
	dq	Help_slash_symbol
	db	"c.e", 0, 0, 0, 0, 0
	dq	Help_c_e
	db	"c.gr", 0, 0, 0, 0
	dq	Help_c_gr
	db	"c.ln2", 0, 0, 0
	dq	Help_c_ln2
	db	"c.pi", 0, 0, 0, 0
	dq	Help_c_pi


	db	"c.pi.ch", 0
	dq	Help_c_pi_ch
	db	"c.pi.ra", 0
	dq	Help_c_pi_ra
	db	"c.pi.ze", 0
	dq	Help_c_pi_ze

	db	"c.pi.st", 0
	dq	Help_c_pi_st


	db	"c.pi.mc", 0
	dq	Help_c_pi_mc
	db	"c.sr2", 0, 0, 0
	dq	Help_c_sr2
	db	"chs", 0, 0, 0, 0, 0
	dq	Help_chs
	db	"clrall", 0, 0
	dq	Help_clrall
	db	"clrreg", 0, 0
	dq	Help_clrreg
	db	"clrstk", 0, 0
	dq	Help_clrstk
	db	"clrx", 0, 0, 0, 0
	dq	Help_clrx
	db	"cmdlist", 0
	dq	Help_cmdlist
	db	"comment", 0
	dq	Help_comment
	db	"D.comp", 0, 0
	dq	Help_D.comp
	db	"D.fill", 0, 0
	dq	Help_D.fill
	db	"D.flag", 0, 0
	dq	Help_D.flag
	db	"D.init", 0, 0
	dq	Help_D.init
	db	"D.ofst", 0, 0
	dq	Help_D.ofst
	db	"desc", 0, 0, 0, 0
	dq	Help_desc
	db	"descnew", 0
	dq	Help_descnew
	db	"enter", 0, 0, 0
	dq	Help_enter
	db	"exit", 0, 0, 0, 0
	dq	Help_q

	db	"f.asin", 0, 0
	dq	Help_f_asin
	db	"f.cos", 0, 0, 0
	dq	Help_f_cos
	db	"f.exp", 0, 0, 0
	dq	Help_f_exp
	db	"f.ipwr", 0, 0
	dq	Help_f_ipwr
	db	"f.ln", 0, 0, 0, 0
	dq	Help_f_ln
	db	"f.nroot", 0
	dq	Help_f_nroot
	db	"f.sin", 0, 0, 0
	dq	Help_f_sin
	db	"f.zeta", 0, 0
	dq	Help_f_zeta

	db	"fix", 0, 0, 0, 0, 0
	dq	Help_fix
	db	"help", 0, 0, 0, 0
	dq	Help_help
	db	"helpall", 0
	dq	Help_helpall
	db	"hex", 0, 0, 0, 0, 0
	dq	Help_hex
	db	"int", 0, 0, 0, 0, 0
	dq	Help_int
	db	"load", 0, 0, 0, 0
	dq	Help_load
	db	"log", 0, 0, 0, 0, 0
	dq	Help_log
	db	"logoff", 0, 0
	dq	Help_logoff
	db	"mmode", 0, 0, 0
	dq	Help_mmode
	db	"mobile", 0, 0
	dq	Help_mobile
	db	"normal", 0, 0
	dq	Help_normal
	db	"print", 0, 0, 0
	dq	Help_print
%IFDEF PROFILE
	db	"profile", 0
	dq	Help_profile
%ENDIF
	db	"q", 0, 0, 0, 0, 0, 0, 0
	dq	Help_q
	db	"quiet", 0, 0, 0
	dq	Help_quiet
	db	"rcl", 0, 0, 0, 0, 0
	dq	Help_rcl
	db	"rdown", 0, 0, 0
	dq	Help_rdown
	db	"rup", 0, 0, 0, 0, 0
	dq	Help_rup
	db	"save", 0, 0, 0, 0
	dq	Help_save
	db	"sci", 0, 0, 0, 0, 0
	dq	Help_sci
	db	"sf", 0, 0, 0, 0, 0, 0
	dq	Help_sigfigs
	db	"show", 0, 0, 0, 0
	dq	Help_show
	db	"showoff", 0
	dq	Help_showoff
	db	"sigfigs", 0
	dq	Help_sigfigs
	db	"stack", 0, 0, 0
	dq	Help_stack
	db	"sstep", 0, 0, 0
	dq	Help_sstep
	db	"sto", 0, 0, 0, 0, 0
	dq	Help_sto
	db	"vars", 0, 0, 0, 0
	dq	Help_vars
	db	"verbose", 0
	dq	Help_verbose
	db	"xonly", 0, 0, 0
	dq	Help_xonly
	db	"xy", 0, 0, 0, 0, 0, 0
	dq	Help_xy


Help_Table_End:
	db	0, 0, 0, 0, 0, 0, 0, 0
	dq	0				; End of list
;
;
;
Help_plus_symbol:
	db	"Usage: +", 0xD, 0xA, 0xA
	db	"Description: Floating Point Addition Xreg = YReg + XReg.", 0xD, 0xA
	db	"Parser: move XReg --> ACC, YReg --> OPR", 0xD, 0xA
	db	"FP_Additon: ACC = ACC + OPR (Floating point addietion, normalized)", 0xD, 0xA
	db	"Parser: move ACC --> XReg, then roll stack down.", 0xD, 0xA, 0
;
;
;
Help_minus_symbol:
	db	"Usage: -", 0xD, 0xA, 0xA
	db	"Description: Floating Point Subtraction Xreg = YReg - XReg.", 0xD, 0xA
	db	"Parser: move XReg --> ACC", 0xD, 0xA
	db	"FP_TwosCompliment: Perform 2s compliment on ACC", 0xD, 0xA
	db	"Parser: move YReg --> OPR", 0xD, 0xA
	db	"FP_Additon: ACC = OPR + (-ACC)", 0xD, 0xA
	db	"Parser: move ACC --> XReg, then roll stack down.", 0xD, 0xA, 0
;
;
;
Help_star_symbol:
	db	"Usage: *", 0xD, 0xA, 0xA
	db	"Description: Floating Point Multiplication XReg = YReg * XReg.", 0xD, 0xA
	db	"Parser: move XReg --> ACC, YReg --> OPR", 0xD, 0xA
	db	"FP_Multiplication: Check for short multiplication ( ACC < 64 bit )", 0xD, 0xA
	db	"FP_Long_Multiplication (or FP_Short_Multiplication)", 0xD, 0xA
	db	"         ACC = OPR * ACC  (uses WorkA, WorkB)", 0xD, 0xA
	db	"Parser: move ACC --> XReg, then roll stack down.", 0xD, 0xA, 0
;
;
;
Help_slash_symbol:
	db	"Usage: /", 0xD, 0xA, 0xA
	db	"Description: Floating Point Division XReg = YReg / XReg.", 0xD, 0xA
	db	"Parser: move XReg --> ACC, YReg --> OPR", 0xD, 0xA
	db	"FP_Division: Check for short division (OPR, denominator < 64 bit )", 0xD, 0xA
	db	"FP_Long_Division (or FP_Short_Division)", 0xD, 0xA
	db	"         ACC = OPR / ACC  (uses WorkA, WorkB, WorkC)", 0xD, 0xA
	db	"Parser: move ACC --> XReg, then roll stack down.", 0xD, 0xA, 0
;
;
;
Help_c_e:
	db	"Usage: c.e <optional method code 1, 2, 3, or 4>", 0xD, 0xA, 0xA
	db	"Description: Calculation of the constant e.", 0xD, 0xA
	db	"The calculation is performed by the summation of 1/n!.", 0xD, 0xA
	db	"Default (no argument) uses case method code = 1.", 0xD, 0xA
	db	"1 - divide 1/n fixed precision (non-normalized arithemetic).", 0xD, 0xA
	db	"2 - divide 1/n i7 register arithemetic (64 bit DIV).", 0xD, 0xA
	db	"3 - divide 1/n full floating point arithemetic.", 0xD, 0xA
	db	"4 - call function exp(XReg) with XReg =1.", 0xD, 0xA
	db	"The prefix 'c.' indicates calculation of fixed constant.", 0xD, 0xA, 0
;
;
;
Help_c_gr:
	db	"Usage: c.gr", 0xD, 0xA, 0xA
	db	"Description: Calculation of the Golden Ratio", 0xD, 0xA, 0
;
;
;
Help_c_ln2:
	db	"Usage: c.ln2", 0xD, 0xA, 0xA
	db	"Description: Calculation of natural log of 2, ln(2). The number", 0xD, 0xA
	db	"is calculated by summation of Ln(2) = Sum ( 1/(n*2^n).", 0xD, 0xA
	db	"The prefix 'c.' indicates calculation of fixed constant.", 0xD, 0xA, 0
;
;
;
Help_c_pi:
	db	"Usage: c.pi", 0xD, 0xA, 0xA
	db	"Description: Calculation of pi using default method", 0xD, 0xA
	db	"Default is Chudnovsky formula", 0xD, 0xA, 0
;
;
;
Help_c_pi_ch:
	db	"Usage: c.pi.ch", 0xD, 0xA, 0xA
	db	"Description: Calculation of pi using Chudnovsky formula", 0xD, 0xA, 0
;
;
;
Help_c_pi_ra:
	db	"Usage: c.pi.ra", 0xD, 0xA, 0xA
	db	"Description: Calculation of pi using Ramanujan formula.", 0xD, 0xA, 0
;
;
;
Help_c_pi_ze:
	db	"Usage: c.pi.ze", 0xD, 0xA, 0xA
	db	"Description: Calculation of pi using zeta(2) = (pi^2)/6.", 0xD, 0xA
	db	"Note: this is very slowly convergent. ", 0xD, 0xA
	db	"It will likely hit slimit and abort before convergence", 0xD, 0xA, 0
;
;
;
Help_c_pi_st:
	db	"Usage: c.pi.st <optional method code>", 0xD, 0xA, 0xA
	db	"Description: Calculation of pi result in X-Reg.", 0xD, 0xA, 0xA
	db	"Default (no argument) Stormer formula as single calculation", 0xD, 0xA
	db	"1 - Stormer part 1 of 4 to disk file pi-st-1.num", 0xD, 0xA
	db	"2 - Stormer part 2 of 4 to disk file pi-st-2.num", 0xD, 0xA
	db	"3 - Stormer part 3 of 4 to disk file pi-st-3.num", 0xD, 0xA
	db	"4 - Stormer part 4 of 4 to disk file pi-st-4.num", 0xD, 0xA
	db	"1234 - Load 4 parts and combine for multitask Stormer method", 0xD, 0xA, 0xA
	db	"To use multi-tasking Stormer mode, run 4 copies concurrently.", 0xD, 0xA
	db	"If processor cores available, each will run 100% CPU in own core.", 0xD, 0xA
	db	"The time of calculation will be the longest sum, the first, 1.", 0xD, 0xA
	db	"Each result will saved automatically to files:", 0xD, 0xA
	db	"pi-st-1.num, pi-st-2.num, pi-st-3.num, pi-st-4.num.", 0xD, 0xA
	db	"* * * Warning: the files must not exist or error will result.", 0xD, 0xA
	db	"Series 1, 2, 3, and 4 will exit the program when complete.", 0xD, 0xA
	db	"Code 1234 will load all 4 results and place sum in XReg.", 0xD, 0xA
	db	"Command for multitasking:  c.pi.se <number> where number = 1, 2, 3, 4 or 1234.", 0xD, 0xA
	db	"If number omitted or 0 then all series summed normally", 0xD, 0xA
	db	"with result in X-reg and sums in Reg0, Reg1, Reg2 and Reg3.", 0xD, 0xA, 0
;
;
;
Help_c_pi_mc:
	db	"Usage: c.pi.mc", 0xD, 0xA, 0xA
	db	"Description: Calculation of pi using Monte Carlo simulation.", 0xD, 0xA
	db	"Suggest sigfigs 10 and slimit 1000000", 0xD, 0xA, 0
;
;
;
Help_c_sr2:
	db	"Usage: c.sr2", 0xD, 0xA, 0xA
	db	"Description: Calculation of the square root of 2.", 0xD, 0xA
	db	"Calculation uses Newton Raphson method of successive", 0xD, 0xA
	db	"approximations.", 0xD, 0xA
	db	"X(i) = last guess   X(i+1) = next guess  A = input number", 0xD, 0xA
	db	"  X(i+1) =  [ (A / X(i)) + (X(i)) ] / 2", 0xD, 0xA
	db	"The prefix 'c.' indicates calculation of fixed constant.", 0xD, 0xA, 0
;
;
;
Help_chs:
	db	"Usage: chs", 0xD, 0xA, 0xA
	db	"Description: Change sign of X-reg (Twos compliment)", 0xD, 0xA, 0
;
;
;
Help_clrall:
	db	"Usage: clrall", 0xD, 0xA, 0xA
	db	"Description: Clear all floating point variables to zero.", 0xD, 0xA
	db	"(Xreg, YReg, Zreg, TReg, Reg0, Reg1, Reg2..., ACC, Opr...", 0xD, 0xA , 0
;
;
;
Help_clrreg:
	db	"Usage: clrreg", 0xD, 0xA, 0xA
	db	"Description: Clear floating point registers to zero.", 0xD, 0xA
	db	"(Reg0, Reg1, Reg2...)", 0xD, 0xA, 0
;
;
;
Help_clrstk:
	db	"Usage: clrstk", 0xD, 0xA, 0xA
	db	"Description: Clear floating point stack to zero.", 0xD, 0xA
	db	"(XReg, YReg, Zreg, Treg)", 0xD, 0xA, 0
;
;
;
Help_clrx:
	db	"Usage: clrx", 0xD, 0xA, 0xA
	db	"Description: Clear X, floating point XReg", 0xD, 0xA, 0
;
;
;
Help_cmdlist:
	db	"Usage: cmdlist <optional first letter>", 0xD, 0xA, 0xA
	db	"Description: Prints a list of availble commands. ", 0xD, 0xA
	db	"To shorten the list provide the  first letter as a", 0xD, 0xA
	db	"command argument.", 0xD, 0xA, 0
;
;
;
Help_comment:
	db	"Usage: comment <comment string>", 0xD, 0xA, 0xA
	db	"Description: Echo the comment string to the program output", 0xD, 0xA
	db	"This is useful when capturing output text to a file.", 0xD, 0xA, 0
;
;
;
Help_D.comp:
	db	"Usage: D.comp <handle> <handle>", 0xD, 0xA, 0xA
	db	"Description: This is a debug command used to compare two", 0xD, 0xA
	db	"variables. If there is a difference, the D.comp command ", 0xD, 0xA
	db	"will indicate which words are different. The hex command", 0xD, 0xA
	db	"can be used without argument to see a list of variable", 0xD, 0xA
	db	"handle numbers.", 0xD, 0xA, 0
;
;
;
Help_D.fill:
	db	"Usage: D.fill <handle>", 0xD, 0xA, 0xA
	db	"Description: This is a debug command to fill a variable with", 0xD, 0xA
	db	"sequential byte value numbers. It starts with the exponent ", 0xD, 0xA
	db	"0102030405060708 (exponent)", 0xD, 0xA
	db	"1011121314151617 (most significant word)", 0xD, 0xA
	db	"18191A1B1C1D1E1F (next word in mantissa)", 0xD, 0xA
	db	"This is very useful to check low level functions, such as ", 0xD, 0xA
	db	"shifting memory left or right 1 bit.", 0xD, 0xA, 0
;
;
;
Help_D.flag:
	db	"Usage: D.flag <optional integer value>", 0xD, 0xA, 0xA
	db	"Description: This is a debug command used to inspect or", 0xD, 0xA
	db	"set the program variable 'DebugFlag' (64 bit integer).", 0xD, 0xA
	db	"When no argument is provided the current value is printed.", 0xD, 0xA
	db	"During debugging, the DebugFlag variable can be tested", 0xD, 0xA
	db	"conditionally by the program to optionally execute debug code.", 0xD, 0xA, 0
;
;
;
Help_D.init:
	db	"Usage D.init", 0xD, 0xA, 0xA
	db	"Description: Calls FP_Initialize to reinitialize program", 0xD, 0xA
	db	"variables. This is intended primarily for debugging.", 0xD, 0xA
	db	"To fully reset the memory, it is recommended to restart", 0xD, 0xA
	db	"the program.", 0xD, 0xA, 0
;
;
;
Help_D.ofst:
	db	"Usage: D.ofst", 0xD, 0xA, 0xA
	db	"Description: This is a debug command used to print the current", 0xD, 0xA
	db	"memory offset of internal variable fields, realtive to the low", 0xD, 0xA
	db	"address of the variable. (i.e. offset to exponent word).", 0xD, 0xA
	db	"It is useful when looking at the variables with gdb debugger, ", 0xD, 0xA, 0
;
;
;
Help_desc:
	db	"Usage: desc", 0xD, 0xA, 0xA
	db	"Description: The file format of variables saved to disk includes", 0xD, 0xA
	db	"a 32 character text field for a null terminated string used to", 0xD, 0xA
	db	"hold a description of the variable contents. The command 'desc'", 0xD, 0xA
	db	"shows the current description to be used with the next 'save'", 0xD, 0xA
	db	"command and/or the previous load command. New descriptions", 0xD, 0xA
	db	"are created with 'descnew'.", 0xD, 0xA, 0
;
;
;
Help_descnew:
	db	"Usage: descnew", 0xD, 0xA, 0xA
	db	"Description: The file format of variables saved to disk includes", 0xD, 0xA
	db	"a 32 character text field for a null terminated string used to", 0xD, 0xA
	db	"hold a description of the variable contents. The 'descnew'", 0xD, 0xA
	db	"command is used to enter a new description string to be used", 0xD, 0xA
	db	"with the next 'save' command.", 0xD, 0xA, 0
;
;
;
Help_enter:
	db	"Usage: enter", 0xD, 0xA, 0xA
	db	"Duplicate X-Reg and roll X-->Y, Y-->Z, Z-->T (T is discarded)", 0xD, 0xA, 0
;
;
;
Help_f_asin:
	db	"Usage f.asin", 0xD, 0xA, 0xA
	db	"Description: Calculate arcsine of Xreg", 0xD, 0xA
	db	"Valid range -1 <= Xreg <= 1", 0xD, 0xA
	db	"Calculation time increases as Xreg approaches |1|", 0xD, 0XA
	db	"* Range not checked *", 0xD, 0XA, 0
 ;
 ;
 ;
 Help_f_cos:
	db	"Usage f.cos", 0xD, 0xA, 0xA
	db	"Description: Calculate cosine of Xreg", 0xD, 0xA
	db	"Valid range -2pi <= Xreg <= 2pi", 0xD, 0xA
	db	"* Range not checked *", 0xD, 0XA, 0
;
;
;
Help_f_exp:
	db	"Usage f.exp", 0xD, 0xA, 0xA
	db	"Description: Calculate exponential of Xreg", 0xD, 0xA, 0
;
;
;
Help_f_ipwr:
	db	"Usage f.ipwr <integer>", 0xD, 0xA, 0xA
	db	"Description: Calculate Xreg to the power of <integer>", 0xD, 0xA
	db	"Input must be a positive integer >= 2", 0xD, 0xA, 0
;
;
;
Help_f_ln:
	db	"Usage f.ln", 0xD, 0xA
	db	"Usage f.ln.rg", 0xD, 0xA
	db	"Usage f.ln.is", 0xD, 0xA
	db	"Description: Calculate Natural Logarithm of Xreg", 0xD, 0xA
	db	"Valid range Xreg > 0", 0xD, 0xA
	db	"Method", 0xD, 0xA
	db	"f.ln (default method = f.ln.is) ", 0xD, 0xA
	db	"f.ln.rg Iterative guess method", 0xD, 0xA
	db	"f.ln.is Infinite Series", 0xD, 0xA, 0
;
;
;
Help_f_nroot:
	db	"Usage f.nroot <integer>", 0xD, 0xA, 0xA
	db	"Description: nth root of Xreg", 0xD, 0xA
	db	"Input must be positive integer >= 2", 0xD, 0xA, 0
;
;
;
Help_f_sin:
	db	"Usage f.sin", 0xD, 0xA, 0xA
	db	"Description: Calculate sine of Xreg", 0xD, 0xA
	db	"Valid range -2*pi <= Xreg <= 2*pi", 0xD, 0xA
	db	"* Range not checked *", 0xD, 0XA, 0
 ;
 ;
 ;
 Help_f_zeta:
	db	"Usage f.zeta <integer>", 0xD, 0xA, 0xA
	db	"Description: Zeta function Xreg", 0xD, 0xA
	db	"Sum of 1/n^x where x=input", 0xD, 0xA
	db	"Input must be positive integer >= 2", 0xD, 0xA
	db	"This converges very slowly.", 0xD, 0xA
	db	"It will likely hit slimit before convergence", 0xD, 0xA, 0
;
;
;
Help_fix:
	db	"Usage: fix", 0xD, 0xA, 0xA
	db	"Description: Set the output printing mode to fixed notation.", 0xD, 0xA
	db	"Note: this is the output printing mode, not the calculation mode.", 0xD, 0xA
	db	"With accuracy 60 digits, 'sci', 'fix' and 'int' format as follows:", 0xD, 0xA
	db	"Sci: +1.234567800000000000000000000000000000000000000000000000000000 E+7", 0xD, 0xA
	db	"Fix: +12345678.00000000000000000000000000000000000000000000000000000", 0xD, 0xA
	db	"Int: +12345678 (rounded off value)", 0xD, 0xA, 0
;
;
;
Help_help:
	db	"Usage: help <command name>", 0xD, 0xA, 0xA
	db	"Description: help will provice description and", 0xD, 0xA
	db	"instructions for the use of a specific command.", 0xD, 0xA, 0
;
;
;
Help_helpall:
	db	"Usage: helpall", 0xD, 0xA, 0xA
	db	"Description: helpall will print a continuous list of", 0xD, 0xA
	db	"all help command descriptions.", 0xD, 0xA, 0
;
;
;
Help_hex:
	db	"Usage: hex <optoinal variable handle number>", 0xD, 0xA, 0xA
	db	"Description: Hex command is used to display variables in ", 0xD, 0xA
	db	"binary (hexidecimal) format. If the hex command is called", 0xD, 0xA
	db	"without an argument, all the registers are printed showing", 0xD, 0xA
	db	"showing the first 3 words, the last word, and exponent in", 0xD, 0xA
	db	"64-bit words in hexidecimal. If a variable hands is ", 0xD, 0xA
	db	"is provided, the entire variable is printed.", 0xD, 0xA, 0
;
;
;
Help_int:
	db	"Usage: int", 0xD, 0xA, 0xA
	db	"Description: Set the output printing mode to integer notation.", 0xD, 0xA
	db	"Note: this is the output printing mode, not the calculation mode.", 0xD, 0xA
	db	"With accuracy 60 digits, 'sci', 'fix' and 'int' format as follows:", 0xD, 0xA
	db	"Sci: +1.234567800000000000000000000000000000000000000000000000000000 E+7", 0xD, 0xA
	db	"Fix: +12345678.00000000000000000000000000000000000000000000000000000", 0xD, 0xA
	db	"Int: +12345678 (rounded off value)", 0xD, 0xA, 0
;
;
;
Help_load:
	db	"Usage: load <filename>", 0xD, 0xA, 0xA
	db	"Description: This command loads X-Reg with the contents of", 0xD, 0xA
	db	"the file. The file contains the number in binary format.", 0xD, 0xA
	db	"During the load process, the accuracy of the variable is", 0xD, 0xA
	db	"compared to the current accuracy (sigfigs). Upon mismatch, ", 0xD, 0xA
	db	"the program accuracy is updated to match the variable.", 0xD, 0xA, 0
;
;
;
Help_mobile:
	db	"Usage: mobile", 0xD, 0xA, 0xA
	db	"Auto print Xreg to TReg values after each calculation.", 0xD, 0xA
	db	"Sets iShowCalcMask to inhibit selected progress indicators.", 0xD, 0xA
	db	"See also: mobile, normal, quiet, verbose, xonly", 0xD, 0xA, 0
;
;
;
Help_log:
	db	"Usage log", 0xD, 0xA, 0xA
	db	"Description: The command 'log' starts a terminal log session.", 0xD, 0xA
	db	"The filenames are sequential as follows:", 0xD, 0xA
	db	"out/out001.txt, out/out002.txt, out/out003.txt ...", 0xD, 0xA
	db	"the folder 'out' is expected in the working directory.", 0xD, 0xA
	db	"Logging is stopped with the 'logoff' command", 0xD, 0xA, 0
;
;
;
Help_logoff:
	db	"Usage logoff", 0xD, 0xA, 0xA
	db	"Description: The command 'log' stops a terminal log session.", 0xD, 0xA, 0
;
;
;
Help_mmode:
	db	"Usage: mmode <optional integer bit pattern>", 0xD, 0xA, 0xA
	db	"Descripton: Without argument, mmode displays MathMode variable.", 0xD, 0xA
	db	"Using mmode with argument will load the integer argument into", 0xD, 0xA
	db	"the MathMode variable. ", 0xD, 0xA, 0xA
	db	"Modes:", 0xD, 0xA
	db	"   1   (0x01)  Force: FP_Long_Mult (binary shift and add)", 0xD, 0xA
	db	"   2   (0x02)  Force: FP_Long_Div (binary shift and subtract)", 0xD, 0xA
	db	"   4   (0x04)  Disable: 64 bit i7 MUL with single word non-zero.", 0xD, 0xA
	db	"   8   (0x08)  Disable: 64 bit i7 DIV with single word non-zero.", 0xD, 0xA
	db	"   16  (0x10)  FP_Reciprocal: Disable variable accuracy.", 0xD, 0xA
	db	"   32  (0x20)  FP_Reciprocal: bitwise multiplication.", 0xD, 0xA
	db	"   64  (0x40)  FP_Addition: Force bitwise alignment", 0xD, 0xA
	db	"   128 (0x80)  FP_Normalization: Force bitwise alignment", 0xD, 0xA
	db	"   256 (0x100) Disable function ReduceSeriesAccuracy during summations", 0xD, 0xA, 0xA
	db	"   Use 0 to select normal (most efficient) mode.", 0xD, 0xA
	db	"   Use 12 to force matrix mode (disable auto short).", 0xD, 0xA
	db	"   Use 15 to force binary long mode.", 0xD, 0xA
	db	"   Use 463 for full bitwise arithmetic (for benchmarking).", 0xD, 0xA, 0
;
;
;
Help_normal:
	db	"Usage: normal", 0xD, 0xA, 0xA
	db	"Auto print Xreg to TReg values after each calculation.", 0xD, 0xA
	db	"See also: mobile, normal, quiet, verbose, xonly", 0xD, 0xA, 0
;
;
;
Help_print:
	db	"Usage: .   (print X-Reg, equivalent command is 'print')", 0xD, 0xA
	db	"Usage: . f (formated - 10 and 1000 digit block output.", 0xD, 0xA
	db	"Usage: . s (short - short lines for mobile screen.", 0xD, 0xA
	db	"Usage: . q (quiet - terminal output suppressed, 10 1000 format", 0xD, 0xA
	db	"Usage: . u (unformatted - no line feed or page formatting", 0xD, 0xA, 0xA
	db	"Description: The . (period character) or 'print' will convert", 0xD, 0xA
	db	"the contents of X-reg from binary to decimail. The output", 0xD, 0xA
	db	"will be printed to stdout. Use 'sci' 'fix' or 'int' before", 0xD, 0xA
	db	"printing to set scientific notation, fix notation or integer", 0xD, 0xA
	db	"notation. q (quiet) inhibits console output when capturing", 0xD, 0xA
	db	"output to a file using the 'log' and 'logoff' commands.", 0xD, 0xA, 0
;
;
;
%IFDEF PROFILE
Help_profile:
	db	"Usage profile <i = optional to initialize>", 0xD, 0xA, 0xA
	db	"Description: If the program is compliled with '%DEFINE PROFILE'", 0xD, 0xA
	db	"then counters are compiled into various functions to monitor", 0xD, 0xA
	db	"performance. For example, several multiplication methods ", 0xD, 0xA
	db	"can be auto-selected at runtime. The profile counters can", 0xD, 0xA
	db	"show frequency of each method. To display counters, use", 0xD, 0xA
	db	"the profile command without argument. The optional 'i'", 0xD, 0xA
	db	"argument will reset all counters to zero", 0xD, 0xA, 0
%ENDIF
;
;
;
Help_q:
	db	"Usage: quit", 0xD, 0xA, 0xA
	db	"Description: Quit the program.", 0xD, 0xA, 0
;
;
;
Help_quiet:
	db	"Usage: quiet", 0xD, 0xA, 0xA
	db	"Inhibit print register values after each calculation", 0xD, 0xA
	db	"See also: mobile, normal, verbose, xonly", 0xD, 0xA, 0
;
;
;
Help_rcl:
	db	"Usage: rcl <register-number>", 0xD, 0xA, 0xA
	db	"Copy the value of Register into X-reg.", 0xD, 0xA
	db	"Stack is rolled: Z-->T, Y-->Z, X-->Y", 0xD, 0xA
	db	"Valid registers start 0, 1, 2.. up to the to highest register.", 0xD, 0xA
	db	"The count of registers is configured when program is complied.", 0xD, 0xA, 0
;
;
;
Help_rdown:
	db	"Usage: rdown", 0xD, 0xA, 0xA
	db	"Stack Roll DOWN: T-->Z, Z-->Y, Y-->X, X-->T", 0xD, 0xA, 0
;
;
;
Help_rup:
	db	"Usage: rup", 0xD, 0xA, 0xA
	db	"Stack Roll up: X-->Y, Y-->Z, Z-->T, T-->X", 0xD, 0xA, 0
;
;
;
Help_save:
	db	"Usage: save <filename>", 0xD, 0xA, 0xA
	db	"Description: This command saves the contents of X-Reg to a file", 0xD, 0xA
	db	"in binary format. The file contains a 32 character text", 0xD, 0xA
	db	"description, the variable size in words (binary) and ", 0xD, 0xA
	db	"characters (decimal), and a 32 character text description.", 0xD, 0xA
	db	"Description can be set with the descnew command.", 0xD, 0xA, 0
;
;
;
Help_sci:
	db	"Usage: sci", 0xD, 0xA, 0xA
	db	"Description: Set the output printing mode to scientific notation.", 0xD, 0xA
	db	"Note: this is the output printing mode, not the calculation mode.", 0xD, 0xA
	db	"With accuracy 60 digits, 'sci', 'fix' and 'int' format as follows:", 0xD, 0xA
	db	"Sci: +1.234567800000000000000000000000000000000000000000000000000000 E+7", 0xD, 0xA
	db	"Fix: +12345678.00000000000000000000000000000000000000000000000000000", 0xD, 0xA
	db	"Int: +12345678 (rounded off value)", 0xD, 0xA, 0
;
;
;
Help_show:
	db	"Usage: show", 0xD, 0xA, 0xA
	db	"See related commands: showoff, sstep", 0xD, 0xA, 0xA
	db	"Description: The purpose of this function is to enable", 0xD, 0xA
	db	"printing of real time status update during a long", 0xD, 0xA
	db	"calculation. When writing code to perform a series summation, ", 0xD, 0xA
	db	"the ShowCalcProgress function can be called within the loop.", 0xD, 0xA
	db	"The RAX processor register contains bits which specify which", 0xD, 0xA
	db	"of the following updates are printed. When initialized with", 0xD, 0xA
	db	"RAX = 0x02000000 the processor RBX register is used to ", 0xD, 0xA
	db	"initialize a skip counter. The skip counter is set using the", 0xD, 0xA
	db	"sstep command. A sstep setting of 10000 will print an update", 0xD, 0xA
	db	"1 out of every 10000 loop iterations.", 0xD, 0xA, 0xA
	db	"   RAX bit mask, used when calling ShowCalcProgress", 0xD, 0xA
	db	"0x00000000 (all zero) initialize at start of calculation", 0xD, 0xA
	db	"   iCounter01", 0xD, 0xA
	db	"0x00000001 Print iCounter01 value (integer)", 0xD, 0xA
	db	"0x00000002 Print iCounter01 name (iCounter01=)", 0xD, 0xA
	db	"0x00000004 Increment iCounter01", 0xD, 0xA
	db	"0x00000008 Reset iCounter01 to Zero", 0xD, 0xA
	db	"   iCounter02", 0xD, 0xA
	db	"0x00000010 Print iCounter02 value", 0xD, 0xA
	db	"0x00000020 Print iCounter02 name", 0xD, 0xA
	db	"0x00000040 Increment iCounter02", 0xD, 0xA
	db	"0x00000080 Reset iCounter02 to Zero", 0xD, 0xA
	db	"   iTimer01", 0xD, 0xA
	db	"0x00000100 Print iTimer01 value (hh:mm:ss)", 0xD, 0xA
	db	"0x00000200 Print iTimer01 name (iTimer01:)", 0xD, 0xA
	db	"0x00000400 Reset to Zero during Print Update (Skip counter)", 0xD, 0xA
	db	"0x00000800 Reset to Zero", 0xD, 0xA
	db	"   iTimer02", 0xD, 0xA
	db	"0x00001000 Print iTimer02 value", 0xD, 0xA
	db	"0x00002000 Print iTimer01 name", 0xD, 0xA
	db	"0x00004000 Reset to Zero during Print Update (skip counter)", 0xD, 0xA
	db	"0x00008000 Reset to Zero", 0xD, 0xA
	db	"   Command Timer (total time of program function)", 0xD, 0xA
	db	"0x00010000 Print command timer value(hh:mm:ss)", 0xD, 0xA
	db	"0x00020000 Print command timer name (Command:)", 0xD, 0xA
	db	"0x00040000 Print command timer value in Seconds", 0xD, 0xA
	db	"0x00080000 Print seconds label (seconds:)", 0xD, 0xA
	db	"   Shift_Count", 0xD, 0xA
	db	"0x00100000 Print current accuracy value (Last_Shift_Count)", 0xD, 0xA
	db	"0x00200000 Print Name (Shift:)", 0xD, 0xA
	db	"0x00400000 (not used)", 0xD, 0xA
	db	"0x00800000 (not used)", 0xD, 0xA
	db	"   Initialization and formatting commands", 0xD, 0xA
	db	"0x01000000 Print mantissa nibble sample (see below)", 0xD, 0xA
	db	"0x02000000 Initialize skip count from RBX value", 0xD, 0xA
	db	"0x04000000 Print mantissa nibble ruler", 0xD, 0xA
	db	"0x08000000 (not used)", 0xD, 0xA
	db	"0x10000000 Print Leading CR/LF", 0xD, 0xA
	db	"0x20000000 Print Tailing LF", 0xD, 0xA
	db	"0x40000000 Obey skip counter?", 0xD, 0xA
	db	"0x80000000 Suppress Printing to File", 0xD, 0xA, 0xA
	db	"The mantissa nibble is derived by selecting many", 0xD, 0xA
	db	"bytes over the full mantissa, then combining a 4 bit", 0xD, 0xA
	db	"hexadecimal nibble for each byte. This is useful to", 0xD, 0xA
	db	"for showing convergence of a series (like a progress bar)", 0xD, 0xA, 0
;
;
;
Help_showoff:
	db	"Usage: showoff", 0xD, 0xA, 0xA
	db	"Description: Turn off show function (see show command).", 0xD, 0xA, 0
;
;
;
Help_sigfigs:
	db	"Usage: sf             (prints current accuracy)", 0xD, 0xA
	db	"Usage: sf   <integer> (set new accuracy digits base 10)", 0xD, 0xA
	db	"Usage: sf w <integer> (set new accuracy 64 bit words)", 0xD, 0xA
	db	"Usage: sf e <integer> (set new extended digits, 0 for none)", 0xD, 0xA
	db	"Usage: sf v           (display accuracy verbose)", 0xD, 0xA
	db	"Usage: sf K           (sets accuracy to 1K 1, 000 digits base 10)", 0xD, 0xA
	db	"Usage: sf M           (sets accuracy to 1M 1, 000, 000 digits base 10)", 0xD, 0xA
	db	"Usage: sf x           (sets accuracy to maximum)", 0xD, 0xA, 0xA
	db	"The sf (and sigfigs) commands aure used to set or display the current", 0xD, 0xA
	db	"precision level (significant digits) for floating point variables.", 0xD, 0xA
	db	"64 bit word size can be converted to base 10 number size by:", 0xD, 0xA
	db	"19.2659197224948 digit/QWord(64 bit) = log_base10(2^64)", 0xD, 0xA
	db	"Guard words provide additional precision to absorb rounding errors.", 0xD, 0xA
	db	"Set extended digits show result past specified accuracy.", 0xD, 0xA
	db	"Variable size VAR_WSIZE and GUARDWORDS specified in var_header.inc.", 0xD, 0xA, 0

;
;
;
Help_stack:
	db	"Usage: stack", 0xD, 0xA, 0xA
	db	"Description: prints list of Xreg, Yreg, Zreg and TReg.", 0xD, 0xA, 0
;
;
;
Help_sstep:
	db	"Usage: sstep <optional interval count>", 0xD, 0xA, 0xA
	db	"Description: When used without argument, sstep prints the current", 0xD, 0xA
	db	"value of the show step interval. When supplied with an integer argument, ", 0xD, 0xA
	db	"the show step interval is set to a new value. The show step interval, ", 0xD, 0xA
	db	"determines the frequency of status updates during program loop for", 0xD, 0xA
	db	"a long series summation. (see show command)", 0xD, 0xA, 0
;
;
;
Help_sto:
	db	"Usage: sto <register-number>", 0xD, 0xA, 0xA
	db	"Copy the value of X-Reg into the specified register.", 0xD, 0xA
	db	"Valid registers start 0, 1, 2.. up to the to highest register.", 0xD, 0xA
	db	"The count of registers is configured when program is complied.", 0xD, 0xA, 0
;
;
;
Help_vars:
	db	"Usage: vars", 0xD, 0xA, 0xA
	db	"Description: prints list showing the contents of all", 0xD, 0xA
	db	"the registers. X, Y, X, T and Reg0, Reg1, ...", 0xD, 0xA
	db	"(ASCII space is quivalent command)", 0xD, 0xA, 0
;
;
;
Help_verbose:
	db	"Usage: verbose", 0xD, 0xA, 0xA
	db	"Auto print Xreg to TReg, Reg0, Reg1...(all) values after each calculation.", 0xD, 0xA
	db	"See also: mobile, normal, quiet, xonly", 0xD, 0xA, 0
;
;
;
Help_xonly:
	db	"Usage: xonly", 0xD, 0xA, 0xA
	db	"Auto print Xreg value after each calculation.", 0xD, 0xA
	db	"Other registers are not shown.", 0xD, 0xA
	db	"See also: mobile, normal, quiet, verbose", 0xD, 0xA, 0
;
;
;
Help_xy:
	db	"Usage: xy", 0xD, 0xA, 0xA
	db	"Exchange X-Reg <--> Y-Reg", 0xD, 0xA, 0
;
;
;
;=====================================
; Default help message
;=====================================
;
DefaultHelp:
	db	"Usage: help <command name>", 0xD, 0xA, 0XA
	db	"Description: help will provide description and", 0xD, 0xA
	db	"instructions for the use of a specific command.", 0xD, 0xA
	db	"To see a list of all commands, type 'cmdlist'. ", 0xD, 0xA, 0xA,
	db	"Help in html format is in the docs/ folder or on the web at ", 0xD, 0xA
	db      "https://cotarr.github.io/calc-pi-x86-64-asm/docs/", 0xD, 0xA, 0xA
	db	"Help is available for the following commands:", 0xD, 0xA, 0xA, 0


HelpNotFound:
	db	"No help was found for that command.", 0xD, 0xA, 0xA
	db	"To see a list of all commands, type 'cmdlist'.", 0xD, 0xA
	db	"To see help for a specific command type: 'help <command>'.", 0xD, 0xA
	db	"Help is available for the following commands:", 0xD, 0xA, 0xA, 0
;
; Welcome message shown at program start
;
WelcomeMsg:		; 0x22 is double quote
	db	"SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR", 0xD, 0xA, 0xA
	db	"MIT License", 0xD, 0xA, 0xA
	db	"Copyright 2014-2020 David Bolenbaugh", 0xD, 0xA, 0xA
	db	"Permission is hereby granted, free of charge, to any person obtaining a copy", 0xD, 0xA
	db	"of this software and associated documentation files (the ", 0x22, "Software", 0x22, "), to deal", 0xD, 0xA
	db	"in the Software without restriction, including without limitation the rights", 0xD, 0xA
	db	"to use, copy, modify, merge, publish, distribute, sublicense, and/or sell", 0xD, 0xA
	db	"copies of the Software, and to permit persons to whom the Software is", 0xD, 0xA
	db	"furnished to do so, subject to the following conditions:", 0xD, 0xA, 0xA
	db	"The above copyright notice and this permission notice shall be included in all", 0xD, 0xA
	db	"copies or substantial portions of the Software.", 0xD, 0xA, 0xA
	db	"THE SOFTWARE IS PROVIDED ", 0x22, "AS IS", 0x22, ", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR", 0xD, 0xA
	db	"IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, ", 0xD, 0xA
	db	"FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE", 0xD, 0xA
	db	"AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER", 0xD, 0xA
	db	"LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, ", 0xD, 0xA
	db	"OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE", 0xD, 0xA
	db	"SOFTWARE.", 0xD, 0xA, 0xA
	db	"Source code: https://github.com/cotarr/calc-pi-x86-64-asm", 0xD, 0xA, 0xA, 0


SECTION         .bss    ; Section containing uninitialized data

SECTION         .text   ; Section containing code


;-----------------------------------------------------------------------------
;
;    Help Welcome Message
;
;    Input: none
;
;    Output: none
;
;-----------------------------------------------------------------------------
Help_Welcome:
	push	rax
	push	rbx
	push	rbp
;
	call	CROut
	mov	rax, WelcomeMsg			; Get address of welcome message
	call	StrOut				; Print welcome message

	pop	rbp
	pop	rbx
	pop	rax
	ret
;
;-----------------------------------------------------------------------------
;
;    Help Interface
;
;    Input: RAX address to input command buffer
;
;    Output: none
;
;-----------------------------------------------------------------------------
Help:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
;
; Check alignment of command table (could be entry/code error)
;
	mov	rbx, Help_Table_End		; Check for byte alignment
	and	rbx, 0x07			; Should be zero
	jz	.Help_Tab_OK
	mov	rax, .Command_Error2
	call	StrOut
	mov	rax, 0
	jmp	FatalError
.Help_Tab_OK:
;
; Check for help argument, if no argument then show default help
	or 	rax, rax
	jnz	.Help_Argument_Found
	mov	rax, DefaultHelp
	call	StrOut
	call	PrintHelpList
	jmp	.exit
;
;
; Loop here for next help argument check
;
.Help_Argument_Found:
	mov	rbx, Help_Table			; Table Address
.Help_Tab_Loop1:
;
; Check for end of table, if end, show default message
;
	cmp	byte [rbx], 0			; Check for past last command in table
	jne	.not_table_end			; Zero marker found, end of command table
	mov	rax, HelpNotFound
	call	StrOut
	call	PrintHelpList
	jmp	.exit
.not_table_end:
	mov	rbp, 0				; Reset pointer to start of record
;
; Loop here for next character check
;
.Help_Tab_Loop2:
	mov	dl, [rax+rbp]
	cmp	byte [rbx+rbp], dl
	jne	.Help_Tab_Next
	inc	rbp				; next character compare
	cmp	rbp, 8				; Only 7 char + zero allowed
	jne	.Help_Tab_Skip1			; 8 Found is fatal error in table
	mov	rax, .Command_Error1
	call	StrOut
	mov	rax, 0
	call	FatalError
.Help_Tab_Skip1:
	cmp	byte [rbx+rbp], 0		; No more characters?
	jne	.Help_Tab_Loop2			; Not zero, more to check
	cmp	byte [rax+rbp], 0		; Else was zero, see if command 0 or space
	je	.Help_Tab_Match
	jmp	.Help_Tab_Next			; Not match zero or space on next char
.Help_Tab_Match:
	mov	rax, [rbx+BYTE_PER_WORD]
	call	StrOut
	jmp	.exit
.Help_Tab_Next:
	add	rbx, (BYTE_PER_WORD * 2)	; Point to next command
	jmp	.Help_Tab_Loop1
.exit:
	call	CROut
;
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
.Command_Error1:
	db	"HelpCmd: zero end marker not found in text table", 0xD, 0xA, 0
.Command_Error2:
	db	"HelpCmd: End of help table not QWord aligned, probably table error", 0xD, 0xA, 0
;-----------------------------------------------------------------------
;----------------------------------------------
;
; Print Command List
;
; Input:
;
;----------------------------------------------

PrintHelpList:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	r15

	mov	r15, 0				; Initialize line feed coutner
	mov	CL, al				; Get search character
	mov	rbx, Help_Table			; Address of command table
.loop1:
	mov	rax, rbx			; Get pointer
	mov	dl, [rax]			; Get character to see if done
	or	dl, dl				; Is it zero, then done
	jz	.done
	call	StrOut				; Print command
	mov	al, ' '
	call	CharOut
	inc	r15				; Increment line feed counter
	cmp	r15, 8				; Check limit
	jc	.skip2
	mov	r15, 0				; Reset counter
	call	CROut				; Return + line feed
.skip2:
	add	rbx, (BYTE_PER_WORD * 2)
	jmp	.loop1
.done:
	pop	r15
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;----------------------------------------------
;
; Print All Help
;
; Input:
;
;----------------------------------------------

PrintAllHelp:
	push	rax
	push	rbx
	push	rcx
	push	rdx

	mov	rbx, Help_Table			; Address of command table
.loop1:
	call	CROut
	mov	rax, HelpListDiv
	call	StrOut
	mov	rax, rbx			; Get pointer
	mov	dl, [rax]			; Get character to see if done
	or	dl, dl				; Is it zero, then done
	jz	.done
	call	StrOut				; Print command
	call	CROut
	mov	rax, HelpListDiv
	call	StrOut
	call	CROut
	add	rbx, BYTE_PER_WORD		; Point at next address pointer
	mov	rax, [rbx]			; Move address from memory to RAX
	call	StrOut				; Print command
.skip2:
	add	rbx, BYTE_PER_WORD
	jmp	.loop1
.done:
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
HelpListDiv:	db	"----------", 0xD, 0xA, " ", 0

;
;--------------------
; help.asm - EOF
;--------------------
