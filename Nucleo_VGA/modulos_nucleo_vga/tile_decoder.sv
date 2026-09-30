`timescale 1ns / 1ps

// ============================================================
// Módulo: tile_decoder
// Descripción:
//   Interpreta la información de 32 bits correspondiente al tile
//   actual almacenado en la Video RAM y genera el color RGB que
//   debe mostrarse para ese píxel.
//
//   Los tres bits menos significativos de tile_data representan
//   el estado visual de la casilla, permitiendo distinguir agua,
//   barco, disparo fallido, barco impactado y selección.
//
//   Las coordenadas local_x y local_y indican la posición del
//   píxel dentro del tile de 32x32 y se utilizan para generar un
//   borde alrededor de cada casilla. Las salidas RGB utilizan
//   4 bits por componente, compatibles con la salida VGA de la
//   FPGA.
// ============================================================

module tile_decoder (
    input  logic [31:0] tile_data,
    input  logic [4:0]  local_x,
    input  logic [4:0]  local_y,

    output logic [3:0] red,
    output logic [3:0] green,
    output logic [3:0] blue
);

    logic borde;

    always_comb begin

        borde = (local_x == 5'd0)  ||
                (local_x == 5'd31) ||
                (local_y == 5'd0)  ||
                (local_y == 5'd31);

        red   = 4'h0;
        green = 4'h0;
        blue  = 4'h0;

        if (borde) begin

            red   = 4'hF;
            green = 4'hF;
            blue  = 4'hF;

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