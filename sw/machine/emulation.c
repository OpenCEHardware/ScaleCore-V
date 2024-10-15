#include <stdint.h>

#include "encoding.h"
#include "m.h"

#define INSN_FIELD_RD_SHIFT  7
#define INSN_FIELD_RS1_SHIFT 15
#define INSN_FIELD_RS2_SHIFT 20

static unsigned m_read_reg(int reg);
static void     m_write_reg(int reg, unsigned value);

int m_try_emulate(unsigned insn)
{
	int rd = (insn & INSN_FIELD_RD) >> INSN_FIELD_RD_SHIFT;
	int rs1 = (insn & INSN_FIELD_RS1) >> INSN_FIELD_RS1_SHIFT;
	int rs2 = (insn & INSN_FIELD_RS2) >> INSN_FIELD_RS2_SHIFT;

	unsigned a = m_read_reg(rs1);
	unsigned b = m_read_reg(rs2);

	// Emulated support for RV32IM
	//
	// MUL/MULH[[S]U]: Integer multiplication
	// DIV[U]:         Integer division quotient
	// REM[U]:         Integer division remainder
	if ((insn & MASK_MUL) == MATCH_MUL) 
		m_write_reg(rd, a * b);
	else if ((insn & MASK_MULH) == MATCH_MULH)
		m_write_reg(rd, (unsigned) (((int64_t) a * (int64_t) b) >> 32));
	else if ((insn & MASK_MULHU) == MATCH_MULHU)
		m_write_reg(rd, (unsigned) (((uint64_t) a * (uint64_t) b) >> 32));
	else if ((insn & MASK_MULHSU) == MATCH_MULHSU)
		m_write_reg(rd, (unsigned) (((int64_t) a * (uint64_t) b) >> 32));
	else if ((insn & MASK_DIV) == MATCH_DIV)
		m_write_reg(rd, b != 0 ? (unsigned) ((int) a / (int) b) : 0xffffffff);
	else if ((insn & MASK_DIVU) == MATCH_DIVU)
		m_write_reg(rd, b != 0 ? a / b : 0xffffffff);
	else if ((insn & MASK_REM) == MATCH_REM)
		m_write_reg(rd, b != 0 ? (unsigned) ((int) a % (int) b) : a);
	else if ((insn & MASK_REMU) == MATCH_REMU)
		m_write_reg(rd, b != 0 ? a % b : a);
	else
		// This instruction didn't match any of the emulated opcode patterns.
		// Return false to signal an unrecoverable illegal instruction exception.
		return 0;

	// If we reach here, the instruction was successfully executed via emulation,
	// even though there is no hardware support for it.
	return 1;
}

static unsigned m_read_reg(int reg)
{
	switch (reg & 31) {
		case 0:  return 0;
		case 1:  return m_trap_context.x1;
		case 2:  return m_trap_context.x2;
		case 3:  return m_trap_context.x3;
		case 4:  return m_trap_context.x4;
		case 5:  return m_trap_context.x5;
		case 6:  return m_trap_context.x6;
		case 7:  return m_trap_context.x7;
		case 8:  return m_trap_context.x8;
		case 9:  return m_trap_context.x9;
		case 10: return m_trap_context.x10;
		case 11: return m_trap_context.x11;
		case 12: return m_trap_context.x12;
		case 13: return m_trap_context.x13;
		case 14: return m_trap_context.x14;
		case 15: return m_trap_context.x15;
		case 16: return m_trap_context.x16;
		case 17: return m_trap_context.x17;
		case 18: return m_trap_context.x18;
		case 19: return m_trap_context.x19;
		case 20: return m_trap_context.x20;
		case 21: return m_trap_context.x21;
		case 22: return m_trap_context.x22;
		case 23: return m_trap_context.x23;
		case 24: return m_trap_context.x24;
		case 25: return m_trap_context.x25;
		case 26: return m_trap_context.x26;
		case 27: return m_trap_context.x27;
		case 28: return m_trap_context.x28;
		case 29: return m_trap_context.x29;
		case 30: return m_trap_context.x30;
		case 31: return m_trap_context.x31;
	}
}

static void m_write_reg(int reg, unsigned value)
{
	switch (reg) {
		case 1:  m_trap_context.x1 = value; break;
		case 2:  m_trap_context.x2 = value; break;
		case 3:  m_trap_context.x3 = value; break;
		case 4:  m_trap_context.x4 = value; break;
		case 5:  m_trap_context.x5 = value; break;
		case 6:  m_trap_context.x6 = value; break;
		case 7:  m_trap_context.x7 = value; break;
		case 8:  m_trap_context.x8 = value; break;
		case 9:  m_trap_context.x9 = value; break;
		case 10: m_trap_context.x10 = value; break;
		case 11: m_trap_context.x11 = value; break;
		case 12: m_trap_context.x12 = value; break;
		case 13: m_trap_context.x13 = value; break;
		case 14: m_trap_context.x14 = value; break;
		case 15: m_trap_context.x15 = value; break;
		case 16: m_trap_context.x16 = value; break;
		case 17: m_trap_context.x17 = value; break;
		case 18: m_trap_context.x18 = value; break;
		case 19: m_trap_context.x19 = value; break;
		case 20: m_trap_context.x20 = value; break;
		case 21: m_trap_context.x21 = value; break;
		case 22: m_trap_context.x22 = value; break;
		case 23: m_trap_context.x23 = value; break;
		case 24: m_trap_context.x24 = value; break;
		case 25: m_trap_context.x25 = value; break;
		case 26: m_trap_context.x26 = value; break;
		case 27: m_trap_context.x27 = value; break;
		case 28: m_trap_context.x28 = value; break;
		case 29: m_trap_context.x29 = value; break;
		case 30: m_trap_context.x30 = value; break;
		case 31: m_trap_context.x31 = value; break;
		default: break;
	}
}
