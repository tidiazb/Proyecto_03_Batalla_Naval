//Sumado parametrizable, será usado tambien para el diseño de PC+4 y PC+imm
module adder #(
  parameter int WIDTH = 32
)(
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  output logic [WIDTH-1:0] y_o
);

  assign y_o = a_i + b_i;

endmodule
