`timescale 1ns / 1ps

//============================================================
// Testbench: tb_buzzer_controller
// Issue #10 - Buzzer
//
// Verifica automáticamente:
//   001 -> Impacto
//   010 -> Fallo
//   011 -> Barco hundido
//   100 -> Colocación inválida
//   101 -> Secuencia de victoria
//
// Se comprueba:
//   - Activación de busy
//   - Generación de señal en buzzer
//   - Finalización automática del sonido
//   - Diferenciación básica entre los efectos
//   - Secuencia de tres etapas para victoria
//
// Resultado:
//       TEST PASSED
//       TEST FAILED
//============================================================

module tb_buzzer_controller;

    //========================================================
    // Frecuencia reducida para simulación
    //
    // Debe mantenerse suficientemente alta para que los
    // divisores de 400, 800 y 1200 Hz sean mayores que cero.
    //========================================================

    localparam integer CLK_FREQ_TB = 120_000;


    //========================================================
    // Códigos de sonido
    //========================================================

    localparam logic [2:0] SOUND_NONE    = 3'b000;
    localparam logic [2:0] SOUND_HIT     = 3'b001;
    localparam logic [2:0] SOUND_MISS    = 3'b010;
    localparam logic [2:0] SOUND_SUNK    = 3'b011;
    localparam logic [2:0] SOUND_INVALID = 3'b100;
    localparam logic [2:0] SOUND_WIN     = 3'b101;


    //========================================================
    // Señales
    //========================================================

    logic clk;
    logic rst;

    logic start;
    logic [2:0] sound_sel;

    logic buzzer;
    logic busy;

    integer errors;


    //========================================================
    // DUT
    //========================================================

    buzzer_controller #(
        .CLK_FREQ(CLK_FREQ_TB)
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .start     (start),
        .sound_sel (sound_sel),
        .buzzer    (buzzer),
        .busy      (busy)
    );


    //========================================================
    // Reloj
    //
    // Periodo = 10 ns
    //========================================================

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end


    //========================================================
    // Generar pulso START
    //========================================================

    task automatic start_sound(
        input logic [2:0] selected_sound
    );

        begin

            sound_sel = selected_sound;

            @(negedge clk);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

        end

    endtask


    //========================================================
    // Comprobar sonido normal
    //
    // Verifica:
    // 1. busy se activa.
    // 2. buzzer cambia de estado.
    // 3. busy finalmente vuelve a cero.
    //========================================================

    task automatic check_sound(
        input logic [2:0] selected_sound,
        input string      sound_name
    );

        integer toggle_count;
        logic previous_buzzer;

        begin

            $display("");
            $display("----------------------------------------");
            $display("Prueba de sonido: %s", sound_name);
            $display("----------------------------------------");

            start_sound(selected_sound);


            //------------------------------------------------
            // Comprobar BUSY
            //------------------------------------------------

            @(posedge clk);
            #1;

            if (busy !== 1'b1) begin

                $display(
                    "FAIL | %s | BUSY no se activo",
                    sound_name
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "PASS | %s | BUSY activado",
                    sound_name
                );

            end


            //------------------------------------------------
            // Contar cambios de la señal buzzer
            //------------------------------------------------

            toggle_count    = 0;
            previous_buzzer = buzzer;

            while (busy) begin

                @(posedge clk);
                #1;

                if (buzzer != previous_buzzer) begin

                    toggle_count = toggle_count + 1;

                    previous_buzzer = buzzer;

                end

            end


            //------------------------------------------------
            // Debe haberse generado una onda
            //------------------------------------------------

            if (toggle_count == 0) begin

                $display(
                    "FAIL | %s | No se detectaron cambios en buzzer",
                    sound_name
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "PASS | %s | Cambios detectados en buzzer = %0d",
                    sound_name,
                    toggle_count
                );

            end


            //------------------------------------------------
            // Al terminar debe quedar apagado
            //------------------------------------------------

            if (buzzer !== 1'b0) begin

                $display(
                    "FAIL | %s | Buzzer no termino apagado",
                    sound_name
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "PASS | %s | Sonido finalizado correctamente",
                    sound_name
                );

            end


            // Pequeña separación entre pruebas
            repeat (5) @(posedge clk);

        end

    endtask


    //========================================================
    // Comprobar secuencia de victoria
    //
    // La victoria debe recorrer:
    //
    // sequence_step = 0
    // sequence_step = 1
    // sequence_step = 2
    //
    // y luego finalizar.
    //========================================================

    task automatic check_victory;

        logic saw_step_0;
        logic saw_step_1;
        logic saw_step_2;

        integer toggle_count;
        logic previous_buzzer;

        begin

            $display("");
            $display("----------------------------------------");
            $display("Prueba de sonido: VICTORIA");
            $display("----------------------------------------");

            saw_step_0 = 1'b0;
            saw_step_1 = 1'b0;
            saw_step_2 = 1'b0;

            toggle_count = 0;

            start_sound(SOUND_WIN);

            @(posedge clk);
            #1;


            //------------------------------------------------
            // BUSY debe activarse
            //------------------------------------------------

            if (busy !== 1'b1) begin

                $display(
                    "FAIL | VICTORIA | BUSY no se activo"
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "PASS | VICTORIA | BUSY activado"
                );

            end


            //------------------------------------------------
            // Supervisar toda la secuencia
            //------------------------------------------------

            previous_buzzer = buzzer;

            while (busy) begin

                //------------------------------------------------
                // Verificar las etapas internas
                //------------------------------------------------

                case (dut.sequence_step)

                    3'd0:
                        saw_step_0 = 1'b1;

                    3'd1:
                        saw_step_1 = 1'b1;

                    3'd2:
                        saw_step_2 = 1'b1;

                    default: begin
                    end

                endcase


                //------------------------------------------------
                // Contar cambios del buzzer
                //------------------------------------------------

                @(posedge clk);
                #1;

                if (buzzer != previous_buzzer) begin

                    toggle_count = toggle_count + 1;

                    previous_buzzer = buzzer;

                end

            end


            //------------------------------------------------
            // Verificar las tres etapas
            //------------------------------------------------

            if (
                saw_step_0 &&
                saw_step_1 &&
                saw_step_2
            ) begin

                $display(
                    "PASS | VICTORIA | Secuencia 0 -> 1 -> 2 detectada"
                );

            end
            else begin

                $display(
                    "FAIL | VICTORIA | Secuencia incompleta"
                );

                errors = errors + 1;

            end


            //------------------------------------------------
            // Debe existir actividad en buzzer
            //------------------------------------------------

            if (toggle_count > 0) begin

                $display(
                    "PASS | VICTORIA | Cambios detectados en buzzer = %0d",
                    toggle_count
                );

            end
            else begin

                $display(
                    "FAIL | VICTORIA | No hubo actividad en buzzer"
                );

                errors = errors + 1;

            end


            //------------------------------------------------
            // Debe terminar apagado
            //------------------------------------------------

            if (buzzer === 1'b0) begin

                $display(
                    "PASS | VICTORIA | Secuencia finalizada correctamente"
                );

            end
            else begin

                $display(
                    "FAIL | VICTORIA | Buzzer no termino apagado"
                );

                errors = errors + 1;

            end

        end

    endtask


    //========================================================
    // Secuencia principal
    //========================================================

    initial begin

        errors = 0;

        rst       = 1'b1;
        start     = 1'b0;
        sound_sel = SOUND_NONE;


        $display("");
        $display("========================================");
        $display(" ISSUE #10 - TEST BUZZER");
        $display("========================================");


        //====================================================
        // RESET
        //====================================================

        repeat (5) @(posedge clk);

        rst = 1'b0;

        repeat (2) @(posedge clk);

        if (
            busy   === 1'b0 &&
            buzzer === 1'b0
        ) begin

            $display(
                "PASS | RESET | Buzzer en reposo"
            );

        end
        else begin

            $display(
                "FAIL | RESET | Estado incorrecto"
            );

            errors = errors + 1;

        end


        //====================================================
        // PRUEBA 1
        // Impacto
        //====================================================

        check_sound(
            SOUND_HIT,
            "IMPACTO"
        );


        //====================================================
        // PRUEBA 2
        // Fallo
        //====================================================

        check_sound(
            SOUND_MISS,
            "FALLO"
        );


        //====================================================
        // PRUEBA 3
        // Barco hundido
        //====================================================

        check_sound(
            SOUND_SUNK,
            "BARCO HUNDIDO"
        );


        //====================================================
        // PRUEBA 4
        // Colocación inválida
        //====================================================

        check_sound(
            SOUND_INVALID,
            "COLOCACION INVALIDA"
        );


        //====================================================
        // PRUEBA 5
        // Victoria
        //====================================================

        check_victory();


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