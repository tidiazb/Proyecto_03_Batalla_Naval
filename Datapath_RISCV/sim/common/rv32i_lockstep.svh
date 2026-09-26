// ============================================================================
// rv32i_lockstep.svh  (SOLO SIMULACIÓN)
// Cuerpo común de los testbenches en lockstep: memorias ROM/RAM, modelo de
// referencia del conjunto de instrucciones (ISS), programa dirigido,
// programas aleatorios, cobertura y veredicto.
//
// Lo incluyen tb_datapath.sv (datapath + ref_control) y tb_riscv_core.sv
// (control_unit real + datapath). Antes del `include, el testbench debe:
//   - declarar clk, rst y las señales prog_addr, instr, data_addr,
//     data_wdata, data_we, data_rdata, ctl_branch, branch_taken
//   - definir `DP      = ruta jerárquica a la instancia del datapath
//   - definir `TB_NAME = nombre del testbench (string)
// ============================================================================

  localparam int N_RAND_PROGS = 30;
  localparam int N_RAND_INSTR = 400;
  localparam int ROM_WORDS    = 2048;          // 0x0000_0000 - 0x0000_1FFF
  localparam int RAM_WORDS    = 1024;          // 0x0000_2000 - 0x0000_2FFF
  localparam logic [31:0] RAM_BASE = 32'h0000_2000;


  logic [31:0] rom [ROM_WORDS];
  logic [31:0] ram [RAM_WORDS];

  function automatic logic in_ram(input logic [31:0] addr);
    in_ram = (addr >= RAM_BASE) && (addr < RAM_BASE + 4 * RAM_WORDS);
  endfunction

  function automatic logic [31:0] rom_read(input logic [31:0] addr);
    if (addr < 4 * ROM_WORDS) rom_read = rom[addr[12:2]];
    else                      rom_read = HALT;
  endfunction


  assign instr      = rom_read(prog_addr);
  assign data_rdata = in_ram(data_addr) ? ram[data_addr[11:2]] : 32'h0;

  always @(posedge clk)
    if (data_we && in_ram(data_addr)) ram[data_addr[11:2]] <= data_wdata;


  // --------------------------------------------------------------------------
  // ISS: modelo de referencia
  // --------------------------------------------------------------------------
  logic [31:0] iss_x   [32];
  logic [31:0] iss_ram [RAM_WORDS];
  logic [31:0] iss_pc;
  logic        iss_we;
  logic [31:0] iss_waddr, iss_wdata;
  logic        iss_taken;

  // Cobertura
  localparam int NCOV = 40;
  int    cov [NCOV];
  string cov_name [NCOV];
  int    errors = 0, cycles_total = 0;

  // índices de cobertura
  localparam int C_ADD=0, C_SUB=1, C_SLL=2, C_SLT=3, C_SLTU=4, C_XOR=5, C_SRL=6, C_SRA=7,
                 C_OR=8, C_AND=9, C_ADDI=10, C_SLTI=11, C_SLTIU=12, C_XORI=13, C_ORI=14,
                 C_ANDI=15, C_SLLI=16, C_SRLI=17, C_SRAI=18, C_LW=19, C_SW=20,
                 C_BEQ_T=21, C_BEQ_N=22, C_BNE_T=23, C_BNE_N=24, C_BLT_T=25, C_BLT_N=26,
                 C_BGE_T=27, C_BGE_N=28, C_BLTU_T=29, C_BLTU_N=30, C_BGEU_T=31, C_BGEU_N=32,
                 C_JAL=33, C_JALR=34, C_LUI=35, C_AUIPC=36, C_X0W=37;

  task automatic iss_step();
    logic [31:0] ins, a, b, res, imm_i, imm_s, imm_b, imm_j, imm_u, next, ea;
    logic [6:0]  op;
    logic [2:0]  f3;
    logic        f7b5, wr;
    int          rd, rs1, rs2, sh;

    ins  = rom_read(iss_pc);
    op   = ins[6:0];  f3 = ins[14:12]; f7b5 = ins[30];
    rd   = ins[11:7]; rs1 = ins[19:15]; rs2 = ins[24:20];
    a    = iss_x[rs1];
    b    = iss_x[rs2];
    imm_i = {{20{ins[31]}}, ins[31:20]};
    imm_s = {{20{ins[31]}}, ins[31:25], ins[11:7]};
    imm_b = {{20{ins[31]}}, ins[7], ins[30:25], ins[11:8], 1'b0};
    imm_j = {{12{ins[31]}}, ins[19:12], ins[20], ins[30:21], 1'b0};
    imm_u = {ins[31:12], 12'h000};

    next = iss_pc + 32'd4; wr = 1'b0; res = 32'd0;
    iss_we = 1'b0; iss_waddr = 32'd0; iss_wdata = 32'd0; iss_taken = 1'b0;

    case (op)
      7'b0110011: begin // tipo R
        wr = 1'b1; sh = b[4:0];
        case (f3)
          3'b000: if (f7b5) begin res = a - b; cov[C_SUB]++; end
                  else      begin res = a + b; cov[C_ADD]++; end
          3'b001: begin res = a << sh; cov[C_SLL]++; end
          3'b010: begin res = ($signed(a) < $signed(b)) ? 1 : 0; cov[C_SLT]++; end
          3'b011: begin res = (a < b) ? 1 : 0; cov[C_SLTU]++; end
          3'b100: begin res = a ^ b; cov[C_XOR]++; end
          3'b101: if (f7b5) begin res = $signed(a) >>> sh; cov[C_SRA]++; end
                  else      begin res = a >> sh; cov[C_SRL]++; end
          3'b110: begin res = a | b; cov[C_OR]++; end
          3'b111: begin res = a & b; cov[C_AND]++; end
        endcase
      end
      7'b0010011: begin // tipo I aritmético
        wr = 1'b1; sh = imm_i[4:0];
        case (f3)
          3'b000: begin res = a + imm_i; cov[C_ADDI]++; end
          3'b001: begin res = a << sh; cov[C_SLLI]++; end
          3'b010: begin res = ($signed(a) < $signed(imm_i)) ? 1 : 0; cov[C_SLTI]++; end
          3'b011: begin res = (a < imm_i) ? 1 : 0; cov[C_SLTIU]++; end
          3'b100: begin res = a ^ imm_i; cov[C_XORI]++; end
          3'b101: if (f7b5) begin res = $signed(a) >>> sh; cov[C_SRAI]++; end
                  else      begin res = a >> sh; cov[C_SRLI]++; end
          3'b110: begin res = a | imm_i; cov[C_ORI]++; end
          3'b111: begin res = a & imm_i; cov[C_ANDI]++; end
        endcase
      end
      7'b0000011: begin // lw
        wr = 1'b1; ea = a + imm_i;
        res = in_ram(ea) ? iss_ram[ea[11:2]] : 32'h0;
        cov[C_LW]++;
      end
      7'b0100011: begin // sw
        iss_we = 1'b1; iss_waddr = a + imm_s; iss_wdata = b;
        cov[C_SW]++;
      end
      7'b1100011: begin // branches
        case (f3)
          3'b000: begin iss_taken = (a == b);                   cov[iss_taken ? C_BEQ_T  : C_BEQ_N ]++; end
          3'b001: begin iss_taken = (a != b);                   cov[iss_taken ? C_BNE_T  : C_BNE_N ]++; end
          3'b100: begin iss_taken = ($signed(a) <  $signed(b)); cov[iss_taken ? C_BLT_T  : C_BLT_N ]++; end
          3'b101: begin iss_taken = ($signed(a) >= $signed(b)); cov[iss_taken ? C_BGE_T  : C_BGE_N ]++; end
          3'b110: begin iss_taken = (a <  b);                   cov[iss_taken ? C_BLTU_T : C_BLTU_N]++; end
          3'b111: begin iss_taken = (a >= b);                   cov[iss_taken ? C_BGEU_T : C_BGEU_N]++; end
          default: iss_taken = 1'b0;
        endcase
        if (iss_taken) next = iss_pc + imm_b;
      end
      7'b1101111: begin // jal
        wr = 1'b1; res = iss_pc + 32'd4; next = iss_pc + imm_j; cov[C_JAL]++;
      end
      7'b1100111: begin // jalr
        wr = 1'b1; res = iss_pc + 32'd4; next = (a + imm_i) & ~32'd1; cov[C_JALR]++;
      end
      7'b0110111: begin wr = 1'b1; res = imm_u;          cov[C_LUI]++;   end
      7'b0010111: begin wr = 1'b1; res = iss_pc + imm_u; cov[C_AUIPC]++; end
      default: ;
    endcase

    if (wr && rd == 0 && op != 7'b1101111) cov[C_X0W]++;
    if (wr && rd != 0) iss_x[rd] = res;
    if (iss_we && in_ram(iss_waddr)) iss_ram[iss_waddr[11:2]] = iss_wdata;
    iss_pc = next;
  endtask

  // --------------------------------------------------------------------------
  // Ejecución en lockstep de un programa ya cargado en rom[]
  // --------------------------------------------------------------------------
  task automatic run_program(input string name, input int max_cycles);
    int cyc, local_err;
    bit halted;
    cyc = 0; local_err = 0; halted = 0;

    // Reset síncrono de 2 ciclos; la RAM se limpia con el PC ya en 0
    @(negedge clk); rst = 1;
    @(posedge clk); @(posedge clk);
    @(negedge clk);
    for (int i = 0; i < RAM_WORDS; i++) begin ram[i] = 32'h0; iss_ram[i] = 32'h0; end
    for (int i = 0; i < 32; i++) iss_x[i] = 32'h0;
    iss_pc = RESET_VECTOR;
    rst = 0;

    while (!halted && cyc < max_cycles) begin
      // 1) estado arquitectónico: PC y registros
      if (prog_addr !== iss_pc) begin
        local_err++;
        if (local_err <= 10) $display("  [%s] ciclo %0d: PC DUT=%h ISS=%h", name, cyc, prog_addr, iss_pc);
      end
      for (int r = 0; r < 32; r++)
        if (((r == 0) ? 32'h0 : `DP.u_rf.regs[r]) !== iss_x[r]) begin
            local_err++;
            if (local_err <= 10) $display("  [%s] ciclo %0d (PC=%h): x%0d DUT=%h ISS=%h",
                                          name, cyc, iss_pc, r, `DP.u_rf.regs[r], iss_x[r]);
          end
      if (`DP.u_rf.regs[0] !== 32'h0) begin
        local_err++; $display("  [%s] x0 distinto de cero", name);
      end

      if (rom_read(iss_pc) == HALT) halted = 1;
      else begin
        // 2) el ISS ejecuta la instrucción actual y dice qué bus esperar
        iss_step();
        if (data_we !== iss_we ||
            (iss_we && (data_addr !== iss_waddr || data_wdata !== iss_wdata))) begin
          local_err++;
          if (local_err <= 10)
            $display("  [%s] ciclo %0d: bus datos DUT we=%b addr=%h data=%h | ISS we=%b addr=%h data=%h",
                     name, cyc, data_we, data_addr, data_wdata, iss_we, iss_waddr, iss_wdata);
        end
        if (ctl_branch && (branch_taken !== iss_taken)) begin
          local_err++;
          if (local_err <= 10) $display("  [%s] ciclo %0d: branch_taken DUT=%b ISS=%b", name, cyc, branch_taken, iss_taken);
        end
        @(negedge clk);
        cyc++;
      end
    end

    if (!halted) begin
      local_err++; $display("  [%s] TIMEOUT: no llegó a HALT en %0d ciclos", name, max_cycles);
    end
    for (int i = 0; i < RAM_WORDS; i++)
      if (ram[i] !== iss_ram[i]) begin
        local_err++;
        if (local_err <= 10) $display("  [%s] RAM[%h] DUT=%h ISS=%h", name, RAM_BASE + 4*i, ram[i], iss_ram[i]);
      end

    cycles_total += cyc;
    errors += local_err;
    if (local_err != 0) $display("  [%s] FALLÓ con %0d errores", name, local_err);
  endtask

  // --------------------------------------------------------------------------
  // Programa dirigido (ensamblador codificado con rv32i_enc_pkg)
  // --------------------------------------------------------------------------
  int pc_w;  // índice de palabra para ir "ensamblando"
  function automatic void emit(input logic [31:0] ins);
    rom[pc_w] = ins; pc_w++;
  endfunction

  task automatic load_directed_program();
    for (int i = 0; i < ROM_WORDS; i++) rom[i] = NOP;
    pc_w = 0;
    // ---- Aritmética / lógica tipo I y R ----
    emit(addi(1, 0, 5));          // x1 = 5
    emit(addi(2, 0, -3));         // x2 = -3
    emit(add_(3, 1, 2));          // x3 = 2
    emit(sub_(4, 1, 2));          // x4 = 8
    emit(and_(5, 1, 2));          // x5 = 5 & -3 = 5
    emit(or_ (6, 1, 2));          // x6 = -3
    emit(xor_(7, 1, 2));          // x7 = -8
    emit(sll_(8, 1, 1));          // x8 = 5 << 5 = 160
    emit(srl_(9, 2, 1));          // x9 = 0xFFFFFFFD >> 5 = 0x07FFFFFF
    emit(sra_(10, 2, 1));         // x10 = -3 >>> 5 = -1
    emit(slt_(11, 2, 1));         // x11 = (-3 < 5) = 1
    emit(sltu_(12, 2, 1));        // x12 = (0xFFFFFFFD < 5) = 0
    emit(slti(13, 2, -2));        // x13 = (-3 < -2) = 1
    emit(sltiu(14, 1, -1));       // x14 = (5 < 0xFFFFFFFF) = 1
    emit(andi(15, 2, 255));       // x15 = 0xFD
    emit(ori (16, 1, -2048));     // x16 = 0xFFFFF805
    emit(xori(17, 2, -1));        // x17 = ~(-3) = 2
    emit(slli(18, 1, 31));        // x18 = 0x80000000
    emit(srli(19, 18, 31));       // x19 = 1
    emit(srai(20, 18, 31));       // x20 = 0xFFFFFFFF
    emit(addi(0, 1, 123));        // x0 NO cambia
    // ---- lui / auipc ----
    emit(lui(21, 32'h00002));     // x21 = 0x2000 (base de RAM)
    emit(auipc(22, 0));           // x22 = PC de esta instrucción
    emit(lui(23, 32'h12345));
    emit(addi(23, 23, 32'h678));  // x23 = 0x12345678 (patrón 'li')
    // ---- memoria ----
    emit(sw(23, 21, 0));          // RAM[0x2000] = 0x12345678
    emit(sw(2, 21, 4));           // RAM[0x2004] = -3
    emit(addi(24, 21, 64));       // x24 = 0x2040
    emit(sw(4, 24, -4));          // RAM[0x203C] = 8  (offset negativo)
    emit(lw(25, 21, 0));          // x25 = 0x12345678
    emit(lw(26, 24, -60));        // x26 = RAM[0x2004] = -3
    emit(lw(27, 21, 60));         // x27 = RAM[0x203C] = 8
    emit(sw(25, 21, 12));         // store dependiente de un load previo
    // ---- branches: cada uno tomado y no tomado ----
    // Convención: si el branch se comporta mal, se ejecuta "addi x31,x31,1" (error)
    emit(addi(31, 0, 0));         // x31 = contador de errores del programa
    emit(beq (1, 1, 8));  emit(addi(31, 31, 1));      // tomado
    emit(beq (1, 2, 8));  emit(jal(0, 8));  emit(addi(31, 31, 1)); // no tomado -> salta el error
    emit(bne (1, 2, 8));  emit(addi(31, 31, 1));
    emit(bne (1, 1, 8));  emit(jal(0, 8));  emit(addi(31, 31, 1));
    emit(blt (2, 1, 8));  emit(addi(31, 31, 1));      // -3 < 5
    emit(blt (1, 2, 8));  emit(jal(0, 8));  emit(addi(31, 31, 1));
    emit(bge (1, 2, 8));  emit(addi(31, 31, 1));      // 5 >= -3
    emit(bge (1, 1, 8));  emit(addi(31, 31, 1));      // igualdad
    emit(bge (2, 1, 8));  emit(jal(0, 8));  emit(addi(31, 31, 1));
    emit(bltu(1, 2, 8));  emit(addi(31, 31, 1));      // 5 < 0xFFFFFFFD
    emit(bltu(2, 1, 8));  emit(jal(0, 8));  emit(addi(31, 31, 1));
    emit(bgeu(2, 1, 8));  emit(addi(31, 31, 1));
    emit(bgeu(1, 2, 8));  emit(jal(0, 8));  emit(addi(31, 31, 1));
    // ---- lazo hacia atrás: suma 1..10 ----
    emit(addi(28, 0, 0));         // acumulador
    emit(addi(29, 0, 10));        // contador
    emit(add_(28, 28, 29));       // loop:
    emit(addi(29, 29, -1));
    emit(bne (29, 0, -8));        //   vuelve a 'loop'
    emit(sw(28, 21, 8));          // RAM[0x2008] = 55
    // ---- llamada a subrutina con jal / ret (jalr x0, 0(ra)) ----
    emit(addi(30, 0, 0));
    emit(jal (1, 16));            // call sub  (ra = x1)
    emit(jal (1, 12));            // call sub otra vez
    emit(sw(30, 21, 16));         // RAM[0x2010] = 2
    emit(jal (0, 12));            // salta sobre la subrutina
    emit(addi(30, 30, 1));        // sub:  x30++
    emit(jalr(0, 1, 0));          //       ret
    // ---- jalr con destino impar: el bit 0 debe limpiarse ----
    emit(auipc(5, 0));            // x5 = PC
    emit(jalr(6, 5, 17));         // destino = PC+17 -> PC+16 (bit 0 limpio)
    emit(addi(31, 31, 1));        // (saltada)
    emit(addi(31, 31, 1));        // (saltada)
    emit(sw(6, 21, 20));          // PC+16: guarda dirección de retorno
    // ---- fin ----
    emit(sw(31, 21, 24));         // RAM[0x2018] = errores del programa (debe ser 0)
    emit(HALT);
  endtask

  // --------------------------------------------------------------------------
  // Programas aleatorios
  // --------------------------------------------------------------------------
  function automatic int rreg();  rreg = $urandom_range(30, 0); endfunction  // x31 reservado
  function automatic int rimm12(); rimm12 = int'($urandom_range(4095, 0)) - 2048; endfunction

  task automatic load_random_program(input int n);
    int kind, left;
    for (int i = 0; i < ROM_WORDS; i++) rom[i] = NOP;
    pc_w = 0;
    emit(lui(31, 32'h00002));                       // x31 = base de RAM
    // valores iniciales variados (incluye negativos y grandes)
    for (int r = 1; r < 31; r++) begin
      emit(lui(r, $urandom_range(20'hFFFFF, 0)));
      emit(addi(r, r, rimm12()));
    end
    for (int k = 0; k < n; k++) begin
      left = n - k;
      kind = $urandom_range(99, 0);
      if (kind < 30) begin            // tipo R
        case ($urandom_range(9, 0))
          0: emit(add_(rreg(), rreg(), rreg()));  1: emit(sub_(rreg(), rreg(), rreg()));
          2: emit(sll_(rreg(), rreg(), rreg()));  3: emit(slt_(rreg(), rreg(), rreg()));
          4: emit(sltu_(rreg(), rreg(), rreg())); 5: emit(xor_(rreg(), rreg(), rreg()));
          6: emit(srl_(rreg(), rreg(), rreg()));  7: emit(sra_(rreg(), rreg(), rreg()));
          8: emit(or_(rreg(), rreg(), rreg()));   default: emit(and_(rreg(), rreg(), rreg()));
        endcase
      end else if (kind < 55) begin   // tipo I
        case ($urandom_range(8, 0))
          0: emit(addi(rreg(), rreg(), rimm12()));  1: emit(slti(rreg(), rreg(), rimm12()));
          2: emit(sltiu(rreg(), rreg(), rimm12())); 3: emit(xori(rreg(), rreg(), rimm12()));
          4: emit(ori(rreg(), rreg(), rimm12()));   5: emit(andi(rreg(), rreg(), rimm12()));
          6: emit(slli(rreg(), rreg(), $urandom_range(31, 0)));
          7: emit(srli(rreg(), rreg(), $urandom_range(31, 0)));
          default: emit(srai(rreg(), rreg(), $urandom_range(31, 0)));
        endcase
      end else if (kind < 60) begin
        if ($urandom_range(1, 0)) emit(lui(rreg(), $urandom_range(20'hFFFFF, 0)));
        else                      emit(auipc(rreg(), $urandom_range(20'hFFFFF, 0)));
      end else if (kind < 70) begin   // stores alineados dentro de la RAM
        emit(sw(rreg(), 31, 4 * $urandom_range(511, 0)));
      end else if (kind < 80) begin   // loads
        emit(lw(rreg(), 31, 4 * $urandom_range(511, 0)));
      end else if (kind < 95 && left > 4) begin  // branch hacia adelante (salta 1..3)
        int off; off = 4 * $urandom_range(4, 2);
        case ($urandom_range(5, 0))
          0: emit(beq(rreg(), rreg(), off));  1: emit(bne(rreg(), rreg(), off));
          2: emit(blt(rreg(), rreg(), off));  3: emit(bge(rreg(), rreg(), off));
          4: emit(bltu(rreg(), rreg(), off)); default: emit(bgeu(rreg(), rreg(), off));
        endcase
      end else if (left > 4) begin    // jal hacia adelante con rd aleatorio
        emit(jal(rreg(), 4 * $urandom_range(3, 1)));
      end else begin
        emit(addi(rreg(), rreg(), rimm12()));
      end
    end
    // relleno de seguridad y fin
    for (int k = 0; k < 4; k++) emit(NOP);
    emit(HALT);
  endtask

  // --------------------------------------------------------------------------
  // Secuencia principal
  // --------------------------------------------------------------------------
  initial begin
    int e0, sign_err;
    for (int i = 0; i < NCOV; i++) cov[i] = 0;
    cov_name[C_ADD]="add"; cov_name[C_SUB]="sub"; cov_name[C_SLL]="sll"; cov_name[C_SLT]="slt";
    cov_name[C_SLTU]="sltu"; cov_name[C_XOR]="xor"; cov_name[C_SRL]="srl"; cov_name[C_SRA]="sra";
    cov_name[C_OR]="or"; cov_name[C_AND]="and"; cov_name[C_ADDI]="addi"; cov_name[C_SLTI]="slti";
    cov_name[C_SLTIU]="sltiu"; cov_name[C_XORI]="xori"; cov_name[C_ORI]="ori"; cov_name[C_ANDI]="andi";
    cov_name[C_SLLI]="slli"; cov_name[C_SRLI]="srli"; cov_name[C_SRAI]="srai"; cov_name[C_LW]="lw";
    cov_name[C_SW]="sw"; cov_name[C_BEQ_T]="beq tomado"; cov_name[C_BEQ_N]="beq no tomado";
    cov_name[C_BNE_T]="bne tomado"; cov_name[C_BNE_N]="bne no tomado"; cov_name[C_BLT_T]="blt tomado";
    cov_name[C_BLT_N]="blt no tomado"; cov_name[C_BGE_T]="bge tomado"; cov_name[C_BGE_N]="bge no tomado";
    cov_name[C_BLTU_T]="bltu tomado"; cov_name[C_BLTU_N]="bltu no tomado"; cov_name[C_BGEU_T]="bgeu tomado";
    cov_name[C_BGEU_N]="bgeu no tomado"; cov_name[C_JAL]="jal"; cov_name[C_JALR]="jalr";
    cov_name[C_LUI]="lui"; cov_name[C_AUIPC]="auipc"; cov_name[C_X0W]="escritura a x0";

    // ---------------- 1) Programa dirigido ----------------
    load_directed_program();
    e0 = errors;
    run_program("dirigido", 1000);

    // Firma calculada A MANO (independiente del ISS)
    sign_err = 0;
    if (`DP.u_rf.regs[3]  !== 32'd2)          sign_err++;
    if (`DP.u_rf.regs[4]  !== 32'd8)          sign_err++;
    if (`DP.u_rf.regs[9]  !== 32'h07FF_FFFF)  sign_err++;
    if (`DP.u_rf.regs[10] !== 32'hFFFF_FFFF)  sign_err++;
    if (`DP.u_rf.regs[11] !== 32'd1)          sign_err++;
    if (`DP.u_rf.regs[12] !== 32'd0)          sign_err++;
    if (`DP.u_rf.regs[16] !== 32'hFFFF_F805)  sign_err++;
    if (`DP.u_rf.regs[18] !== 32'h8000_0000)  sign_err++;
    if (`DP.u_rf.regs[20] !== 32'hFFFF_FFFF)  sign_err++;
    if (`DP.u_rf.regs[22] !== 32'd88)         sign_err++;  // auipc en la instrucción #22 -> 22*4
    if (`DP.u_rf.regs[23] !== 32'h1234_5678)  sign_err++;
    if (`DP.u_rf.regs[26] !== 32'hFFFF_FFFD)  sign_err++;
    if (ram[0]  !== 32'h1234_5678) sign_err++;   // 0x2000
    if (ram[2]  !== 32'd55)        sign_err++;   // 0x2008 suma 1..10
    if (ram[3]  !== 32'h1234_5678) sign_err++;   // 0x200C
    if (ram[4]  !== 32'd2)         sign_err++;   // 0x2010 dos llamadas a subrutina
    if (ram[6]  !== 32'd0)         sign_err++;   // 0x2018 errores internos del programa
    if (ram[15] !== 32'd8)         sign_err++;   // 0x203C offset negativo
    if (sign_err != 0) $display("  [dirigido] firma calculada a mano: %0d diferencias", sign_err);
    errors += sign_err;
    $display("Programa dirigido: %s", (errors == e0) ? "OK" : "FALLÓ");

    // ---------------- 2) Programas aleatorios ----------------
    e0 = errors;
    for (int p = 0; p < N_RAND_PROGS; p++) begin
      load_random_program(N_RAND_INSTR);
      run_program($sformatf("aleatorio_%0d", p), 5000);
    end
    $display("Programas aleatorios (%0d x %0d instr): %s", N_RAND_PROGS, N_RAND_INSTR,
             (errors == e0) ? "OK" : "FALLÓ");

    // ---------------- Cobertura ----------------
    $display("Cobertura de instrucciones ejecutadas:");
    for (int i = 0; i <= C_X0W; i++) begin
      $display("  %-16s %6d %s", cov_name[i], cov[i], (cov[i] == 0) ? "<-- SIN CUBRIR" : "");
      if (cov[i] == 0) errors++;
    end

    if (errors == 0) $display("%s: %0d ciclos verificados en lockstep, 0 errores -> TEST PASSED", `TB_NAME, cycles_total);
    else             $fatal(1, "%s: %0d errores -> TEST FAILED", `TB_NAME, errors);
    $finish;
  end
