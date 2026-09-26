
`timescale 1ns/1ps
module tb_reg_file;

  localparam int N_RAND = 20000;

  logic        clk = 0, rst = 1, we = 0;
  logic [4:0]  wa = 0, ra1 = 0, ra2 = 0;
  logic [31:0] wd = 0, rd1, rd2;
  logic [31:0] model [32];
  int errors = 0, checks = 0;

  always #5 clk = ~clk;

  reg_file dut (.clk_i(clk), .rst_i(rst), .we_i(we), .waddr_i(wa), .wdata_i(wd),
                .raddr1_i(ra1), .raddr2_i(ra2), .rdata1_o(rd1), .rdata2_o(rd2));

  task automatic expect_read(input logic [4:0] r1, r2, input string tag);
    ra1 = r1; ra2 = r2; #1;
    checks += 2;
    if (rd1 !== model[r1]) begin errors++; if (errors <= 20)
      $display("ERROR [%s] rd1 x%0d = %h (esperado %h)", tag, r1, rd1, model[r1]); end
    if (rd2 !== model[r2]) begin errors++; if (errors <= 20)
      $display("ERROR [%s] rd2 x%0d = %h (esperado %h)", tag, r2, rd2, model[r2]); end
  endtask

  // Escritura: se aplican las entradas en negedge y se captura en posedge
  task automatic write_reg(input logic [4:0] a, input logic [31:0] d, input logic en);
    @(negedge clk); we = en; wa = a; wd = d;
    @(posedge clk); #1;
    if (en && a != 0) model[a] = d;
    we = 0;
  endtask

  task automatic do_reset();
    @(negedge clk); rst = 1; @(posedge clk); #1; rst = 0;
    foreach (model[i]) model[i] = '0;
  endtask

  initial begin
    foreach (model[i]) model[i] = '0;
    // Registros con basura antes del reset para comprobar que reset limpia
    repeat (2) @(posedge clk);
    do_reset();

    //  todo en 0 tras reset
    for (int i = 0; i < 32; i++) expect_read(i[4:0], 5'(31 - i), "reset");

    //  escribir patrón distinto en cada registro y leer por ambos puertos
    for (int i = 0; i < 32; i++) write_reg(i[4:0], 32'hC0DE_0000 | i, 1'b1);
    for (int i = 0; i < 32; i++) expect_read(i[4:0], 5'(31 - i), "patron");

    //  x0 siempre en cero
    write_reg(5'd0, 32'hFFFF_FFFF, 1'b1);
    expect_read(5'd0, 5'd0, "x0");

    //  we = 0 no escribe
    write_reg(5'd7, 32'h1234_5678, 1'b0);
    expect_read(5'd7, 5'd7, "we0");

    //  lectura durante escritura: valor viejo antes del flanco, nuevo después
    @(negedge clk); we = 1; wa = 5'd9; wd = 32'hDEAD_BEEF; ra1 = 5'd9; ra2 = 5'd9; #1;
    checks++; if (rd1 !== model[9]) begin errors++; $display("ERROR lectura antes del flanco = %h", rd1); end
    @(posedge clk); #1; model[9] = 32'hDEAD_BEEF; we = 0;
    expect_read(5'd9, 5'd9, "rw");

    //  aleatorio: en cada ciclo escritura aleatoria + dos lecturas aleatorias
    for (int n = 0; n < N_RAND; n++) begin
      @(negedge clk);
      we = $urandom_range(1, 0); wa = $urandom; wd = $urandom;
      ra1 = $urandom; ra2 = $urandom; #1;
      checks += 2;   // lecturas combinacionales antes del flanco
      if (rd1 !== model[ra1] || rd2 !== model[ra2]) begin
        errors++; if (errors <= 20)
          $display("ERROR [random] x%0d=%h x%0d=%h (esperado %h %h)", ra1, rd1, ra2, rd2, model[ra1], model[ra2]);
      end
      @(posedge clk); #1;
      if (we && wa != 0) model[wa] = wd;
    end
    we = 0;

    //  reset a mitad de operación
    do_reset();
    for (int i = 0; i < 32; i++) expect_read(i[4:0], i[4:0], "reset2");

    if (errors == 0) $display("tb_reg_file: %0d chequeos, 0 errores -> TEST PASSED", checks);
    else             $fatal(1, "tb_reg_file: %0d errores en %0d chequeos -> TEST FAILED", errors, checks);
    $finish;
  end
endmodule
