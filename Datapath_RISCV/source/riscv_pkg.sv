// Contrato compartido entre el DATAPATH y la UNIDAD DE CONTROL del núcleo
//
// No se debe modificar ningun parametro en este archivo ya que sea cae el procesador
// La unidad de control debe tener estos mimos parametros
// ============================================================================
package riscv_pkg;

  // No todos los módulos usan todas las constantes -> se silencia el linter
  /* verilator lint_off UNUSEDPARAM */

  // --------------------------------------------------------------------------
  // Anchos
  // --------------------------------------------------------------------------
  localparam int XLEN        = 32;           // ancho de palabra
  localparam int REG_ADDR_W  = 5;            // 32 registros -> 5 bits
  localparam logic [31:0] RESET_VECTOR = 32'h0000_0000;  // spec: inicio en 0x0

  // --------------------------------------------------------------------------
  // Opcodes RV32I (instr[6:0]) - útiles para control y para los testbenches
  // --------------------------------------------------------------------------
  localparam logic [6:0] OP_R      = 7'b0110011; // add, sub, sll, slt, ...
  localparam logic [6:0] OP_I_ALU  = 7'b0010011; // addi, slli, slti, ...
  localparam logic [6:0] OP_LOAD   = 7'b0000011; // lw
  localparam logic [6:0] OP_STORE  = 7'b0100011; // sw
  localparam logic [6:0] OP_BRANCH = 7'b1100011; // beq, bne, blt, bge, bltu, bgeu
  localparam logic [6:0] OP_JAL    = 7'b1101111; // jal
  localparam logic [6:0] OP_JALR   = 7'b1100111; // jalr
  localparam logic [6:0] OP_LUI    = 7'b0110111; // lui   (lo genera 'li')
  localparam logic [6:0] OP_AUIPC  = 7'b0010111; // auipc (lo genera 'la'/'call')

  // --------------------------------------------------------------------------
  // alu_ctrl[3:0]
  // Codificación = {funct7[5], funct3} de RISC-V. Así el decodificador de ALU
  // de la unidad de control es casi un "pass-through":
  //   - Tipo R           : alu_ctrl = {instr[30], instr[14:12]}
  //   - Tipo I aritmético: alu_ctrl = {1'b0,      instr[14:12]}
  //                        excepto srai (funct3=101): {instr[30], 3'b101}
  //   - lw / sw / jalr   : ALU_ADD (dirección = rs1 + imm)
  //   - lui              : ALU_PASS_B
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // imm_src[2:0] : formato del inmediato
  // --------------------------------------------------------------------------
  localparam logic [2:0] IMM_I = 3'b000;  // addi, lw, jalr, slli...
  localparam logic [2:0] IMM_S = 3'b001;  // sw
  localparam logic [2:0] IMM_B = 3'b010;  // beq, bne, ...
  localparam logic [2:0] IMM_J = 3'b011;  // jal
  localparam logic [2:0] IMM_U = 3'b100;  // lui, auipc

  // --------------------------------------------------------------------------
  // result_src[1:0] : qué se escribe en el Register File
  // --------------------------------------------------------------------------
  localparam logic [1:0] RES_ALU    = 2'b00;  // tipo R / tipo I / lui
  localparam logic [1:0] RES_MEM    = 2'b01;  // lw (DataIn_i)
  localparam logic [1:0] RES_PC4    = 2'b10;  // jal / jalr (dirección de retorno)
  localparam logic [1:0] RES_PC_IMM = 2'b11;  // auipc

  // --------------------------------------------------------------------------
  // alu_src_b : segundo operando de la ALU
  // --------------------------------------------------------------------------
  localparam logic ALUB_RS2 = 1'b0;
  localparam logic ALUB_IMM = 1'b1;

  // --------------------------------------------------------------------------
  // funct3 de branches (los evalúa branch_unit dentro del datapath)
  // --------------------------------------------------------------------------
  localparam logic [2:0] F3_BEQ  = 3'b000;
  localparam logic [2:0] F3_BNE  = 3'b001;
  localparam logic [2:0] F3_BLT  = 3'b100;
  localparam logic [2:0] F3_BGE  = 3'b101;
  localparam logic [2:0] F3_BLTU = 3'b110;
  localparam logic [2:0] F3_BGEU = 3'b111;

  /* verilator lint_on UNUSEDPARAM */

endpackage