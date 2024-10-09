.text

.global m_trap_entry
m_trap_entry:

.option push
.option norelax
	# We use the scratch CSR as temp storage, it would be impossible
	# to save the state of all registers otherwise
	csrw  mscratch, a0
	la    a0, m_trap_context

	# Save all registers
	sw    ra,  4(a0)
	sw    sp,  8(a0)
	sw    gp,  12(a0)
	sw    tp,  16(a0)
	sw    t0,  20(a0)
	sw    t1,  24(a0)
	sw    t2,  28(a0)
	sw    s0,  32(a0)
	sw    s1,  36(a0)
	# We will save a0 later (remember, it is in mscratch)
	sw    a1,  44(a0)
	sw    a2,  48(a0)
	sw    a3,  52(a0)
	sw    a4,  56(a0)
	sw    a5,  60(a0)
	sw    a6,  64(a0)
	sw    a7,  68(a0)
	sw    s2,  72(a0)
	sw    s3,  76(a0)
	sw    s4,  80(a0)
	sw    s5,  84(a0)
	sw    s6,  88(a0)
	sw    s7,  92(a0)
	sw    s8,  96(a0)
	sw    s9,  100(a0)
	sw    s10, 104(a0)
	sw    s11, 108(a0)
	sw    t3,  112(a0)
	sw    t4,  116(a0)
	sw    t5,  120(a0)
	sw    t6,  124(a0)

	# Next, we save the trap PC, cause and value

	csrr  t0, mepc
	sw    t0, 0(a0)

	# The value in mscratch used to be a0
	csrr  t1, mscratch
	sw    t1, 40(a0)

	csrr  t2, mstatus
	sw    t2, 128(a0)

	csrr  t3, mcause
	sw    t3, 132(a0)

	csrr  t4, mtval
	sw    t4, 136(a0)

    la    gp, __global_pointer$
	la    sp, m_trap_stack_top
	mv    ra, zero
	jal   m_handle_trap
.option pop

	# When m_handle_trap returns, it will jump to m_trap_exit, because that
	# is what comes after this point in code. In other words, the relative
	# order of m_trap_entry and m_trap_exit must not be changed.

.global m_trap_exit
m_trap_exit:
	la    a0, m_trap_context

	lw    t0, 0(a0)
	csrw  mepc, t0

	lw    t1, 128(a0)
	csrw  mstatus, t1

	lw    ra,  4(a0)
	lw    sp,  8(a0)
	lw    gp,  12(a0)
	lw    tp,  16(a0)
	lw    t0,  20(a0)
	lw    t1,  24(a0)
	lw    t2,  28(a0)
	lw    s0,  32(a0)
	lw    s1,  36(a0)
	# We will restore a0 last
	lw    a1,  44(a0)
	lw    a2,  48(a0)
	lw    a3,  52(a0)
	lw    a4,  56(a0)
	lw    a5,  60(a0)
	lw    a6,  64(a0)
	lw    a7,  68(a0)
	lw    s2,  72(a0)
	lw    s3,  76(a0)
	lw    s4,  80(a0)
	lw    s5,  84(a0)
	lw    s6,  88(a0)
	lw    s7,  92(a0)
	lw    s8,  96(a0)
	lw    s9,  100(a0)
	lw    s10, 104(a0)
	lw    s11, 108(a0)
	lw    t3,  112(a0)
	lw    t4,  116(a0)
	lw    t5,  120(a0)
	lw    t6,  124(a0)

	# Finally, restore a0 and return from trap
	lw    a0,  40(a0)
	mret 

.section .bss
.skip 1024
.balign 4
m_trap_stack_top:
