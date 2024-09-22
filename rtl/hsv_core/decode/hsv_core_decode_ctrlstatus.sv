module hsv_core_decode_ctrlstatus
  import hsv_core_pkg::*;
  import hsv_core_decode_pkg::*;
(
    input  word              insn,
    output ctrlstatus_data_t ctrlstatus_data,

    input  decode_common_t common_i,
    output common_data_t   common_o,
    output logic           illegal,

    input privilege_t current_mode
);

  logic dst_is_zero, src_is_zero;

  always_comb begin
    illegal = 0;

    unique case (rv_major_op(
        insn
    ))
      RV_MAJOR_SYSTEM:
      unique case (rv_funct3_op(
          insn
      ))
        RvFunct3SystemPriv: begin
          common_o = common_i.r_type;
          common_o.rs2_addr = '0;
        end

        RvFunct3SystemCsrrw, RvFunct3SystemCsrrs, RvFunct3SystemCsrrc: common_o = common_i.i_type;

        RvFunct3SystemCsrrwi, RvFunct3SystemCsrrsi, RvFunct3SystemCsrrci: begin
          common_o = common_i.i_type;
          common_o.rs1_addr = '0;
          ctrlstatus_data.is_immediate = 1;
        end

        default: illegal = 1;
      endcase

      default: illegal = 1;
    endcase

    dst_is_zero = common_o.rd_addr == '0;
    src_is_zero = common_o.rs1_addr == '0;

    ctrlstatus_data = '0;
    ctrlstatus_data.short_immediate = common_o.rs1_addr;

    unique case (rv_funct3_op(
        insn
    ))
      RvFunct3SystemPriv: begin
        unique case (rv_funct12_op(
            insn
        ))
          RvFunct12SystemPrivMret: begin
            ctrlstatus_data.mode_return = 1;
            if (current_mode != MACHINE_MODE) illegal = 1;
          end

          RvFunct12SystemPrivWfi: ctrlstatus_data.wait_irq = 1;

          default: illegal = 1;
        endcase

        if (~src_is_zero | ~dst_is_zero) illegal = 1;
      end

      RvFunct3SystemCsrrw:  ;
      RvFunct3SystemCsrrs:  ;
      RvFunct3SystemCsrrc:  ;
      RvFunct3SystemCsrrwi: ;
      RvFunct3SystemCsrrsi: ;
      RvFunct3SystemCsrrci: ;

      default: illegal = 1;
    endcase

    unique case (rv_funct3_op(
        insn
    ))
      RvFunct3SystemPriv: ;

      RvFunct3SystemCsrrw, RvFunct3SystemCsrrwi: begin
        ctrlstatus_data.read  = ~dst_is_zero;
        ctrlstatus_data.write = 1;
      end

      RvFunct3SystemCsrrs, RvFunct3SystemCsrrc, RvFunct3SystemCsrrsi, RvFunct3SystemCsrrci: begin
        ctrlstatus_data.read  = 1;
        ctrlstatus_data.write = ~src_is_zero;
      end

      default: illegal = 1;
    endcase

    unique case (rv_funct3_op(
        insn
    ))
      RvFunct3SystemPriv, RvFunct3SystemCsrrw, RvFunct3SystemCsrrwi: ;

      RvFunct3SystemCsrrs, RvFunct3SystemCsrrsi: ctrlstatus_data.write_mask = 1;

      RvFunct3SystemCsrrc, RvFunct3SystemCsrrci: begin
        ctrlstatus_data.write_flip = 1;
        ctrlstatus_data.write_mask = 1;
      end

      default: illegal = 1;
    endcase

    if (illegal) begin
      common_o = 'x;
      ctrlstatus_data = 'x;
    end
  end

endmodule
