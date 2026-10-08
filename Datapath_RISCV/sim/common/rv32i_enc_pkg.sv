// ============================================================================
// rv32i_enc_pkg.sv  (SOLO SIMULACIÓN)
// Funciones para codificar instrucciones RV32I desde los testbenches, así los
// programas de prueba se escriben "en ensamblador" sin necesitar toolchain.
// Ej.: rom[0] = addi(1, 0, 5);  // addi x1, x0, 5
// ============================================================================
package rv32i_enc_pkg;

  // ------------------------- formatos base ----------------------------------
  function automatic logic [31:0] enc_r(input logic [6:0] f7, input int rs2, input int rs1,
                                        input logic [2:0] f3, input int rd, input logic [6:0] op);
    enc_r = {f7, 5'(rs2), 5'(rs1), f3, 5'(rd), op};
  endfunction

  function automatic logic [31:0] enc_i(input int imm, input int rs1, input logic [2:0] f3,
                                        input int rd, input logic [6:0] op);
    logic [31:0] im; im = imm;
    enc_i = {im[11:0], 5'(rs1), f3, 5'(rd), op};
  endfunction

  function automatic logic [31:0] enc_s(input int imm, input int rs2, input int rs1,
                                        input logic [2:0] f3, input logic [6:0] op);
    logic [31:0] im; im = imm;
    enc_s = {im[11:5], 5'(rs2), 5'(rs1), f3, im[4:0], op};
  endfunction

  function automatic logic [31:0] enc_b(input int imm, input int rs2, input int rs1,
                                        input logic [2:0] f3);
    logic [31:0] im; im = imm;
    enc_b = {im[12], im[10:5], 5'(rs2), 5'(rs1), f3, im[4:1], im[11], 7'b1100011};
  endfunction

  function automatic logic [31:0] enc_u(input int imm20, input int rd, input logic [6:0] op);
    logic [31:0] im; im = imm20;
    enc_u = {im[19:0], 5'(rd), op};
  endfunction

  function automatic logic [31:0] enc_j(input int imm, input int rd);
    logic [31:0] im; im = imm;
    enc_j = {im[20], im[10:1], im[11], im[19:12], 5'(rd), 7'b1101111};
  endfunction

  // ------------------------- tipo R -----------------------------------------
  localparam logic [6:0] OPR = 7'b0110011;
  function automatic logic [31:0] add_ (input int rd, rs1, rs2); add_  = enc_r(7'h00, rs2, rs1, 3'b000, rd, OPR); endfunction
  function automatic logic [31:0] sub_ (input int rd, rs1, rs2); sub_  = enc_r(7'h20, rs2, rs1, 3'b000, rd, OPR); endfunction
  function automatic logic [31:0] sll_ (input int rd, rs1, rs2); sll_  = enc_r(7'h00, rs2, rs1, 3'b001, rd, OPR); endfunction
  function automatic logic [31:0] slt_ (input int rd, rs1, rs2); slt_  = enc_r(7'h00, rs2, rs1, 3'b010, rd, OPR); endfunction
  function automatic logic [31:0] sltu_(input int rd, rs1, rs2); sltu_ = enc_r(7'h00, rs2, rs1, 3'b011, rd, OPR); endfunction
  function automatic logic [31:0] xor_ (input int rd, rs1, rs2); xor_  = enc_r(7'h00, rs2, rs1, 3'b100, rd, OPR); endfunction
  function automatic logic [31:0] srl_ (input int rd, rs1, rs2); srl_  = enc_r(7'h00, rs2, rs1, 3'b101, rd, OPR); endfunction
  function automatic logic [31:0] sra_ (input int rd, rs1, rs2); sra_  = enc_r(7'h20, rs2, rs1, 3'b101, rd, OPR); endfunction
  function automatic logic [31:0] or_  (input int rd, rs1, rs2); or_   = enc_r(7'h00, rs2, rs1, 3'b110, rd, OPR); endfunction
  function automatic logic [31:0] and_ (input int rd, rs1, rs2); and_  = enc_r(7'h00, rs2, rs1, 3'b111, rd, OPR); endfunction

  // ------------------------- tipo I aritmético ------------------------------
  localparam logic [6:0] OPI = 7'b0010011;
  function automatic logic [31:0] addi (input int rd, rs1, imm); addi  = enc_i(imm, rs1, 3'b000, rd, OPI); endfunction
  function automatic logic [31:0] slti (input int rd, rs1, imm); slti  = enc_i(imm, rs1, 3'b010, rd, OPI); endfunction
  function automatic logic [31:0] sltiu(input int rd, rs1, imm); sltiu = enc_i(imm, rs1, 3'b011, rd, OPI); endfunction
  function automatic logic [31:0] xori (input int rd, rs1, imm); xori  = enc_i(imm, rs1, 3'b100, rd, OPI); endfunction
  function automatic logic [31:0] ori  (input int rd, rs1, imm); ori   = enc_i(imm, rs1, 3'b110, rd, OPI); endfunction
  function automatic logic [31:0] andi (input int rd, rs1, imm); andi  = enc_i(imm, rs1, 3'b111, rd, OPI); endfunction
  function automatic logic [31:0] slli (input int rd, rs1, sh);  slli  = enc_i(sh & 31,          rs1, 3'b001, rd, OPI); endfunction
  function automatic logic [31:0] srli (input int rd, rs1, sh);  srli  = enc_i(sh & 31,          rs1, 3'b101, rd, OPI); endfunction
  function automatic logic [31:0] srai (input int rd, rs1, sh);  srai  = enc_i((sh & 31) | 1024, rs1, 3'b101, rd, OPI); endfunction

  // ------------------------- memoria ----------------------------------------
  function automatic logic [31:0] lw(input int rd, rs1, imm);  lw = enc_i(imm, rs1, 3'b010, rd, 7'b0000011); endfunction
  function automatic logic [31:0] sw(input int rs2, rs1, imm); sw = enc_s(imm, rs2, rs1, 3'b010, 7'b0100011); endfunction

  // ------------------------- branches (offset en bytes) ---------------------
  function automatic logic [31:0] beq (input int rs1, rs2, off); beq  = enc_b(off, rs2, rs1, 3'b000); endfunction
  function automatic logic [31:0] bne (input int rs1, rs2, off); bne  = enc_b(off, rs2, rs1, 3'b001); endfunction
  function automatic logic [31:0] blt (input int rs1, rs2, off); blt  = enc_b(off, rs2, rs1, 3'b100); endfunction
  function automatic logic [31:0] bge (input int rs1, rs2, off); bge  = enc_b(off, rs2, rs1, 3'b101); endfunction
  function automatic logic [31:0] bltu(input int rs1, rs2, off); bltu = enc_b(off, rs2, rs1, 3'b110); endfunction
  function automatic logic [31:0] bgeu(input int rs1, rs2, off); bgeu = enc_b(off, rs2, rs1, 3'b111); endfunction

  // ------------------------- saltos y tipo U --------------------------------
  function automatic logic [31:0] jal  (input int rd, off);      jal   = enc_j(off, rd); endfunction
  function automatic logic [31:0] jalr (input int rd, rs1, imm); jalr  = enc_i(imm, rs1, 3'b000, rd, 7'b1100111); endfunction
  function automatic logic [31:0] lui  (input int rd, imm20);    lui   = enc_u(imm20, rd, 7'b0110111); endfunction
  function automatic logic [31:0] auipc(input int rd, imm20);    auipc = enc_u(imm20, rd, 7'b0010111); endfunction

  localparam logic [31:0] NOP  = 32'h0000_0013;  // addi x0, x0, 0
  localparam logic [31:0] HALT = 32'h0000_006F;  // jal x0, 0  (lazo infinito)

endpackage
