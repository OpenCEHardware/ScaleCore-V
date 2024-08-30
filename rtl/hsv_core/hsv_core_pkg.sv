package hsv_core_pkg;
//      ______________________________________
//_____/ CORE

  // Constants

  parameter int RegAmount = 32;

  // -------------- Core typedefs --------------

  typedef logic [31:0] word;
  typedef logic [4:0] reg_addr;

  // Instructions are 4-byte sized and aligned
  typedef logic [31:2] pc_ptr;

  // -------------- Core enums --------------


  // -------------- Core structs --------------

  typedef struct packed {
      word pc;
      reg_addr rs1_addr;
      reg_addr rs2_addr;
      reg_addr rd_addr;
      word immediate;
    } common_data_t;

//      ______________________________________
//_____/ FRONTEND STAGE


  // -------------- Frontend typedefs --------------



  // -------------- Frontend enums -----------------



  // -------------- Frontend structs ---------------




//      ______________________________________
//_____/ EXECUTE-MEMORY STAGE


  // -------------- Exec-Mem typedefs --------------

  // ALU adder requires an additional 33th bit to implement slt/sltu
  typedef logic [$bits(word):0] adder_in;

  typedef logic [4:0] shift;

  // -------------- Exec-Mem enums -----------------

    // -- ALU --

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

    // -- Branch --

      typedef enum logic [0:0] {
        BRANCH_COND_EQUAL,
        BRANCH_COND_LESS_THAN
      } branch_cond_t;

    // -- Control-Status --



    // -- Memory --



  // -------------- Exec-Mem structs ---------------

    typedef struct packed {
      word pc;
      word pc_increment;
      word rs1;
      word rs2;
      word immediate;
    } exec_mem_common_t;

    // -- ALU --

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
        exec_mem_common_t common;
      } alu_data_t;

    // -- Branch --

      typedef struct packed {
        word          predicted;
        branch_cond_t cond;
        logic         cond_signed;
        logic         unconditional;
        logic         negate;
        logic         relative;
        logic         link;
        exec_mem_common_t common;
      } branch_data_t;

    // -- Control-Status --

      // Example
      typedef struct packed {
        word          csr_address;
        word          csr_data;
        logic         csr_write;
        exec_mem_common_t common;
      } ctrl_status_data_t;

    // -- Memory --

      // Example
      typedef struct packed {
        word          address;
        word          store_data;
        logic         load;
        logic         store;
        exec_mem_common_t common;
      } mem_data_t;

    typedef struct packed {
      alu_data_t         alu_data;
      mem_data_t         mem_data;
      branch_data_t      branch_data;
      ctrl_status_data_t ctrl_status_data;
    } exec_mem_data_t;

//      ______________________________________
//_____/ ISSUE STAGE


  // -------------- Issue typedefs --------------

  typedef logic [RegAmount-1:1] reg_mask;


  // -------------- Issue enums -----------------

    // In this case we use a one-hot vector notation to avoid adding extra
    // decoding logic. On downside is unknown behavour should the signal
    // erroneously flip one bit
    typedef struct packed{
      logic alu;
      logic branch;
      logic ctrl_status;
      logic mem;
    } exec_select_t;

  // -------------- Issue structs ---------------

    typedef struct packed {
      common_data_t common;
      exec_mem_data_t exec_mem_data;
      exec_select_t exec_select;
    } issue_data_t;

//      ______________________________________
//_____/ COMMIT STAGE


// -------------- Commit typedefs --------------



// -------------- Commit enums -----------------



// -------------- Commit structs ---------------

  typedef struct packed {
    word          next_pc;
    word          result;
    logic         jump;
    logic         trap;
    logic         writeback;
    exec_mem_common_t common;
  } commit_data_t;

endpackage : hsv_core_pkg
