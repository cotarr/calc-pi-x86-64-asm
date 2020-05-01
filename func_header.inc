;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Global incluse file - functions headers
;
; File:   func_header.inc
; Exec:   calc-pi
;
; Created   10/15/2014
; Last Edit 04/29/2020
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

;===========================================
%ifdef MAINFILE
	global	_start
	global ProgramExit
	global FatalError
%else
	extern	_start
	extern ProgramExit
	extern FatalError
%endif
;===========================================
%ifdef HELP4334
	global Help_Welcome
	global Help_sigfigs
	global Help
	global PrintAllHelp
%else
	extern Help_Welcome
	extern Help_sigfigs
	extern Help
	extern PrintAllHelp
%endif
;===========================================
%ifdef FUNC1234
	global Function_arcsin_x
	global Function_cos_x
	global Function_sin_x
	global Function_nth_root_x
	global Function_int_power_x
	global Function_exp_x
	global Function_ln_x_by_guess
	global Function_ln_x_series
%else
	extern Function_arcsin_x
	extern Function_cos_x
	extern Function_sin_x
	extern Function_int_power_x
	extern Function_nth_root_x
	extern Function_exp_x
	extern Function_ln_x_by_guess
	extern Function_ln_x_series
%endif
;===========================================
%ifdef CALC1234
	global Function_calc_pi_chud
	global Function_calc_pi_ram
	global Function_calc_pi_sto
	global Function_calc_pi_monte_carlo
	global Function_calc_e_Fix
	global Function_calc_e_FP
	global Function_calc_e_Reg
	global Function_calc_ln2
	global Function_calc_sr2
	global Function_calc_zeta
	global Function_calc_pi_zeta2
%else
	extern Function_calc_pi_chud
	extern Function_calc_pi_ram
	extern Function_calc_pi_sto
	extern Function_calc_pi_monte_carlo
	extern Function_calc_e_Fix
	extern Function_calc_e_FP
	extern Function_calc_e_Reg
	extern Function_calc_ln2
	extern Function_calc_sr2
	extern Function_calc_zeta
	extern Function_calc_pi_zeta2
%endif
;===========================================
%ifdef IO_MODULE
	global InitializeIO
	global FileCloseForExit
	global StartEcho
	global StopEcho
	global CheckEchoing
	global SaveVariable
	global LoadVariable
	global EnterFileDescription
	global CharOut
	global CharOutFmt
	global CharOutFmtInit
	global CROut
	global StrOut
	global KeyIn
	global ReadSysTime
%else
	extern InitializeIO
	extern FileCloseForExit
	extern StartEcho
	extern StopEcho
	extern CheckEchoing
	extern SaveVariable
	extern LoadVariable
	extern EnterFileDescription
	extern CharOut
	extern CharOutFmt
	extern CharOutFmtInit
	extern CROut
	extern StrOut
	extern KeyIn
	extern ReadSysTime
%endif
;===========================================
%ifdef PARSER
	global ParseCmd
	global SetNormal
%else
	extern ParseCmd
	extern SetNormal
%endif
;===========================================
%ifdef	MATH
; math.asm
	global Set_No_Word
	global Set_No_Word_Temp
	global GrabSeriesAccuracy
	global ClearGrabAccuracy
	global ReduceSeriesAccuracy
	global RestoreFullAccuracy
; math-fixed.asm
	global FIX_Load64BitNumber
	global FIX_TwosCompliment
	global FIX_VA_Addition
	global FIX_Addition
	global FIX_Subtraction
	global FIX_US_Multiplication
	global FIX_US_VA_Division
	global FIX_US_Division
	global FIX_Check_Sum_Done
	global Conv_FP_to_FIX
	global Conv_FIX_to_FP

; math-subr.asm
	global FP_Initialize
	global GetVarNameAdr
	global ClearVariable
	global SetToOne
	global SetToTwo
	global CopyVariable
	global ExchangeVariable
	global FP_TwosCompliment
	global FP_Load64BitNumber
