#include <limits.h>
#include <stdint.h>
#include <string.h>

#include "m.h"

volatile unsigned tohost;

#define HTIF_CALL_WRITE 64
#define HTIF_FD_STDOUT  1

static unsigned htif_syscall(unsigned which, unsigned arg0, unsigned arg1, unsigned arg2)
{
	volatile uint64_t buffer[8] __attribute__((aligned(64)));
	buffer[0] = which;
	buffer[1] = arg0;
	buffer[2] = arg1;
	buffer[3] = arg2;

	__sync_synchronize();
	tohost = (uintptr_t)buffer;
	__sync_synchronize();

	return (unsigned)buffer[0];
}

void m_print_chr(char c)
{
	htif_syscall(HTIF_CALL_WRITE, HTIF_FD_STDOUT, (unsigned)&c, sizeof c);
}

void m_print_str(const char *str)
{
	htif_syscall(HTIF_CALL_WRITE, HTIF_FD_STDOUT, (unsigned)str, strlen(str));
}

void m_print_hex_bits(unsigned value, int bits)
{
	static const char HEX_DIGITS[16] = "0123456789abcdef";

	char buffer[2 * sizeof value + 1];

	int index = 2 * sizeof value;
	do {
		index -= 2;

		unsigned lo = value & 0x0f;
		unsigned hi = (value >> 4) & 0x0f;

		buffer[index] = HEX_DIGITS[hi];
		buffer[index + 1] = HEX_DIGITS[lo];

		value >>= 8;
	} while (index > 0);

	buffer[2 * sizeof value] = '\0';

	int nibbles = (bits + 3) / 4;

	int offset = 2 * sizeof value - nibbles;
	if (offset < 0 || offset > 2 * sizeof value)
		offset = 0;

	m_print_str(buffer + offset);
}

void __attribute__((noreturn)) m_die(unsigned code)
{
	M_INFO("cpu halted\n");

	__sync_synchronize();
	tohost = (code << 1) | 1;
	__sync_synchronize();

	while (1)
		asm volatile ("wfi");
}
