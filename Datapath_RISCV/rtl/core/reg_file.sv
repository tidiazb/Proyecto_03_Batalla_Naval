// ============================================================================
// reg_file.sv - Banco de 32 registros x 32 bits (x0..x31)
//   * 2 puertos de lectura combinacionales (necesario en uniciclo)
//   * 1 puerto de escritura síncrono (flanco positivo)
//   * x0 SIEMPRE lee 0: se fuerza en la lectura y nunca se escribe
//   * reset síncrono activo en alto: todos los registros a 0
// Nota: una escritura y una lectura del mismo registro en el mismo ciclo
// devuelven el valor VIEJO (el nuevo aparece después del flanco), que es
// exactamente lo que requiere un procesador uniciclo.
// ============================================================================
module reg_file #(
  parameter int WIDTH  = 32,
  parameter int ADDR_W = 5
)(
  input  logic              clk_i,
  input  logic              rst_i,
  // escritura
  input  logic              we_i,       // RegWrite (de control)
  input  logic [ADDR_W-1:0] waddr_i,    // rd  = instr[11:7]
  input  logic [WIDTH-1:0]  wdata_i,    // resultado (mux de write-back)
  // lectura
  input  logic [ADDR_W-1:0] raddr1_i,   // rs1 = instr[19:15]
  input  logic [ADDR_W-1:0] raddr2_i,   // rs2 = instr[24:20]
  output logic [WIDTH-1:0]  rdata1_o,
  output logic [WIDTH-1:0]  rdata2_o
);

  localparam int NREGS = 1 << ADDR_W;

  logic [WIDTH-1:0] regs [NREGS];

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      for (int i = 0; i < NREGS; i++) regs[i] <= '0;
    end else if (we_i && (waddr_i != '0)) begin
      regs[waddr_i] <= wdata_i;
    end
  end

  // x0 = 0 garantizado por construcción en la lectura
  assign rdata1_o = (raddr1_i == '0) ? '0 : regs[raddr1_i];
  assign rdata2_o = (raddr2_i == '0) ? '0 : regs[raddr2_i];

endmodule
