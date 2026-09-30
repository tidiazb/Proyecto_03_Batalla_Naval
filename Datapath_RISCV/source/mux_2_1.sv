// ============================================================================
// Multiplexor 2:1 parametrizable en número de bits (WIDTH)
// ============================================================================
module mux_2_1 #(
  parameter int WIDTH = 32
)(
  input  logic [WIDTH-1:0] d0_i,
  input  logic [WIDTH-1:0] d1_i,
  input  logic             sel_i,
  output logic [WIDTH-1:0] y_o
);

  assign y_o = sel_i ? d1_i : d0_i;

endmodule
