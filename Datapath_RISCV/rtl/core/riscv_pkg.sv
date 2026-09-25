package riscv_pkg;
//Anchos
    localparam int XLEN        = 32;           // ancho de palabra
    localparam int REG_ADDR_W  = 5;            // 32 registros -> 5 bits
    localparam logic [31:0] RESET_VECTOR = 32'h0000_0000;  // spec: inicio en 0x0
//Opcodes
    localparam logic [6:0] OP_R      = 7'b0110011; // add, sub, sll, slt, ...
    localparam logic [6:0] OP_I_ALU  = 7'b0010011; // addi, slli, slti, ...
    localparam logic [6:0] OP_LOAD   = 7'b0000011; // lw
    localparam logic [6:0] OP_STORE  = 7'b0100011; // sw
    localparam logic [6:0] OP_BRANCH = 7'b1100011; // beq, bne, blt, bge, bltu, bgeu
    localparam logic [6:0] OP_JAL    = 7'b1101111; // jal
    localparam logic [6:0] OP_JALR   = 7'b1100111; // jalr
    localparam logic [6:0] OP_LUI    = 7'b0110111; // lui   (lo genera 'li')
    localparam logic [6:0] OP_AUIPC  = 7'b0010111; // auipc (lo genera 'la'/'call')
//Alu instructons
    localparam logic [3:0] ALU_ADD    = 4'b0000;
    localparam logic [3:0] ALU_SLL    = 4'b0001;
    localparam logic [3:0] ALU_SLT    = 4'b0010;  // con signo
    localparam logic [3:0] ALU_SLTU   = 4'b0011;  // sin signo
    localparam logic [3:0] ALU_XOR    = 4'b0100;
    localparam logic [3:0] ALU_SRL    = 4'b0101;
    localparam logic [3:0] ALU_OR     = 4'b0110;
    localparam logic [3:0] ALU_AND    = 4'b0111;
    localparam logic [3:0] ALU_SUB    = 4'b1000;
    localparam logic [3:0] ALU_SRA    = 4'b1101;
    localparam logic [3:0] ALU_PASS_B = 4'b1111;  // resultado = operando B (lui)

// Segundo operando ALu
    localparam logic ALUB_RS2 = 1'b0;
    localparam logic ALUB_IMM = 1'b1;

//Generdot de inmmediatos
    localparam logic [2:0] IMM_I = 3'b000;  // addi, lw, jalr, slli...
    localparam logic [2:0] IMM_S = 3'b001;  // sw
    localparam logic [2:0] IMM_B = 3'b010;  // beq, bne, ...
    localparam logic [2:0] IMM_J = 3'b011;  // jal
    localparam logic [2:0] IMM_U = 3'b100;  // lui, auipc

//Register 
    localparam logic [1:0] RES_ALU    = 2'b00;  // tipo R / tipo I / lui
    localparam logic [1:0] RES_MEM    = 2'b01;  // lw (DataIn_i)
    localparam logic [1:0] RES_PC4    = 2'b10;  // jal / jalr (dirección de retorno)
    localparam logic [1:0] RES_PC_IMM = 2'b11;  // auipc



endpackage