module hsv_core_mem_address
  import hsv_core_pkg::*;
(
    input logic clk_core,

    input logic flush,
    input logic request_stall,
    input logic response_stall,

    input mem_data_t mem_data,
    input logic      valid_i,

    output read_write_t transaction,
    output logic        request_valid_o,
    output logic        response_valid_o
);

  localparam int AddrSubwordBits = $clog2($bits(word) / 8);
  localparam int AddrSubhalfBits = AddrSubwordBits - 1;

  word address, write_data, write_data_word;
  logic misaligned_address;
  logic [3:0] write_strobe;
  logic [7:0] write_data_byte;
  logic [15:0] write_data_half;

  assign write_data_byte = write_data_word[$bits(write_data_byte)-1:0];
  assign write_data_half = write_data_word[$bits(write_data_half)-1:0];
  assign write_data_word = mem_data.common.rs2;

  always_comb begin
    // Note that rs1 is always the base address, even for stores:
    // lw rd,  imm(rs1)
    // sw rs2, imm(rs1)
    address = mem_data.common.rs1 + mem_data.common.immediate;

    // AXI requires all accesses to be word-sized and word-aligned. However,
    // RISC-V permits loads and stores to individual bytes and half-words
    // (lb/lh, sb/sh). Therefore, we map these instructions into
    // equivalent word accesses. For writes, AXI's wstrb signal (write
    // strobe) is used to indicate which of the 4 bytes in a word are
    // actually written. We simply repeat the datum as many times as needed
    // to fill a word and then set the strobe appropriately (see below).
    //
    // For reads, it is sufficient to request the whole word and select
    // whatever part of it we really need. The read data word is
    // right-shifted and either sign-extended or zero-extended (lh/lb vs
    // lhu/lbu).
    //
    // In both cases, the lower address bits select the correct shifts
    // and/or masks. We also need to raise traps if an misaligned access is
    // attempted, and this is also done by checking the lower bits.
    //
    // For words (datum 'x' is 32 bits wide):
    // - Written word is x.
    // - Write strobe mask is always 4'b1111 because all bytes are written.
    // - Read word remains as-is
    // - Alignment trap if address bits [1:0] != 2'b00.
    //
    // For half-words (datum 'x' is 16 bits wide):
    // - Written word is {x, x}
    // - Write strobe mask is either 4'b0011 or 4'b1100, depending on
    //    address bit [1].
    // - Read selects either bits [15:0] or bits [31:16] from read word
    // - Alignment trap if bit [0] != 1'b0.
    //
    // For bytes (datum 'x' is 8 bits wide)
    // - Written word is {x, x, x, x}.
    // - Write strobe mask is one of 4'b0001, 4'b0010, 4'b0100, 4'b1000,
    //   depending on address bits [1:0].
    // - Read selects one of [7:0], [15:8], [23:16] or [31:24].
    // - Alignment traps never happen since any address is aligned to 1 byte.

    unique case (mem_data.size)
      MEM_SIZE_WORD: begin
        write_data = write_data_word;
        write_strobe = 4'b1111;
        misaligned_address = address[AddrSubwordBits-1:0] != '0;
      end

      MEM_SIZE_HALF: begin
        write_data = {2{write_data_half}};

        unique case (address[AddrSubwordBits-1:AddrSubhalfBits])
          1'b0:    write_strobe = 4'b0011;
          1'b1:    write_strobe = 4'b1100;
          default: write_strobe = 'x;
        endcase

        misaligned_address = address[AddrSubhalfBits-1:0] != '0;
      end

      MEM_SIZE_BYTE: begin
        write_data = {4{write_data_byte}};

        unique case (address[AddrSubwordBits-1:0])
          2'b00:   write_strobe = 4'b0001;
          2'b01:   write_strobe = 4'b0010;
          2'b10:   write_strobe = 4'b0100;
          2'b11:   write_strobe = 4'b1000;
          default: write_strobe = 'x;
        endcase

        misaligned_address = 1'b0;
      end

      default: begin
        write_data = 'x;
        write_strobe = 'x;
        misaligned_address = 'x;
      end
    endcase

    // Finally, zero-out the lower bits as we don't need them anymore. This
    // `address` has now become the actual address the CPU core will send
    // through dmem to the interconnect.
    address[AddrSubwordBits-1:0] = '0;
  end

  always_ff @(posedge clk_core) begin
    if (~request_stall) request_valid_o <= valid_i & ~response_stall;

    if (~response_stall) response_valid_o <= valid_i & ~request_stall;

    if (~request_stall & ~response_stall) begin
      transaction.address <= address;
      transaction.mem_data <= mem_data;
      transaction.is_memory <= address_is_memory(address);
      transaction.write_data <= write_data;
      transaction.write_strobe <= write_strobe;
      transaction.misaligned_address <= misaligned_address;
    end

    if (flush) begin
      request_valid_o  <= 0;
      response_valid_o <= 0;
    end
  end

endmodule
