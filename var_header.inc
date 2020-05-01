;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Global include file - variables and data storage
;
; File:   var_header.inc
; Exec:   calc-pi
;
; Created   10/15/2014
; Last Edit 08/14/2015
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
;   Conditional Code Flags
%define CHECK4ERRORS
%define PROFILE
;
; General Register Notes (Keep it simple)
;
;   ----- i86-64 bit values
WSCALE			equ	8	; For effective address calculation, 4 or 8 depend on word size
BIT_PER_WORD		equ	0x040	; 020H for 32 Bit, 040H for 64 Bit
BYTE_PER_WORD		equ	0x08	; 004H for 32 Bit, 008H for 64 Bit
%define	WORDFFFF	0x0FFFFFFFFFFFFFFFF
%define WORD8000	0x08000000000000000
%define WORD4000	0x04000000000000000
;                          0123456789abcdef <-- Ruler
;
;  insert comment with (32_64_CHECK) if upgrade to 64 bit should look at this

; Variable size and Exponent size must be multiple of 8 byte (64 bit) QWord
;
;VAR_WSIZE	equ	0x010		;Size of variable in words (~250  Digits)
;VAR_WSIZE	equ	0x0100		;Size of variable in words (~  4 KDigits)
;VAR_WSIZE	equ	0x01000		;Size of variable in words (~ 75 KDigits)
;VAR_WSIZE	equ	0x010000	;Size of variable in words (1.26 MDigits)
;VAR_WSIZE	equ	0x040000	;Size of variable in words ( ~5 MDigits)
;VAR_WSIZE	equ	0x0100000	;Size of variable in words (~20 MDigits)
VAR_WSIZE	equ	0x0200000	;Size of variable in words (~40 MDigits)
;VAR_WSIZE	equ	0x0400000	;Size of variable in words (~80.8 MDigits)
;VAR_WSIZE	equ	0x0800000	;Size of variable in words (~161  MDigits)
;
EXP_WSIZE 	equ     1				;Size of binary exponent in words
VAR_BSIZE	equ	(VAR_WSIZE * BYTE_PER_WORD)	;Maximum size of variable in bytes
EXP_BSIZE 	equ     (EXP_WSIZE * BYTE_PER_WORD)	;Size of binary exponent in bytes
MAN_WSIZE  	equ     (VAR_WSIZE - EXP_WSIZE)		;Maximum size of Mantissa in words
MAN_BSIZE  	equ     (VAR_BSIZE - EXP_BSIZE)		;Maximum size of Mantissa in bytes

MAN_MSB_OFST	equ     MAN_BSIZE-1			;Offset mantissa most significant byte
MAN_MSW_OFST	equ     MAN_BSIZE-(1*BYTE_PER_WORD)	;Offset mantissa most significant word

EXP_MSB_OFST	equ     VAR_BSIZE-1			;Offset exponent most significant byte
EXP_MSW_OFST	equ     VAR_BSIZE-(BYTE_PER_WORD)	;Offset exponent most significant word
EXP_WORD_OFST	equ	VAR_BSIZE-(EXP_BSIZE)		;Assumes exponent is one word

GUARDWORDS	equ     4   ;12/13/14 FP_Reciprocal and Function_calc_sr2 need 4 guard words
GUARDBYTES	equ	(GUARDWORDS*BYTE_PER_WORD)

INIT_NO_WORD	equ	4+GUARDWORDS			; Initial accuracy setting when program starts
MINIMUM_WORD	equ	2+GUARDWORDS  			;**** Includes GUARD Bytes ****

INIT_SIG_DIG	equ	60
INIT_EXT_DIG	equ	0
MINIMUM_DIG	equ	5				; needed for printing
;
; Linux 64 bit syscall list
;
%define sys_read	0x00
%define sys_write	0x01
%define sys_open	0x02
%define sys_close	0x03
%define sys_creat	0x55
;
%define sys_time	0xC9
%define sys_exit	0x3C
;
;
;
;  Following from http://www.opensource.apple.com/source/xnu/xnu-1456.1.26/bsd/sys/fcntl.h
%define O_RDONLY	0x0000		; open for reading only */
%define O_WRONLY	0x0001		; open for writing only */
%define O_RDWR		0x0002		; open for reading and writing */
%define O_ACCMODE	0x0003		; mask for above modes */
%define O_APPEND	0x0008		; set append mode */
%define O_CREAT		0x0200		; create if nonexistant */
%define O_TRUNC		0x0400		; truncate to zero length */
%define O_EXCL		0x0800		; error if already exists */


;-------------------------
; Variable Handle Numbers
;-------------------------
;
HAND_ACC	equ	0
HAND_OPR	equ	1
HAND_WORKA	equ	2
HAND_WORKB	equ	3
HAND_WORKC	equ	4
HAND_XREG	equ	5
HAND_YREG	equ	6
HAND_ZREG	equ	7
HAND_TREG	equ	8
HAND_REG0	equ	9
HAND_REG1	equ	10
HAND_REG2	equ	11
HAND_REG3	equ 	12
HAND_REG4	equ	13
HAND_REG5	equ	14
HAND_REG6	equ	15
HAND_REG7	equ	16
TOPHAND		equ	HAND_REG7

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Global Variable Label Declarations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%ifdef IO_MODULE
	global fd_echo
	global FN_Echo
