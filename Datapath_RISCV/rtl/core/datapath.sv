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