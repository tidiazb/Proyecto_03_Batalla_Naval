`timescale 1ns / 1ps

module tb_alu_decoder;

    // ============================================================
    // Entradas del DUT
    // ============================================================
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7_5;

    // ============================================================
    // Salida del DUT
    // ============================================================
    logic [3:0] alu_ctrl;

    // Contadores
    integer tests;
    integer errors;

    // ============================================================
    // Codificacion de operaciones ALU
    // Debe coincidir con alu_decoder.sv
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
    // DUT
    // ============================================================
    alu_decoder dut (
        .opcode   (opcode),
        .funct3   (funct3),
        .funct7_5 (funct7_5),
        .alu_ctrl (alu_ctrl)
    );

    // ============================================================
    // Tarea de comprobacion automatica
    // ============================================================
    task automatic check_alu(
        input string      test_name,
        input logic [6:0] test_opcode,
        input logic [2:0] test_funct3,
        input logic       test_funct7_5,
        input logic [3:0] expected_alu_ctrl
    );

        begin

            tests = tests + 1;

            opcode   = test_opcode;
            funct3   = test_funct3;
            funct7_5 = test_funct7_5;

            #1;

            if (alu_ctrl === expected_alu_ctrl) begin

                $display(
                    "[PASS] %-12s | opcode=%b funct3=%b funct7_5=%b | ALUCtrl=%b",
                    test_name,
                    opcode,
                    funct3,
                    funct7_5,
                    alu_ctrl
                );

            end
            else begin

                errors = errors + 1;

                $display(
                    "[FAIL] %-12s | esperado=%b obtenido=%b",
                    test_name,
                    expected_alu_ctrl,
                    alu_ctrl
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

        opcode   = 7'b0000000;
        funct3   = 3'b000;
        funct7_5 = 1'b0;

        #5;

        $display("");
        $display("==============================================================");
        $display("          TESTBENCH ALU DECODER - RISC-V RV32I");
        $display("==============================================================");
        $display("");


        // ========================================================
        // 1. INSTRUCCIONES R-TYPE
        // ========================================================

        $display("----- R-TYPE -----");

        // ADD
        check_alu(
            "ADD",
            OP_RTYPE,
            3'b000,
            1'b0,
            ALU_ADD
        );

        // SUB
        check_alu(
            "SUB",
            OP_RTYPE,
            3'b000,
            1'b1,
            ALU_SUB
        );

        // SLL
        check_alu(
            "SLL",
            OP_RTYPE,
            3'b001,
            1'b0,
            ALU_SLL
        );

        // SLT
        check_alu(
            "SLT",
            OP_RTYPE,
            3'b010,
            1'b0,
            ALU_SLT
        );

        // SLTU
        check_alu(
            "SLTU",
            OP_RTYPE,
            3'b011,
            1'b0,
            ALU_SLTU
        );

        // XOR
        check_alu(
            "XOR",
            OP_RTYPE,
            3'b100,
            1'b0,
            ALU_XOR
        );

        // SRL
        check_alu(
            "SRL",
            OP_RTYPE,
            3'b101,
            1'b0,
            ALU_SRL
        );

        // SRA
        check_alu(
            "SRA",
            OP_RTYPE,
            3'b101,
            1'b1,
            ALU_SRA
        );

        // OR
        check_alu(
            "OR",
            OP_RTYPE,
            3'b110,
            1'b0,
            ALU_OR
        );

        // AND
        check_alu(
            "AND",
            OP_RTYPE,
            3'b111,
            1'b0,
            ALU_AND
        );


        // ========================================================
        // 2. INSTRUCCIONES I-TYPE ALU
        // ========================================================

        $display("");
        $display("----- I-TYPE ALU -----");

        // ADDI
        check_alu(
            "ADDI",
            OP_ITYPE,
            3'b000,
            1'b0,
            ALU_ADD
        );

        // SLLI
        check_alu(
            "SLLI",
            OP_ITYPE,
            3'b001,
            1'b0,
            ALU_SLL
        );

        // SLTI
        check_alu(
            "SLTI",
            OP_ITYPE,
            3'b010,
            1'b0,
            ALU_SLT
        );

        // SLTIU
        check_alu(
            "SLTIU",
            OP_ITYPE,
            3'b011,
            1'b0,
            ALU_SLTU
        );

        // XORI
        check_alu(
            "XORI",
            OP_ITYPE,
            3'b100,
            1'b0,
            ALU_XOR
        );

        // SRLI
        check_alu(
            "SRLI",
            OP_ITYPE,
            3'b101,
            1'b0,
            ALU_SRL
        );

        // SRAI
        check_alu(
            "SRAI",
            OP_ITYPE,
            3'b101,
            1'b1,
            ALU_SRA
        );

        // ORI
        check_alu(
            "ORI",
            OP_ITYPE,
            3'b110,
            1'b0,
            ALU_OR
        );

        // ANDI
        check_alu(
            "ANDI",
            OP_ITYPE,
            3'b111,
            1'b0,
            ALU_AND
        );


        // ========================================================
        // 3. ACCESO A MEMORIA
        // ========================================================

        $display("");
        $display("----- MEMORIA -----");

        // LW: direccion = rs1 + inmediato
        check_alu(
            "LW",
            OP_LOAD,
            3'b010,
            1'b0,
            ALU_ADD
        );

        // SW: direccion = rs1 + inmediato
        check_alu(
            "SW",
            OP_STORE,
            3'b010,
            1'b0,
            ALU_ADD
        );


        // ========================================================
        // 4. BRANCH
        // ========================================================

        $display("");
        $display("----- BRANCH -----");

        // El alu_decoder actual selecciona SUB para los branches
        check_alu(
            "BRANCH",
            OP_BRANCH,
            3'b000,
            1'b0,
            ALU_SUB
        );


        // ========================================================
        // 5. SALTOS
        // ========================================================

        $display("");
        $display("----- JUMPS -----");

        // JAL
        check_alu(
            "JAL",
            OP_JAL,
            3'b000,
            1'b0,
            ALU_ADD
        );

        // JALR
        check_alu(
            "JALR",
            OP_JALR,
            3'b000,
            1'b0,
            ALU_ADD
        );


        // ========================================================
        // 6. U-TYPE
        // ========================================================

        $display("");
        $display("----- U-TYPE -----");

        // LUI
        check_alu(
            "LUI",
            OP_LUI,
            3'b000,
            1'b0,
            ALU_PASS_B
        );

        // AUIPC
        check_alu(
            "AUIPC",
            OP_AUIPC,
            3'b000,
            1'b0,
            ALU_ADD
        );


        // ========================================================
        // 7. OPCODE INVALIDO
        // ========================================================

        $display("");
        $display("----- OPCODE INVALIDO -----");

        check_alu(
            "INVALIDO",
            7'b1111111,
            3'b111,
            1'b1,
            ALU_ADD
        );


        // ========================================================
        // RESULTADO FINAL
        // ========================================================

        $display("");
        $display("==============================================================");
        $display("                     RESULTADO FINAL");
        $display("==============================================================");
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

        $display("==============================================================");
        $display("");

        $finish;

    end

endmodule