; math-rotate.asm
	global Left1BitAdjExp
	global Left1Bit
	global Right1BitAdjExp
	global Right1Bit
	global Left1ByteAdjExp
	global Left1Byte
	global Right1ByteAdjExp
	global Right1Byte
	global Left1WordAdjExp
	global Left1Word
	global Right1WordAdjExp
	global Right1Word
	global FP_Normalize
; math-arith.asm
	global FP_Addition
	global FP_Multiplication
	global FP_Short_Multiplication
	global FP_Long_Multiplication
	global FP_Word_Multiplication
	global FP_Division
	global FP_Register_Division
	global FP_Short_Division
	global FP_Long_Division
	global FP_Reciprocal
; math-output.asm
	global PrintResult
	global PrintVariable
	global PrintSciNotOld
	global IntegerInput
	global FP_Exponent_XReg_Input
; math-debug.asm
	global Header_Update
	global Header_Init
	global Header_Cancel
	global ClrScr
	global Variable_Compare
	global Profile_Init
	global Profile_Show
	global Profile_Show_Always
	global ShowCalcProgress
	global PrintVar
	global PrintHex
	global DebugFillVariable
	global EndianCheck
%else
; math.asm
	extern Set_No_Word
	extern Set_No_Word_Temp
	extern GrabSeriesAccuracy
	extern ClearGrabAccuracy
	extern ReduceSeriesAccuracy
	extern RestoreFullAccuracy
; math-fixed.asm
	extern FIX_Load64BitNumber
	extern FIX_TwosCompliment
	extern FIX_VA_Addition
	extern FIX_Addition
	extern FIX_Subtraction
	extern FIX_US_Multiplication
	extern FIX_US_VA_Division
	extern FIX_US_Division
	extern FIX_Check_Sum_Done
	extern Conv_FP_to_FIX
	extern Conv_FIX_to_FP
; math-subr.asm
	extern FP_Initialize
	extern GetVarNameAdr
	extern ClearVariable
	extern SetToOne
	extern SetToTwo
	extern CopyVariable
	extern ExchangeVariable
	extern FP_TwosCompliment
	extern FP_Load64BitNumber
; math-rotate.asm
	extern Left1BitAdjExp
	extern Left1Bit
	extern Right1BitAdjExp
	extern Right1Bit
	extern Left1ByteAdjExp
	extern Left1Byte
	extern Right1ByteAdjExp
	extern Right1Byte
	extern Left1WordAdjExp
	extern Left1Word
	extern Right1WordAdjExp
	extern Right1Word
	extern FP_Normalize
; math-arith.asm
	extern FP_Addition
	extern FP_Multiplication
	extern FP_Division
	extern FP_Register_Division
	extern FP_Short_Division
	extern FP_Long_Division
	extern FP_Reciprocal
; math-output.asm
	extern PrintResult
	extern IntegerInput
	extern PrintVariable
	extern PrintSciNotOld
	extern FP_Exponent_XReg_Input
; math-debug.asm
	extern Header_Update
	extern Header_Init
	extern Header_Cancel
	extern ClrScr
	extern Variable_Compare
	extern Profile_Init
	extern Profile_Show
	extern Profile_Show_Always
	extern ShowCalcProgress
	extern PrintVar
	extern PrintHex
	extern DebugFillVariable
	extern EndianCheck
%endif
;===========================================
%ifdef UTIL
	global PrintAccuracy
	global SetDigitAccuracy
	global SetExtendedDigits
	global SetWordAccuracy
	global SetMaximumAccuracy
	global PrintAccVerbose
	global PrintWordB10
	global Digits_2_Words
	global Words_2_Digits
	global PrintHexByte
	global PrintHexWord
	global PrintDDHHMMSS
	global IntWordInput
%else
	extern PrintAccuracy
	extern SetDigitAccuracy
	extern SetExtendedDigits
	extern SetWordAccuracy
	extern SetMaximumAccuracy
	extern PrintAccVerbose
	extern PrintWordB10
	extern Digits_2_Words
	extern Words_2_Digits
	extern PrintHexByte
	extern PrintHexWord
	extern PrintDDHHMMSS
	extern IntWordInput
%endif
;===========================================
%ifdef SANDBOX
	global Sand
	global SandBox
%else
	extern Sand
	extern SandBox
%endif
;===========================================
