module main_decoder (
    input  logic [6:0] opcode,

    output logic       reg_write,
    output logic       alu_src_b,
    output logic [2:0] imm_src,
    output logic [1:0] result_src,
    output logic       mem_write,
    output logic       branch,
    output logic       jump,
    output logic       jalr
);

    // ============================================================
    // Codificación de ImmSrc
    // Debe coincidir con riscv_pkg.sv del datapath
    // ============================================================
    localparam logic [2:0]
        IMM_I = 3'b000,
        IMM_S = 3'b001,
        IMM_B = 3'b010,
        IMM_J = 3'b011,
        IMM_U = 3'b100;

    // ============================================================
    // Codificación de ResultSrc
    // Debe coincidir con riscv_pkg.sv del datapath
    // ============================================================
    localparam logic [1:0]
        RES_ALU    = 2'b00,
        RES_MEM    = 2'b01,
        RES_PC4    = 2'b10,
        RES_PC_IMM = 2'b11;

    // ============================================================
    // Opcodes RV32I utilizados
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
    // Decodificador principal
    // ============================================================
    always_comb begin

        // Valores por defecto
        reg_write  = 1'b0;
        alu_src_b  = 1'b0;
        imm_src    = IMM_I;
        result_src = RES_ALU;
        mem_write  = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;

        case (opcode)

            // ----------------------------------------------------
            // Instrucciones tipo R
            // ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
            // ----------------------------------------------------
            OP_RTYPE: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b0;
                result_src = RES_ALU;
            end

            // ----------------------------------------------------
            // Instrucciones ALU con inmediato
            // ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI...
            // ----------------------------------------------------
            OP_ITYPE: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;
                imm_src    = IMM_I;
                result_src = RES_ALU;
            end

            // ----------------------------------------------------
            // LOAD
            // lw
            // ----------------------------------------------------
            OP_LOAD: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;
                imm_src    = IMM_I;
                result_src = RES_MEM;
            end

            // ----------------------------------------------------
            // STORE
            // sw
            // ----------------------------------------------------
            OP_STORE: begin
                alu_src_b = 1'b1;
                imm_src   = IMM_S;
                mem_write = 1'b1;
            end

            // ----------------------------------------------------
            // BRANCH
            // beq, bne, blt, bge, bltu, bgeu
            // ----------------------------------------------------
            OP_BRANCH: begin
                alu_src_b = 1'b0;
                imm_src   = IMM_B;
                branch    = 1'b1;
            end

            // ----------------------------------------------------
            // JAL
            // ----------------------------------------------------
            OP_JAL: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;
                imm_src    = IMM_J;
                result_src = RES_PC4;
                jump       = 1'b1;
            end

            // ----------------------------------------------------
            // JALR
            // ----------------------------------------------------
            OP_JALR: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;
                imm_src    = IMM_I;
                result_src = RES_PC4;
                jalr       = 1'b1;
            end

            // ----------------------------------------------------
            // LUI
            // ----------------------------------------------------
            OP_LUI: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;
                imm_src    = IMM_U;
                result_src = RES_ALU;
            end

            // ----------------------------------------------------
            // AUIPC
            // ----------------------------------------------------
            OP_AUIPC: begin
                reg_write  = 1'b1;
                imm_src    = IMM_U;
                result_src = RES_PC_IMM;
            end

            // Opcode no reconocido:
            // se mantienen los valores seguros por defecto.
            default: begin
            end

        endcase
    end

endmodule