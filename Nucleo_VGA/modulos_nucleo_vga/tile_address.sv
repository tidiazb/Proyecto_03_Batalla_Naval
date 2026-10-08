`timescale 1ns / 1ps

// ============================================================
// Módulo: tile_address
// Descripción:
//   Convierte las coordenadas bidimensionales de un tile en una
//   dirección lineal que puede utilizarse para acceder a la
//   memoria de video.
//
//   El sistema VGA divide la región visible en una cuadrícula
//   de 20 columnas por 15 filas, para un total de 300 tiles.
//   El módulo recibe la columna tile_x y la fila tile_y, y
//   calcula una dirección entre 0 y 299 siguiendo un recorrido
//   por filas.
//
//   De esta forma, cada posición de la cuadrícula queda asociada
//   con una posición única dentro de la Video RAM.
// ============================================================

module tile_address (
    input  logic [4:0] tile_x,
    input  logic [3:0] tile_y,

    output logic [8:0] tile_addr
);

    always_comb begin
        tile_addr = (tile_y * 9'd20) + tile_x;
    end

endmodule
