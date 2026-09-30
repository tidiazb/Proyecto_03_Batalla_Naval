module alu_decoder (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic       funct7_5,

    output logic [3:0] alu_ctrl
);

    // ============================================================
    // Codificación de operaciones de la ALU
    // Debe coincidir con riscv_pkg.sv del datapath
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
    // Decodificador de la ALU
    // ============================================================
    always_comb begin

        // Operación segura por defecto
        alu_ctrl = ALU_ADD;

        case (opcode)

            // ====================================================
            // INSTRUCCIONES TIPO R
            // ====================================================
            OP_RTYPE: begin

                case (funct3)

                    // ADD / SUB
                    3'b000: begin
                        if (funct7_5)
                            alu_ctrl = ALU_SUB;
                        else
                            alu_ctrl = ALU_ADD;
                    end

                    // SLL
                    3'b001:
                        alu_ctrl = ALU_SLL;

                    // SLT
                    3'b010:
                        alu_ctrl = ALU_SLT;

                    // SLTU
                    3'b011:
                        alu_ctrl = ALU_SLTU;

                    // XOR
                    3'b100:
                        alu_ctrl = ALU_XOR;

                    // SRL / SRA
                    3'b101: begin
                        if (funct7_5)
                            alu_ctrl = ALU_SRA;
                        else
                            alu_ctrl = ALU_SRL;
                    end

                    // OR
                    3'b110:
                        alu_ctrl = ALU_OR;

                    // AND
                    3'b111:
                        alu_ctrl = ALU_AND;

                    default:
                        alu_ctrl = ALU_ADD;

                endcase
            end

            // ====================================================
            // INSTRUCCIONES TIPO I - ALU
            // ====================================================
            OP_ITYPE: begin

                case (funct3)

                    // ADDI
                    3'b000:
                        alu_ctrl = ALU_ADD;

                    // SLLI
                    3'b001:
                        alu_ctrl = ALU_SLL;

                    // SLTI
                    3'b010:
                        alu_ctrl = ALU_SLT;

                    // SLTIU
                    3'b011:
                        alu_ctrl = ALU_SLTU;

                    // XORI
                    3'b100:
                        alu_ctrl = ALU_XOR;

                    // SRLI / SRAI
                    3'b101: begin
                        if (funct7_5)
                            alu_ctrl = ALU_SRA;
                        else
                            alu_ctrl = ALU_SRL;
                    end

                    // ORI
                    3'b110:
                        alu_ctrl = ALU_OR;

                    // ANDI
                    3'b111:
                        alu_ctrl = ALU_AND;

                    default:
                        alu_ctrl = ALU_ADD;

                endcase
            end

            // ====================================================
            // LOAD
            // La ALU calcula: rs1 + inmediato
            // ====================================================
            OP_LOAD:
                alu_ctrl = ALU_ADD;

            // ====================================================
            // STORE
            // La ALU calcula: rs1 + inmediato
            // ====================================================
            OP_STORE:
                alu_ctrl = ALU_ADD;

            // ====================================================
            // BRANCH
            // La comparación se realiza mediante resta
            // ====================================================
            OP_BRANCH:
                alu_ctrl = ALU_SUB;

            // ====================================================
            // JALR
            // Dirección destino = rs1 + inmediato
            // ====================================================
            OP_JALR:
                alu_ctrl = ALU_ADD;

            // ====================================================
            // LUI
            // Se pasa el inmediato hacia el resultado
            // ====================================================
            OP_LUI:
                alu_ctrl = ALU_PASS_B;

            // ====================================================
            // JAL y AUIPC
            //
            // El cálculo principal del PC se realiza fuera
            // de esta ALU según la arquitectura del datapath.
            // ====================================================
            OP_JAL:
                alu_ctrl = ALU_ADD;

            OP_AUIPC:
                alu_ctrl = ALU_ADD;

            // ====================================================
            // Opcode no reconocido
            // ====================================================
            default:
                alu_ctrl = ALU_ADD;

        endcase
    end

endmodule