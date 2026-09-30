// Contiene: PC, lógica de siguiente PC, Register File, generador de
// inmediatos, ALU, unidad de comparación de branches y multiplexores.
// NO contiene la unidad de control ni las memorias: las señales de control
// entran como puertos y las memorias se conectan por los buses del core.

//  DataIn_i ---> mux write-back {ALU, DataIn, PC+4, PC+imm} --> rd     
//
// Reset síncrono activo en alto. Vector de reset = 0x0000_0000.


module datapath
#(
  parameter int          WIDTH        = 32,
  parameter logic [31:0] RST_VECTOR = riscv_pkg::RESET_VECTOR
)(
  input  logic             clk_i,
  input  logic             rst_i,

  // ---------------- Interfaz con memoria de programa (ROM) ----------------
  output logic [WIDTH-1:0] prog_addr_o,    // -> ProgAddress_o
  input  logic [31:0]      instr_i,        // <- ProgIn_i

  // ---------------- Interfaz con memoria de datos / periféricos -----------
  output logic [WIDTH-1:0] data_addr_o,    // -> DataAddress_o (rs1 + imm)
  output logic [WIDTH-1:0] data_wdata_o,   // -> DataOut_o     (rs2)
  output logic             data_we_o,      // -> we_o
  input  logic [WIDTH-1:0] data_rdata_i,   // <- DataIn_i

  // ---------------- Interfaz con la unidad de control ---------------------
  input  logic             reg_write_i,    // escribir rd
  input  logic             alu_src_b_i,    // 0: rs2, 1: imm
  input  logic [3:0]       alu_ctrl_i,     // operación ALU (riscv_pkg)
  input  logic [2:0]       imm_src_i,      // formato inmediato (riscv_pkg)
  input  logic [1:0]       result_src_i,   // fuente write-back (riscv_pkg)
  input  logic             mem_write_i,    // sw
  input  logic             branch_i,       // beq/bne/blt/bge/bltu/bgeu
  input  logic             jump_i,         // jal
  input  logic             jalr_i,         // jalr

  // ---------------- Estado hacia control / depuración ---------------------
  output logic             branch_taken_o, // branch_i & condición cumplida
  output logic             alu_zero_o
);

  import riscv_pkg::*;

  // --------------------------------------------------------------------------
  // Señales internas
  // --------------------------------------------------------------------------
  logic [WIDTH-1:0] pc, pc_next, pc_plus4, pc_target;
  logic [WIDTH-1:0] imm_ext;
  logic [WIDTH-1:0] rs1_data, rs2_data;
  logic [WIDTH-1:0] alu_b, alu_result;
  logic [WIDTH-1:0] wb_data;
  logic             branch_cond;
  logic             pc_redirect;

  // Campos de la instrucción usados por el datapath
  logic [4:0] rs1_addr, rs2_addr, rd_addr;
  logic [2:0] funct3;

  assign rs1_addr = instr_i[19:15];
  assign rs2_addr = instr_i[24:20];
  assign rd_addr  = instr_i[11:7];
  assign funct3   = instr_i[14:12];

  // El opcode (instr[6:0]) solo lo usa la unidad de control
  /* verilator lint_off UNUSEDSIGNAL */
  logic unused_opcode;
  assign unused_opcode = ^instr_i[6:0];
  logic unused_redirect;
  assign unused_redirect = pc_redirect;
  /* verilator lint_on UNUSEDSIGNAL */

  // --------------------------------------------------------------------------
  // PC y siguiente PC
  // --------------------------------------------------------------------------
  pc_reg #(.WIDTH(WIDTH), .RESET_VECTOR(RST_VECTOR)) u_pc (
    .clk_i     (clk_i),
    .rst_i     (rst_i),
    .pc_next_i (pc_next),
    .pc_o      (pc)
  );

  next_pc_logic #(.WIDTH(WIDTH)) u_next_pc (
    .pc_i          (pc),
    .imm_i         (imm_ext),
    .alu_result_i  (alu_result),
    .branch_i      (branch_i),
    .jump_i        (jump_i),
    .jalr_i        (jalr_i),
    .branch_cond_i (branch_cond),
    .pc_next_o     (pc_next),
    .pc_plus4_o    (pc_plus4),
    .pc_target_o   (pc_target),
    .pc_redirect_o (pc_redirect)
  );

  // --------------------------------------------------------------------------
  // Register File
  // --------------------------------------------------------------------------
  reg_file #(.WIDTH(WIDTH), .ADDR_W(5)) u_rf (
    .clk_i    (clk_i),
    .rst_i    (rst_i),
    .we_i     (reg_write_i),
    .waddr_i  (rd_addr),
    .wdata_i  (wb_data),
    .raddr1_i (rs1_addr),
    .raddr2_i (rs2_addr),
    .rdata1_o (rs1_data),
    .rdata2_o (rs2_data)
  );

  // --------------------------------------------------------------------------
  // Generador de inmediatos
  // --------------------------------------------------------------------------
  imm_gen u_imm (
    .instr_i   (instr_i[31:7]),
    .imm_src_i (imm_src_i),
    .imm_o     (imm_ext)
  );

  // --------------------------------------------------------------------------
  // Operandos y ALU
  // --------------------------------------------------------------------------
  mux_2_1 #(.WIDTH(WIDTH)) u_alu_b_mux (
    .d0_i  (rs2_data),
    .d1_i  (imm_ext),
    .sel_i (alu_src_b_i),
    .y_o   (alu_b)
  );

  alu #(.WIDTH(WIDTH)) u_alu (
    .a_i        (rs1_data),
    .b_i        (alu_b),
    .alu_ctrl_i (alu_ctrl_i),
    .result_o   (alu_result),
    .zero_o     (alu_zero_o)
  );

  // --------------------------------------------------------------------------
  // Comparación de branches
  // --------------------------------------------------------------------------
  branch_unit #(.WIDTH(WIDTH)) u_branch (
    .rs1_i    (rs1_data),
    .rs2_i    (rs2_data),
    .funct3_i (funct3),
    .cond_o   (branch_cond)
  );

  assign branch_taken_o = branch_i & branch_cond;

  // --------------------------------------------------------------------------
  // Write-back: qué se escribe en rd
  // --------------------------------------------------------------------------
  mux_4_1 #(.WIDTH(WIDTH)) u_wb_mux (
    .d0_i  (alu_result),    // RES_ALU
    .d1_i  (data_rdata_i),  // RES_MEM
    .d2_i  (pc_plus4),      // RES_PC4
    .d3_i  (pc_target),     // RES_PC_IMM
    .sel_i (result_src_i),
    .y_o   (wb_data)
  );

  // --------------------------------------------------------------------------
  // Buses externos
  // --------------------------------------------------------------------------
  assign prog_addr_o  = pc;
  assign data_addr_o  = alu_result;
  assign data_wdata_o = rs2_data;
  assign data_we_o    = mem_write_i;

endmodule
