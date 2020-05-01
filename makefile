calc-pi: main.o io_module.o parser.o math.o util.o calc.o sandbox.o func.o help.o
	ld -o calc-pi main.o help.o math.o io_module.o parser.o util.o calc.o func.o sandbox.o
main.o: main.asm var_header.inc func_header.inc
	nasm -f elf64 -g -F dwarf -l main.lst main.asm
io_module.o: io_module.asm var_header.inc func_header.inc
	nasm -f elf64 -g -F dwarf -l io_module.lst io_module.asm
parser.o: parser.asm var_header.inc func_header.inc
	nasm -f elf64 -g -F dwarf -l parser.lst parser.asm
math.o: math.asm math-subr.asm math-output.asm math-debug.asm math-rotate.asm math-add.asm math-mult.asm math-div.asm math-fixed.asm var_header.inc func_header.inc
	nasm -f elf64 -g -F dwarf -l math.lst math.asm
func.o: func.asm func-trig.asm func-roots.asm func-exp.asm func-ln.asm var_header.inc func_header.inc
	nasm -f elf64 -g -F dwarf -l func.lst func.asm
util.o: util.asm var_header.inc func_header.inc
	nasm -f elf64 -g -F dwarf -l util.lst util.asm
calc.o: calc.asm calc-pi-st.asm calc-pi-ra.asm calc-pi-ch.asm calc-pi-mc.asm calc-e.asm calc-sr2.asm calc-zeta.asm var_header.inc func_header.inc
	nasm -f elf64 -g -F dwarf -l calc.lst calc.asm
sandbox.o: sandbox.asm var_header.inc func_header.inc
	nasm -f elf64 -g -F dwarf -l sandbox.lst sandbox.asm
help.o:	help.asm var_header.inc var_header.inc
	nasm -f elf64 -g -F dwarf -l help.lst help.asm
