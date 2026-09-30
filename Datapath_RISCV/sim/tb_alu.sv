// ============================================================================
`timescale 1ns/1ps
module tb_alu;
  import riscv_pkg::*;

  localparam int N_RAND = 5000;

  logic [31:0] a, b, y;
  logic [3:0]  ctrl;
  logic        zero;
  int          errors = 0, checks = 0;

  alu dut (.a_i(a), .b_i(b), .alu_ctrl_i(ctrl), .result_o(y), .zero_o(zero));

  // Modelo de referencia escrito de forma distinta al RTL (aritmética 64 bits)
  function automatic logic [31:0] ref_alu(input logic [31:0] ra, rb, input logic [3:0] op);
    longint sa, sb;           // con signo en 64 bits
    longint unsigned ua, ub;  // sin signo en 64 bits
    logic [63:0] ext;
    int sh;
    sa = longint'($signed(ra)); sb = longint'($signed(rb));
    ua = {32'b0, ra};           ub = {32'b0, rb};
    sh = rb[4:0];
    case (op)
      ALU_ADD:    ref_alu = 32'(ua + ub);
      ALU_SUB:    ref_alu = 32'(ua - ub);
      ALU_AND:    ref_alu = ra & rb;
      ALU_OR:     ref_alu = ra | rb;
      ALU_XOR:    ref_alu = ra ^ rb;
      ALU_SLL:    ref_alu = 32'(ua << sh);
      ALU_SRL:    ref_alu = 32'(ua >> sh);
      ALU_SRA:    begin ext = {{32{ra[31]}}, ra}; ref_alu = 32'(ext >> sh); end
      ALU_SLT:    ref_alu = (sa < sb) ? 32'd1 : 32'd0;
      ALU_SLTU:   ref_alu = (ua < ub) ? 32'd1 : 32'd0;
      ALU_PASS_B: ref_alu = rb;
      default:    ref_alu = 32'd0;
    endcase
  endfunction

  task automatic check(input logic [31:0] ta, tb_, input logic [3:0] op, input string tag);
    logic [31:0] exp;
    a = ta; b = tb_; ctrl = op;
    #1;
    exp = ref_alu(ta, tb_, op);
    checks++;
    if (y !== exp || zero !== (exp == 32'd0)) begin
      errors++;
      if (errors <= 20)
        $display("ERROR [%s] op=%b a=%h b=%h -> y=%h zero=%b (esperado y=%h zero=%b)",
                 tag, op, ta, tb_, y, zero, exp, (exp == 32'd0));
    end
  endtask

  // Listas como funciones (compatibles con Icarus, Vivado xsim y Verilator)
  function automatic logic [3:0] op_at(input int k);
    case (k)
      0: op_at = ALU_ADD;  1: op_at = ALU_SUB;  2: op_at = ALU_AND;  3: op_at = ALU_OR;
      4: op_at = ALU_XOR;  5: op_at = ALU_SLL;  6: op_at = ALU_SRL;  7: op_at = ALU_SRA;
      8: op_at = ALU_SLT;  9: op_at = ALU_SLTU; default: op_at = ALU_PASS_B;
    endcase
  endfunction
  localparam int N_OPS = 11;

  function automatic logic [31:0] corner(input int k);
    case (k)
      0: corner = 32'h0000_0000; 1: corner = 32'h0000_0001; 2: corner = 32'hFFFF_FFFF;
      3: corner = 32'h8000_0000; 4: corner = 32'h7FFF_FFFF; 5: corner = 32'h0000_001F;
      6: corner = 32'h0000_0020; default: corner = 32'hA5A5_5A5A;
    endcase
  endfunction
  localparam int N_CORNERS = 8;

  initial begin
    // --- Casos dirigidos concretos (valores calculados a mano) ---
    a = 32'd7;  b = 32'd5;  ctrl = ALU_SUB; #1;
    checks++; if (y !== 32'd2) begin errors++; $display("ERROR dirigido 7-5 = %0d", y); end
    a = 32'hFFFF_FFF0; b = 32'd4; ctrl = ALU_SRA; #1;   // -16 >>> 4 = -1
    checks++; if (y !== 32'hFFFF_FFFF) begin errors++; $display("ERROR dirigido sra = %h", y); end
    a = 32'hFFFF_FFF0; b = 32'd4; ctrl = ALU_SRL; #1;
    checks++; if (y !== 32'h0FFF_FFFF) begin errors++; $display("ERROR dirigido srl = %h", y); end
    a = 32'hFFFF_FFFF; b = 32'd1; ctrl = ALU_SLT; #1;   // -1 < 1 con signo
    checks++; if (y !== 32'd1) begin errors++; $display("ERROR dirigido slt = %h", y); end
    ctrl = ALU_SLTU; #1;                                // 0xFFFFFFFF < 1 sin signo? no
    checks++; if (y !== 32'd0) begin errors++; $display("ERROR dirigido sltu = %h", y); end
    a = 32'd1; b = 32'h0000_0421; ctrl = ALU_SLL; #1;   // shamt = b[4:0] = 1 (srai-like imm)
    checks++; if (y !== 32'd2) begin errors++; $display("ERROR dirigido sll shamt = %h", y); end

    // --- Esquinas: todas las combinaciones de corners x operaciones ---
    for (int k = 0; k < N_OPS; k++)
      for (int i = 0; i < N_CORNERS; i++)
        for (int j = 0; j < N_CORNERS; j++)
          check(corner(i), corner(j), op_at(k), "corner");

    // --- Aleatorio ---
    for (int k = 0; k < N_OPS; k++)
      for (int n = 0; n < N_RAND; n++)
        check($urandom, $urandom, op_at(k), "random");

    // --- Códigos no asignados -> 0 ---
    check($urandom, $urandom, 4'b1001, "unused");
    check($urandom, $urandom, 4'b1010, "unused");
    check($urandom, $urandom, 4'b1011, "unused");
    check($urandom, $urandom, 4'b1100, "unused");
    check($urandom, $urandom, 4'b1110, "unused");

    if (errors == 0) $display("tb_alu: %0d chequeos, 0 errores -> TEST PASSED", checks);
    else             $fatal(1, "tb_alu: %0d errores en %0d chequeos -> TEST FAILED", errors, checks);
    $finish;
  end
endmodule
