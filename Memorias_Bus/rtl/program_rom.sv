`timescale 1ns/1ps

// ROM de instrucciones: 0x0000_0000 ... 0x0000_1FFF (2048 palabras).
// El archivo hexadecimal contiene una instruccion de 32 bits por linea.
module program_rom #(
    parameter INIT_FILE = ""
) (
    input  logic [31:0] prog_addr_i,
    output logic [31:0] prog_instr_o
);
    localparam integer WORDS = 2048;
    localparam logic [31:0] NOP = 32'h0000_0013; // addi x0, x0, 0

    logic [31:0] rom [0:WORDS-1];

    initial begin : INIT_ROM
        // Una ROM sin programa entrega NOP y no instrucciones desconocidas.
        for (integer i = 0; i < WORDS; i = i + 1)
            rom[i] = NOP;
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, rom);
    end

    always_comb begin
        prog_instr_o = NOP;
        if ((prog_addr_i <= 32'h0000_1FFF) && (prog_addr_i[1:0] == 2'b00))
            prog_instr_o = rom[prog_addr_i[12:2]];
    end
endmodule
