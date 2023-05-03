GCC=riscv32-unknown-elf-gcc
OBJDUMP=riscv32-unknown-elf-objdump
MARCH=rv32i
MABI=ilp32
LD_SCRIPT=sykt.ld
CFLAGS=-O0
LDFLAGS=-ffreestanding -Wl,--gc-sections
LDFLAGS+=-nostartfiles -nostdlib -nodefaultlibs -Wl,-T,$(LD_SCRIPT)
LDFLAGS+=-march=$(MARCH) -mabi=$(MABI)
all:
	$(GCC) -g $(CFLAGS) $(LDFLAGS) crt0.s main.c -o sykt
	$(OBJDUMP) -DxS sykt > sykt.lst
