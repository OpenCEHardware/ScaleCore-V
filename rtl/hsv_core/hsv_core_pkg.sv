package hsv_core_pkg;

typedef logic [31:0] word;


typedef struct {

    word reg_a;
    word reg_b;

} issue2exec_t;

typedef struct {

    issue2exec_t common;



} issue2alu_t;

typedef struct {

    issue2exec_t common;


} issue2mem_t;

typedef struct {

    issue2alu_t alu;
    issue2mem mem;


} issue2exec_t;

endpackage
