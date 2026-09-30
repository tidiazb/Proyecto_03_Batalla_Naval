`timescale 1ns / 1ps

// ============================================================
// Módulo: video_layout
//
// Descripción:
// Este módulo define la distribución de las diferentes regiones
// gráficas utilizadas en la pantalla del juego Batalla Naval.
// Recibe las coordenadas de tile generadas a partir de la posición
// actual del píxel y determina si dicho tile pertenece al tablero
// propio, al tablero rival, al HUD o al fondo de la pantalla.
//
// Cada tablero ocupa una región de 8x8 tiles. Cuando la posición
// pertenece a uno de los tableros, el módulo también genera las
// coordenadas locales de la casilla, con valores entre 0 y 7.
// La salida region_o permite identificar posteriormente qué tipo
// de contenido debe mostrarse en cada zona de la pantalla.
// ============================================================

module video_layout (
    input  logic [4:0] tile_x_i,
    input  logic [3:0] tile_y_i,

    output logic [1:0] region_o,
    output logic [2:0] board_x_o,
    output logic [2:0] board_y_o
);

    localparam logic [1:0] REGION_FONDO   = 2'b00;
    localparam logic [1:0] REGION_PROPIO  = 2'b01;
    localparam logic [1:0] REGION_RIVAL   = 2'b10;
    localparam logic [1:0] REGION_HUD     = 2'b11;

    always_comb begin

        region_o  = REGION_FONDO;
        board_x_o = 3'd0;
        board_y_o = 3'd0;

        if ((tile_x_i >= 5'd1)  &&
            (tile_x_i <= 5'd8)  &&
            (tile_y_i >= 4'd2)  &&
            (tile_y_i <= 4'd9)) begin

            region_o  = REGION_PROPIO;
            board_x_o = tile_x_i - 5'd1;
            board_y_o = tile_y_i - 4'd2;

        end
        else if ((tile_x_i >= 5'd11) &&
                 (tile_x_i <= 5'd18) &&
                 (tile_y_i >= 4'd2)  &&
                 (tile_y_i <= 4'd9)) begin

            region_o  = REGION_RIVAL;
            board_x_o = tile_x_i - 5'd11;
            board_y_o = tile_y_i - 4'd2;

        end
        else if ((tile_x_i >= 5'd1)  &&
                 (tile_x_i <= 5'd18) &&
                 (tile_y_i >= 4'd11) &&
                 (tile_y_i <= 4'd13)) begin

            region_o = REGION_HUD;

        end

    end

endmodule