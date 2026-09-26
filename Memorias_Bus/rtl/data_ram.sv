`timescale 1ns/1ps

// RAM de datos: 1024 palabras x 32 bits, direccionada por indice de palabra.
// Escritura sincrona y lectura combinacional (contrato para CPU de ciclo unico).
// No tiene reset de contenido: BTN_RST reinicia la partida sin borrar victorias.
module data_ram (
    input  logic        clk_i,
    input  logic        select_i,
    input  logic        write_enable_i,
    input  logic [9:0]  word_addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o
);
    logic [31:0] ram [0:1023];

    // Estado de encendido definido para FPGA; el programa administra los
    // datos de cada nueva partida con instrucciones sw.
    initial begin : INIT_RAM
        for (integer i = 0; i < 1024; i = i + 1)
            ram[i] = 32'b0;
    end

    always_ff @(posedge clk_i) begin
        if (select_i && write_enable_i)
            ram[word_addr_i] <= wdata_i;
    end

    always_comb begin
        rdata_o = 32'b0;
        if (select_i)
            rdata_o = ram[word_addr_i];
    end
endmodule
