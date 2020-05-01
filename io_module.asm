%define IO_MODULE
%include "var_header.inc"		; Header has global variable definitions for other modules
%include "func_header.inc"		; Header has global function definitions for other modules
;-------------------------------------------------------------
;
; SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR
;
; INPUT / OUTPUT MODULE
; This module contains Input and Output routines
;
; Module: io_module.asm
; Module: io_module.asm, io_module.o
; Exec:   calc-pi
;
; Created:    10/14/2014
; Last rdit:  05/15/2015
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
;  TODO ***** check RCX and R11 destroyed on SYSCALL
;
;-------------------------------------------------------------
; InitializeIO
; FileCloseForExit
; StartEcho
; StopEcho
; CheckEchoing
; LoadVariable
; SaveVariable
; EnterFileDescription
; CharOutFmt
; CharOut
; CROut
; StrOut
; ClrScr
; KeyIn
; ReadSysTime
;-------------------------------------------------------------
SECTION		.data   ; Section containing initialized data
;
CharOutbuf:	db  	0			; Used by CharOut to hold output character for syscall
time2:		dq	0			; Used by sys_time call
;FN_Echo:	db	"out/output.txt", 0
						; File name for echoing the console terminal
;
FN_Echo:	db	"out/out000.txt"
						; WARNING 0 position hardcoded below
