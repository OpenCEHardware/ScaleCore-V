#ifndef MACHINE_M_H
#define MACHINE_M_H

// CPU state before a trap. You can modify register values within a trap
// handler, they will take effect once the handler returns.
//
// Do not change existing struct members. Offsets to it are referenced
// directly within assembly code (see entry_exit.S). If you need to add
// more members, do so below all existing ones.
extern struct trap_context
{
	unsigned pc;

	union { unsigned x1;  unsigned ra; };
	union { unsigned x2;  unsigned sp; };
	union { unsigned x3;  unsigned gp; };
	union { unsigned x4;  unsigned tp; };
	union { unsigned x5;  unsigned t0; };
	union { unsigned x6;  unsigned t1; };
	union { unsigned x7;  unsigned t2; };
	union { unsigned x8;  unsigned s0; };
	union { unsigned x9;  unsigned s1; };
	union { unsigned x10; unsigned a0; };
	union { unsigned x11; unsigned a1; };
	union { unsigned x12; unsigned a2; };
	union { unsigned x13; unsigned a3; };
	union { unsigned x14; unsigned a4; };
	union { unsigned x15; unsigned a5; };
	union { unsigned x16; unsigned a6; };
	union { unsigned x17; unsigned a7; };
	union { unsigned x18; unsigned s2; };
	union { unsigned x19; unsigned s3; };
	union { unsigned x20; unsigned s4; };
	union { unsigned x21; unsigned s5; };
	union { unsigned x22; unsigned s6; };
	union { unsigned x23; unsigned s7; };
	union { unsigned x24; unsigned s8; };
	union { unsigned x25; unsigned s9; };
	union { unsigned x26; unsigned s10; };
	union { unsigned x27; unsigned s11; };
	union { unsigned x28; unsigned t3; };
	union { unsigned x29; unsigned t4; };
	union { unsigned x30; unsigned t5; };
	union { unsigned x31; unsigned t6; };

	unsigned mstatus;
	unsigned mcause;
	unsigned mtval;
} m_trap_context;

extern const struct exc_map_entry
{
	unsigned    code;
	const char *description;
} m_exc_map[];

extern const struct insn_map_entry
{
	unsigned    mask;
	unsigned    match;
	const char *mnemonic;
} m_insn_map[];

void m_print_hex(unsigned value);
void m_print_str(const char *str);

void __attribute__((noreturn)) m_die(unsigned code);
void __attribute__((noreturn)) m_bad_trap(void);

#endif
