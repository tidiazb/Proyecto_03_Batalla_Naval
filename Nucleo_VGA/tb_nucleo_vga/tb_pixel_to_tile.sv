`timescale 1ns / 1ps

// ============================================================
// Testbench: tb_pixel_to_tile
// Descripción:
//   Verifica el funcionamiento del módulo pixel_to_tile mediante
//   diferentes coordenadas de píxel dentro de la región visible
//   de 640x480.
//
//   Las pruebas comprueban que cada coordenada pixel_x y pixel_y
//   sea convertida correctamente a una posición de tile dentro
//   de la cuadrícula de 20x15. También se verifican local_x y
//   local_y, que indican la posición del píxel dentro de cada
//   tile de 32x32 píxeles.
//
//   Se prueban el origen, los límites entre tiles, posiciones
//   intermedias y el último píxel visible de la pantalla. El
//   testbench informa automáticamente si todas las conversiones
//   fueron realizadas correctamente.
// ============================================================

module tb_pixel_to_tile;

    logic [9:0] pixel_x;
    logic [9:0] pixel_y;

    logic [4:0] tile_x;
    logic [3:0] tile_y;

    logic [4:0] local_x;
    logic [4:0] local_y;

    int errores;

    pixel_to_tile dut (
        .pixel_x (pixel_x),
        .pixel_y (pixel_y),
        .tile_x  (tile_x),
        .tile_y  (tile_y),
        .local_x (local_x),
        .local_y (local_y)
    );

    task automatic verificar (
        input logic [9:0] px,
        input logic [9:0] py,
        input logic [4:0] tx,
        input logic [3:0] ty,
        input logic [4:0] lx,
        input logic [4:0] ly
    );
        begin
            pixel_x = px;
            pixel_y = py;

            #1;

            if ((tile_x  !== tx) ||
                (tile_y  !== ty) ||
                (local_x !== lx) ||
                (local_y !== ly)) begin

                $error(
                    "Pixel (%0d,%0d): esperado tile=(%0d,%0d) local=(%0d,%0d), obtenido tile=(%0d,%0d) local=(%0d,%0d)",
                    px, py,
                    tx, ty,
                    lx, ly,
                    tile_x, tile_y,
                    local_x, local_y
                );

                errores++;
            end
        end
    endtask

    initial begin

        errores = 0;

        // Origen de la pantalla
        verificar(10'd0,   10'd0,   5'd0,  4'd0,  5'd0,  5'd0);

        // Último píxel del primer tile
        verificar(10'd31,  10'd31,  5'd0,  4'd0,  5'd31, 5'd31);

        // Primer píxel del siguiente tile horizontal
        verificar(10'd32,  10'd0,   5'd1,  4'd0,  5'd0,  5'd0);

        // Primer píxel del siguiente tile vertical
        verificar(10'd0,   10'd32,  5'd0,  4'd1,  5'd0,  5'd0);

        // Primer píxel del tile (1,1)
        verificar(10'd32,  10'd32,  5'd1,  4'd1,  5'd0,  5'd0);

        // Posición intermedia
        verificar(10'd100, 10'd70,  5'd3,  4'd2,  5'd4,  5'd6);

        // Otro límite entre tiles
        verificar(10'd319, 10'd239, 5'd9,  4'd7,  5'd31, 5'd15);

        // Último píxel visible de 640x480
        verificar(10'd639, 10'd479, 5'd19, 4'd14, 5'd31, 5'd31);

        if (errores == 0) begin
            $display("============================================");
            $display("TB PIXEL TO TILE: TODAS LAS PRUEBAS PASARON");
            $display("============================================");
        end
        else begin
            $display("============================================");
            $display("TB PIXEL TO TILE: %0d ERRORES", errores);
            $display("============================================");
        end

        $finish;

    end

endmodule
