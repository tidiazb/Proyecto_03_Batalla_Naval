`timescale 1ns / 1ps

// ============================================================
// Módulo: pixel_to_tile
// Descripción:
//   Convierte las coordenadas de píxel generadas por el sistema
//   VGA en coordenadas de tiles para una pantalla dividida en
//   una cuadrícula de 20 columnas por 15 filas.
//
//   Cada tile ocupa una región de 32x32 píxeles. Por lo tanto,
//   los bits superiores de pixel_x y pixel_y permiten determinar
//   directamente la columna y fila del tile correspondiente.
//
//   Además, el módulo entrega las coordenadas internas del píxel
//   dentro del tile. Estas coordenadas podrán utilizarse
//   posteriormente para generar bordes, símbolos y otros
//   elementos gráficos dentro de cada casilla.
// ============================================================

module pixel_to_tile (
    input  logic [9:0] pixel_x,
    input  logic [9:0] pixel_y,

    output logic [4:0] tile_x,
    output logic [3:0] tile_y,

    output logic [4:0] local_x,
    output logic [4:0] local_y
);

    always_comb begin
        tile_x  = pixel_x[9:5];
        tile_y  = pixel_y[8:5];

        local_x = pixel_x[4:0];
        local_y = pixel_y[4:0];
    end

endmodule
