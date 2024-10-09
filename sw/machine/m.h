#ifndef MACHINE_M_H
#define MACHINE_M_H

#include <limits.h>

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

extern const struct csr_map_entry
{
	unsigned    csr;
	const char *name;
} m_csr_map[];

extern const struct insn_map_entry
{
	unsigned    mask;
	unsigned    match;
	const char *mnemonic;
} m_insn_map[];

enum rv_privilege
{
	USER_MODE       = 0b00,
	SUPERVISOR_MODE = 0b01,
	MACHINE_MODE    = 0b11,
};

enum rv_csr_prot
{
	CSR_RW_00 = 0b00,
	CSR_RW_01 = 0b01,
	CSR_RW_10 = 0b10,
	CSR_RO    = 0b11,
};

// https://github.com/ARM-software/abi-aa/blob/main/semihosting/semihosting.rst
enum semihosting_call
{
	SEMIHOSTING_SYS_CLOCK         = 0x10,
	SEMIHOSTING_SYS_CLOSE         = 0x02,
	SEMIHOSTING_SYS_ELAPSED       = 0x30,
	SEMIHOSTING_SYS_ERRNO         = 0x13,
	SEMIHOSTING_SYS_EXIT          = 0x18,
	SEMIHOSTING_SYS_EXIT_EXTENDED = 0x20,
	SEMIHOSTING_SYS_FLEN          = 0x0C,
	SEMIHOSTING_SYS_GET_CMDLINE   = 0x15,
	SEMIHOSTING_SYS_HEAPINFO      = 0x16,
	SEMIHOSTING_SYS_ISERROR       = 0x08,
	SEMIHOSTING_SYS_ISTTY         = 0x09,
	SEMIHOSTING_SYS_OPEN          = 0x01,
	SEMIHOSTING_SYS_READ          = 0x06,
	SEMIHOSTING_SYS_READC         = 0x07,
	SEMIHOSTING_SYS_REMOVE        = 0x0E,
	SEMIHOSTING_SYS_RENAME        = 0x0F,
	SEMIHOSTING_SYS_SEEK          = 0x0A,
	SEMIHOSTING_SYS_SYSTEM        = 0x12,
	SEMIHOSTING_SYS_TICKFREQ      = 0x31,
	SEMIHOSTING_SYS_TIME          = 0x11,
	SEMIHOSTING_SYS_TMPNAM        = 0x0D,
	SEMIHOSTING_SYS_WRITE         = 0x05,
	SEMIHOSTING_SYS_WRITEC        = 0x03,
	SEMIHOSTING_SYS_WRITE0        = 0x04,
};
#define SEMIHOSTING_SYS_

void m_print_chr(char c);
void m_print_str(const char *str);
void m_print_hex_bits(unsigned value, int bits);

static inline void m_print_hex(unsigned value)
{
	m_print_hex_bits(value, sizeof value * CHAR_BIT);
}

#define M_INFO(msg) m_print_str("[m] " msg)
#define M_LOG(msg)  do { m_print_str("[m] "); m_print_str(__func__); m_print_str("(): " msg); } while (0)

void m_handle_semihosting(void);
int  m_try_emulate(unsigned insn);

void __attribute__((noreturn)) m_die(unsigned code);
void __attribute__((noreturn)) m_bad_trap(void);

#endif
