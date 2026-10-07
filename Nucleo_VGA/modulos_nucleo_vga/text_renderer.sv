`timescale 1ns / 1ps

// ============================================================
// Módulo: text_renderer
// Descripción:
//   Convierte la celda de texto leída de text_ram y la posición
//   del píxel dentro de la celda (16x16) en un píxel de texto.
//
//   Cada carácter de la fuente 5x7 se dibuja escalado al doble
//   (10x14 píxeles), centrado horizontalmente en la celda:
//   columnas 3..12 y filas 1..14. El resto de la celda queda
//   transparente, lo que deja una separación entre letras y
//   entre renglones.
//
//   Las minúsculas (0x60-0x7F) se muestran como mayúsculas. Los
//   códigos menores o iguales a 0x20 (espacio) son transparentes.
//
//   Paleta de text_cell_i[10:8]:
//     0 blanco, 1 amarillo, 2 verde, 3 rojo,
//     4 turquesa, 5 gris, 6 naranja, 7 celeste
//
//   text_on_o indica si el píxel pertenece al trazo de una letra;
//   en ese caso vga_top usa el color del texto en lugar del tile.
// ============================================================

module text_renderer (
    input  logic [15:0] text_cell_i,
    input  logic [3:0]  local_x_i,
    input  logic [3:0]  local_y_i,

    output logic        text_on_o,
    output logic [3:0]  red_o,
    output logic [3:0]  green_o,
    output logic [3:0]  blue_o
);

    logic [6:0] code;
    logic [5:0] char_idx;
    logic       visible_char;
    logic [3:0] glyph_x;
    logic [3:0] glyph_y;
    logic       in_glyph;
    logic [2:0] font_row;
    logic [2:0] font_col;
    logic [4:0] font_bits;

    font_rom u_font_rom (
        .char_idx_i (char_idx),
        .row_i      (font_row),
        .bits_o     (font_bits)
    );

    always_comb begin
        // Minúsculas -> mayúsculas
        if (text_cell_i[6:5] == 2'b11)
            code = text_cell_i[6:0] - 7'h20;
        else
            code = text_cell_i[6:0];

        visible_char = (code > 7'h20);
        char_idx     = code[5:0] - 6'h20;

        // Posición dentro del glifo de 10x14 (escala 2x)
        glyph_x  = local_x_i - 4'd3;
        glyph_y  = local_y_i - 4'd1;
        in_glyph = (local_x_i >= 4'd3) && (local_x_i <= 4'd12) &&
                   (local_y_i >= 4'd1) && (local_y_i <= 4'd14);

        font_col = glyph_x[3:1];
        font_row = glyph_y[3:1];
    end

    // Bloque separado: usa la salida de la ROM, que depende del
    // bloque anterior (así no aparece como lazo combinacional).
    always_comb begin
        text_on_o = visible_char && in_glyph &&
                    font_bits[3'd4 - font_col];

        case (text_cell_i[10:8])
            3'd0: begin red_o = 4'hF; green_o = 4'hF; blue_o = 4'hF; end
            3'd1: begin red_o = 4'hF; green_o = 4'hF; blue_o = 4'h0; end
            3'd2: begin red_o = 4'h0; green_o = 4'hF; blue_o = 4'h0; end
            3'd3: begin red_o = 4'hF; green_o = 4'h2; blue_o = 4'h2; end
            3'd4: begin red_o = 4'h0; green_o = 4'hF; blue_o = 4'hF; end
            3'd5: begin red_o = 4'hA; green_o = 4'hA; blue_o = 4'hA; end
            3'd6: begin red_o = 4'hF; green_o = 4'h8; blue_o = 4'h0; end
            default: begin red_o = 4'h4; green_o = 4'hA; blue_o = 4'hF; end
        endcase
    end

endmodule
