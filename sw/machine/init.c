#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "encoding.h"
#include "m.h"

int u_main(void);

void m_trap_entry(void);
void __attribute__((noreturn)) m_trap_exit(void);

void __attribute__((constructor(1000))) m_init(void)
{
	memset(&m_trap_context, 0, sizeof m_trap_context);
	write_csr(mtvec, (uintptr_t)m_trap_entry);


	M_LOG("early init ok\n");

	unsigned jump_address;

	asm volatile (
		"la   %0, in_user_mode\n"
		"csrw mepc, %0\n"
		"csrw mstatus, zero\n"
		"mret\n"
		"in_user_mode:\n"
		: "=r" (jump_address)
	);
}
