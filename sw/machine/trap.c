#include "encoding.h"
#include "m.h"

struct trap_context m_trap_context;

static volatile int m_in_trap;

static void m_handle_breakpoint(void);

#define MCAUSE_INTERRUPT  (1 << 31)
#define MSTATUS_MPP_SHIFT 11

#define SEMIHOSTING_MAGIC_PRE  0x01f01013 // sll zero, zero, 31
#define SEMIHOSTING_MAGIC_POST 0x40705013 // sra zero, zero, 7

void m_handle_trap(void)
{
	if (m_in_trap) {
		M_LOG("faulted while handling a previous trap\n");
		m_bad_trap();
	}

	m_in_trap = 1;

	switch (m_trap_context.mcause) {
		case CAUSE_BREAKPOINT:
			m_handle_breakpoint();
			break;

		default:
			m_bad_trap();
			break;
	}

	m_in_trap = 0;
}

void __attribute__((noreturn)) m_bad_trap(void)
{
	if (!m_in_trap) {
		M_LOG("called outside of trap context!\n");
		m_die(1);
	}

	int is_interrupt = !!(m_trap_context.mcause & MCAUSE_INTERRUPT);

	char mode;
	switch ((m_trap_context.mstatus & MSTATUS_MPP) >> MSTATUS_MPP_SHIFT) {
		case USER_MODE:
			mode = 'U';
			break;

		case SUPERVISOR_MODE:
			mode = 'S';
			break;

		case MACHINE_MODE:
			mode = 'M';
			break;

		default:
			mode = '?';
			break;
	}

	const char *exc_cause = "unknown";
	if (!is_interrupt)
		for (const struct exc_map_entry *entry = m_exc_map; entry->description; ++entry)
			if (entry->code == m_trap_context.mcause) {
				exc_cause = entry->description;
				break;
			}

	const char mode_str[] = {mode, '\0'};

	M_INFO("unhandled ");
	m_print_str(mode_str);
	m_print_str("-mode trap: ");

	if (is_interrupt)
		m_print_str("interrupt\n");
	else {
		m_print_str(exc_cause);
		m_print_str(" exception\n");
	}

	m_print_str("pc=");
	m_print_hex(m_trap_context.pc);
	m_print_str("  ra=");
	m_print_hex(m_trap_context.ra);
	m_print_str("  sp=");
	m_print_hex(m_trap_context.sp);
	m_print_str("  gp=");
	m_print_hex(m_trap_context.gp);
	m_print_str("\ntp=");
	m_print_hex(m_trap_context.tp);
	m_print_str("  t0=");
	m_print_hex(m_trap_context.t0);
	m_print_str("  t1=");
	m_print_hex(m_trap_context.t1);
	m_print_str("  t2=");
	m_print_hex(m_trap_context.t2);
	m_print_str("\ns0=");
	m_print_hex(m_trap_context.s0);
	m_print_str("  s1=");
	m_print_hex(m_trap_context.s1);
	m_print_str("  a0=");
	m_print_hex(m_trap_context.a0);
	m_print_str("  a1=");
	m_print_hex(m_trap_context.a1);
	m_print_str("\na2=");
	m_print_hex(m_trap_context.a2);
	m_print_str("  a3=");
	m_print_hex(m_trap_context.a3);
	m_print_str("  a4=");
	m_print_hex(m_trap_context.a4);
	m_print_str("  a5=");
	m_print_hex(m_trap_context.a5);
	m_print_str("\na6=");
	m_print_hex(m_trap_context.a6);
	m_print_str("  a7=");
	m_print_hex(m_trap_context.a7);
	m_print_str("  s2=");
	m_print_hex(m_trap_context.s2);
	m_print_str("  s3=");
	m_print_hex(m_trap_context.s3);
	m_print_str("\ns4=");
	m_print_hex(m_trap_context.s4);
	m_print_str("  s5=");
	m_print_hex(m_trap_context.s5);
	m_print_str("  s6=");
	m_print_hex(m_trap_context.s6);
	m_print_str("  s7=");
	m_print_hex(m_trap_context.s7);
	m_print_str("\ns8=");
	m_print_hex(m_trap_context.s8);
	m_print_str("  s9=");
	m_print_hex(m_trap_context.s9);
	m_print_str(" s10=");
	m_print_hex(m_trap_context.s10);
	m_print_str(" s11=");
	m_print_hex(m_trap_context.s11);
	m_print_str("\nt3=");
	m_print_hex(m_trap_context.t3);
	m_print_str("  t4=");
	m_print_hex(m_trap_context.t4);
	m_print_str("  t5=");
	m_print_hex(m_trap_context.t5);
	m_print_str("  t6=");
	m_print_hex(m_trap_context.t6);
	m_print_str("\nmstatus=");
	m_print_hex(m_trap_context.mstatus);
	m_print_str(" mcause=");
	m_print_hex(m_trap_context.mcause);
	m_print_str(" mtval=");
	m_print_hex(m_trap_context.mtval);
	m_print_chr('\n');

	m_die(1);
}

static void m_handle_breakpoint(void)
{
	const unsigned *code = (const unsigned *)m_trap_context.pc;
	if (code[-1] == SEMIHOSTING_MAGIC_PRE && code[1] == SEMIHOSTING_MAGIC_POST) {
		m_handle_semihosting();
		return;
	}

	//TODO: implement a debugger here

	m_bad_trap();
}