;
SECTION		.bss    ; Section containing uninitialized data
;
KeyBufLen	equ	0x100
KeyBuf:		resb	KeyBufLen		; buffer for keyboard input
FilenameLen	equ	0x100
Filename:	resb	FilenameLen
InBufLen	equ	0x100
InBuf:		resb	InBufLen
OutBufLen	equ	0x100
OutBuf:		resb	OutBufLen
fd_echo:	resq	1			; File descriptor (console echo)
fd_out:		resq	1			; File descriptor (saving variable)
fd_in:		resq	1			; Fine descriptor (loading variable
;
SECTION		.text				; Section containing code
;
;--------------------------------------------------------------
;
;   Initialize I/O
;
;--------------------------------------------------------------
InitializeIO:
	push	rax
	mov	rax, 0
	mov	[fd_echo], rax			; Mark file descriptors as file closed
	mov	[fd_out], rax			; Mark file descriptors as file closed
	mov	[fd_in], rax			; Mark file descriptors as file closed
	pop	rax
	ret
;--------------------------------------------------------------
;
;   Shutdown I/O for protram exit
;
;--------------------------------------------------------------
FileCloseForExit:
	push	rax
	push	rdi
	push	rcx
	push	r11
;
	mov	rax, [fd_echo]
	or	rax, rax			; file open?
	jz 	.skip1
;
; Close the file
	mov	rax, sys_close
	mov	rdi, [fd_echo]
	syscall
.skip1:
	pop	r11
	pop	rcx
	pop	rdi
	pop	rax
	ret
;--------------------------------------------------------------
;
;   Echo console output to sequential numbered file
;
;   Input:  none
;
;   Output: none
;
;--------------------------------------------------------------
StartEcho:
	push	rax
	push	rbx
	push	rcx				; corrupted by by sys_call
	push	rdx
	push	rbp
	push	rsi
	push	rdi
	push	r11				; maybe corrupted by sys_call
;
; Check for handle in use
;
	mov	rax, [fd_echo]			; if file open?
	or	rax, rax			; if zero closed
	jz	.skip1
	mov	rax, .msg4			; Error: File handle not zero
	call	StrOut				; error message
	jmp	.exit
.skip1:
;
; Clear inhibit if left enabled
;
	mov	rax, 0
	mov	[OutInhibit], rax
;
;  Setfilename to "000"
;
	mov	al, 0x30			; ASCII digit for zero
	mov	[FN_Echo+7], al			; set to "000"
	mov	[FN_Echo+8], al
	mov	[FN_Echo+9], al
;
;  Increment file name to next number
;
.TryNextFN:
	mov	rbx, FN_Echo+9			; Address of 1's digit
	inc	byte [rbx]			; Increment ascii digit
	cmp	byte [rbx], 0x3A		; greater than character 9  ?
	jl	.GoTryFile			; OK, go try open file
;
	mov	byte [rbx], 0x30		; ASCII digit back to 0
	mov	rbx, FN_Echo+8			; Address of 10's digit
	inc	byte [rbx]			; increment
	cmp	byte [rbx], 0x3A		; greater than character 9  ?
	jl	.GoTryFile			; OK, go try open file
;
	mov	byte[rbx], 0x30			; ASCII digit back to 0
	mov	rbx, FN_Echo+7			; Address of 100's digit
	inc	byte [rbx]			; increment
	cmp	byte [rbx], 0x3A		; greater than character 9  ?
	jl	.GoTryFile			; OK, go try open file
;
;  Handle no more filename error
;
	mov	rax, .msg5			; No more filename error
	call	StrOut
	jmp	.exit				; exit without open file.
;
.GoTryFile:
	mov	rax, .msg2			; Echoing console to file
	call	StrOut				; Message to console
	mov	rax, FN_Echo			; Filename
	call	StrOut
	call	CROut
;
;  See if file exists, Open the file (check for error)
;
	mov	rax, sys_open			; sys call open stream
	mov	rdi, FN_Echo			; filename
	mov	rsi, O_RDONLY			; Mode=read only, checking if exists
	mov	rdx, 0o644			; File permissions
	syscall					; Call Kernel
;
;  Error, see if file not exist
;
	mov	rcx, -2				; File not found error
	cmp	rax, rcx			; was file found?
	je	.ok_not_exist			; No, not found, this is the expected result
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jne	.error1				; Handle the generic error
;
; close the file (File is open from read, close it)
;
	push	rax				; Save file handle
	pop	rdi				; Restore File handle
	mov	rax, sys_close		;
	syscall					; Call kernel to close the file
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1				; Handle generic file error
	jmp	.TryNextFN			; Try next filename

.ok_not_exist:
;
;create the file
;
	mov	rax, sys_creat			; Create new file
	mov	rdi, FN_Echo			; Filename incrementing filename
	mov	rsi, 0o644			; File permissions
	syscall					; Call Kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1				; Handle generic file error
;
;  File is open for write, save handle
;
	mov	[fd_echo], rax			; save handle
	mov	rax, .msg6			; tell of open file
	call	StrOut
	mov	rax, FN_Echo			; filename
	call	StrOut
	call	CROut
.exit:
	pop	r11
	pop	rdi
	pop	rsi
	pop	rbp
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
; Jump here if error to print message
;
.error1:
	push	rax
	mov	rax, 0
	mov	[fd_echo], rax			; Save error
	mov	rax, .msg1			; Error message
	call	StrOut;
	pop	rax				; Get error code
	neg	rax				; 2's compliment to make positive
	call	PrintWordB10			; Error number
	call	CROut
	jmp	.exit

.msg1:	db	0xD, 0xA, "Error trying to open file for console echo. Code: ", 0
.msg2:	db	"      Trying file: ", 0
.msg3:	db	"File output.txt not found. Creating file.", 0xD, 0xA, 0
.msg4:	db	0xD, 0xA, "Error: There is already a file handle associated with console echo", 0xD, 0xA, 0
.msg5:	db	0xD, 0xA, "Error: Only 999 sequential filenames allowed.", 0xD, 0xA, 0
.msg6:	db	0xD, 0xA, "Echoing StdOut to file: ", 0

;--------------------------------------------------------------
;
;   Terminate console output to file: output.txt
;
;   Input:  none
;
;   Output: none
;
;--------------------------------------------------------------
StopEcho:
	push	rax
	push	rdi
	push	rcx				; corrupted by by sys_call
	push	r11				; maybe corrupted by sys_call

	mov	rax, [fd_echo]			; is file open?
	or	rax, rax
	jnz	.skip1
	mov	rax, .msg1
	call	StrOut				; Print error message
	jmp	.exit
.skip1:
	mov	rax, .msg2
	call	StrOut
	mov	rax, FN_Echo
	call	StrOut
	call	CROut
; Close the file
	mov	rax, sys_close
	mov	rdi, [fd_echo]
	syscall
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1
	mov	[fd_echo], rax			; save handle
.exit:
	pop	r11
	pop	rcx
	pop	rdi
	pop	rax
	ret
.error1:
	push	rax
	mov	rax, 0
	mov	[fd_echo], rax			; Save error
	mov	rax, .msg3			; Error message
	call	StrOut;
	pop	rax
	call	PrintHexWord			; Error number
	call	CROut
	jmp	.exit
;
.msg1	db	0xD, 0xA, "Error: output not currently echoing to file", 0xD, 0xA, 0
.msg2	db	"Closing file: ", 0
.msg3	db	0xD, 0xA, "Error closing text capture output file", 0xD, 0xA, 0;
;
;--------------------------------------------------------------
;
;   Check if output is echoing to file
;
;  Output  RAX = 0, not echoing
;          RAX = 1, echoing
;
;--------------------------------------------------------------
CheckEchoing:
	mov	rax, [fd_echo]
	or	rax, rax			; Is file handle zero (file closed?)
	jz	.skip1				; RAX is zero, file is closed, return zero
	mov	rax, 1				; RAX not zero, return 1
.skip1:
	ret
;
;--------------------------------------------------------------
;
;   Load Variable from file
;
;   Input: RAX = address of filename buffer
;                  or RAX = 0 to prompt
;
;        See SaveVariable for format description
;
;--------------------------------------------------------------
;
LoadVariable:
;
; Preserve Registers
;
	push	rax				; General use
	push	rbx				; Address Pointer
	push	rcx				; Counter
	push	rdx				; Address Pointer
	push	rsi				; Used system call
	push	rdi				; Used system call
	push	rbp				; Pointer index
	push	r11				; maybe corrupted by sys_call
;
; Prompt for filename and get input
;
	or	rax, rax			; check for zero
	jnz	.have_fn			; not zero have filename
	mov	rax, .FNPrompt
	call	StrOut				; Issue prompt to operaator
	call	KeyIn				; Get filename
.have_fn:
	mov	rbx, rax			; Address to buffer
	mov	rdx, Filename			; Address to filename
	mov	rcx, 0				; Counter
	mov	rbp, 0				; Index
.loop1:
	mov	al, [rbx+rbp]			; Get character from KeyBuf
	mov	[rdx+rbp], al			; Save character in Finename
	or	al, al				; Done?
	jz	.ckfn				; End of string marker
	inc	rbp				; Point next character
	inc	rcx				; Character Counter
	cmp	rcx, 80				; Maximum filename size
	jl	.loop1				; Size ok? Yes, loop for more characters
						; No, filename too long error
	mov	rax, .InvalidFN
	call	StrOut				; Error message invalid filename (too short)
	jmp	.exit				; Abort function
.ckfn:
	cmp	rcx, 3				; Check Filename length, must be 3 or greater
	jge	.fnok				; filename length ok
	mov	rax, .InvalidFN
	call	StrOut				; Error message invalid filename (too long)
	jmp	.exit				; Abort function
.fnok:
	mov	al, '.'				; Filename Extension ".num"
	mov	[rdx+rbp], al
	inc	rbp
	mov	al, 'n'
	mov	[rdx+rbp], al
	inc	rbp
	mov	al, 'u'
	mov	[rdx+rbp], al
	inc	rbp
	mov	al, 'm'
	mov	[rdx+rbp], al
	inc	rbp
	mov	al, 0				; Null terminate filename
	mov	[rdx+rbp], al
	inc	rbp
;
; Print filename (for capture text output)
;
	mov	rax, .FileNameMsg
	call	StrOut
	mov	rax, Filename
	call	StrOut
	call	CROut
;
;  Open the file for read, Check file exist, Check for error
;
	mov	rax, sys_open			; sys call code 1 = write
	mov	rdi, Filename			; Filename
	mov	rsi, O_RDONLY			; Open as read only
	mov	rdx, 0o644			; File permissions
	syscall					; Call Kernel
;
	mov	rcx, -2				; File not found error code
	cmp	rax, rcx			; was file found?
	jne	.skipFNF			; No, not found, handle not found error
	mov	rax, .LoadNotFound		; Message, file not found
	call	StrOut				; Print error
	jmp	.exit				; Abort functions
;
;  Error, Print generic error message
;
.skipFNF:
	mov	rcx, WORD8000			; Negative if error
	test	rax, rcx			; Error exist? (negative is error)
	jne	.error1				; Yes print generic error message
;
;  File handle
;
	mov	[fd_in], rax			; No error, file is open for read, save File handle
;
;  Save last accuracy
;
	mov	rax, [No_Word]
	mov	[File_Last_Word], rax
	mov	rax, [No_Byte]
	mov	[File_Last_Byte], rax
	mov	rax, [LSWOfst]
	mov	[File_Last_LSWO], rax
	mov	rax, [NoSigDig]
	mov	[File_Last_SDig], rax

		;---------------------------------
			; Read the program variable file
			; (See SaveVariable description for file format)
		;---------------------------------
;
; Read Header ID code, version, sub-version and reserved bytes
;      TODO parse these separately
;
	mov	rax, sys_read			; Mode to read stream
	mov	rdi, [fd_in]			; File descriptor
	mov	rsi, InBuf			; Input buffer
	mov	rdx, 8				; Read length
	syscall					; Call the kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1
;                     FEDCBA9876543210 <-- Ruler
	mov	rax, 0x5562020000000000
						; ID Code and version
	cmp	[InBuf], rax			; EOF marker found?
	je	.startmarkok			; Variable loaded successfully, done

	mov	rax, .ErrStMark			; Point to error message
	call	StrOut				; Print error message
	jmp	.abort				; restore accuracy, zero ACC, and exit
.startmarkok:
	mov	rax, .FileRec			; File recignized message
	call	StrOut
	mov	al, [InBuf+5]			; Get version
	or	al, 0x30			; Form ascii
	call	CharOut
	mov	al, '.'
	call	CharOut
	mov	al, [InBuf+4]			; SubVersion
	or	al, 0x30			; form ascii
	call	CharOut
	call	CROut
;
; Read system time stamp from file (ignored for now)
;
	mov	rax, sys_read			; Mode to read stream
	mov	rdi, [fd_in]			; File descriptor
	mov	rsi, InBuf			; Input buffer
	mov	rdx, 8				; Read length
	syscall					; Call the kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1
;
; Read description from file to description string variable
;
	mov	rax, sys_read			; Mode to read stream
	mov	rdi, [fd_in]			; File descriptor
	mov	rsi, Description			; Input buffer
	mov	rdx, 32				; Read length
	syscall					; Call the kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1
	mov	rax, .DescripMsg
	call	StrOut
	mov	rax, Description
	call	StrOut				; Print description
	call	CROut
;
;  Read Number Significant words in Mantissa
;
	mov	rax, sys_read			; Mode to read stream
	mov	rdi, [fd_in]			; File descriptor
	mov	rsi, InBuf			; Input buffer
	mov	rdx, 8				; Read length
	syscall					; Call the kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1
;  Check word minimum limit
	mov	rax, [InBuf]			; Get number of words
	mov	rbx, rax			; Save number of words
	cmp	rax, MINIMUM_WORD
	jge	.skipnml			; Less than minimum
	mov	rax, .LoadMin			; Point error message
	call	StrOut				; Print message
	jmp	.abort				; restore accuracy, zero ACC, and exit
; Check Word  Upper Limit
.skipnml:
	mov	rax, VAR_WSIZE-EXP_WSIZE
						; Maximum mantissa word size
	cmp	rax, rbx			; subtract requested amount
	jge	.skipwok			; if negative, request too small
	mov	rax, .LoadMax			; Point error message
	call	StrOut				; Print message
	jmp	.abort				; restore accuracy, zero ACC, and exit
; No word errors, save
.skipwok:
	mov	rax, rbx			; Remember number of words
	call	Set_No_Word			; Set No_Word, No_byte ... etc
;
;  Read number of significant digits in mantissa
;
	mov	rax, sys_read			; Mode to read stream
	mov	rdi, [fd_in]			; File descriptor
	mov	rsi, InBuf			; Input buffer
	mov	rdx, 8				; Read length
	syscall					; Call the kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1
; Check against minimum
	mov	rax, [InBuf]			; Get significant digits
	mov	rbx, rax			; Save number of digits
	cmp	rax, MINIMUM_DIG		; Less than minimum?
	jge	.skipmsd			; No above minimum, continue
	mov	rax, .LoadMinDig		; Point error message
	call	StrOut				; Print message
	jmp	.abort				; restore accuracy, zero ACC, and exit
; No digit errors, save
.skipmsd:
	mov	[NoSigDig], rbx			; Set number significant digits
;
; Print accuracy stuff
;
	mov	rax, [File_Last_Word]
	sub	rax, [No_Word]			; Are words the same as saved in file
	jne	.accsame
	mov	rax, [File_Last_SDig]
	sub	rax, [NoSigDig]			; Are digits the same as saved in file
	jne	.accsame
	mov	rax, .LoadSame			; Pointer to message
	call	StrOut				; Print message
	jmp	.skipshowacc
.accsame:
	mov	rax, [File_Last_Word]
	sub	rax, [No_Word]			; Are words the same as saved in file
	je	.wrdsame
	mov	rax, .WordChange
	call	StrOut				; print mssage of word change
	mov	rax, [File_Last_Word]
	call	PrintWordB10
	mov	rax, .MidChange
	call	StrOut				; print mssage of word change
	mov	rax, [No_Word]
	call	PrintWordB10
	call	CROut
.wrdsame:
	mov	rax, [File_Last_SDig]
	sub	rax, [NoSigDig]			; Are digits the same as saved in file
	je	.skipshowacc
	mov	rax, .DigChange
	call	StrOut				; print mssage of word change
	mov	rax, [File_Last_SDig]
	call	PrintWordB10
	mov	rax, .MidChange
	call	StrOut				; print mssage of word change
	mov	rax, [NoSigDig]
	call	PrintWordB10
	call	CROut
.skipshowacc:
;
; Setup addresses to write variable mantissa andexponent
;
	mov 	rsi, FP_Acc+EXP_WORD_OFST	; Point to  Exponent
	mov	rbp, [No_Word]			; Number words mantissa
	inc	rbp				; Increment to include exponent
;
; Loop to write exponent and mantissa
;
.loop:
	mov	rax, sys_read			; Mode to read stream
	mov	rdi, [fd_in]			; File descriptor
	;;;	rsi				; Pointer to data word
	mov	rdx, BYTE_PER_WORD		; Length for write
	syscall					; call kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1				; Handle generic error
	sub	rsi, BYTE_PER_WORD 		; Point to next work
	dec	rbp				; Increment counter
	jnz	.loop
;
; Read and check end of file marker
;
	mov	rax, sys_read			; Mode to read stream
	mov	rdi, [fd_in]			; File descriptor
	mov	rsi, InBuf			; Input buffer
	mov	rdx, 8				; Read length
	syscall					; Call the kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1
	mov	rax, 0x12344321			; End of file marker
	cmp	[InBuf], rax			; EOF marker found?
	je	.endmarkok			; Variable loaded successfully, done
;
	mov	rax, .ErrEndMark		; Point to error message
	call	StrOut				; Print error message
;
.abort	mov	rax, [File_Last_Word]		; Restore accuracy
	mov	[No_Word], rax
	mov	rax, [File_Last_Byte]
	mov	[No_Byte], rax
	mov	rax, [File_Last_LSWO]
	mov	[LSWOfst], rax
	mov	rax, [File_Last_SDig]
	mov	[NoSigDig], rax
;
	mov	rsi, HAND_ACC			; Variable handle number
	call	ClearVariable			; Clear variable
;
	jmp	.done
.endmarkok:
	mov	rax, .LoadOK			; Pointer to success message
	call	StrOut
;
; Close the file
;
.done:
	mov	rax, sys_close
	mov	rdi, [fd_in]
	syscall
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1
;
; Restore Registers
;
.exit:
	pop	r11
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
; Generic error message
;
.error1:
	push	rax				; Save error code
	mov	rax, 0				; Set file descriptor to zero (closed)
	mov	[fd_out], rax			; Mark as closed
	mov	rax, .FileError			; I/O Error message
	call	StrOut;				; Print error message
	pop	rax				; Get error code
	neg	rax				; Make positive
	call	PrintWordB10			; Error number
	call	CROut
	call	CROut
	jmp	.exit				; Exit functions
;
.FNPrompt:	db	"Enter Filename: ", 0
.FileNameMsg:	db	0xD, 0xA, "File Load: Filename: ", 0
.FileRec:	db	"File Load: File format recognized, Version: ", 0
.DescripMsg:	db	"File Load: Description: ", 0
.LoadSame:	db	"File Load: Significant words and digits match, no changes", 0xD, 0xA, 0
.WordChange:	db	"File Load: Number Words changed:  ", 0
.DigChange:	db	"File Load: Number Digits changed: ", 0
.MidChange:	db	" --> ", 0
.LoadOK:	db	"File Load: Number successfully loaded to ACC", 0xD, 0xA, 0
.ErrEndMark:	db	0xD, 0xA, "File Load: Error, end of file marker not found", 0xD, 0xA, 0
.ErrStMark:	db	0xD, 0xA, "File Load: Error, beginning file marker not found or does not match.", 0xD, 0xA, 0
.FileError:	db	0xD, 0xA, "File Load: I/O Error trying to read variable, Code: -", 0
.InvalidFN:	db	0xD, 0xA, "File Load: Error, Invalid filename", 0xD, 0xA, 0
.LoadNotFound:	db	0xD, 0xA, "File Load: Error, File Not Found", 0xD, 0xA, 0
.LoadMin:	db	0xD, 0xA, "File Load: Error, file mantissa word size below minimum", 0xD, 0xA, 0
.LoadMax:	db	0xD, 0xA, "File Load: Error, file mantissa word size above maximum", 0xD, 0xA, 0
.LoadMinDig:	db	0xD, 0xA, "File Load: Error, file mantissa digit size below minimum", 0xD, 0xA, 0
;
;--------------------------------------------------------------
;
;   Save Variable to file
;
;         Input:  rax = pointer to filename, or zero to prompt
;                 Variable to save in X-Reg (different from load, uses ACC)
;         Output: none
;
;   File Format:
;
;       Word  Byte
;        0       0      - Header
;                             Byte 7 - 0x55   ID code, this is a variable?
;                             Byte 6 - 0x62   ID code, this is a variable?
;                             Byte 5 - 0x02   File format version number
;                             Byte 4 - 0x00   File sub-version number
;		              Byte 3-0        Reserved
;        1       8      - Timestamp (unix time in seconds)
;        2-5    16      - Description 32 character null terminated ASCII string
;        6      48      - Number of significant words [No_Word] (64 bit binary)
;        7      56      - Number of significant decimal digits  (64 bit binary)
;        8      64      - Exponent (64 bit word)
;        9      72      - Start of mantissa, length = [No_Word]
;        10+[No_Word]+1 - 0x12344321 - end of file marker
;--------------------------------------------------------------
;
SaveVariable:
;
; Preserve Registers
;
	push	rax				; General use
	push	rbx				; Address Pointer
	push	rcx				; Counter
	push	rdx				; Address Pointer
	push	rsi				; Used system call
	push	rdi				; Used system call
	push	rbp				; Pointer index
	push	r11				; maybe corrupted by sys_call
;
; Prompt for filename and get input
;
	or	rax, rax			; check for zero
	jnz	.have_fn			; not zero have filename
	mov	rax, .FNPrompt
	call	StrOut				; Issue prompt to operaator
	call	KeyIn				; Get filename
.have_fn:
	mov	rbx, rax			; Address to buffer
	mov	rdx, Filename			; Address to filename
	mov	rcx, 0				; Counter
	mov	rbp, 0				; Index
.loop1:
	mov	al, [rbx+rbp]			; Get character from KeyBuf
	mov	[rdx+rbp], al			; Save character in Finename
	or	al, al				; Done?
	jz	.ckfn				; End of string marker
	inc	rbp				; Point next character
	inc	rcx				; Character Counter
	cmp	rcx, 80				; Maximum filename size
	jl	.loop1				; Size ok? Yes, loop for more characters
						; No, filename too long error
	mov	rax, .InvalidFN
	call	StrOut				; Error message invalid filename (too short)
	jmp	.exit				; Abort function
.ckfn:
	cmp	rcx, 3				; Check Filename length, must be 3 or greater
	jge	.fnok				; filename length ok
	mov	rax, .InvalidFN
	call	StrOut				; Error message invalid filename (too long)
	jmp	.exit				; Abort function
.fnok:
	mov	al, '.'				; Filename Extension ".num"
	mov	[rdx+rbp], al
	inc	rbp
	mov	al, 'n'
	mov	[rdx+rbp], al
	inc	rbp
	mov	al, 'u'
	mov	[rdx+rbp], al
	inc	rbp
	mov	al, 'm'
	mov	[rdx+rbp], al
	inc	rbp
	mov	al, 0				; Null terminate filename
	mov	[rdx+rbp], al
	inc	rbp
;
;  See if file exists, Open the file (check for error)
;
	mov	rax, sys_open			; sys call open stream
	mov	rdi, Filename			; filename
	mov	rsi, O_RDONLY			; Mode=read only, checking if exists
	mov	rdx, 0o644			; File permissions
	syscall					; Call Kernel
;
;  Error, see if file not exist
;
	mov	rcx, -2				; File not found error
	cmp	rax, rcx			; was file found?
	je	.ok_not_exist			; No, not found, this is the expected result
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jne	.error1				; Handle the generic error
;
; close the file (File is open from read, close it)
;
	push	rax				; Aave file handle
	mov	rax, .FileExistError
	call	StrOut				; Error message
	pop	rdi				; Restore File handle
	mov	rax, sys_close		;
	syscall					; Call kernel to close the file
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1				; Handle generic file error
	jmp	.exit				; exit quietly, file exist (abort)
.ok_not_exist:
;
;create the file
;
	mov	rax, sys_creat			; Create new file
	mov	rdi, Filename			; Filename (from operator input)
	mov	rsi, 0o644			; File permissions
	syscall					; Call Kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1				; Handle generic file error
;
;  File is open for write, save handle
;
	mov	[fd_out], rax			; save handle
;
		;---------------------------------
			; Write the program variable file
			; (See SaveVariable description for file format)
		;---------------------------------
;
; All writes are in 64 bit words
; Write file header into first 64 bit word
;     0x5562 (ID code) 0x01 0x00 (Version/sub-version) + reserved bytes
;
;                     FEDCBA9876543210 <-- Ruler
	mov	rax, 0x5562020000000000
						; ID Code and version
	mov	[OutBuf], rax			; Code into buffer
	mov	rax, sys_write			; Write to stream
	mov	rdi, [fd_out]			; File handle
	mov	rsi, OutBuf			; Buffer Address
	mov	rdx, 8				; Length for write
	syscall					; call kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1				; Handle generic error
;
; Write Timestamp
;
	call    ReadSysTime			; Get unix time seconds
	mov	[OutBuf], rax			; Save in buffer
	mov	rax, sys_write			; Write to stream
	mov	rdi, [fd_out]			; File handle
	mov	rsi, OutBuf			; Buffer Address
	mov	rdx, 8				; Length for write
	syscall					; call kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1				; Handle generic error
;
; Write description from descriptoin string to file
;
	mov	rax, sys_write			; Write to stream
	mov	rdi, [fd_out]			; File handle
	mov	rsi, Description		; Buffer Address
	mov	rdx, 32				; Length for write
	syscall					; call kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1				; Handle generic error
;
; Write number signifcant words and digits (64 bit binary)
;
	mov	rax, sys_write			; Write to stream
	mov	rdi, [fd_out]			; File handle
	mov	rsi, No_Word			; Significant Words (64 bit binary)
	mov	rdx, 8				; Length for write
	syscall					; call kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1				; Handle generic error

	mov	rax, sys_write			; Write to stream
	mov	rdi, [fd_out]			; File handle
	mov	rsi, NoSigDig			; Significant digits (64 bit binary)
	mov	rdx, BYTE_PER_WORD		; Length for write
	syscall					; call kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1				; Handle generic error
;
; Setup addresses to write variable mantissa adn exponent
;
	mov 	rsi, FP_X_Reg+EXP_WORD_OFST	; Point to  Exponent
	mov	rbp, [No_Word]			; Number words mantissa
	inc	rbp				; Increment to include exponent
;
; Loop to write exponent and mantissa
;
.loop:
	mov	rax, sys_write			; Write to stream
	mov	rdi, [fd_out]			; File handle
	;;;	rsi				; Pointer to data word
	mov	rdx, BYTE_PER_WORD		; Length for write
	syscall					; call kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1				; Handle generic error
	sub	rsi, BYTE_PER_WORD		; Point to next word
	dec	rbp				; Increment counter
	jnz	.loop
;
; Write end of file marker
;
	mov	rax, 0x12344321			; Code for end of file marker
	mov	[OutBuf], rax			; Code into buffer
	mov	rax, sys_write			; Write to stream
	mov	rdi, [fd_out]			; File handle
	mov	rsi, OutBuf			; Buffer Address
	mov	rdx, 8				; Length for write
	syscall					; call kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1				; Handle generic error
;
; Close the file
;
	mov	rax, sys_close			; Close the file
	mov	rdi, [fd_out]			; File handle
	syscall					; Call the kernel
	mov	rcx, WORD8000
	test	rax, rcx			; Error? (negative is error)
	jnz	.error1				; Handle generic file error
;
; Write result message
;
	mov	rax, .Msg_success
	call	StrOut
	mov	rax, Filename
	call	StrOut
	call	CROut
;
; Restore registers
;
.exit:
	pop	r11
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
;
; Generic error message
;
.error1:
	push	rax				; Save error code
	mov	rax, 0				; Set file descriptor to zero (closed)
	mov	[fd_out], rax			; Mark as closed
	mov	rax, .FileError			; I/O Error message
	call	StrOut;				; Print error message
	pop	rax				; Get error code
	neg	rax				; Make positive
	call	PrintWordB10			; Error number
	call	CROut
	call	CROut
	jmp	.exit				; Exit functions
;
.FileError:		db	0xD, 0xA, "File Save: I/O Error trying to write variable, Code: -", 0
.FileExistError:	db	"File Save: Error, file exists, please choose another filename.", 0
.FNPrompt:		db	"Enter Filename: ", 0
.InvalidFN:		db	"File Save: Error, Invalid filename", 0
.Msg_success:		db	"File Save: Variable X-Reg successfully saved to file: ", 0
;--------------------------------------------------------------
;
;  Enter File Description
;
;--------------------------------------------------------------
EnterFileDescription:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rbp

	mov	rax, .prompt
	call	StrOut
	call	KeyIn
;
	mov	rbx, rax			; Source address
	mov	rdx, Description		; Dest address
	mov	rcx, 32				; size
	mov	rbp, 0				; index
;
	mov	al, [rbx]			; Check first for zero, abort
	or	al, al				; is it zero?
	jnz	.loop1				; not zero, keep going
	mov	rax, .oldkept			; message for keeping old
	call	StrOut
	jmp	.abort
;
;  This asssumes it is a null terminated string

.loop1:
	mov	al, [rbx+rbp]			; Get character]
	mov	[rdx+rbp], al			; Move character
	or	al, al				; Was it zero?
	jz	.restzero			; Yes, fill rest with zeros
	inc	rbp				; Increment index pointer
	loop	.loop1				; dec RCX and loop
	jmp	.exitloop
