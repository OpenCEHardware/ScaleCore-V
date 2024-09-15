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
    input  logic [4:0] ctrl_trap_cause,
    input  word        ctrl_trap_value,
    input  word        ctrl_next_pc,
    input  logic       ctrl_commit,
    output logic       ctrl_begin_irq,

    input  hsv_core_ctrlstatus_regs__out_t         regs_i,
    output hsv_core_ctrlstatus_regs__MSTATUS__in_t mstatus_o,
    output hsv_core_ctrlstatus_regs__MEPC__in_t    mepc_o,
    output hsv_core_ctrlstatus_regs__MCAUSE__in_t  mcause_o,
    output hsv_core_ctrlstatus_regs__MTVAL__in_t   mtval_o,

    output privilege_t current_mode
);

  typedef enum int unsigned {
    TRAP,
    FLUSH_ENTER,
    FLUSH_EXIT,
    RUN,
    IRQ_PENDING
  } state_t;

  state_t state, next_state;
  privilege_t to_mode;

  logic interrupt_enable, irq_pending, mode_switch, take_irq;

  word jump_address;
  logic is_trap, jump, write_trap;
  logic [$bits(mcause_o.CODE.next) - 1:0] trap_code;

  localparam int MepcPadBits = $bits(ctrl_next_pc) - $bits(mepc_o.PC.next);
  localparam int MtvecPadBits = $bits(ctrl_next_pc) - $bits(regs_i.MTVEC.BASE.value);
  localparam int McausePadBits = $bits(mcause_o.CODE.next) - $bits(ctrl_trap_cause);

  assign is_trap = ctrl_trap | take_irq;
  assign jump_address = is_trap ? {regs_i.MTVEC.BASE.value, {MtvecPadBits{1'b0}}} : ctrl_next_pc;

  assign mstatus_o.MIE.we = mode_switch;
  assign mstatus_o.MIE.next = 0;

  assign mstatus_o.MPP.we = mode_switch;
  assign mstatus_o.MPP.next = current_mode;

  assign mstatus_o.MPIE.we = mode_switch;
  assign mstatus_o.MPIE.next = interrupt_enable;

  assign mepc_o.PC.we = write_trap;
  assign mepc_o.PC.next = ctrl_next_pc[$bits(ctrl_next_pc)-1:MepcPadBits];

  assign mcause_o.CODE.we = write_trap;
  assign mcause_o.CODE.next = trap_code;

  assign mcause_o.INTERRUPT.we = write_trap;
  assign mcause_o.INTERRUPT.next = take_irq;

  assign mtval_o.VALUE.we = write_trap;
  assign mtval_o.VALUE.next = ctrl_trap_value;

  always_comb begin
    if (~take_irq) trap_code = {{McausePadBits{1'b0}}, ctrl_trap_cause};
    else trap_code = 'd11;  //TODO

    unique case (current_mode)
      // Interrupts are always enabled in user current_mode
      USER_MODE: interrupt_enable = 1;

      MACHINE_MODE: interrupt_enable = regs_i.MSTATUS.MIE.value;

      default: interrupt_enable = 'x;
    endcase

    jump = 0;
    flush_req = 0;
    ctrl_begin_irq = 0;

    to_mode = MACHINE_MODE;
    write_trap = 0;
    mode_switch = 0;

    next_state = state;

    unique case (state)
      TRAP: begin
        jump       = 1;
        flush_req  = 1;
        next_state = FLUSH_ENTER;

        if (is_trap) begin
          write_trap  = 1;
          mode_switch = 1;
        end
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

        if (ctrl_flush_begin) next_state = TRAP;
        else if (irq_pending) next_state = IRQ_PENDING;
      end

      IRQ_PENDING: begin
        flush_req = 0;
        ctrl_begin_irq = 1;

        if (ctrl_flush_begin | ctrl_commit) next_state = TRAP;
      end

      default: flush_req = 'x;
    endcase
  end

  always_ff @(posedge clk_core) begin
    take_irq <= ctrl_begin_irq & ~ctrl_flush_begin;
    irq_pending <= irq & interrupt_enable;

    if (jump) flush_target <= jump_address;
  end

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) begin
      state <= TRAP;
      current_mode <= MACHINE_MODE;
    end else begin
      state <= next_state;

      if (mode_switch) current_mode <= to_mode;
    end

endmodule
