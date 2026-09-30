`timescale 1ns / 1ps

// ============================================================
// Módulo: rgb_output
// Descripción:
//   Controla las señales RGB finales que serán enviadas hacia
//   la salida VGA. Recibe el color generado por el decodificador
//   de tiles y utiliza active_video para determinar si el píxel
//   actual pertenece a la región visible de 640x480.
//
//   Cuando active_video está activo, el módulo permite el paso
//   de los tres componentes de color de 4 bits. Durante los
//   intervalos no visibles del barrido VGA, las salidas RGB se
//   fuerzan a cero para mantener la pantalla en negro durante
//   los períodos de blanking y sincronización.
// ============================================================

module rgb_output (
    input  logic       active_video,

    input  logic [3:0] red_in,
    input  logic [3:0] green_in,
    input  logic [3:0] blue_in,

    output logic [3:0] vga_red,
    output logic [3:0] vga_green,
    output logic [3:0] vga_blue
);

    always_comb begin

        if (active_video) begin
            vga_red   = red_in;
            vga_green = green_in;
            vga_blue  = blue_in;
        end
        else begin
            vga_red   = 4'h0;
            vga_green = 4'h0;
            vga_blue  = 4'h0;
        end

    end

endmodule