.loop2:
	mov	al, 0
	mov	[rdx+rbp], al
.restzero:
	inc	rbp
	loop	.loop2
.exitloop:
	mov	rax, 0
	mov	[Description+31], rax
.abort:
	pop	rbp
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
.prompt:	db	"         Ruler -->1   5    0    5    0    5    0 <-- ", 0xD, 0xA
		db	"Enter Description:", 0
.oldkept:	db	0xD, 0xA, "Zero length string. Input aborted. Old description retained.", 0xD, 0xA, 0

;--------------------------------------------------------------
;  Print character with 'Foratted' output
;
;  Input AL - Character to print
;--------------------------------------------------------------
;
CharOutFmt:
	push	rax
	push	rbx
	push	rdx
	push	r8
;
	mov	rdx, 0x1			; bit 0 = enabled
	test	rdx, [OutCountActive]		; test bit if enabled
	jz	.go_charout			; not enabled, skip formatting
;
;
	mov	rdx, [OutPreCount]
	cmp	rdx, [OutPreCountLimit]
	je	.skip1
	inc	rdx
	mov	[OutPreCount], rdx
	jmp	.go_charout			; Skip everything until precount = 4
.skip1:
	inc	qword[OutCharCount]
;
	mov	rbx, 0
	inc	qword[OutWordCount]
	cmp	qword[OutWordCount], 10
	jl	.skip1a
	mov	qword[OutWordCount], 0
	mov	rbx, 1
