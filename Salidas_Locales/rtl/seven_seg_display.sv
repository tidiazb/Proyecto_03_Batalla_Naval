`timescale 1ns / 1ps

//============================================================
// Módulo: seven_seg_display
// Issue #10 - Displays de 7 segmentos
//
// Función:
// - Recibe las victorias acumuladas del Jugador 1 y Jugador 2.
// - Cada jugador puede tener valores de 00 a 99.
// - Utiliza 4 displays de 7 segmentos.
// - Separa cada valor en decenas y unidades.
// - Multiplexa los cuatro displays.
//
// Distribución:
//
//      AN3     AN2     AN1     AN0
//     J2 DEC  J2 UNI  J1 DEC  J1 UNI
//
// Ejemplo:
//     player1 = 37
//     player2 = 84
//
// Display:
//            8 4 3 7
//
// Los ánodos y segmentos se consideran activos en bajo.
//============================================================

module seven_seg_display #(
    // Este parámetro permite acelerar la simulación.
    // Para hardware se puede utilizar un valor mayor.
    parameter integer REFRESH_BITS = 18
)(
    input  logic       clk,
    input  logic       rst,

    // Contadores de victorias de ambos jugadores
    input  logic [7:0] player1,
    input  logic [7:0] player2,

    // Salidas hacia el display
    output logic [6:0] seg,
    output logic [3:0] an
);

    //========================================================
    // Señales internas
    //========================================================

    logic [REFRESH_BITS-1:0] refresh_counter;

    logic [1:0] display_select;

    logic [3:0] current_digit;

    logic [3:0] p1_units;
    logic [3:0] p1_tens;

    logic [3:0] p2_units;
    logic [3:0] p2_tens;


    //========================================================
    // Separación de unidades y decenas
    //
    // Ejemplo:
    //
    // player1 = 37
    //
    // p1_tens  = 3
    // p1_units = 7
    //========================================================

    always_comb begin

        // Protección para mantener el rango solicitado 00-99
        if (player1 <= 8'd99) begin
            p1_tens  = player1 / 10;
            p1_units = player1 % 10;
        end
        else begin
            p1_tens  = 4'd9;
            p1_units = 4'd9;
        end

        if (player2 <= 8'd99) begin
            p2_tens  = player2 / 10;
            p2_units = player2 % 10;
        end
        else begin
            p2_tens  = 4'd9;
            p2_units = 4'd9;
        end

    end


    //========================================================
    // Contador para multiplexado
    //========================================================

    always_ff @(posedge clk) begin

        if (rst) begin
            refresh_counter <= '0;
        end
        else begin
            refresh_counter <= refresh_counter + 1'b1;
        end

    end


    //========================================================
    // Selección del display
    //
    // Se utilizan los dos bits superiores del contador.
    //========================================================

    assign display_select =
        refresh_counter[REFRESH_BITS-1 -: 2];


    //========================================================
    // Multiplexado de los 4 displays
    //
    // an activo en bajo:
    //
    // 1110 -> AN0
    // 1101 -> AN1
    // 1011 -> AN2
    // 0111 -> AN3
    //========================================================

    always_comb begin

        // Valores por defecto
        an            = 4'b1111;
        current_digit = 4'd0;

        case (display_select)

            // Jugador 1 - unidades
            2'b00: begin
                an            = 4'b1110;
                current_digit = p1_units;
            end

            // Jugador 1 - decenas
            2'b01: begin
                an            = 4'b1101;
                current_digit = p1_tens;
            end

            // Jugador 2 - unidades
            2'b10: begin
                an            = 4'b1011;
                current_digit = p2_units;
            end

            // Jugador 2 - decenas
            2'b11: begin
                an            = 4'b0111;
                current_digit = p2_tens;
            end

            default: begin
                an            = 4'b1111;
                current_digit = 4'd0;
            end

        endcase

    end


    //========================================================
    // Decodificador de 7 segmentos
    //
    // Utilizamos el módulo seven_seg_decoder.sv
    // que acabamos de crear.
    //========================================================

    seven_seg_decoder decoder_inst (
        .digit (current_digit),
        .seg   (seg)
    );


endmodule