// ============================================================================
// se escoge un inmediato válido aleatorio, se CODIFICA en una
// instrucción (con el resto de bits aleatorios) usando rv32i_enc_pkg y se
// verifica que imm_gen RECUPERE exactamente el mismo valor con signo.
// Así el modelo de referencia (codificar) es independiente del RTL (decodificar).
// ============================================================================
`timescale 1ns/1ps
module tb_imm_gen;
  import riscv_pkg::*;
  import rv32i_enc_pkg::*;

  localparam int N_RAND = 5000;

  logic [31:0] instr, imm;
  logic [2:0]  src;
  int errors = 0, checks = 0;

  imm_gen dut (.instr_i(instr[31:7]), .imm_src_i(src), .imm_o(imm));

  task automatic check(input logic [31:0] ins, input logic [2:0] s,
                       input logic [31:0] exp, input string tag);
    instr = ins; src = s; #1;
    checks++;
    if (imm !== exp) begin
      errors++;
      if (errors <= 20)
        $display("ERROR [%s] instr=%h -> imm=%h (esperado %h)", tag, ins, imm, exp);
    end
  endtask

  // Inmediato aleatorio con signo en el rango de N bits (múltiplo de 2^lsb)
  function automatic int rand_imm(input int nbits, input int lsb_zeros);
    int v;
    v = $urandom_range((1 << nbits) - 1, 0);          // N bits
    v = v - ((v >> (nbits - 1)) << nbits);            // extensión de signo
    rand_imm = (v >> lsb_zeros) << lsb_zeros;         // alineación
  endfunction

  initial begin
    int v;
    logic [31:0] base;

    // ---- Esquinas dirigidas ----
    check(addi(1, 2, -1),    IMM_I, 32'hFFFF_FFFF, "I -1");
    check(addi(1, 2, 2047),  IMM_I, 32'h0000_07FF, "I max");
    check(addi(1, 2, -2048), IMM_I, 32'hFFFF_F800, "I min");
    check(sw(5, 6, -4),      IMM_S, 32'hFFFF_FFFC, "S -4");
    check(sw(5, 6, 2047),    IMM_S, 32'h0000_07FF, "S max");
    check(beq(1, 2, -4096),  IMM_B, 32'hFFFF_F000, "B min");
    check(beq(1, 2, 4094),   IMM_B, 32'h0000_0FFE, "B max");
    check(beq(1, 2, -2),     IMM_B, 32'hFFFF_FFFE, "B -2");
    check(jal(1, -1048576),  IMM_J, 32'hFFF0_0000, "J min");
    check(jal(1, 1048574),   IMM_J, 32'h000F_FFFE, "J max");
    check(jal(0, -8),        IMM_J, 32'hFFFF_FFF8, "J -8");
    check(lui(3, 20'hFFFFF), IMM_U, 32'hFFFF_F000, "U all1");
    check(lui(3, 20'h00002), IMM_U, 32'h0000_2000, "U 0x2");
    // shift inmediato: srai trae funct7=0100000; la ALU usa solo [4:0]
    check(srai(1, 2, 7),     IMM_I, 32'h0000_0407, "I srai");

    // ---- Aleatorio: el resto de los bits de la instrucción también aleatorios ----
    for (int n = 0; n < N_RAND; n++) begin
      base = $urandom;
      v = rand_imm(12, 0);
      check(enc_i(v, base[19:15], base[14:12], base[11:7], base[6:0]), IMM_I, 32'(v), "I rnd");
      v = rand_imm(12, 0);
      check(enc_s(v, base[24:20], base[19:15], base[14:12], base[6:0]), IMM_S, 32'(v), "S rnd");
      v = rand_imm(13, 1);
      check(enc_b(v, base[24:20], base[19:15], base[14:12]),            IMM_B, 32'(v), "B rnd");
      v = rand_imm(21, 1);
      check(enc_j(v, base[11:7]),                                       IMM_J, 32'(v), "J rnd");
      v = $urandom_range(20'hFFFFF, 0);
      check(enc_u(v, base[11:7], base[6:0]),                            IMM_U, {v[19:0], 12'b0}, "U rnd");
      // códigos imm_src no usados -> 0
      check(base, 3'(5 + (n % 3)), 32'd0, "unused");
    end

    if (errors == 0) $display("tb_imm_gen: %0d chequeos, 0 errores -> TEST PASSED", checks);
    else             $fatal(1, "tb_imm_gen: %0d errores en %0d chequeos -> TEST FAILED", errors, checks);
    $finish;
  end
endmodule
