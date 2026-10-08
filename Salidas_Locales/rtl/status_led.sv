`timescale 1ns / 1ps

//============================================================
// Módulo: status_led
// Issue #10 - LED de estado
//
// Función:
// Representa visualmente la fase actual de la partida.
//
// Estados:
//   00 -> Colocación
//   01 -> Batalla
//   10 -> Resultado final
//   11 -> Estado no válido
//
// Salida RGB:
//   Colocación -> Azul
//   Batalla    -> Verde
//   Resultado  -> Rojo
//   Inválido   -> Apagado
//
// led_rgb[2:0] = {R, G, B}
//============================================================

module status_led (
    input  logic [1:0] game_state,
    output logic [2:0] led_rgb
);

    //========================================================
    // Definición de estados
    //========================================================

    localparam logic [1:0] STATE_PLACEMENT = 2'b00;
    localparam logic [1:0] STATE_BATTLE    = 2'b01;
    localparam logic [1:0] STATE_RESULT    = 2'b10;


    //========================================================
    // Decodificación del estado de la partida
    //========================================================

    always_comb begin

        // Por defecto, LED apagado
        led_rgb = 3'b000;

        case (game_state)

            // Fase de colocación
            STATE_PLACEMENT: begin
                led_rgb = 3'b001;   // Azul
            end

            // Fase de batalla
            STATE_BATTLE: begin
                led_rgb = 3'b010;   // Verde
            end

            // Resultado final
            STATE_RESULT: begin
                led_rgb = 3'b100;   // Rojo
            end

            // Estado no válido
            default: begin
                led_rgb = 3'b000;   // Apagado
            end

        endcase

    end

endmodule