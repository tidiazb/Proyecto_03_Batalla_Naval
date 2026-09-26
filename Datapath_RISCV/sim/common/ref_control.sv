// ============================================================================
// ref_control.sv  (SOLO SIMULACIÓN)
// Modelo de referencia de la unidad de control, usado únicamente para poder
// probar el datapath integrado antes de que exista la unidad de control real.
// Sirve además como ESPECIFICACIÓN EJECUTABLE del contrato de riscv_pkg:
// la unidad de control real debe producir exactamente estas señales.
// ============================================================================
module ref_control
(
  input  logic [31:0] instr_i,
  output logic        reg_write_o,
  output logic        alu_src_b_o,
  output logic [3:0]  alu_ctrl_o,
  output logic [2:0]  imm_src_o,
  output logic [1:0]  result_src_o,
  output logic        mem_write_o,
  output logic        branch_o,
  output logic        jump_o,
  output logic        jalr_o
);

  import riscv_pkg::*;

  logic [6:0] opcode;
  logic [2:0] f3;
  logic       f7b5;

  assign opcode = instr_i[6:0];
  assign f3     = instr_i[14:12];
  assign f7b5   = instr_i[30];

  always_comb begin
    // valores por defecto = NOP seguro (no escribe nada, PC+4)
    reg_write_o  = 1'b0;
    alu_src_b_o  = ALUB_RS2;
    alu_ctrl_o   = ALU_ADD;
    imm_src_o    = IMM_I;
    result_src_o = RES_ALU;
    mem_write_o  = 1'b0;
    branch_o     = 1'b0;
    jump_o       = 1'b0;
    jalr_o       = 1'b0;

    case (opcode)
      OP_R: begin
        reg_write_o = 1'b1;
        alu_ctrl_o  = {f7b5, f3};
      end
      OP_I_ALU: begin
        reg_write_o = 1'b1;
        alu_src_b_o = ALUB_IMM;
        alu_ctrl_o  = (f3 == 3'b101) ? {f7b5, f3} : {1'b0, f3};  // srai vs resto
      end
      OP_LOAD: begin
        reg_write_o  = 1'b1;
        alu_src_b_o  = ALUB_IMM;
        result_src_o = RES_MEM;
      end
      OP_STORE: begin
        alu_src_b_o = ALUB_IMM;
        imm_src_o   = IMM_S;
        mem_write_o = 1'b1;
      end
      OP_BRANCH: begin
        imm_src_o = IMM_B;
        branch_o  = 1'b1;
      end
      OP_JAL: begin
        reg_write_o  = 1'b1;
        imm_src_o    = IMM_J;
        result_src_o = RES_PC4;
        jump_o       = 1'b1;
      end
      OP_JALR: begin
        reg_write_o  = 1'b1;
        alu_src_b_o  = ALUB_IMM;
        result_src_o = RES_PC4;
        jalr_o       = 1'b1;
      end
      OP_LUI: begin
        reg_write_o = 1'b1;
        alu_src_b_o = ALUB_IMM;
        imm_src_o   = IMM_U;
        alu_ctrl_o  = ALU_PASS_B;
      end
      OP_AUIPC: begin
        reg_write_o  = 1'b1;
        imm_src_o    = IMM_U;
        result_src_o = RES_PC_IMM;
      end
      default: ;  // instrucción no soportada -> NOP
    endcase
  end

endmodule
