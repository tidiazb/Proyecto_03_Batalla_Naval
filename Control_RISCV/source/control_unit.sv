module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic       funct7_5,

    output logic       reg_write,
    output logic       alu_src_b,
    output logic [3:0] alu_ctrl,
    output logic [2:0] imm_src,
    output logic [1:0] result_src,
    output logic       mem_write,
    output logic       branch,
    output logic       jump,
    output logic       jalr
);

    // ============================================================
    // Unidad de Control RISC-V RV32I
    //
    // Este módulo integra:
    //   1. Decodificador principal (main_decoder)
    //   2. Decodificador de la ALU (alu_decoder)
    //
    // A partir de opcode, funct3 y funct7[5], genera las señales
    // de control necesarias para el datapath.
    // ============================================================


    // ============================================================
    // MAIN DECODER
    // ============================================================

    main_decoder u_main_decoder (
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
    // ALU DECODER
    // ============================================================

    alu_decoder u_alu_decoder (
        .opcode    (opcode),
        .funct3    (funct3),
        .funct7_5  (funct7_5),
        .alu_ctrl  (alu_ctrl)
    );

endmodule