%else
	extern fd_echo
	extern FN_Echo
%endif


%ifdef	MATH
	global RegAddTable	; Address table holding addresses of large floating point variables
	global RegNameTable	; Address table holding string of variable names
	global No_Byte		; Number of bytes in Mantissa (may change during calculations)
	global No_Word		; Number of words in Mantissa (may change during calculations)
	global LSWOfst		; Offset of current M.S.Word at current No_Word accuracy
	global D_Flt_Byte	; Default Number of bytes in Mantissa
	global D_Flt_Word	; Default Number of words in Mantissa
	global D_Flt_LSWO	; Default LS word offset
	global File_Last_Word	; Remember last when loading from file
	global File_Last_Byte	; Remember last when loading from file
	global File_Last_LSWO	; Remember last when loading from file
	global NoSigDig		; Number of base-10 significant digits
	global File_Last_SDig	; Remember last when loading from file (significant digits)
	global NoExtDig		; Additional base-10 digits to print
	global MathMode		; Type of multiplication and Division
	global ProgSTime	; System time of program start
	global StartSTime	; System time at start of calculation
	global LapSTime		; System time at step calculation
	global CalcSTime	; System time of calculation
	global Timer0		; 10 words for timer if needed
	global Out_Mode		; used by output routine
	global INT_Remainder

	global DebugFlag
	global StackPtrSnapshot
	global StackPtrEntry

	global iCounter01	; Iteration counter
	global iCounter02
	global iCounter03
	global iCounter04
	global iCounter05
	global iPrintSumCount
	global iPrintSumCountLimit
	global iVerboseFlags
	global iShowCalc
	global iShowCalcMask
	global iShowCalcStep

	global Shift_Count
	global Last_Shift_Count
	global Nearly_Zero
	global Last_Nearly_Zero
	global Sum_Limit
	global LCG_Seed
	global LFSR_Seed1
	global LFSR_Seed2
	global RNG_LastN
	global f_ln_noword_exp
	global f_ln_noword_newton

	global OutCountActive
        global OutPreCount
        global OutPreCountLimit
        global OutCharCount
        global OutWordCount
        global OutLineCount
        global OutLineCountLimit
        global OutParaCount
	global OutInhibit
	global ConInhibit
	global HeaderMode

	global DescriptionLen
	global Description

	global FP_Acc		;Addresses of large floating point variables
	global FP_Opr
	global FP_WorkA
	global FP_WorkB
	global FP_WorkC
	global FP_X_Reg
	global FP_Y_Reg
	global FP_Z_Reg
	global FP_T_Reg
	global FP_Reg0
	global FP_Reg1
	global FP_Reg2
	global FP_Reg3
	global FP_Reg4
	global FP_Reg5
	global FP_Reg6
	global FP_Reg7
	global FP_Reg8
	global FP_Reg9
%else
	extern RegAddTable
	extern RegNameTable
	extern No_Byte
	extern No_Word
	extern LSWOfst
	extern D_Flt_Byte
	extern D_Flt_Word
	extern D_Flt_LSWO
	extern File_Last_Word
	extern File_Last_Byte
	extern File_Last_LSWO
	extern NoSigDig
	extern File_Last_SDig
	extern NoExtDig
	extern MathMode
	extern ProgSTime
	extern StartSTime
	extern LapSTime
	extern CalcSTime
	extern Timer0
	extern Out_Mode
	extern INT_Remainder

	extern DebugFlag
	extern StackPtrSnapshot
	extern StackPtrEntry
	extern iCounter01
	extern iCounter02
	extern iCounter03
	extern iCounter04
	extern iCounter05
	extern iPrintSumCount
	extern iPrintSumCountLimit
	extern iVerboseFlags
	extern iShowCalc
	extern iShowCalcMask
	extern iShowCalcStep

	extern Shift_Count
	extern Last_Shift_Count
	extern Nearly_Zero
	extern Last_Nearly_Zero
	extern Sum_Limit
	extern LCG_Seed
	extern LFSR_Seed1
	extern LFSR_Seed2
	extern RNG_LastN
	extern f_ln_noword_exp
	extern f_ln_noword_newton


	extern OutCountActive
        extern OutPreCount
        extern OutPreCountLimit
        extern OutCharCount
        extern OutWordCount
        extern OutLineCount
        extern OutLineCountLimit
        extern OutParaCount
	extern OutInhibit
	extern ConInhibit
	extern HeaderMode

	extern DescriptionLen
	extern Description

	extern FP_Acc;
	extern FP_Opr;
	extern FP_WorkA;
	extern FP_WorkB;
	extern FP_WorkC;
	extern FP_X_Reg;
	extern FP_Y_Reg;
	extern FP_Z_Reg;
	extern FP_T_Reg;
	extern FP_Reg0
	extern FP_Reg1
	extern FP_Reg2
	extern FP_Reg3
	extern FP_Reg4
	extern FP_Reg5
	extern FP_Reg6
	extern FP_Reg7
	extern FP_Reg8
	extern FP_Reg9

%endif
