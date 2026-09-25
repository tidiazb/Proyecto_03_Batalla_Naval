`timescale 1ns / 1ps

module tb_main_decoder;

    // ============================================================
    // Señales de entrada
    // ============================================================
    logic [6:0] opcode;

    // ============================================================
    // Señales de salida
    // ============================================================
    logic       reg_write;
    logic       alu_src_b;
    logic [2:0] imm_src;
    logic [1:0] result_src;
    logic       mem_write;
    logic       branch;
    logic       jump;
    logic       jalr;

    // Contadores para el resumen final
    integer tests;
    integer errors;

    // ============================================================
    // Codificación de ImmSrc
    // ============================================================
    localparam logic [2:0]
        IMM_I = 3'b000,
        IMM_S = 3'b001,
        IMM_B = 3'b010,
        IMM_J = 3'b011,
        IMM_U = 3'b100;

    // ============================================================
    // Codificación de ResultSrc
    // ============================================================
    localparam logic [1:0]
        RES_ALU    = 2'b00,
        RES_MEM    = 2'b01,
        RES_PC4    = 2'b10,
        RES_PC_IMM = 2'b11;

    // ============================================================
    // Opcodes RV32I
    // ============================================================
    localparam logic [6:0]
        OP_RTYPE  = 7'b0110011,
        OP_ITYPE  = 7'b0010011,
        OP_LOAD   = 7'b0000011,
        OP_STORE  = 7'b0100011,
        OP_BRANCH = 7'b1100011,
        OP_JAL    = 7'b1101111,
        OP_JALR   = 7'b1100111,
        OP_LUI    = 7'b0110111,
        OP_AUIPC  = 7'b0010111;

    // ============================================================
    // DUT - Device Under Test
    // ============================================================
    main_decoder dut (
        .opcode     (opcode),
        .reg_write  (reg_write),
        .alu_src_b  (alu_src_b),
        .imm_src    (imm_src),
        .result_src (result_src),
        .mem_write  (mem_write),
        .branch     (branch),
        .jump       (jump),
        .jalr       (jalr)
    );

    // ============================================================
    // Tarea para comprobar automáticamente cada caso
    // ============================================================
    task automatic check_outputs(
        input string      test_name,
        input logic       exp_reg_write,
        input logic       exp_alu_src_b,
        input logic [2:0] exp_imm_src,
        input logic [1:0] exp_result_src,
        input logic       exp_mem_write,
        input logic       exp_branch,
        input logic       exp_jump,
        input logic       exp_jalr
    );

        begin
            tests = tests + 1;

            #1;

            if ((reg_write  === exp_reg_write)  &&
                (alu_src_b  === exp_alu_src_b)  &&
                (imm_src    === exp_imm_src)    &&
                (result_src === exp_result_src) &&
                (mem_write  === exp_mem_write)  &&
                (branch     === exp_branch)     &&
                (jump       === exp_jump)       &&
                (jalr       === exp_jalr)) begin

                $display("[PASS] %s", test_name);

            end
            else begin

                errors = errors + 1;

                $display("[FAIL] %s", test_name);

                $display("       Esperado:");
                $display(
                    "       RegWrite=%b ALUSrcB=%b ImmSrc=%b ResultSrc=%b MemWrite=%b Branch=%b Jump=%b Jalr=%b",
                    exp_reg_write,
                    exp_alu_src_b,
                    exp_imm_src,
                    exp_result_src,
                    exp_mem_write,
                    exp_branch,
                    exp_jump,
                    exp_jalr
                );

                $display("       Obtenido:");
                $display(
                    "       RegWrite=%b ALUSrcB=%b ImmSrc=%b ResultSrc=%b MemWrite=%b Branch=%b Jump=%b Jalr=%b",
                    reg_write,
                    alu_src_b,
                    imm_src,
                    result_src,
                    mem_write,
                    branch,
                    jump,
                    jalr
                );

            end
        end
    endtask

    // ============================================================
    // Secuencia de pruebas
    // ============================================================
    initial begin

        tests  = 0;
        errors = 0;
        opcode = 7'b0000000;

        #5;

        $display("");
        $display("==============================================");
        $display("   TESTBENCH MAIN DECODER - RISC-V RV32I");
        $display("==============================================");
        $display("");

        // --------------------------------------------------------
        // TEST 1 - R-TYPE
        // --------------------------------------------------------
        opcode = OP_RTYPE;

        check_outputs(
            "R-TYPE",
            1'b1,       // RegWrite
            1'b0,       // ALUSrcB = rs2
            IMM_I,      // No utilizado
            RES_ALU,    // Resultado de ALU
            1'b0,       // MemWrite
            1'b0,       // Branch
            1'b0,       // Jump
            1'b0        // Jalr
        );

        // --------------------------------------------------------
        // TEST 2 - I-TYPE ALU
        // --------------------------------------------------------
        opcode = OP_ITYPE;

        check_outputs(
            "I-TYPE ALU",
            1'b1,
            1'b1,
            IMM_I,
            RES_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // --------------------------------------------------------
        // TEST 3 - LOAD (lw)
        // --------------------------------------------------------
        opcode = OP_LOAD;

        check_outputs(
            "LOAD (LW)",
            1'b1,
            1'b1,
            IMM_I,
            RES_MEM,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // --------------------------------------------------------
        // TEST 4 - STORE (sw)
        // --------------------------------------------------------
        opcode = OP_STORE;

        check_outputs(
            "STORE (SW)",
            1'b0,
            1'b1,
            IMM_S,
            RES_ALU,
            1'b1,
            1'b0,
            1'b0,
            1'b0
        );

        // --------------------------------------------------------
        // TEST 5 - BRANCH
        // --------------------------------------------------------
        opcode = OP_BRANCH;

        check_outputs(
            "BRANCH",
            1'b0,
            1'b0,
            IMM_B,
            RES_ALU,
            1'b0,
            1'b1,
            1'b0,
            1'b0
        );

        // --------------------------------------------------------
        // TEST 6 - JAL
        // --------------------------------------------------------
        opcode = OP_JAL;

        check_outputs(
            "JAL",
            1'b1,
            1'b1,
            IMM_J,
            RES_PC4,
            1'b0,
            1'b0,
            1'b1,
            1'b0
        );

        // --------------------------------------------------------
        // TEST 7 - JALR
        // --------------------------------------------------------
        opcode = OP_JALR;

        check_outputs(
            "JALR",
            1'b1,
            1'b1,
            IMM_I,
            RES_PC4,
            1'b0,
            1'b0,
            1'b0,
            1'b1
        );

        // --------------------------------------------------------
        // TEST 8 - LUI
        // --------------------------------------------------------
        opcode = OP_LUI;

        check_outputs(
            "LUI",
            1'b1,
            1'b1,
            IMM_U,
            RES_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // --------------------------------------------------------
        // TEST 9 - AUIPC
        // --------------------------------------------------------
        opcode = OP_AUIPC;

        check_outputs(
            "AUIPC",
            1'b1,
            1'b0,
            IMM_U,
            RES_PC_IMM,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // --------------------------------------------------------
        // TEST 10 - OPCODE NO RECONOCIDO
        // Comprueba los valores seguros por defecto.
        // --------------------------------------------------------
        opcode = 7'b1111111;

        check_outputs(
            "OPCODE INVALIDO",
            1'b0,
            1'b0,
            IMM_I,
            RES_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // ========================================================
        // Resultado final
        // ========================================================
        $display("");
        $display("==============================================");
        $display("             RESULTADO FINAL");
        $display("==============================================");
        $display("Pruebas ejecutadas : %0d", tests);
        $display("Errores encontrados: %0d", errors);

        if (errors == 0) begin
            $display("");
            $display("TODOS LOS TEST PASARON - PASS");
        end
        else begin
            $display("");
            $display("SE ENCONTRARON ERRORES - FAIL");
        end

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule