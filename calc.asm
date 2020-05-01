%define CALC1234
%include "var_header.inc"	; Header has global variable definitions for other modules
%include "func_header.inc"	; Header has global function definitions for other modules
;--------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; Contains calculation of specific constants
;
; File    calc.asm
; Module: calc.asm, calc.o
; Exec:   calc-pi
;
; Created:    11/08/2014
; Last Edit:  04/25/2020
;
;-------------------------------------------------------------
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
SECTION		.data   ; Section containing initialized data

;
SECTION		.bss    ; Section containing uninitialized data


SECTION		.text	; Section containing code

;--------------------------------------------------------------
;
;   Include Functions
;
;--------------------------------------------------------------

%INCLUDE "calc-pi-st.asm"
%INCLUDE "calc-pi-ra.asm"
%INCLUDE "calc-pi-ch.asm"
%INCLUDE "calc-pi-mc.asm"
%INCLUDE "calc-e.asm"
%INCLUDE "calc-sr2.asm"
%INCLUDE "calc-zeta.asm"
;---------------------
; End functions.asm
;---------------------
