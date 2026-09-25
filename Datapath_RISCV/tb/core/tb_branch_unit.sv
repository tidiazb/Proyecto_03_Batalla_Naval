
`timescale 1ns/1ps
module tb_branch_unit;

  localparam int N_RAND = 5000;

  logic [31:0] a, b;
  logic [2:0]  f3;
  logic        cond;
  int errors = 0, checks = 0;

  branch_unit dut (.rs1_i(a), .rs2_i(b), .funct3_i(f3), .cond_o(cond));

  function automatic logic ref_cond(input logic [31:0] x, y, input logic [2:0] f);
    logic [32:0] du, ds;
    logic ltu, lts;
    du  = {1'b0, x} - {1'b0, y};           // borrow = x < y sin signo
    ltu = du[32];
    ds  = {x[31], x} - {y[31], y};          // resta con signo en 33 bits
    lts = ds[32];
    case (f)
      3'b000:  ref_cond = (du[31:0] == 0);
      3'b001:  ref_cond = (du[31:0] != 0);
      3'b100:  ref_cond = lts;
      3'b101:  ref_cond = !lts;
      3'b110:  ref_cond = ltu;
      3'b111:  ref_cond = !ltu;
      default: ref_cond = 1'b0;
    endcase
  endfunction

  task automatic check(input logic [31:0] x, y, input logic [2:0] f);
    a = x; b = y; f3 = f; #1;
    checks++;
    if (cond !== ref_cond(x, y, f)) begin
      errors++;
      if (errors <= 20) $display("ERROR f3=%b a=%h b=%h -> %b (esperado %b)", f, x, y, cond, ref_cond(x, y, f));
    end
  endtask

  function automatic logic [31:0] corner(input int k);
    case (k)
      0: corner = 32'h0;         1: corner = 32'h1;         2: corner = 32'hFFFF_FFFF;
      3: corner = 32'h8000_0000; 4: corner = 32'h7FFF_FFFF; 5: corner = 32'h8000_0001;
      default: corner = 32'h1234_5678;
    endcase
  endfunction

  initial begin
    // Casos a mano: -1 vs 1
    a = 32'hFFFF_FFFF; b = 32'd1;
    f3 = 3'b100; #1; checks++; if (cond !== 1'b1) begin errors++; $display("ERROR blt -1<1"); end
    f3 = 3'b110; #1; checks++; if (cond !== 1'b0) begin errors++; $display("ERROR bltu 0xFFFFFFFF<1"); end
    f3 = 3'b101; #1; checks++; if (cond !== 1'b0) begin errors++; $display("ERROR bge -1>=1"); end
    f3 = 3'b111; #1; checks++; if (cond !== 1'b1) begin errors++; $display("ERROR bgeu"); end

    for (int f = 0; f < 8; f++) begin
      for (int i = 0; i < 7; i++) for (int j = 0; j < 7; j++) check(corner(i), corner(j), 3'(f));
      for (int n = 0; n < N_RAND; n++) begin
        logic [31:0] x;
        x = $urandom;
        check(x, $urandom, 3'(f));
        check(x, x, 3'(f));   // iguales (importante para beq/bne/bge)
      end
    end

    if (errors == 0) $display("tb_branch_unit: %0d chequeos, 0 errores -> TEST PASSED", checks);
    else             $fatal(1, "tb_branch_unit: %0d errores en %0d chequeos -> TEST FAILED", errors, checks);
    $finish;
  end
endmodule
