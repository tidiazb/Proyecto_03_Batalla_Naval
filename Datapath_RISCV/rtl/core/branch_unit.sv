// ============================================================================
// Evalúa la condición de salto condicional comparando rs1 y rs2 según funct3.
// Es combinacional y no depende de la ALU (la ALU queda libre).
//
//   funct3 | instr | condición
//   -------+-------+----------------------------
//    000   | beq   | rs1 == rs2
//    001   | bne   | rs1 != rs2
//    100   | blt   | rs1 <  rs2  (con signo)
//    101   | bge   | rs1 >= rs2  (con signo)
//    110   | bltu  | rs1 <  rs2  (sin signo)
//    111   | bgeu  | rs1 >= rs2  (sin signo)
//    010/011 no existen en RV32I -> cond = 0
// ============================================================================
module branch_unit #(
  parameter int WIDTH = 32
)(
  input  logic [WIDTH-1:0] rs1_i,
  input  logic [WIDTH-1:0] rs2_i,
  input  logic [2:0]       funct3_i,
  output logic             cond_o     // 1 = la condición del branch se cumple
);

  logic eq, lt_s, lt_u;

  assign eq   = (rs1_i == rs2_i);
  assign lt_s = ($signed(rs1_i) < $signed(rs2_i));
  assign lt_u = (rs1_i < rs2_i);

  always_comb begin
    case (funct3_i)
      3'b000:  cond_o =  eq;    // beq
      3'b001:  cond_o = ~eq;    // bne
      3'b100:  cond_o =  lt_s;  // blt
      3'b101:  cond_o = ~lt_s;  // bge
      3'b110:  cond_o =  lt_u;  // bltu
      3'b111:  cond_o = ~lt_u;  // bgeu
      default: cond_o = 1'b0;   // 010, 011: no válidos
    endcase
  end

endmodule
