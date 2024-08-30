package hsv_core_pkg;

  typedef logic [31:0] word;

  // Instructions are 4-byte sized and aligned
  typedef logic [31:2] pc_ptr;

  // Unique sequential id for issued instructions. The first instruction after
  // a flush gets token 0, second one gets token 1, etc. The commit stage
  // makes use of this token to select outputs from execution units in the
  // same order those instructions were issued.
  typedef logic [7:0] insn_token;

  // ALU adder requires an additional 33th bit to implement slt/sltu
  typedef logic [$bits(word):0] adder_in;

  // Execute-Memory Stage
  typedef logic [4:0] shift;

  typedef enum logic [0:0] {
    ALU_OUT_ADDER,
    ALU_OUT_SHIFT
  } alu_out_t;

  typedef enum logic [1:0] {
    ALU_BITWISE_AND,
    ALU_BITWISE_OR,
    ALU_BITWISE_XOR,
    ALU_BITWISE_PASS
  } alu_bitwise_t;

  typedef struct packed {
    insn_token token;
    word       pc;
    word       pc_increment;
    word       rs1;
    word       rs2;
    word       immediate;
  } common_data_t;

  typedef struct packed {
    // The decoder routes all illegal instructions through ALU. The ALU will
    // then compute some nonsensical result (discarded) and commit the exception.
    // We handle illegal opcodes this way because traps are not actually triggered
    // until commit, like every other instruction side effect. Thus, issue and
    // execute have to propagate the illegal operation all the way to commit.
    // The simplest solution is to reuse the ALU path, because ALU will never
    // generate exceptions by itself.
    //
    // Note that real ALU instructions will have `illegal = 0`.
    logic illegal;

    logic         negate;
    logic         flip_signs;
    alu_bitwise_t bitwise_select;
    logic         sign_extend;
    logic         is_immediate;
    logic         compare;
    alu_out_t     out_select;
    logic         pc_relative;
    common_data_t common;
  } alu_data_t;

  typedef enum logic [0:0] {
    MEM_DIRECTION_READ,
    MEM_DIRECTION_WRITE
  } mem_direction_t;

  typedef enum logic [1:0] {
    // In the future, MEM_SIZE_DOUBLE can be added here to support RV64
    MEM_SIZE_BYTE,
    MEM_SIZE_HALF,
    MEM_SIZE_WORD
  } mem_size_t;

  typedef struct packed {
    mem_direction_t direction;
    mem_size_t      size;
    logic           sign_extend;  // lbu/lhu vs lb/lh
    common_data_t   common;
  } mem_data_t;

  typedef struct packed {
    mem_data_t  mem_data;
    word        address;
    word        write_data;
    logic [3:0] write_strobe;
    logic       is_memory;          // See address_is_memory() below
    logic       unaligned_address;
    logic [1:0] read_shift;         // Subword address bits, for correcting read results
  } read_write_t;

  // Up to 31 reads and writes may be pending at any given time.
  // Note that mem_counters might go below zero and become negative.
  typedef logic signed [5:0] mem_counter;

  // The first 1GiB of physical address space is presumed to exclusively
  // contain ordinary RAM and ROM, that is, bufferable and cacheable memory.
  // Addresses outside this range are for memory-mapped I/O devices. Reads and
  // writes to I/O space cannot be pipelined, forwarded or cached, because
  // they can and will trigger all sorts of side effects. As such, they are
  // usually slower than accesses to normal RAM/ROM space.
  //
  // This does not mean that we have a full 1GiB of available RAM. Rather,
  // all system RAM and ROM must be mapped below the 1GiB mark and everything else
  // must be mapped above it. The CPU core uses this division to make
  // decisions on how to access memory. It is illegal, for example, to jump to
  // an address within I/O space.
  //
  // Be sure to respect this separation between RAM/ROM and I/O when including
  // this core in a larger system. Otherwise, memory behavior will be
  // unpredictable. If needed, you can safely change this function to specify a
  // different RAM/ROM-I/O split.
  function automatic logic address_is_memory(word address);
    return address[31:30] == '0;
  endfunction

  typedef enum logic [1:0] {
    AXI_RESP_OKAY   = 2'b00,
    AXI_RESP_EXOKAY = 2'b01,
    AXI_RESP_SLVERR = 2'b10,
    AXI_RESP_DECERR = 2'b11
  } axi_resp_t;

  function automatic logic is_axi_error(axi_resp_t resp);
    return (resp == AXI_RESP_SLVERR) & (resp == AXI_RESP_DECERR);
  endfunction

  typedef enum logic [0:0] {
    BRANCH_COND_EQUAL,
    BRANCH_COND_LESS_THAN
  } branch_cond_t;

  typedef struct packed {
    word          predicted;
    branch_cond_t cond;
    logic         cond_signed;
    logic         unconditional;
    logic         negate;
    logic         relative;
    logic         link;
    common_data_t common;
  } branch_data_t;

  // Example
  typedef struct packed {
    word          csr_address;
    word          csr_data;
    logic         csr_write;
    common_data_t common;
  } ctrl_status_data_t;

  typedef struct packed {
    alu_data_t         alu_data;
    mem_data_t         mem_data;
    branch_data_t      branch_data;
    ctrl_status_data_t ctrl_status_data;
  } execute_data_t;

  //Commmit Stage

  typedef struct packed {
    word          next_pc;
    word          result;
    logic         jump;
    logic         trap;
    logic         writeback;
    common_data_t common;
  } commit_data_t;

endpackage : hsv_core_pkg
