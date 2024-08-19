package hsv_core_pkg;

  typedef logic [31:0] word;

  // Instructions are 4-byte sized and aligned
  typedef logic [31:2] pc_ptr;

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
    word pc;
    word pc_increment;
    word rs1;
    word rs2;
    word immediate;
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

  // Example
  typedef struct packed {
    word          address;
    word          store_data;
    logic         load;
    logic         store;
    common_data_t common;
  } mem_data_t;

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
