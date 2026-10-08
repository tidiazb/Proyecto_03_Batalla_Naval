// ============================================================================
//
// Integra la unidad de control (Control_RISCV) con el datapath
// (Datapath_RISCV). Los puertos son exactamente los de la Figura 2 del
// enunciado:
//
//   ProgAddress_o[31:0] -> ROM de programa    ProgIn_i[31:0]  <- instrucción
//   DataAddress_o[31:0] -> RAM / periféricos  DataIn_i[31:0]  <- dato leído
//   DataOut_o[31:0]     -> dato a escribir    we_o            -> escritura
//
// Requisito de las memorias: ProgIn_i y DataIn_i deben responder en el MISMO
// ciclo que la dirección (lectura combinacional), porque el núcleo es uniciclo.
// Reset síncrono activo en alto; vector de reset 0x0000_0000.
// ============================================================================
module riscv_core (
  input  logic        en_i,   // nuevo puerto para slack error
  input  logic        clk_i,
  input  logic        rst_i,

  // Memoria de programa (ROM)
  output logic [31:0] ProgAddress_o,
  input  logic [31:0] ProgIn_i,

  // Memoria de datos y periféricos
  output logic [31:0] DataAddress_o,
  output logic [31:0] DataOut_o,
  input  logic [31:0] DataIn_i,
  output logic        we_o
);

  // --------------------------------------------------------------------------
  // Señales de control (codificación en riscv_pkg.sv)
  // --------------------------------------------------------------------------
  logic       reg_write, alu_src_b, mem_write, branch, jump, jalr;
  logic [3:0] alu_ctrl;
  logic [2:0] imm_src;
  logic [1:0] result_src;

  // Estado del datapath que no sale del núcleo (solo depuración)
  /* verilator lint_off UNUSEDSIGNAL */
  logic branch_taken, alu_zero;
  /* verilator lint_on UNUSEDSIGNAL */

  // --------------------------------------------------------------------------
  // Unidad de control
  // --------------------------------------------------------------------------
  control_unit u_ctrl (
    .opcode     (ProgIn_i[6:0]),
    .funct3     (ProgIn_i[14:12]),
    .funct7_5   (ProgIn_i[30]),
    .reg_write  (reg_write),
    .alu_src_b  (alu_src_b),
    .alu_ctrl   (alu_ctrl),
    .imm_src    (imm_src),
    .result_src (result_src),
    .mem_write  (mem_write),
    .branch     (branch),
    .jump       (jump),
    .jalr       (jalr)
  );

  // --------------------------------------------------------------------------
  // Datapath
  // --------------------------------------------------------------------------
  datapath u_dp (
    .en_i           (en_i),
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .prog_addr_o    (ProgAddress_o),
    .instr_i        (ProgIn_i),
    .data_addr_o    (DataAddress_o),
    .data_wdata_o   (DataOut_o),
    .data_we_o      (we_o),
    .data_rdata_i   (DataIn_i),
    .reg_write_i    (reg_write),
    .alu_src_b_i    (alu_src_b),
    .alu_ctrl_i     (alu_ctrl),
    .imm_src_i      (imm_src),
    .result_src_i   (result_src),
    .mem_write_i    (mem_write),
    .branch_i       (branch),
    .jump_i         (jump),
    .jalr_i         (jalr),
    .branch_taken_o (branch_taken),
    .alu_zero_o     (alu_zero)
  );

endmodule

