// ============================================================================
// alu.sv - ALU de 32 bits para RV32I
// La operación la decide la UNIDAD DE CONTROL mediante alu_ctrl_i
// (codificación en riscv_pkg: {funct7[5], funct3}). La ALU conoce la instruccion ni el opcode.
//
//   alu_ctrl | op    | resultado
//   ---------+-------+----------------------------------------
//    0000    | ADD   | a + b
//    1000    | SUB   | a - b
//    0111    | AND   | a & b
//    0110    | OR    | a | b
//    0100    | XOR   | a ^ b
//    0001    | SLL   | a << b[4:0]
//    0101    | SRL   | a >> b[4:0]          (lógico)
//    1101    | SRA   | a >>> b[4:0]         (aritmético)
//    0010    | SLT   | (a < b) con signo  ? 1 : 0
//    0011    | SLTU  | (a < b) sin signo  ? 1 : 0
//    1111    | PASS_B| b                    (lui)
//    otros   |  -    | 0
// Banderas: zero_o (resultado == 0), útil para depuración / extensiones.
// ============================================================================
module alu
#(
  parameter int WIDTH = 32
)(
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic [3:0]       alu_ctrl_i,
  output logic [WIDTH-1:0] result_o,
  output logic             zero_o
);

  import riscv_pkg::*;

  logic [4:0] shamt;
  assign shamt = b_i[4:0];   // RV32I: solo los 5 LSB cuentan en shifts

  always_comb begin
    case (alu_ctrl_i)
      ALU_ADD:    result_o = a_i + b_i;
      ALU_SUB:    result_o = a_i - b_i;
      ALU_AND:    result_o = a_i & b_i;
      ALU_OR:     result_o = a_i | b_i;
      ALU_XOR:    result_o = a_i ^ b_i;
      ALU_SLL:    result_o = a_i << shamt;
      ALU_SRL:    result_o = a_i >> shamt;
      ALU_SRA:    result_o = $unsigned($signed(a_i) >>> shamt);
      ALU_SLT:    result_o = {{(WIDTH-1){1'b0}}, ($signed(a_i) < $signed(b_i))};
      ALU_SLTU:   result_o = {{(WIDTH-1){1'b0}}, (a_i < b_i)};
      ALU_PASS_B: result_o = b_i;
      default:    result_o = '0;
    endcase
  end

  assign zero_o = (result_o == '0);

endmodule