.skip1a:
;
	mov	r8, [OutLineCountLimit]		; default char / line
	inc	qword[OutLineCount]
	cmp	qword[OutLineCount], r8		; character per line
	jl	.skip2
;
	mov	qword[OutLineCount], 0
	mov	rbx, 2
.skip2:
	inc	qword[OutParaCount]
	cmp	qword[OutParaCount], 1000
	jl	.skip3
	mov	rbx, 3
	mov	qword[OutParaCount], 0
.skip3:
	cmp	rbx, 1
	jne	.skip4
	push	rax
	mov	al, ' '
	call	CharOut
	pop	rax
.skip4:
	cmp	rbx, 2
	jne	.skip5
	call	CROut
	push	rax
	mov	al, ' '
	call	CharOut
	call	CharOut
	call	CharOut
	pop	rax
.skip5:
	cmp	rbx, 3
	jne	.skip6
;
	push	rax
	call	CROut
	mov	al, ' '
	call	CharOut
	call	CharOut
	call	CharOut
	call	CharOut
	call	CharOut
	call	CharOut
	mov	al, '('
	call	CharOut
	mov	rax, [OutCharCount]
	call	PrintWordB10
	mov	rax, ')'
	call	CharOut
	call	CROut
	mov	al, ' '
	call	CharOut
	call	CharOut
	call	CharOut
	pop	rax
