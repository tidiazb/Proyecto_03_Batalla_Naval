
// Multiplexor 4:1 parametrizable en digitos binarios
module mux_4_1 #(
  parameter int WIDTH = 32
)(
  input  logic [WIDTH-1:0] d0_i,
  input  logic [WIDTH-1:0] d1_i,
  input  logic [WIDTH-1:0] d2_i,
  input  logic [WIDTH-1:0] d3_i,
  input  logic [1:0]       sel_i,
  output logic [WIDTH-1:0] y_o
);

  always_comb begin
    case (sel_i)
      2'd0:    y_o = d0_i;
      2'd1:    y_o = d1_i;
      2'd2:    y_o = d2_i;
      default: y_o = d3_i;
    endcase
  end

endmodule
