`timescale 1ns / 1ps

//============================================================
// Módulo: peripherals_mmio
// Issue #10 - Periféricos de salida local
//
// Adaptador entre el bus MMIO del Issue #4 y:
//   - Display de 7 segmentos
//   - LED RGB de estado
//   - Buzzer
//
// Direcciones decodificadas por el Issue #4:
//   0x0001_0130 -> Display
//   0x0001_0138 -> LED de estado
//   0x0001_0140 -> Buzzer
//
// El mmio_interconnect del Issue #4 ya genera los pulsos:
//   display_we_i
//   led_we_i
//   buzzer_we_i
//
// Por tanto, este módulo NO vuelve a decodificar direcciones.
//============================================================

module peripherals_mmio #(
    parameter integer DISPLAY_REFRESH_BITS = 18,
    parameter integer BUZZER_CLK_FREQ      = 100_000_000
)(
    input  logic        clk,
    input  logic        rst,

    //========================================================
    // Interfaz proveniente del bus MMIO - Issue #4
    //========================================================

    input  logic [31:0] bus_wdata_i,

    input  logic        display_we_i,
    input  logic        led_we_i,
    input  logic        buzzer_we_i,

    // Datos de lectura que regresan al bus
    output logic [31:0] display_rdata_o,
    output logic [31:0] led_rdata_o,
    output logic [31:0] buzzer_rdata_o,

    //========================================================
    // Salidas físicas
    //========================================================

    output logic [6:0]  seg,
    output logic [3:0]  an,

    output logic [2:0]  led_rgb,

    output logic        buzzer
);

    //========================================================
    // Registros MMIO internos
    //========================================================

    logic [7:0] player1_reg;
    logic [7:0] player2_reg;

    logic [1:0] game_state_reg;

    logic [2:0] sound_sel_reg;

    logic buzzer_start;
    logic buzzer_busy;


    //========================================================
    // REGISTRO DISPLAY
    //
    // Dirección externa:
    // 0x0001_0130
    //
    // Formato:
    //
    // 31                         16 15       8 7        0
    // +---------------------------+----------+----------+
    // |         reservado         |    J2    |    J1    |
    // +---------------------------+----------+----------+
    //
    // J1 = bits [7:0]
    // J2 = bits [15:8]
    //========================================================

    always_ff @(posedge clk) begin

        if (rst) begin

            player1_reg <= 8'd0;
            player2_reg <= 8'd0;

        end
        else if (display_we_i) begin

            //------------------------------------------------
            // Protección del rango 00-99
            //------------------------------------------------

            if (bus_wdata_i[7:0] <= 8'd99)
                player1_reg <= bus_wdata_i[7:0];
            else
                player1_reg <= 8'd99;

            if (bus_wdata_i[15:8] <= 8'd99)
                player2_reg <= bus_wdata_i[15:8];
            else
                player2_reg <= 8'd99;

        end

    end


    //========================================================
    // REGISTRO LED
    //
    // Dirección externa:
    // 0x0001_0138
    //
    // bits [1:0]:
    //
    // 00 -> Colocación
    // 01 -> Batalla
    // 10 -> Resultado final
    // 11 -> Inválido / apagado
    //========================================================

    always_ff @(posedge clk) begin

        if (rst) begin

            game_state_reg <= 2'b00;

        end
        else if (led_we_i) begin

            game_state_reg <= bus_wdata_i[1:0];

        end

    end


    //========================================================
    // REGISTRO BUZZER
    //
    // Dirección externa:
    // 0x0001_0140
    //
    // bits [3:1] -> sound_sel
    // bit  [0]   -> start
    //
    // sound_sel:
    //
    // 001 -> Impacto
    // 010 -> Fallo
    // 011 -> Barco hundido
    // 100 -> Colocación inválida
    // 101 -> Victoria
    //
    // Ejemplo:
    //
    // sound_sel = 001
    // start     = 1
    //
    // bus_wdata = 000...0011
    //========================================================

    always_ff @(posedge clk) begin

        if (rst) begin

            sound_sel_reg <= 3'b000;
            buzzer_start  <= 1'b0;

        end
        else begin

            //------------------------------------------------
            // START funciona como pulso de un ciclo
            //------------------------------------------------

            buzzer_start <= 1'b0;

            if (buzzer_we_i) begin

                sound_sel_reg <= bus_wdata_i[3:1];

                if (bus_wdata_i[0])
                    buzzer_start <= 1'b1;

            end

        end

    end


    //========================================================
    // Lectura de registros MMIO
    //========================================================

    always_comb begin

        //----------------------------------------------------
        // DISPLAY
        //----------------------------------------------------

        display_rdata_o = 32'b0;

        display_rdata_o[7:0]  = player1_reg;
        display_rdata_o[15:8] = player2_reg;


        //----------------------------------------------------
        // LED
        //----------------------------------------------------

        led_rdata_o = 32'b0;

        led_rdata_o[1:0] = game_state_reg;


        //----------------------------------------------------
        // BUZZER
        //
        // [3:1] = sonido seleccionado
        // [0]   = busy
        //----------------------------------------------------

        buzzer_rdata_o = 32'b0;

        buzzer_rdata_o[3:1] = sound_sel_reg;
        buzzer_rdata_o[0]   = buzzer_busy;

    end


    //========================================================
    // DISPLAY DE 7 SEGMENTOS
    //========================================================

    seven_seg_display #(
        .REFRESH_BITS(DISPLAY_REFRESH_BITS)
    ) u_display (
        .clk     (clk),
        .rst     (rst),

        .player1 (player1_reg),
        .player2 (player2_reg),

        .seg     (seg),
        .an      (an)
    );


    //========================================================
    // LED DE ESTADO
    //========================================================

    status_led u_status_led (
        .game_state (game_state_reg),
        .led_rgb    (led_rgb)
    );


    //========================================================
    // BUZZER
    //========================================================

    buzzer_controller #(
        .CLK_FREQ(BUZZER_CLK_FREQ)
    ) u_buzzer (
        .clk       (clk),
        .rst       (rst),

        .start     (buzzer_start),
        .sound_sel (sound_sel_reg),

        .buzzer    (buzzer),
        .busy      (buzzer_busy)
    );


endmodule