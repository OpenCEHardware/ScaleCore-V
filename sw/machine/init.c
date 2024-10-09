#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "encoding.h"
#include "m.h"

int u_main(void);

void m_trap_entry(void);
void __attribute__((noreturn)) m_trap_exit(void);

int __attribute__((noreturn)) main()
{
	write_csr(mtvec, (uintptr_t)m_trap_entry);

	M_LOG("early init ok\n");

	memset(&m_trap_context, 0, sizeof m_trap_context);
	m_trap_context.pc = (uintptr_t)u_main;
	asm volatile ("mv %0, sp" : "=r"(m_trap_context.sp));

	m_trap_exit();
}
