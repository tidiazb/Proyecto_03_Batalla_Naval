// ============================================================================
// imm_gen.sv - Generador de inmediatos (extensión de signo incluida)
// El formato lo decide la unidad de control mediante imm_src_i.
//
//   imm_src | tipo | instrucciones        | inmediato de 32 bits
//   --------+------+----------------------+-------------------------------------------
//    000    |  I   | addi, lw, jalr, ...  | {{20{i[31]}}, i[31:20]}
//    001    |  S   | sw                   | {{20{i[31]}}, i[31:25], i[11:7]}
//    010    |  B   | beq, bne, ...        | {{19{i[31]}}, i[31], i[7], i[30:25], i[11:8], 1'b0}
//    011    |  J   | jal                  | {{11{i[31]}}, i[31], i[19:12], i[20], i[30:21], 1'b0}
//    100    |  U   | lui, auipc           | {i[31:12], 12'b0}
//
// Shifts inmediatos (slli/srli/srai) usan formato I: los bits [11:5] traen
// funct7, pero la ALU solo usa b[4:0] (shamt), así que no hace falta caso aparte.
// ============================================================================
module imm_gen
(
  input  logic [31:7] instr_i,   // el opcode (bits 6:0) no se necesita aquí
  input  logic [2:0]  imm_src_i,
  output logic [31:0] imm_o
);

  import riscv_pkg::*;

  always_comb begin
    case (imm_src_i)
      IMM_I:   imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
      IMM_S:   imm_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
      IMM_B:   imm_o = {{19{instr_i[31]}}, instr_i[31], instr_i[7],
                        instr_i[30:25], instr_i[11:8], 1'b0};
      IMM_J:   imm_o = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12],
                        instr_i[20], instr_i[30:21], 1'b0};
      IMM_U:   imm_o = {instr_i[31:12], 12'b0};
      default: imm_o = '0;
    endcase
  end

endmodule
