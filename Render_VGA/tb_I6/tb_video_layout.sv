`timescale 1ns / 1ps

// ============================================================
// Testbench: tb_video_layout
//
// Descripción:
// Verifica el funcionamiento del módulo video_layout.
// Se prueban posiciones pertenecientes al tablero propio,
// tablero rival, HUD y fondo.
//
// También se verifican las coordenadas locales board_x_o y
// board_y_o generadas dentro de los tableros.
//
// El testbench es autoverificable y reporta PASS o FAIL.
// ============================================================

module tb_video_layout;

    // --------------------------------------------------------
    // Señales de entrada
    // --------------------------------------------------------

    logic [4:0] tile_x_i;
    logic [3:0] tile_y_i;

    // --------------------------------------------------------
    // Señales de salida
    // --------------------------------------------------------

    logic [1:0] region_o;
    logic [2:0] board_x_o;
    logic [2:0] board_y_o;

    // --------------------------------------------------------
    // Contador de errores
    // --------------------------------------------------------

    integer errores;

    // --------------------------------------------------------
    // Códigos de región
    // --------------------------------------------------------

    localparam logic [1:0] REGION_FONDO  = 2'b00;
    localparam logic [1:0] REGION_PROPIO = 2'b01;
    localparam logic [1:0] REGION_RIVAL  = 2'b10;
    localparam logic [1:0] REGION_HUD    = 2'b11;

    // --------------------------------------------------------
    // Instancia del DUT
    // --------------------------------------------------------

    video_layout dut (
        .tile_x_i  (tile_x_i),
        .tile_y_i  (tile_y_i),

        .region_o  (region_o),
        .board_x_o (board_x_o),
        .board_y_o (board_y_o)
    );

    // --------------------------------------------------------
    // Tarea para verificar cada posición
    // --------------------------------------------------------

    task automatic verificar(
        input logic [4:0] x,
        input logic [3:0] y,
        input logic [1:0] region_esperada,
        input logic [2:0] bx_esperado,
        input logic [2:0] by_esperado
    );

        begin

            tile_x_i = x;
            tile_y_i = y;

            #1;

            if ((region_o  !== region_esperada) ||
                (board_x_o !== bx_esperado)     ||
                (board_y_o !== by_esperado)) begin

                $display(
                    "FAIL: tile=(%0d,%0d) region=%b bx=%0d by=%0d | esperado region=%b bx=%0d by=%0d",
                    x,
                    y,
                    region_o,
                    board_x_o,
                    board_y_o,
                    region_esperada,
                    bx_esperado,
                    by_esperado
                );

                errores = errores + 1;

            end
            else begin

                $display(
                    "PASS: tile=(%0d,%0d) region=%b bx=%0d by=%0d",
                    x,
                    y,
                    region_o,
                    board_x_o,
                    board_y_o
                );

            end

        end

    endtask

    // --------------------------------------------------------
    // Pruebas
    // --------------------------------------------------------

    initial begin

        errores = 0;

        tile_x_i = 0;
        tile_y_i = 0;

        #1;

        // ====================================================
        // PRUEBA 1
        // Fondo
        // ====================================================

        verificar(
            5'd0,
            4'd0,
            REGION_FONDO,
            3'd0,
            3'd0
        );

        // ====================================================
        // PRUEBA 2
        // Esquina superior izquierda del tablero propio
        // ====================================================

        verificar(
            5'd1,
            4'd2,
            REGION_PROPIO,
            3'd0,
            3'd0
        );

        // ====================================================
        // PRUEBA 3
        // Posición interna del tablero propio
        // ====================================================

        verificar(
            5'd4,
            4'd5,
            REGION_PROPIO,
            3'd3,
            3'd3
        );

        // ====================================================
        // PRUEBA 4
        // Esquina inferior derecha del tablero propio
        // ====================================================

        verificar(
            5'd8,
            4'd9,
            REGION_PROPIO,
            3'd7,
            3'd7
        );

        // ====================================================
        // PRUEBA 5
        // Esquina superior izquierda del tablero rival
        // ====================================================

        verificar(
            5'd11,
            4'd2,
            REGION_RIVAL,
            3'd0,
            3'd0
        );

        // ====================================================
        // PRUEBA 6
        // Posición interna del tablero rival
        // ====================================================

        verificar(
            5'd14,
            4'd6,
            REGION_RIVAL,
            3'd3,
            3'd4
        );

        // ====================================================
        // PRUEBA 7
        // Esquina inferior derecha del tablero rival
        // ====================================================

        verificar(
            5'd18,
            4'd9,
            REGION_RIVAL,
            3'd7,
            3'd7
        );

        // ====================================================
        // PRUEBA 8
        // Región del HUD
        // ====================================================

        verificar(
            5'd5,
            4'd12,
            REGION_HUD,
            3'd0,
            3'd0
        );

        // ====================================================
        // PRUEBA 9
        // Esquina inicial del HUD
        // ====================================================

        verificar(
            5'd1,
            4'd11,
            REGION_HUD,
            3'd0,
            3'd0
        );

        // ====================================================
        // PRUEBA 10
        // Esquina final del HUD
        // ====================================================

        verificar(
            5'd18,
            4'd13,
            REGION_HUD,
            3'd0,
            3'd0
        );

        // ====================================================
        // PRUEBA 11
        // Espacio entre ambos tableros
        // ====================================================

        verificar(
            5'd9,
            4'd5,
            REGION_FONDO,
            3'd0,
            3'd0
        );

        // ====================================================
        // PRUEBA 12
        // Posición debajo de los tableros
        // ====================================================

        verificar(
            5'd5,
            4'd10,
            REGION_FONDO,
            3'd0,
            3'd0
        );

        // ====================================================
        // Resultado final
        // ====================================================

        if (errores == 0) begin

            $display("==============================================");
            $display("TB VIDEO LAYOUT: TODAS LAS PRUEBAS PASARON");
            $display("==============================================");

        end
        else begin

            $display("==============================================");
            $display("TB VIDEO LAYOUT: %0d ERRORES", errores);
            $display("==============================================");

        end

        $finish;

    end

endmodule