`timescale 1ns / 1ps

module top_prueba (

    input  logic        clk,

    // Switches de la Basys 3
    input  logic [15:0] sw,

    // Botones
    input  logic        btnC,
    input  logic        btnU,

    // Display de 7 segmentos
    output logic [6:0]  seg,
    output logic [3:0]  an,

    // LEDs normales de la Basys
    output logic [2:0]  led,

    // Salida hacia buzzer externo
    output logic        buzzer,

    // LED para visualizar BUSY del buzzer
    output logic        busy_led
);

    //========================================================
    // Señales internas
    //========================================================

    logic [7:0] player1;
    logic [7:0] player2;

    logic [1:0] game_state;
    logic [2:0] sound_sel;

    logic [2:0] led_rgb;

    logic buzzer_busy;


    //========================================================
    // Asignación de controles físicos
    //========================================================

    // SW0-SW3 = jugador 1
    assign player1 = {4'b0000, sw[3:0]};

    // SW4-SW7 = jugador 2
    assign player2 = {4'b0000, sw[7:4]};

    // SW8-SW9 = estado del juego
    assign game_state = sw[9:8];

    // SW10-SW12 = sonido
    assign sound_sel = sw[12:10];


    //========================================================
    // DISPLAY
    //========================================================

    seven_seg_display display_inst (
        .clk     (clk),
        .rst     (btnC),
        .player1 (player1),
        .player2 (player2),
        .seg     (seg),
        .an      (an)
    );


    //========================================================
    // LED DE ESTADO
    //========================================================

    status_led led_inst (
        .game_state (game_state),
        .led_rgb    (led_rgb)
    );

    assign led = led_rgb;


    //========================================================
    // BUZZER
    //========================================================

    buzzer_controller #(
        .CLK_FREQ(100_000_000)
    ) buzzer_inst (
        .clk       (clk),
        .rst       (btnC),
        .start     (btnU),
        .sound_sel (sound_sel),
        .buzzer    (buzzer),
        .busy      (buzzer_busy)
    );


    // Mostrar físicamente BUSY en otro LED
    assign busy_led = buzzer_busy;


endmodule