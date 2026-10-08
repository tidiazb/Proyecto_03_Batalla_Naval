`timescale 1ns / 1ps

// ============================================================
// Módulo: hud_text
// Descripción:
//   Genera los textos de la pantalla del Jugador 1 a partir del
//   estado del juego. Recibe la celda de texto actual (fila 0..29,
//   columna 0..39 de la grilla de 16x16 píxeles) y entrega el
//   carácter ASCII y el color que deben dibujarse en ella.
//
//   El estado lo obtiene vga_top leyendo la Video RAM durante el
//   barrido (tiles del HUD que escribe el firmware y conteo de
//   casillas de los tableros), por lo que el firmware no cambia.
//
//   Distribución (los tableros ocupan las filas de texto 4..19):
//     0      título
//     1      estado de la partida (color según la situación)
//     3      nombres de los mapas
//     21     leyenda de colores
//     23     colocación (fase 0) o resumen de disparos
//     25     orientación del barco (solo mientras se coloca)
//     27-28  instrucciones de los botones de la FPGA
//
//   Cada línea es una constante de 40 caracteres; '@' marca
//   posiciones donde se insertan dígitos. Colores (text_renderer):
//   0 blanco, 1 amarillo, 2 verde, 3 rojo, 4 turquesa, 5 gris,
//   6 naranja, 7 celeste.
//
//   Archivo generado: las columnas de los dígitos se calcularon
//   junto con las constantes.
// ============================================================

module hud_text (
    input  logic [5:0] row_i,
    input  logic [5:0] col_i,

    input  logic [1:0] phase_i,      // 0 colocación, 1 batalla, 2 fin
    input  logic       orient_i,     // 0 horizontal, 1 vertical
    input  logic       turn_i,       // 0 Jugador 1, 1 Jugador 2 (en fin: ganador)
    input  logic [1:0] j1_placed_i,  // barcos colocados 0..3
    input  logic [1:0] j2_placed_i,
    input  logic [6:0] shots_j1_i,   // disparos del J1 (tablero rival)
    input  logic [6:0] hits_j1_i,
    input  logic [6:0] shots_j2_i,   // disparos del J2 (tablero propio)
    input  logic [6:0] hits_j2_i,

    output logic [6:0] char_o,
    output logic [2:0] color_o
);

    localparam logic [319:0] TITLE      = "               JUGADOR 1                ";
    localparam logic [319:0] COLOCA     = "     COLOCA TU BARCO DE @ CASILLAS      ";
    localparam logic [319:0] ESPERA     = "         ESPERANDO AL JUGADOR 2         ";
    localparam logic [319:0] TU_TURNO   = "   TU TURNO - DISPARA AL MAPA ENEMIGO   ";
    localparam logic [319:0] TURNO_J2   = "          TURNO DEL JUGADOR 2           ";
    localparam logic [319:0] WIN        = "        VICTORIA - FIN DEL JUEGO        ";
    localparam logic [319:0] LOSE       = "        DERROTA - FIN DEL JUEGO         ";
    localparam logic [319:0] MAPAS      = "    NUESTRO MAPA        MAPA ENEMIGO    ";
    localparam logic [319:0] LEYENDA    = "     BARCO   IMPACTO   FALLO   AGUA     ";
    localparam logic [319:0] COLOCADOS  = "   BARCOS COLOCADOS  J1: @/3  J2: @/3   ";
    localparam logic [319:0] RESUMEN    = " DISPAROS J1/J2: @@/@@  IMPACTOS: @@/@@ ";
    localparam logic [319:0] ORIENT_H   = "        ORIENTACION: HORIZONTAL         ";
    localparam logic [319:0] ORIENT_V   = "         ORIENTACION: VERTICAL          ";
    localparam logic [319:0] AYUDA_COL1 = "  BOTONES: MOVER EL BARCO   SW0: ROTAR  ";
    localparam logic [319:0] AYUDA_COL2 = "         BOTON CENTRAL: COLOCAR         ";
    localparam logic [319:0] AYUDA_DIS1 = "        BOTONES: MOVER EL CURSOR        ";
    localparam logic [319:0] AYUDA_DIS2 = "        BOTON CENTRAL: DISPARAR         ";
    localparam logic [319:0] AYUDA_FIN  = "           SW1: NUEVA PARTIDA           ";

    // Carácter de la columna col de una línea (col 0 a la izquierda)
    function automatic logic [7:0] pick(input logic [319:0] line,
                                        input logic [5:0]   col);
        pick = line[(6'd39 - col) * 8 +: 8];
    endfunction

    // Dígitos decimales de un valor 0..99 (decenas por comparación,
    // unidades = v - 10*decenas)
    function automatic logic [3:0] tens_val(input logic [6:0] v);
        if      (v >= 7'd90) tens_val = 4'd9;
        else if (v >= 7'd80) tens_val = 4'd8;
        else if (v >= 7'd70) tens_val = 4'd7;
        else if (v >= 7'd60) tens_val = 4'd6;
        else if (v >= 7'd50) tens_val = 4'd5;
        else if (v >= 7'd40) tens_val = 4'd4;
        else if (v >= 7'd30) tens_val = 4'd3;
        else if (v >= 7'd20) tens_val = 4'd2;
        else if (v >= 7'd10) tens_val = 4'd1;
        else                 tens_val = 4'd0;
    endfunction

    function automatic logic [7:0] tens(input logic [6:0] v);
        tens = 8'h30 + {4'd0, tens_val(v)};
    endfunction

    function automatic logic [7:0] ones(input logic [6:0] v);
        logic [6:0] t10;
        logic [6:0] r;
        t10  = ({3'd0, tens_val(v)} << 3) + ({3'd0, tens_val(v)} << 1);
        r    = v - t10;
        ones = 8'h30 + {1'b0, r};
    endfunction

    logic [7:0] ch;

    always_comb begin
        ch      = 8'h20;
        color_o = 3'd0;

        if (col_i < 6'd40) begin
            case (row_i)

                6'd0: begin
                    ch      = pick(TITLE, col_i);
                    color_o = 3'd0;
                end

                6'd1: begin
                    if (phase_i == 2'd0) begin
                        if (j1_placed_i != 2'd3) begin
                            ch      = pick(COLOCA, col_i);
                            color_o = 3'd1;
                            if (col_i == 6'd24)
                                ch = 8'h30 + {6'd0, 2'd3 - j1_placed_i} + 8'd1;
                        end
                        else begin
                            ch      = pick(ESPERA, col_i);
                            color_o = 3'd6;
                        end
                    end
                    else if (phase_i == 2'd1) begin
                        if (!turn_i) begin
                            ch      = pick(TU_TURNO, col_i);
                            color_o = 3'd2;
                        end
                        else begin
                            ch      = pick(TURNO_J2, col_i);
                            color_o = 3'd6;
                        end
                    end
                    else begin
                        if (!turn_i) begin
                            ch      = pick(WIN, col_i);
                            color_o = 3'd2;
                        end
                        else begin
                            ch      = pick(LOSE, col_i);
                            color_o = 3'd3;
                        end
                    end
                end

                6'd3: begin
                    ch      = pick(MAPAS, col_i);
                    color_o = 3'd0;
                end

                6'd21: begin
                    ch = pick(LEYENDA, col_i);
                    if (col_i < 6'd12)      color_o = 3'd5;  // BARCO gris
                    else if (col_i < 6'd22) color_o = 3'd3;  // IMPACTO rojo
                    else if (col_i < 6'd30) color_o = 3'd4;  // FALLO turquesa
                    else                    color_o = 3'd7;  // AGUA celeste
                end

                6'd23: begin
                    color_o = 3'd0;
                    if (phase_i == 2'd0) begin
                        ch = pick(COLOCADOS, col_i);
                        if (col_i == 6'd25) ch = 8'h30 + {6'd0, j1_placed_i};
                        if (col_i == 6'd34) ch = 8'h30 + {6'd0, j2_placed_i};
                    end
                    else begin
                        ch = pick(RESUMEN, col_i);
                        if (col_i == 6'd17) ch = tens(shots_j1_i);
                        if (col_i == 6'd18) ch = ones(shots_j1_i);
                        if (col_i == 6'd20) ch = tens(shots_j2_i);
                        if (col_i == 6'd21) ch = ones(shots_j2_i);
                        if (col_i == 6'd34) ch = tens(hits_j1_i);
                        if (col_i == 6'd35) ch = ones(hits_j1_i);
                        if (col_i == 6'd37) ch = tens(hits_j2_i);
                        if (col_i == 6'd38) ch = ones(hits_j2_i);
                    end
                end

                6'd25: begin
                    color_o = 3'd7;
                    if ((phase_i == 2'd0) && (j1_placed_i != 2'd3))
                        ch = orient_i ? pick(ORIENT_V, col_i)
                                      : pick(ORIENT_H, col_i);
                end

                6'd27: begin
                    color_o = 3'd5;
                    if ((phase_i == 2'd0) && (j1_placed_i != 2'd3))
                        ch = pick(AYUDA_COL1, col_i);
                    else if ((phase_i == 2'd1) && !turn_i)
                        ch = pick(AYUDA_DIS1, col_i);
                    else if (phase_i == 2'd2)
                        ch = pick(AYUDA_FIN, col_i);
                end

                6'd28: begin
                    color_o = 3'd5;
                    if ((phase_i == 2'd0) && (j1_placed_i != 2'd3))
                        ch = pick(AYUDA_COL2, col_i);
                    else if ((phase_i == 2'd1) && !turn_i)
                        ch = pick(AYUDA_DIS2, col_i);
                end

                default: ch = 8'h20;

            endcase
        end

        char_o = ch[6:0];
    end

endmodule