.skip6:


.go_charout:
	call	CharOut
;
	pop	r8
	pop	rdx
	pop	rbx
	pop	rax
	ret

CharOutFmtInit:
	push	rax
;
	mov	qword[OutPreCountLimit], 4
	cmp	qword[Out_Mode], 2
	jne	.skip1
	mov	qword[OutPreCountLimit], 2
.skip1:
	mov	qword[OutLineCountLimit], 100	; default 100 char / line
	mov	rdx, 0x2			; bit 1 = 50 char/line instead
	test	rdx, [OutCountActive]		; test bit if enabled
	jz	.skip2				; no, stick with 100 char/line
	mov	qword[OutLineCountLimit], 50	; default 100 char / line
.skip2:
;
	mov	qword[OutPreCount], 0
	mov	qword[OutCharCount], 0
	mov	qword[OutWordCount], 0
	mov	qword[OutLineCount], 0
	mov	qword[OutParaCount], 0
	pop	rax
	ret


;--------------------------------------------------------------
;  Print character output - syscall
;
;  Input:   AL = character to print
;
;  Output:  none
;
;--------------------------------------------------------------

CharOut:
	push	rax
	push	rdi
	push	rsi
	push	rdx
	push	rcx				; corrupted by sys_call
	push	r11				; maybe corrupted by sys_call
