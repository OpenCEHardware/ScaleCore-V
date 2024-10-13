#ifndef MACHINE_CONFIG_H
#define MACHINE_CONFIG_H

// Enable mnemonic decoding for illegal instructions.
// Adds a large lookup table containing all existing RISC-V instructions.
#define M_DEBUG_INSN 0

// Similar to M_DEBUG_INSN, but for illegal CSR accesses.
// Adds a large lookup table containing all existing RISC-V CSRs.
#define M_DEBUG_CSR 0

#endif
