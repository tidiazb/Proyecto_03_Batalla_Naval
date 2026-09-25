package riscv_pkg;
    localparam int XLEN        = 32;           // ancho de palabra
    localparam int REG_ADDR_W  = 5;            // 32 registros -> 5 bits
    localparam logic [31:0] RESET_VECTOR = 32'h0000_0000;  // spec: inicio en 0x0

    localparam logic [6:0] OP_R      = 7'b0110011; // add, sub, sll, slt, ...
    localparam logic [6:0] OP_I_ALU  = 7'b0010011; // addi, slli, slti, ...
    localparam logic [6:0] OP_LOAD   = 7'b0000011; // lw
    localparam logic [6:0] OP_STORE  = 7'b0100011; // sw
    localparam logic [6:0] OP_BRANCH = 7'b1100011; // beq, bne, blt, bge, bltu, bgeu
    localparam logic [6:0] OP_JAL    = 7'b1101111; // jal
    localparam logic [6:0] OP_JALR   = 7'b1100111; // jalr
    localparam logic [6:0] OP_LUI    = 7'b0110111; // lui   (lo genera 'li')
    localparam logic [6:0] OP_AUIPC  = 7'b0010111; // auipc (lo genera 'la'/'call')

endpackage