;
; Place character to print in buffer
;
	mov	[CharOutbuf], al		; Character to print
;
; If inhibited skip console output
;
	mov	rax, [ConInhibit]
	or	rax, rax			; Inhibited
	jnz	.skip1				; yes, skip
;
; Write to StdOut stream
;
	mov	rax, sys_write			; 64 bit syscall code
	mov	rdi, 1				; File descriptor StdOut
	mov	rsi, CharOutbuf			; Buffer with output character
	mov	rdx, 1				; Length = 1 character
	syscall
;
; If file not open, skip echo output to file
;
.skip1:
	mov	rax, [fd_echo]			; Get file handle
	or	rax, rax			; Zero? File open?
	jz	.exit				; No, don't echo, exit
;
; If inhibited, skip echo output to file
;
	mov	rax, [OutInhibit]
	or	rax, rax
	jnz	.exit
;
; Characters to skip
;
	mov	al, [CharOutbuf]
	cmp	al, 0x7				; bell character
	je	.exit
;
	mov	rax, sys_write			; 64 bit syscall code
	mov	rdi, [fd_echo]			; File descriptor
	mov	rsi, CharOutbuf			; Buffer with output character
	mov	rdx, 1				; Length = 1 character
	syscall
	mov	rcx, WORD8000			; Mask, negative bit if error
	test	rax, rcx			; Error? (negative is error)
	jnz	.error				; Yes, handle error
