`timescale 1ns / 1ps

// ============================================================
// Testbench: tb_tile_address
// Descripción:
//   Verifica el funcionamiento del módulo tile_address mediante
//   diferentes coordenadas de tiles dentro de la cuadrícula
//   de video de 20 columnas por 15 filas.
//
//   Para cada posición (tile_x, tile_y), el testbench comprueba
//   que se genere correctamente una dirección lineal utilizando
//   la relación address = tile_y * 20 + tile_x.
//
//   Se prueban posiciones al inicio y final de distintas filas,
//   posiciones intermedias y el último tile de la cuadrícula.
//   La simulación informa automáticamente si todas las
//   direcciones calculadas son correctas.
// ============================================================

module tb_tile_address;

    logic [4:0] tile_x;
    logic [3:0] tile_y;

    logic [8:0] tile_addr;

    int errores;

    tile_address dut (
        .tile_x    (tile_x),
        .tile_y    (tile_y),
        .tile_addr (tile_addr)
    );

    task automatic verificar (
        input logic [4:0] tx,
        input logic [3:0] ty,
        input logic [8:0] addr_esperada
    );
        begin

            tile_x = tx;
            tile_y = ty;

            #1;

            if (tile_addr !== addr_esperada) begin

                $error(
                    "Tile (%0d,%0d): direccion esperada=%0d, obtenida=%0d",
                    tx,
                    ty,
                    addr_esperada,
                    tile_addr
                );

                errores++;

            end
        end
    endtask

    initial begin

        errores = 0;

        // Primera posición
        verificar(5'd0,  4'd0,  9'd0);

        // Última posición de la primera fila
        verificar(5'd19, 4'd0,  9'd19);

        // Primera posición de la segunda fila
        verificar(5'd0,  4'd1,  9'd20);

        // Segunda posición de la segunda fila
        verificar(5'd1,  4'd1,  9'd21);

        // Posición intermedia
        verificar(5'd3,  4'd2,  9'd43);

        // Última posición de una fila intermedia
        verificar(5'd19, 4'd7,  9'd159);

        // Primera posición de la última fila
        verificar(5'd0,  4'd14, 9'd280);

        // Posición intermedia de la última fila
        verificar(5'd10, 4'd14, 9'd290);

        // Último tile de toda la pantalla
        verificar(5'd19, 4'd14, 9'd299);

        if (errores == 0) begin
            $display("============================================");
            $display("TB TILE ADDRESS: TODAS LAS PRUEBAS PASARON");
            $display("============================================");
        end
        else begin
            $display("============================================");
            $display("TB TILE ADDRESS: %0d ERRORES", errores);
            $display("============================================");
        end

        $finish;

    end

endmodule
