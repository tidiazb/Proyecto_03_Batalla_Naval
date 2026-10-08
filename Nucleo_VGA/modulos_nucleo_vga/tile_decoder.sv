`timescale 1ns / 1ps

// ============================================================
// Módulo: tile_decoder
// Descripción:
//   Interpreta la información de 32 bits correspondiente al tile
//   actual almacenado en la Video RAM y genera el color RGB que
//   debe mostrarse para ese píxel.
//
//   Formato de tile_data:
//     [2:0] estado visual de la casilla
//           000 agua, 001 barco, 010 fallo, 011 impacto,
//           100 selección, 101 fondo
//     [3]   cursor: el firmware lo activa en la casilla donde
//           está el cursor del Jugador 1 (colocación o disparo)
//
//   Las coordenadas local_x y local_y indican la posición del
//   píxel dentro del tile de 32x32 y se utilizan para generar un
//   borde blanco alrededor de cada casilla y, cuando el tile
//   tiene el bit de cursor, un marco amarillo grueso que
//   parpadea según la entrada blink. El color de la casilla se
//   conserva en el centro, para ver qué hay debajo del cursor.
//   Las salidas RGB utilizan 4 bits por componente.
// ============================================================

module tile_decoder (
    input  logic [31:0] tile_data,
    input  logic [4:0]  local_x,
    input  logic [4:0]  local_y,
    input  logic        blink,

    output logic [3:0] red,
    output logic [3:0] green,
    output logic [3:0] blue
);

    logic borde;
    logic marco_cursor;
    logic cursor_visible;

    always_comb begin

        borde = (local_x == 5'd0)  ||
                (local_x == 5'd31) ||
                (local_y == 5'd0)  ||
                (local_y == 5'd31);

        // Marco de 4 píxeles justo dentro del borde blanco
        marco_cursor = (local_x <= 5'd4)  ||
                       (local_x >= 5'd27) ||
                       (local_y <= 5'd4)  ||
                       (local_y >= 5'd27);

        cursor_visible = tile_data[3] && blink;

        red   = 4'h0;
        green = 4'h0;
        blue  = 4'h0;

        if (borde) begin

            red   = 4'hF;
            green = 4'hF;
            blue  = 4'hF;

        end
        else if (cursor_visible && marco_cursor) begin

            red   = 4'hF;
            green = 4'hF;
            blue  = 4'h0;

        end
        else begin

            case (tile_data[2:0])

                3'b000: begin
                    red   = 4'h0;
                    green = 4'h4;
                    blue  = 4'hF;
                end

                3'b001: begin
                    red   = 4'h8;
                    green = 4'h8;
                    blue  = 4'h8;
                end

                3'b010: begin
                    red   = 4'h0;
                    green = 4'hF;
                    blue  = 4'hF;
                end

                3'b011: begin
                    red   = 4'hF;
                    green = 4'h0;
                    blue  = 4'h0;
                end

                3'b100: begin
                    red   = 4'hF;
                    green = 4'hF;
                    blue  = 4'h0;
                end

                default: begin
                    red   = 4'h0;
                    green = 4'h0;
                    blue  = 4'h0;
                end

            endcase

        end

    end

endmodule
