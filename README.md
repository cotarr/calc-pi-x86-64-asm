# calc-pi-x86-64-asm

Documentation:  [cotarr.github.io/calc-pi-x86-64-asm](https://cotarr.github.io/calc-pi-x86-64-asm)

### Description

This is a work in progress...

Calc-pi is a 64 bit assembly language program used to calculate pi.
The interface is a simple text based RPN calculator intended to run in
a Linux command line bash shell. It is fully stand alone and has no
external library dependencies.

I had fun writing this. Several friends encouraged me to share it.
My hope is that it may inspire others to try writing a program of their own.

### System Requirements

- 64 bit Intel microprocessor or equivalent.
- 300 MB available memory for about 40M significant digits.
- 64 bit Linux (Debian or Ubuntu amd64 recommended)

### Security Note

This application was intended for I/O limited to local keyboard and console output
within a Linux command line shell. This calculation includes a rather ubiquitous
use of memory pointers that have not been reviewed for safe pointer practices.
Therefore, modification of the program to service a direct internet connection is not recommended.

System memory used for floating point number variables are defined in
math.asm using RESQ statements to declare uninitialized blocks of memory
in the BSS section. These are statically allocated when the program is
started as part of the load image. No memory is dynamically allocated.

All input and output is performed using assembly language SYSCALL statements.
All I/O functions are located in the "io_module.asm" file.
They are used to accept keyboard input, produce console output, read and write
numbers to disk files, capture program text output to a disk file, and
read the system clock.

Filenames are specified by CLI input.
The default path is the working directory.
Filenames are not filtered to restrict path names,
therefore, can write to any valid path with permission of the user running the program.
I assume this is not an issue since you can do this independently from the CLI shell.

### Installation

Generation of the binary executable is done in Linux using
[NASM](https://www.nasm.us/doc/ "NASM Documentation")
as the assembler and ld as the linker. Check your system's packages.
If make and binutils are not installed, you will need them.
Optionally, you can install the gdb debugger.
These development packages are standard in Debian.
You can  install these standard software development packages in Debian using:
```bash
apt-get update
apt-get install make
apt-get install binutils
apt-get install nasm
```

Install the GitHub repository. There are no library dependencies.
```bash
git clone git@github.com:cotarr/calc-pi-x86-64-asm.git
cd calc-pi-x86-64-asm
```

Run `make` to compile the modules and combine them with the linker.
The assembler and linker options were developed for 64 bit Debian Linux.
It works on my Ubuntu laptop. I have not tried other distributions
of Linux. If successful, an executable file `calc-pi` should be created
in the project folder.
```bash
make
```

Check for errors. The output should look like this.
```
nasm -f elf64 -g -F dwarf -l main.lst main.asm
nasm -f elf64 -g -F dwarf -l io_module.lst io_module.asm
nasm -f elf64 -g -F dwarf -l parser.lst parser.asm
nasm -f elf64 -g -F dwarf -l math.lst math.asm
nasm -f elf64 -g -F dwarf -l util.lst util.asm
nasm -f elf64 -g -F dwarf -l calc.lst calc.asm
nasm -f elf64 -g -F dwarf -l sandbox.lst sandbox.asm
nasm -f elf64 -g -F dwarf -l func.lst func.asm
nasm -f elf64 -g -F dwarf -l help.lst help.asm
ld -o calc-pi main.o help.o math.o io_module.o parser.o util.o calc.o func.o sandbox.o
```

### Start program and calculate PI

To run the executable, type:
```bash
./calc-pi
```

The program will start and display a license message followed by:
```
Accuracy: 60 Digits

XREG   0.0
YREG   0.0
ZREG   0.0
TREG   0.0

(Elapsed time: 0 Seconds 00:00:00) Op Code:
```

Instructions to use the calculator are in the
[docs/](https://cotarr.github.io/calc-pi-x86-64-asm "GitHub-Pages") folder in html.
If you want a quick start, the command prompt is "Op Code:".
Commands terminate with the Enter key.  Try this:

- Op Code: `sigfigs 1000` (Set significant figures to 1000 digits)
- Op Code: `fix` (Change output conversion from scientific notation to fixed)
- Op Code: `c.pi` (Calculate pi)
- Op Code: `print f` (Print base-10 conversion formatted 100 digit per line)

The output from these 4 commands should look like this:
```
(Elapsed time: 0 Seconds 00:00:00) Op Code: sigfigs 1000

Accuracy: 1000 Digits

(Elapsed time: 0 Seconds 00:00:00) Op Code: fix

XREG   0.0
YREG   0.0
ZREG   0.0
TREG   0.0

(Elapsed time: 0 Seconds 00:00:00) Op Code: c.pi

Functon_calc_pi_chud: Calculation of pi using Chudnovsky formula.

XREG  +3.14159265358979323846264338327950288419716939937510
YREG   0.0
ZREG   0.0
TREG   0.0

(Elapsed time: 0 Seconds 00:00:00) Op Code: print f

+3.1415926535 8979323846 2643383279 5028841971 6939937510 5820974944 5923078164 0628620899 8628034825 3421170679
   8214808651 3282306647 0938446095 5058223172 5359408128 4811174502 8410270193 8521105559 6446229489 5493038196
   4428810975 6659334461 2847564823 3786783165 2712019091 4564856692 3460348610 4543266482 1339360726 0249141273
   7245870066 0631558817 4881520920 9628292540 9171536436 7892590360 0113305305 4882046652 1384146951 9415116094
   3305727036 5759591953 0921861173 8193261179 3105118548 0744623799 6274956735 1885752724 8912279381 8301194912
   9833673362 4406566430 8602139494 6395224737 1907021798 6094370277 0539217176 2931767523 8467481846 7669405132
   0005681271 4526356082 7785771342 7577896091 7363717872 1468440901 2249534301 4654958537 1050792279 6892589235
   4201995611 2129021960 8640344181 5981362977 4771309960 5187072113 4999999837 2978049951 0597317328 1609631859
   5024459455 3469083026 4252230825 3344685035 2619311881 7101000313 7838752886 5875332083 8142061717 7669147303
   5982534904 2875546873 1159562863 8823537875 9375195778 1857780532 1712268066 1300192787 6611195909 2164201989

(Elapsed time: 0 Seconds 00:00:00) Op Code:
```

Documentation:  [cotarr.github.io/calc-pi-x86-64-asm](https://cotarr.github.io/calc-pi-x86-64-asm)
