module hsv_core_ctrlstatus_fsm
  import hsv_core_pkg::*;
  import hsv_core_ctrlstatus_regs_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,
    input logic irq,

    output word  flush_target,
    output logic flush_req,
    input  logic flush_ack,

    input  logic       ctrl_flush_begin,
    input  logic       ctrl_trap,
    input  exception_t ctrl_trap_cause,
    input  word        ctrl_trap_value,
    input  logic       ctrl_mode_return,
    input  word        ctrl_next_pc,
    input  logic       ctrl_commit,
    input  logic       ctrl_wait_irq,
    output logic       ctrl_begin_irq,

    input  hsv_core_ctrlstatus_regs__out_t         regs_i,
    output hsv_core_ctrlstatus_regs__MSTATUS__in_t mstatus_o,
    output hsv_core_ctrlstatus_regs__MEPC__in_t    mepc_o,
    output hsv_core_ctrlstatus_regs__MCAUSE__in_t  mcause_o,
    output hsv_core_ctrlstatus_regs__MTVAL__in_t   mtval_o,

    output privilege_t current_mode
);

  typedef enum int unsigned {
    SETTLE,
    FLUSH_ENTER,
    FLUSH_EXIT,
    RUN,
    IRQ_PENDING,
    WAIT_FOR_IRQ
  } state_t;

  state_t state, next_state;
  privilege_t to_mode;

  logic interrupt_enable, irq_pending, is_trap, mode_switch, take_irq, wait_for_irq;

  word jump_address;
  logic jump;
  logic [$bits(mcause_o.CODE.next) - 1:0] trap_code;

  localparam int MepcPadBits = $bits(ctrl_next_pc) - $bits(mepc_o.PC.next);
  localparam int MtvecPadBits = $bits(ctrl_next_pc) - $bits(regs_i.MTVEC.BASE.value);
  localparam int McausePadBits = $bits(mcause_o.CODE.next) - $bits(ctrl_trap_cause);

  assign is_trap = ctrl_trap | take_irq;

  assign mepc_o.PC.we = mode_switch & ~ctrl_mode_return;
  assign mepc_o.PC.next = ctrl_next_pc[$bits(ctrl_next_pc)-1:MepcPadBits];

  assign mcause_o.CODE.we = mode_switch & ~ctrl_mode_return;
  assign mcause_o.CODE.next = trap_code;

  assign mcause_o.INTERRUPT.we = mode_switch & ~ctrl_mode_return;
  assign mcause_o.INTERRUPT.next = take_irq;

  assign mtval_o.VALUE.we = mode_switch & ~ctrl_mode_return;
  assign mtval_o.VALUE.next = ctrl_trap_value;

  always_comb begin
    unique case (current_mode)
      // Interrupts are always enabled in user mode
      USER_MODE: interrupt_enable = 1;

      MACHINE_MODE: interrupt_enable = regs_i.MSTATUS.MIE.value;

      default: interrupt_enable = 'x;
    endcase

    jump = 0;
    flush_req = 0;
    ctrl_begin_irq = 0;

    to_mode = MACHINE_MODE;
    mode_switch = 0;
    wait_for_irq = 0;

    next_state = state;

    unique case (state)
      SETTLE: begin
        jump       = 1;
        flush_req  = 1;
        next_state = ctrl_wait_irq ? WAIT_FOR_IRQ : FLUSH_ENTER;

        if (is_trap) mode_switch = 1;
      end

      FLUSH_ENTER: begin
        flush_req = 1;
        if (flush_ack) next_state = FLUSH_EXIT;
      end

      FLUSH_EXIT: begin
        flush_req = 0;
        if (~flush_ack) next_state = RUN;
      end

      RUN: begin
        flush_req = 0;

        if (ctrl_flush_begin) next_state = SETTLE;
        else if (irq_pending) next_state = IRQ_PENDING;
      end

      IRQ_PENDING: begin
        flush_req = 0;
        ctrl_begin_irq = 1;

        if (ctrl_flush_begin | ctrl_commit) next_state = SETTLE;
      end

      WAIT_FOR_IRQ: begin
        flush_req = 1;
        wait_for_irq = 1;

        if (irq) next_state = SETTLE;
      end

      default: flush_req = 'x;
    endcase

    if (~take_irq) trap_code = {{McausePadBits{1'b0}}, ctrl_trap_cause};
    else trap_code = 'd11;  //TODO

    if (~is_trap) jump_address = ctrl_next_pc;
    else if (ctrl_mode_return) jump_address = {regs_i.MEPC.PC.value, {MepcPadBits{1'b0}}};
    else jump_address = {regs_i.MTVEC.BASE.value, {MtvecPadBits{1'b0}}};

    if (ctrl_mode_return) to_mode = privilege_t'(regs_i.MSTATUS.MPP.value);

    mstatus_o.MIE.we = mode_switch;
    mstatus_o.MIE.next = ctrl_mode_return ? regs_i.MSTATUS.MPIE.value : 0;

    mstatus_o.MPIE.we = mode_switch;
    mstatus_o.MPIE.next = ctrl_mode_return ? 1 : interrupt_enable;

    // Limit MPP to those modes we actually implement. Fallback to
    // the current mode if software writes an invalid value to MPP.
    unique case (regs_i.MSTATUS.MPP.value)
      MACHINE_MODE, USER_MODE: begin
        mstatus_o.MPP.we   = mode_switch;
        mstatus_o.MPP.next = ctrl_mode_return ? USER_MODE : current_mode;
      end

      default: begin
        mstatus_o.MPP.we   = 1;
        mstatus_o.MPP.next = current_mode;
      end
    endcase
  end

  always_ff @(posedge clk_core) begin
    take_irq <= (ctrl_begin_irq & ~ctrl_flush_begin) | (wait_for_irq & interrupt_enable);
    irq_pending <= irq & interrupt_enable;

    if (jump) flush_target <= jump_address;
  end

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) begin
      state <= SETTLE;
      current_mode <= MACHINE_MODE;
    end else begin
      state <= next_state;

      if (mode_switch) current_mode <= to_mode;
    end

endmodule