.exit:
	pop	r11
	pop	rcx
	pop	rdx
	pop	rsi
	pop	rdi
	pop	rax
	ret
.error:
	push	rax				; Save error
	mov	rax, 0
	mov	[fd_echo], rax			; Zero file handle
	mov	rax, .msg1			; Error message
	call	StrOut;
	pop	rax
	call	PrintHexWord			; Error number
	call	CROut
	jmp	.exit

.msg1:	db	0xD, 0xA, "Error writing console output to file output.txt", 0xD, 0xA, 0xA, 0
;--------------------------------------------------------------
;  Print Carriage Return and Line Feed
;
;  Input:   none
;
;  Output:  none
;
;--------------------------------------------------------------
CROut:
	push    rax
	mov     al, 0x0D			; Print Return
	call    CharOut
 	mov	al, 0x0A			; Print Line Feed
	call	CharOut
	pop	rax
	ret

;--------------------------------------------------------------
;  String Out
;
;  Input:   rax	address of nul terminated string
;
;  Output:  none
;
;--------------------------------------------------------------

StrOut:
	push	rax
	push	rbx
	mov	rbx, rax			; get address
.loop1:	mov	al, [rbx]			; read character from memory
	or	al, al				; is this last byte?
	jz	.skip2				; yes, end of string, exit loop
	call	CharOut				; output character
	inc	rbx
	jmp	.loop1				; loop for next character
