package hsv_core_pkg;

  typedef logic [31:0] word;

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
    word rs1;
    word rs2;
    word immediate;
  } common_data_t;

  typedef struct packed {
    logic negate;
    logic flip_signs;
    logic bitwise_select;
    logic sign_extend;
    logic is_immediate;
    logic compare;
    logic out_select;
    word  pc_relative;

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

  // Example
  typedef struct packed {
    word          branch_target;
    logic         branch_taken;
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
    word pc;
    word result;
  } commit_data_t;

endpackage : hsv_core_pkg
