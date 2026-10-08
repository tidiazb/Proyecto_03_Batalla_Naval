`timescale 1ns / 1ps

//============================================================
// Testbench: tb_status_led
// Issue #10 - LED de estado
//
// Verifica:
//   00 -> Colocación     -> Azul
//   01 -> Batalla        -> Verde
//   10 -> Resultado final-> Rojo
//   11 -> Inválido       -> Apagado
//
// El testbench reporta automáticamente PASS o FAIL.
//============================================================

module tb_status_led;

    logic [1:0] game_state;
    logic [2:0] led_rgb;

    integer errors;


    //========================================================
    // DUT
    //========================================================

    status_led dut (
        .game_state (game_state),
        .led_rgb    (led_rgb)
    );


    //========================================================
    // Tarea de verificación
    //========================================================

    task automatic check_state(
        input logic [1:0] state_test,
        input logic [2:0] expected_led,
        input string      state_name
    );

        begin

            game_state = state_test;

            #10;

            if (led_rgb !== expected_led) begin

                $display(
                    "FAIL | Estado=%s | game_state=%b | LED esperado=%b | LED obtenido=%b",
                    state_name,
                    game_state,
                    expected_led,
                    led_rgb
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "PASS | Estado=%s | game_state=%b | LED=%b",
                    state_name,
                    game_state,
                    led_rgb
                );

            end

        end

    endtask


    //========================================================
    // Secuencia de pruebas
    //========================================================

    initial begin

        errors = 0;

        game_state = 2'b00;

        $display("");
        $display("========================================");
        $display(" ISSUE #10 - TEST LED DE ESTADO");
        $display("========================================");


        //----------------------------------------------------
        // PRUEBA 1
        // Fase de colocación
        //----------------------------------------------------

        check_state(
            2'b00,
            3'b001,
            "COLOCACION"
        );


        //----------------------------------------------------
        // PRUEBA 2
        // Fase de batalla
        //----------------------------------------------------

        check_state(
            2'b01,
            3'b010,
            "BATALLA"
        );


        //----------------------------------------------------
        // PRUEBA 3
        // Resultado final
        //----------------------------------------------------

        check_state(
            2'b10,
            3'b100,
            "RESULTADO FINAL"
        );


        //----------------------------------------------------
        // PRUEBA 4
        // Estado no válido
        //----------------------------------------------------

        check_state(
            2'b11,
            3'b000,
            "INVALIDO"
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

        #20;

        $finish;

    end

endmodule