.skip2:	pop	rbx
	pop	rax
	ret


;--------------------------------------------------------------
;  Keypress In
;
;  Input:   none
;
;  Output:  RAX - address of string buffer
;
;   ToDo: check for 0 lenth before remove 0AH
;
;--------------------------------------------------------------

KeyIn:
	push	rdi
	push	rsi
	push	rdx
	push	rcx				; corrupted by sys_call
	push	r11				; maybe corrupted by sys_call

	mov	rax, sys_read
	mov	rdi, 0
	mov	rsi, KeyBuf			; Buffer for characters
	mov	rdx, KeyBufLen-4		; Size of buffer
	syscall

	add	rax, KeyBuf			; Point to last character
	mov	[rax], byte 0			; Null terminate string
	dec	rax				; point to line feed
	mov	[rax], byte 0			; remove line feed 0AH character
	mov	rax, KeyBuf			; Return with address of buffer


	pop	r11
	pop	rcx
	pop	rdx
	pop	rsi
	pop	rdi
	ret


;--------------------------------------------------------------
;
;  Get system time
;
;  Input:   none
;
;  Output:  RAX  Time in seconds
;
;--------------------------------------------------------------
ReadSysTime:
	push	rdi
	push	rcx				; maybe corrupted by sys_call
	push	r11				; maybe corrupted by sys_call
	mov	rax, sys_time			; 64 bit syscall code
	mov	rdi, time2			; time_t (needed by sys_call)
	syscall
	pop	r11				; call the Kernel
	pop	rcx
	pop	rdi
	ret					; return time in RAX
;-----------------------
; io_module.asm - EOF
;-----------------------
