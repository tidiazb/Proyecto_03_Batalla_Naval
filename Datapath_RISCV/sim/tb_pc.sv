
`timescale 1ns/1ps
module tb_pc;

  localparam int N_RAND = 5000;

  logic clk = 0, rst = 1;
  logic [31:0] pc, pc_next, pc4, pct, imm = 0, alu_res = 0;
  logic branch = 0, jump = 0, jalr = 0, cond = 0, redirect;
  logic [31:0] exp_pc;
  int errors = 0, checks = 0;

  always #5 clk = ~clk;

  pc_reg #(.RESET_VECTOR(32'h0000_0000)) u_pc (
    .clk_i(clk), .rst_i(rst), .pc_next_i(pc_next), .pc_o(pc));

  next_pc_logic u_npc (
    .pc_i(pc), .imm_i(imm), .alu_result_i(alu_res),
    .branch_i(branch), .jump_i(jump), .jalr_i(jalr), .branch_cond_i(cond),
    .pc_next_o(pc_next), .pc_plus4_o(pc4), .pc_target_o(pct), .pc_redirect_o(redirect));

  function automatic logic [31:0] ref_next(input logic [31:0] p, i, r, input logic br, j, jr, c);
    if (jr)             ref_next = r & 32'hFFFF_FFFE;
    else if (j | (br & c)) ref_next = p + i;
    else                ref_next = p + 32'd4;
  endfunction

  // Aplica entradas en negedge, verifica salidas combinacionales y el PC tras el flanco
  task automatic step(input logic [31:0] i, r, input logic br, j, jr, c, input string tag);
    logic [31:0] p0;
    @(negedge clk);
    imm = i; alu_res = r; branch = br; jump = j; jalr = jr; cond = c; #1;
    p0 = pc;
    exp_pc = ref_next(p0, i, r, br, j, jr, c);
    checks += 3;
    if (pc4 !== p0 + 32'd4) begin errors++; $display("ERROR [%s] pc_plus4=%h", tag, pc4); end
    if (pct !== p0 + i)     begin errors++; $display("ERROR [%s] pc_target=%h", tag, pct); end
    if (redirect !== (jr | j | (br & c))) begin errors++; $display("ERROR [%s] redirect", tag); end
    @(posedge clk); #1;
    checks++;
    if (pc !== exp_pc) begin
      errors++;
      if (errors <= 20) $display("ERROR [%s] PC=%h (esperado %h) desde %h", tag, pc, exp_pc, p0);
    end
  endtask

  initial begin
    // 1 reset
    @(posedge clk); #1;
    checks++; if (pc !== 32'h0) begin errors++; $display("ERROR reset PC=%h", pc); end
    @(negedge clk); rst = 0;

    // 2 secuencial: +4 por ciclo durante 8 ciclos
    begin
      logic [31:0] start;
      step(0, 0, 0, 0, 0, 0, "seq");  // sincroniza con el reloj
      start = pc;
      for (int k = 0; k < 8; k++) step(0, 0, 0, 0, 0, 0, "seq");
      checks++; if (pc !== start + 32'd32) begin errors++; $display("ERROR secuencia PC=%h desde %h", pc, start); end
    end

    // 3 branch tomado (+16), no tomado, tomado hacia atrás (-8)
    step(32'd16,        0, 1, 0, 0, 1, "br tomado +");
    step(32'd16,        0, 1, 0, 0, 0, "br no tomado");
    step(32'hFFFF_FFF8, 0, 1, 0, 0, 1, "br tomado -");
    step(32'd64,        0, 0, 0, 0, 1, "cond sin branch");   // cond=1 pero branch=0 -> +4

    // 4 jal
    step(32'd256, 0, 0, 1, 0, 0, "jal");
    // 5 jalr: destino impar -> bit 0 limpio; prioridad sobre jump
    step(32'd8, 32'h0000_0101, 0, 0, 1, 0, "jalr impar");
    step(32'd8, 32'h0000_0200, 1, 1, 1, 1, "jalr prioridad");

    // 7 aleatorio (con reset esporádico)
    for (int n = 0; n < N_RAND; n++) begin
      logic [31:0] ri;
      ri = {{19{1'b0}}, 13'($urandom)} & ~32'h1;
      if ($urandom_range(1, 0)) ri = -ri;
      step(ri, $urandom, 1'($urandom), 1'($urandom_range(3, 0) == 0),
           1'($urandom_range(7, 0) == 0), 1'($urandom), "random");
    end

    // reset en cualquier momento regresa a 0
    @(negedge clk); rst = 1; @(posedge clk); #1;
    checks++; if (pc !== 32'h0) begin errors++; $display("ERROR reset final PC=%h", pc); end

    if (errors == 0) $display("tb_pc: %0d chequeos, 0 errores -> TEST PASSED", checks);
    else             $fatal(1, "tb_pc: %0d errores en %0d chequeos -> TEST FAILED", errors, checks);
    $finish;
  end
endmodule
