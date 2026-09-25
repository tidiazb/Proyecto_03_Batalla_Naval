// ============================================================================
// Registro de 32 bits, reset SÍNCRONO activo en alto al vector de reset.
// En un procesador uniciclo el PC se actualiza en cada flanco (sin enable).
// ============================================================================
module pc_reg #(
  parameter int          WIDTH        = 32,
  parameter logic [31:0] RESET_VECTOR = 32'h0000_0000
)(
  input  logic             clk_i,
  input  logic             rst_i,      // síncrono, activo en alto
  input  logic [WIDTH-1:0] pc_next_i,  // siguiente PC (de next_pc_logic)
  output logic [WIDTH-1:0] pc_o        // PC actual -> ProgAddress_o
);

  always_ff @(posedge clk_i) begin
    if (rst_i) pc_o <= RESET_VECTOR[WIDTH-1:0];
    else       pc_o <= pc_next_i;
  end

endmodule
