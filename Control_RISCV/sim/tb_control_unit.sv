`timescale 1ns / 1ps

module tb_control_unit;

    // ============================================================
    // Entradas
    // ============================================================
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7_5;

    // ============================================================
    // Salidas
    // ============================================================
    logic       reg_write;
    logic       alu_src_b;
    logic [3:0] alu_ctrl;
    logic [2:0] imm_src;
    logic [1:0] result_src;
    logic       mem_write;
    logic       branch;
    logic       jump;
    logic       jalr;

    integer tests;
    integer errors;

    // ============================================================
    // ImmSrc
    // ============================================================
    localparam logic [2:0]
        IMM_I = 3'b000,
        IMM_S = 3'b001,
        IMM_B = 3'b010,
        IMM_J = 3'b011,
        IMM_U = 3'b100;

    // ============================================================
    // ResultSrc
    // ============================================================
    localparam logic [1:0]
        RES_ALU    = 2'b00,
        RES_MEM    = 2'b01,
        RES_PC4    = 2'b10,
        RES_PC_IMM = 2'b11;

    // ============================================================
    // ALU Control
    // ============================================================
    localparam logic [3:0]
        ALU_ADD    = 4'b0000,
        ALU_SLL    = 4'b0001,
        ALU_SLT    = 4'b0010,
        ALU_SLTU   = 4'b0011,
        ALU_XOR    = 4'b0100,
        ALU_SRL    = 4'b0101,
        ALU_OR     = 4'b0110,
        ALU_AND    = 4'b0111,
        ALU_SUB    = 4'b1000,
        ALU_SRA    = 4'b1101,
        ALU_PASS_B = 4'b1111;

    // ============================================================
    // Opcodes
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
    // DUT
    // ============================================================
    control_unit dut (
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7_5   (funct7_5),

        .reg_write  (reg_write),
        .alu_src_b  (alu_src_b),
        .alu_ctrl   (alu_ctrl),
        .imm_src    (imm_src),
        .result_src (result_src),
        .mem_write  (mem_write),
        .branch     (branch),
        .jump       (jump),
        .jalr       (jalr)
    );

    // ============================================================
    // Tarea autoverificable
    // ============================================================
    task automatic check_control(
        input string      test_name,

        input logic [6:0] test_opcode,
        input logic [2:0] test_funct3,
        input logic       test_funct7_5,

        input logic       exp_reg_write,
        input logic       exp_alu_src_b,
        input logic [3:0] exp_alu_ctrl,
        input logic [2:0] exp_imm_src,
        input logic [1:0] exp_result_src,
        input logic       exp_mem_write,
        input logic       exp_branch,
        input logic       exp_jump,
        input logic       exp_jalr
    );

        begin

            tests = tests + 1;

            opcode   = test_opcode;
            funct3   = test_funct3;
            funct7_5 = test_funct7_5;

            #1;

            if (
                (reg_write  === exp_reg_write)  &&
                (alu_src_b  === exp_alu_src_b)  &&
                (alu_ctrl   === exp_alu_ctrl)   &&
                (imm_src    === exp_imm_src)    &&
                (result_src === exp_result_src) &&
                (mem_write  === exp_mem_write)  &&
                (branch     === exp_branch)     &&
                (jump       === exp_jump)       &&
                (jalr       === exp_jalr)
            )
            begin

                $display(
                    "[PASS] %-10s | opcode=%b funct3=%b f7_5=%b | ALUCtrl=%b",
                    test_name,
                    opcode,
                    funct3,
                    funct7_5,
                    alu_ctrl
                );

            end
            else begin

                errors = errors + 1;

                $display("");
                $display("[FAIL] %s", test_name);

                $display(
                    "Esperado: RW=%b AS=%b ALU=%b IMM=%b RES=%b MW=%b BR=%b J=%b JR=%b",
                    exp_reg_write,
                    exp_alu_src_b,
                    exp_alu_ctrl,
                    exp_imm_src,
                    exp_result_src,
                    exp_mem_write,
                    exp_branch,
                    exp_jump,
                    exp_jalr
                );

                $display(
                    "Obtenido: RW=%b AS=%b ALU=%b IMM=%b RES=%b MW=%b BR=%b J=%b JR=%b",
                    reg_write,
                    alu_src_b,
                    alu_ctrl,
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
    // PRUEBAS
    // ============================================================
    initial begin

        tests  = 0;
        errors = 0;

        opcode   = 7'b0;
        funct3   = 3'b0;
        funct7_5 = 1'b0;

        #5;

        $display("");
        $display("========================================================");
        $display("     TEST CONTROL UNIT INTEGRADA - RISC-V RV32I");
        $display("========================================================");


        // ========================================================
        // R-TYPE
        // ========================================================

        $display("");
        $display("----- R-TYPE -----");

        check_control(
            "ADD",
            OP_RTYPE, 3'b000, 1'b0,
            1'b1, 1'b0, ALU_ADD,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "SUB",
            OP_RTYPE, 3'b000, 1'b1,
            1'b1, 1'b0, ALU_SUB,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "SLL",
            OP_RTYPE, 3'b001, 1'b0,
            1'b1, 1'b0, ALU_SLL,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "SLT",
            OP_RTYPE, 3'b010, 1'b0,
            1'b1, 1'b0, ALU_SLT,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "SLTU",
            OP_RTYPE, 3'b011, 1'b0,
            1'b1, 1'b0, ALU_SLTU,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "XOR",
            OP_RTYPE, 3'b100, 1'b0,
            1'b1, 1'b0, ALU_XOR,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "SRL",
            OP_RTYPE, 3'b101, 1'b0,
            1'b1, 1'b0, ALU_SRL,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "SRA",
            OP_RTYPE, 3'b101, 1'b1,
            1'b1, 1'b0, ALU_SRA,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "OR",
            OP_RTYPE, 3'b110, 1'b0,
            1'b1, 1'b0, ALU_OR,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "AND",
            OP_RTYPE, 3'b111, 1'b0,
            1'b1, 1'b0, ALU_AND,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );


        // ========================================================
        // I-TYPE
        // ========================================================

        $display("");
        $display("----- I-TYPE -----");

        check_control(
            "ADDI",
            OP_ITYPE, 3'b000, 1'b0,
            1'b1, 1'b1, ALU_ADD,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "SLLI",
            OP_ITYPE, 3'b001, 1'b0,
            1'b1, 1'b1, ALU_SLL,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "SLTI",
            OP_ITYPE, 3'b010, 1'b0,
            1'b1, 1'b1, ALU_SLT,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "SLTIU",
            OP_ITYPE, 3'b011, 1'b0,
            1'b1, 1'b1, ALU_SLTU,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "XORI",
            OP_ITYPE, 3'b100, 1'b0,
            1'b1, 1'b1, ALU_XOR,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "SRLI",
            OP_ITYPE, 3'b101, 1'b0,
            1'b1, 1'b1, ALU_SRL,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "SRAI",
            OP_ITYPE, 3'b101, 1'b1,
            1'b1, 1'b1, ALU_SRA,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "ORI",
            OP_ITYPE, 3'b110, 1'b0,
            1'b1, 1'b1, ALU_OR,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "ANDI",
            OP_ITYPE, 3'b111, 1'b0,
            1'b1, 1'b1, ALU_AND,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );


        // ========================================================
        // MEMORIA
        // ========================================================

        $display("");
        $display("----- MEMORIA -----");

        check_control(
            "LW",
            OP_LOAD, 3'b010, 1'b0,
            1'b1, 1'b1, ALU_ADD,
            IMM_I, RES_MEM,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "SW",
            OP_STORE, 3'b010, 1'b0,
            1'b0, 1'b1, ALU_ADD,
            IMM_S, RES_ALU,
            1'b1, 1'b0, 1'b0, 1'b0
        );


        // ========================================================
        // BRANCH
        // ========================================================

        $display("");
        $display("----- BRANCH -----");

        check_control(
            "BEQ",
            OP_BRANCH, 3'b000, 1'b0,
            1'b0, 1'b0, ALU_SUB,
            IMM_B, RES_ALU,
            1'b0, 1'b1, 1'b0, 1'b0
        );


        // ========================================================
        // JUMPS
        // ========================================================

        $display("");
        $display("----- JUMPS -----");

        check_control(
            "JAL",
            OP_JAL, 3'b000, 1'b0,
            1'b1, 1'b1, ALU_ADD,
            IMM_J, RES_PC4,
            1'b0, 1'b0, 1'b1, 1'b0
        );

        check_control(
            "JALR",
            OP_JALR, 3'b000, 1'b0,
            1'b1, 1'b1, ALU_ADD,
            IMM_I, RES_PC4,
            1'b0, 1'b0, 1'b0, 1'b1
        );


        // ========================================================
        // U-TYPE
        // ========================================================

        $display("");
        $display("----- U-TYPE -----");

        check_control(
            "LUI",
            OP_LUI, 3'b000, 1'b0,
            1'b1, 1'b1, ALU_PASS_B,
            IMM_U, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );

        check_control(
            "AUIPC",
            OP_AUIPC, 3'b000, 1'b0,
            1'b1, 1'b0, ALU_ADD,
            IMM_U, RES_PC_IMM,
            1'b0, 1'b0, 1'b0, 1'b0
        );


        // ========================================================
        // OPCODE INVALIDO
        // ========================================================

        $display("");
        $display("----- OPCODE INVALIDO -----");

        check_control(
            "INVALIDO",
            7'b1111111, 3'b111, 1'b1,
            1'b0, 1'b0, ALU_ADD,
            IMM_I, RES_ALU,
            1'b0, 1'b0, 1'b0, 1'b0
        );


        // ========================================================
        // RESULTADO FINAL
        // ========================================================

        $display("");
        $display("========================================================");
        $display("                  RESULTADO FINAL");
        $display("========================================================");

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

        $display("========================================================");
        $display("");

        $finish;

    end

endmodule