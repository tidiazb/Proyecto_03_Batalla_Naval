// ============================================================================
// Calcula el siguiente PC y las direcciones auxiliares.
//
//   pc_plus4   = PC + 4                 (actualización normal / retorno jal)
//   pc_target  = PC + imm               (destino de branch y jal; auipc)
//   jalr_tgt   = (rs1 + imm) & ~1       (la suma la hace la ALU)
//
// Selección (prioridad):
//   jalr_i                    -> jalr_tgt
//   jump_i | (branch_i&cond)  -> pc_target
//   caso contrario            -> pc_plus4
//
// Las señales branch_i / jump_i / jalr_i vienen de la unidad de control;
// branch_cond_i viene de branch_unit.
// ============================================================================
module next_pc_logic #(
  parameter int WIDTH = 32
)(
  input  logic [WIDTH-1:0] pc_i,
  input  logic [WIDTH-1:0] imm_i,
  /* verilator lint_off UNUSEDSIGNAL */   // bit 0 se descarta (jalr)
  input  logic [WIDTH-1:0] alu_result_i,  // rs1 + imm (solo se usa en jalr)
  /* verilator lint_on UNUSEDSIGNAL */
  input  logic             branch_i,      // la instrucción es un branch
  input  logic             jump_i,        // la instrucción es jal
  input  logic             jalr_i,        // la instrucción es jalr
  input  logic             branch_cond_i, // condición evaluada por branch_unit
  output logic [WIDTH-1:0] pc_next_o,
  output logic [WIDTH-1:0] pc_plus4_o,
  output logic [WIDTH-1:0] pc_target_o,
  output logic             pc_redirect_o  // 1 = el flujo NO sigue en PC+4
);

  localparam logic [WIDTH-1:0] FOUR = WIDTH'(4);

  logic [WIDTH-1:0] jalr_tgt;
  logic [1:0]       pc_sel;     // 0: PC+4, 1: PC+imm, 2: jalr
  logic             take_target;

  adder #(.WIDTH(WIDTH)) u_add_pc4 (
    .a_i (pc_i),
    .b_i (FOUR),
    .y_o (pc_plus4_o)
  );

  adder #(.WIDTH(WIDTH)) u_add_target (
    .a_i (pc_i),
    .b_i (imm_i),
    .y_o (pc_target_o)
  );

  // El estándar exige limpiar el bit 0 en jalr
  assign jalr_tgt    = {alu_result_i[WIDTH-1:1], 1'b0};
  assign take_target = jump_i | (branch_i & branch_cond_i);

  always_comb begin
    if (jalr_i)           pc_sel = 2'd2;
    else if (take_target) pc_sel = 2'd1;
    else                  pc_sel = 2'd0;
  end

  assign pc_redirect_o = jalr_i | take_target;

  mux_4_1 #(.WIDTH(WIDTH)) u_pc_mux (
    .d0_i  (pc_plus4_o),
    .d1_i  (pc_target_o),
    .d2_i  (jalr_tgt),
    .d3_i  (pc_plus4_o),   // no usado
    .sel_i (pc_sel),
    .y_o   (pc_next_o)
  );

endmodule
