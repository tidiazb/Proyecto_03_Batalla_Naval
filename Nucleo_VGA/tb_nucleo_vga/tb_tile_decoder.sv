`timescale 1ns / 1ps

// ============================================================
// Testbench: tb_tile_decoder
// Descripción:
//   Verifica el funcionamiento del módulo tile_decoder mediante
//   diferentes valores de estado almacenados en tile_data.
//
//   El testbench comprueba que los estados de agua, barco,
//   disparo fallido, barco impactado y casilla seleccionada
//   produzcan los valores RGB esperados. También verifica que
//   los píxeles ubicados en los límites de cada tile generen
//   correctamente un borde blanco.
//
//   Finalmente se prueba un estado reservado para comprobar el
//   comportamiento por defecto del decodificador. La simulación
//   informa automáticamente si todas las pruebas son correctas.
// ============================================================

module tb_tile_decoder;

    logic [31:0] tile_data;
    logic [4:0]  local_x;
    logic [4:0]  local_y;

    logic [3:0] red;
    logic [3:0] green;
    logic [3:0] blue;

    int errores;

    tile_decoder dut (
        .tile_data (tile_data),
        .local_x   (local_x),
        .local_y   (local_y),
        .red       (red),
        .green     (green),
        .blue      (blue)
    );

    task automatic verificar (
        input logic [31:0] dato,
        input logic [4:0]  lx,
        input logic [4:0]  ly,
        input logic [3:0]  red_esperado,
        input logic [3:0]  green_esperado,
        input logic [3:0]  blue_esperado
    );
        begin

            tile_data = dato;
            local_x   = lx;
            local_y   = ly;

            #1;

            if ((red   !== red_esperado)   ||
                (green !== green_esperado) ||
                (blue  !== blue_esperado)) begin

                $error(
                    "Dato=%h local=(%0d,%0d): RGB esperado=(%h,%h,%h), obtenido=(%h,%h,%h)",
                    dato,
                    lx,
                    ly,
                    red_esperado,
                    green_esperado,
                    blue_esperado,
                    red,
                    green,
                    blue
                );

                errores++;

            end

        end
    endtask

    initial begin

        errores = 0;

        // Agua
        verificar(
            32'h00000000,
            5'd15, 5'd15,
            4'h0, 4'h4, 4'hF
        );

        // Barco
        verificar(
            32'h00000001,
            5'd15, 5'd15,
            4'h8, 4'h8, 4'h8
        );

        // Disparo fallido
        verificar(
            32'h00000002,
            5'd15, 5'd15,
            4'h0, 4'hF, 4'hF
        );

        // Barco impactado
        verificar(
            32'h00000003,
            5'd15, 5'd15,
            4'hF, 4'h0, 4'h0
        );

        // Casilla seleccionada
        verificar(
            32'h00000004,
            5'd15, 5'd15,
            4'hF, 4'hF, 4'h0
        );

        // Estado reservado
        verificar(
            32'h00000005,
            5'd15, 5'd15,
            4'h0, 4'h0, 4'h0
        );

        // Borde izquierdo
        verificar(
            32'h00000000,
            5'd0, 5'd15,
            4'hF, 4'hF, 4'hF
        );

        // Borde derecho
        verificar(
            32'h00000001,
            5'd31, 5'd15,
            4'hF, 4'hF, 4'hF
        );

        // Borde superior
        verificar(
            32'h00000002,
            5'd15, 5'd0,
            4'hF, 4'hF, 4'hF
        );

        // Borde inferior
        verificar(
            32'h00000003,
            5'd15, 5'd31,
            4'hF, 4'hF, 4'hF
        );

        // Esquina del tile
        verificar(
            32'h00000004,
            5'd0, 5'd0,
            4'hF, 4'hF, 4'hF
        );

        if (errores == 0) begin
            $display("============================================");
            $display("TB TILE DECODER: TODAS LAS PRUEBAS PASARON");
            $display("============================================");
        end
        else begin
            $display("============================================");
            $display("TB TILE DECODER: %0d ERRORES", errores);
            $display("============================================");
        end

        $finish;

    end

endmodule
