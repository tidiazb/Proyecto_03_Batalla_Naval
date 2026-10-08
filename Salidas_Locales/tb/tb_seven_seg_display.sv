`timescale 1ns / 1ps

//============================================================
// Testbench: tb_seven_seg_display
// Issue #10 - Displays de 7 segmentos
//
// Verifica automáticamente:
// 1. Reset
// 2. Visualización de valores 00-99
// 3. Visualización simultánea J1 y J2
// 4. Multiplexado de los cuatro dígitos
// 5. Decodificación correcta a 7 segmentos
// 6. Saturación a 99 para valores > 99
//
// Resultado final:
//      TEST PASSED
// o
//      TEST FAILED
//============================================================

module tb_seven_seg_display;

    //========================================================
    // Parámetros
    //========================================================

    // Valor pequeño para acelerar la simulación
    localparam integer REFRESH_BITS_TB = 4;

    //========================================================
    // Señales
    //========================================================

    logic clk;
    logic rst;

    logic [7:0] player1;
    logic [7:0] player2;

    logic [6:0] seg;
    logic [3:0] an;

    integer errors;


    //========================================================
    // DUT - Device Under Test
    //========================================================

    seven_seg_display #(
        .REFRESH_BITS(REFRESH_BITS_TB)
    ) dut (
        .clk     (clk),
        .rst     (rst),
        .player1 (player1),
        .player2 (player2),
        .seg     (seg),
        .an      (an)
    );


    //========================================================
    // Generación del reloj
    //
    // Periodo = 10 ns
    // Frecuencia simulada = 100 MHz
    //========================================================

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end


    //========================================================
    // Función para obtener el patrón esperado
    // de los 7 segmentos.
    //
    // Activo en bajo.
    //========================================================

    function automatic logic [6:0] expected_seg(
        input logic [3:0] digit
    );

        begin

            case (digit)

                4'd0: expected_seg = 7'b0000001;
                4'd1: expected_seg = 7'b1001111;
                4'd2: expected_seg = 7'b0010010;
                4'd3: expected_seg = 7'b0000110;
                4'd4: expected_seg = 7'b1001100;
                4'd5: expected_seg = 7'b0100100;
                4'd6: expected_seg = 7'b0100000;
                4'd7: expected_seg = 7'b0001111;
                4'd8: expected_seg = 7'b0000000;
                4'd9: expected_seg = 7'b0000100;

                default:
                    expected_seg = 7'b1111111;

            endcase

        end

    endfunction


    //========================================================
    // Tarea para comprobar un dígito
    //========================================================

    task automatic check_digit(
        input logic [3:0] expected_an,
        input logic [3:0] expected_digit
    );

        begin

            // Esperar hasta que el multiplexor seleccione
            // el display solicitado.
            wait(an == expected_an);

            #1;

            if (seg !== expected_seg(expected_digit)) begin

                $display(
                    "FAIL | Tiempo=%0t | AN=%b | Digito esperado=%0d | SEG esperado=%b | SEG obtenido=%b",
                    $time,
                    an,
                    expected_digit,
                    expected_seg(expected_digit),
                    seg
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "PASS | Tiempo=%0t | AN=%b | Digito=%0d | SEG=%b",
                    $time,
                    an,
                    expected_digit,
                    seg
                );

            end

        end

    endtask


    //========================================================
    // Tarea para comprobar los cuatro displays
    //
    // Distribución:
    //
    // AN3 = J2 decenas
    // AN2 = J2 unidades
    // AN1 = J1 decenas
    // AN0 = J1 unidades
    //========================================================

    task automatic check_display(
        input integer p1,
        input integer p2
    );

        integer value1;
        integer value2;

        logic [3:0] p1_units;
        logic [3:0] p1_tens;

        logic [3:0] p2_units;
        logic [3:0] p2_tens;

        begin

            //------------------------------------------------
            // Aplicar los valores
            //------------------------------------------------

            player1 = p1;
            player2 = p2;

            //------------------------------------------------
            // El diseño satura valores mayores que 99
            //------------------------------------------------

            if (p1 > 99)
                value1 = 99;
            else
                value1 = p1;

            if (p2 > 99)
                value2 = 99;
            else
                value2 = p2;


            //------------------------------------------------
            // Obtener decenas y unidades esperadas
            //------------------------------------------------

            p1_units = value1 % 10;
            p1_tens  = value1 / 10;

            p2_units = value2 % 10;
            p2_tens  = value2 / 10;


            $display("");
            $display("========================================");
            $display(
                "Prueba: J1=%0d | J2=%0d",
                p1,
                p2
            );
            $display("========================================");


            //------------------------------------------------
            // Comprobar los cuatro dígitos
            //------------------------------------------------

            // AN0 -> Jugador 1 unidades
            check_digit(
                4'b1110,
                p1_units
            );

            // AN1 -> Jugador 1 decenas
            check_digit(
                4'b1101,
                p1_tens
            );

            // AN2 -> Jugador 2 unidades
            check_digit(
                4'b1011,
                p2_units
            );

            // AN3 -> Jugador 2 decenas
            check_digit(
                4'b0111,
                p2_tens
            );

        end

    endtask


    //========================================================
    // Secuencia principal de pruebas
    //========================================================

    initial begin

        //----------------------------------------------------
        // Inicialización
        //----------------------------------------------------

        errors  = 0;

        rst     = 1'b1;

        player1 = 8'd0;
        player2 = 8'd0;


        //----------------------------------------------------
        // RESET
        //----------------------------------------------------

        $display("");
        $display("========================================");
        $display(" ISSUE #10 - TEST DISPLAY 7 SEGMENTOS");
        $display("========================================");

        $display("");
        $display("Aplicando RESET...");

        #30;

        rst = 1'b0;

        $display("RESET liberado.");

        #20;


        //====================================================
        // PRUEBA 1
        // Valores mínimos
        //====================================================

        check_display(
            0,
            0
        );


        //====================================================
        // PRUEBA 2
        // Valor con cero inicial
        //
        // Display esperado:
        // J2 = 12
        // J1 = 05
        //
        // Visualmente: 1 2 0 5
        //====================================================

        check_display(
            5,
            12
        );


        //====================================================
        // PRUEBA 3
        // Valores normales
        //
        // Display esperado:
        // J2 = 84
        // J1 = 37
        //
        // Visualmente: 8 4 3 7
        //====================================================

        check_display(
            37,
            84
        );


        //====================================================
        // PRUEBA 4
        // Valores intermedios
        //====================================================

        check_display(
            42,
            56
        );


        //====================================================
        // PRUEBA 5
        // Valor máximo permitido
        //====================================================

        check_display(
            99,
            99
        );


        //====================================================
        // PRUEBA 6
        // Comprobación adicional
        //====================================================

        check_display(
            10,
            90
        );


        //====================================================
        // PRUEBA 7
        // Valor superior a 99
        //
        // El diseño debe saturarlo a 99.
        //====================================================

        check_display(
            105,
            120
        );


        //====================================================
        // RESULTADO FINAL
        //====================================================

        $display("");
        $display("========================================");

        if (errors == 0) begin

            $display("       TEST PASSED");
            $display(" Todas las pruebas fueron correctas.");

        end
        else begin

            $display("       TEST FAILED");
            $display(
                " Numero total de errores: %0d",
                errors
            );

        end

        $display("========================================");
        $display("");

        #50;

        $finish;

    end

endmodule