#include "encoding.h"
#include "m.h"

struct trap_context m_trap_context;

static volatile int m_in_trap;

static void m_handle_interrupt(void);

#define MCAUSE_INTERRUPT (1 << 31)

void m_handle_trap(void)
{
	if (m_in_trap) {
		m_print_str("[m] faulted while handling trap\n");
		m_bad_trap();
	}

	m_in_trap = 1;

	if (m_trap_context.mcause & MCAUSE_INTERRUPT) {
		m_handle_interrupt();
		return;
	}

	switch (m_trap_context.mcause) {
		default:
			m_bad_trap();
			break;
	}

	m_in_trap = 0;
}

void __attribute__((noreturn)) m_bad_trap(void)
{
	int is_interrupt = !!(m_trap_context.mcause & MCAUSE_INTERRUPT);

	const char *exc_cause = "unknown";
	if (!is_interrupt)
		for (const struct exc_map_entry *entry = m_exc_map; entry->description; ++entry)
			if (entry->code == m_trap_context.mcause) {
				exc_cause = entry->description;
				break;
			}

	m_print_str("[m] unhandled trap: ");

	if (is_interrupt)
		m_print_str("interrupt");
	else {
		m_print_str(exc_cause);
		m_print_str(" exception");
	}

	m_print_str(" (");
	m_print_hex(m_trap_context.mcause);
	m_print_str(")\n");

	m_die(1);
}

static void m_handle_interrupt(void)
{
	m_bad_trap(); //TODO
}
