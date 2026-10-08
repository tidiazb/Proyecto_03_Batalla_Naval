`timescale 1ns / 1ps

// ============================================================
// Módulo: video_ram
// Descripción:
//   Implementa la memoria de video utilizada por el subsistema
//   VGA. La memoria contiene 300 posiciones de 32 bits, donde
//   cada posición corresponde a uno de los tiles de la
//   cuadrícula de 20x15 utilizada para representar la pantalla.
//
//   La memoria utiliza dos puertos. El puerto A permite que el
//   sistema principal acceda a la memoria para escribir o leer
//   el estado de los tiles. El puerto B es utilizado por el
//   sistema VGA para leer continuamente el tile correspondiente
//   a la posición que se está mostrando.
//
//   Las lecturas son síncronas con sus respectivos relojes,
//   permitiendo que ambos puertos trabajen de forma independiente.
// ============================================================

module video_ram (
    input  logic        clk_a,
    input  logic        we_a,
    input  logic [8:0]  addr_a,
    input  logic [31:0] wdata_a,
    output logic [31:0] rdata_a,

    input  logic        clk_b,
    input  logic [8:0]  addr_b,
    output logic [31:0] rdata_b
);

    logic [31:0] mem [0:299];

    always_ff @(posedge clk_a) begin
        if (we_a)
            mem[addr_a] <= wdata_a;

        rdata_a <= mem[addr_a];
    end

    always_ff @(posedge clk_b) begin
        rdata_b <= mem[addr_b];
    end

endmodule