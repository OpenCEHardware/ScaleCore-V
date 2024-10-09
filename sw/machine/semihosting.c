#include "m.h"

void m_handle_semihosting(void)
{
	unsigned call = m_trap_context.a0;
	unsigned arg1 = m_trap_context.a1;
	unsigned arg2 = m_trap_context.a2;
	unsigned arg3 = m_trap_context.a3;
	unsigned arg4 = m_trap_context.a4;

	unsigned ret = 0;

	switch (call) {
		case SEMIHOSTING_SYS_WRITEC:
			m_print_chr(*(const char *)arg1);
			break;

		case SEMIHOSTING_SYS_WRITE0:
			m_print_str((const char *)arg1);
			break;

		default:
			M_LOG("unknown call ");
			m_print_hex(call);
			m_print_str("\n");

			m_bad_trap();
			break;
	}

	m_trap_context.a0 = ret;
	m_trap_context.pc += 8;
}
