`timescale 1ns / 1ps

// ============================================================
// Módulo: vga_timing
// Descripción:
//   Genera las señales de temporización para una salida VGA
//   con resolución visible de 640x480 píxeles.
//
//   A partir de un reloj de píxel de 25 MHz, mantiene los
//   contadores horizontal y vertical que representan la
//   posición actual del barrido de la pantalla. El contador
//   horizontal recorre las 800 posiciones de cada línea y el
//   vertical las 525 líneas que forman un cuadro completo.
//
//   Con estos contadores genera las señales de sincronización
//   horizontal (hsync) y vertical (vsync), además de
//   active_video, que indica cuándo el barrido se encuentra
//   dentro del área visible de 640x480 píxeles.
//
//   Las salidas pixel_x y pixel_y entregan la posición actual
//   del barrido y posteriormente serán utilizadas por el
//   sistema de video para determinar qué debe mostrarse.
// ============================================================

module vga_timing (
    input  logic       pixel_clk,
    input  logic       rst,

    output logic [9:0] pixel_x,
    output logic [9:0] pixel_y,
    output logic       hsync,
    output logic       vsync,
    output logic       active_video
);

    logic [9:0] h_count;
    logic [9:0] v_count;

    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end
        else begin
            if (h_count == 10'd799) begin
                h_count <= 10'd0;

                if (v_count == 10'd524)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 10'd1;
            end
            else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    always_comb begin
        pixel_x = h_count;
        pixel_y = v_count;

        active_video = (h_count < 10'd640) &&
                       (v_count < 10'd480);

        hsync = ~((h_count >= 10'd656) &&
                  (h_count <  10'd752));

        vsync = ~((v_count >= 10'd490) &&
                  (v_count <  10'd492));
    end

endmodule