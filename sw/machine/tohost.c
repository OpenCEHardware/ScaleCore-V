#include <stdint.h>
#include <string.h>

#include "m.h"

volatile unsigned tohost;

static unsigned htfi_syscall(unsigned which, unsigned arg0, unsigned arg1, unsigned arg2)
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

void m_print(const char *str)
{
	htfi_syscall(64, 1, (unsigned)str, strlen(str));
}
