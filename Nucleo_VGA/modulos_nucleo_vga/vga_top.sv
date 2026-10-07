`timescale 1ns / 1ps

// ============================================================
// Módulo: vga_top
// Descripción:
//   Integra todos los bloques que forman el subsistema VGA.
//   A partir del reloj principal de 100 MHz, utiliza el PLL para
//   generar el reloj de píxel de 25 MHz y produce la temporización
//   necesaria para una salida VGA de 640x480.
//
//   La imagen se forma con dos capas:
//
//   1. Tiles (20x15 de 32x32 píxeles): las coordenadas del barrido
//      se convierten en una dirección de la Video RAM y el dato se
//      interpreta en tile_decoder. Solo se dibujan los tiles de los
//      dos tableros (video_layout); el resto de la pantalla es negro.
//
//   2. Texto (grilla de 40x30 celdas de 16x16 píxeles): hud_text
//      decide qué carácter va en cada celda y text_renderer lo
//      dibuja con la fuente 5x7 escalada al doble. El texto se
//      superpone a los tiles.
//
//   Estado del juego para los textos, sin cambios en el firmware:
//   - El firmware escribe el estado en tiles del HUD (fila 11:
//     fase+1, orientación+1, turno+1; filas 12 y 13: barcos
//     colocados por J1 y J2, código 1 = colocado). El barrido lee
//     esos tiles en cada cuadro y aquí se guardan en registros;
//     los tiles del HUD ya no se dibujan.
//   - Al recorrer los tableros se cuentan las casillas de fallo
//     (010) e impacto (011): en el tablero rival son disparos del
//     J1 y en el propio, del J2. El conteo se publica al inicio de
//     cada cuadro.
//   Todo ocurre en el dominio del reloj de píxel.
//
//   Un contador de cuadros genera la señal blink que hace parpadear
//   el cursor (bit 3 del tile): cambia cada 16 cuadros (~1.9 Hz).
//
//   El puerto A de la Video RAM queda expuesto para el procesador.
//   Debido a la lectura síncrona de la memoria, todas las señales
//   que acompañan al dato leído se registran un ciclo para mantener
//   el pipeline de video alineado.
// ============================================================

module vga_top (
    input  logic        clk_100mhz,
    input  logic        rst,

    input  logic        video_we,
    input  logic [8:0]  video_addr,
    input  logic [31:0] video_wdata,
    output logic [31:0] video_rdata,

    output logic        hsync,
    output logic        vsync,

    output logic [3:0]  vga_red,
    output logic [3:0]  vga_green,
    output logic [3:0]  vga_blue
);

    localparam logic [1:0] REGION_PROPIO = 2'b01;
    localparam logic [1:0] REGION_RIVAL  = 2'b10;

    logic pixel_clk;
    logic locked;
    logic rst_vga;

    logic [9:0] pixel_x;
    logic [9:0] pixel_y;
    logic       active_video;
    logic       frame_start;

    logic [4:0] tile_x;
    logic [3:0] tile_y;
    logic [4:0] local_x;
    logic [4:0] local_y;

    logic [8:0] tile_addr;

    logic [31:0] tile_data;

    logic [1:0] region;
    logic [2:0] board_x_unused;
    logic [2:0] board_y_unused;

    // Señales registradas (alineadas con tile_data)
    logic [4:0] local_x_d;
    logic [4:0] local_y_d;
    logic [4:0] tile_x_d;
    logic [3:0] tile_y_d;
    logic [1:0] region_d;
    logic       active_video_d;

    logic [4:0] frame_count;
    logic       blink;

    logic [3:0] tile_red;
    logic [3:0] tile_green;
    logic [3:0] tile_blue;

    // Estado del juego leído del HUD
    logic [2:0] hud_phase;
    logic [2:0] hud_orient;
    logic [2:0] hud_turn;
    logic [2:0] hud_j1_ship;
    logic [2:0] hud_j2_ship;

    logic [1:0] phase;
    logic       orient;
    logic       turn;
    logic [1:0] j1_placed;
    logic [1:0] j2_placed;

    // Conteo de casillas durante el cuadro y valores publicados
    logic       tile_first_px;
    logic [6:0] cnt_shots_j1, cnt_hits_j1, cnt_shots_j2, cnt_hits_j2;
    logic [6:0] shots_j1, hits_j1, shots_j2, hits_j2;

    // Capa de texto
    logic [6:0] hud_char;
    logic [2:0] hud_color;
    logic [6:0] hud_char_d;
    logic [2:0] hud_color_d;
    logic       text_on;
    logic [3:0] text_red;
    logic [3:0] text_green;
    logic [3:0] text_blue;

    logic [3:0] mix_red;
    logic [3:0] mix_green;
    logic [3:0] mix_blue;


    assign rst_vga = rst | ~locked;


    vga_clock u_vga_clock (
        .clk_in1   (clk_100mhz),
        .reset     (rst),
        .pixel_clk (pixel_clk),
        .locked    (locked)
    );


    vga_timing u_vga_timing (
        .pixel_clk    (pixel_clk),
        .rst          (rst_vga),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .hsync        (hsync),
        .vsync        (vsync),
        .active_video (active_video)
    );

    assign frame_start = (pixel_x == 10'd0) && (pixel_y == 10'd0);


    pixel_to_tile u_pixel_to_tile (
        .pixel_x (pixel_x),
        .pixel_y (pixel_y),
        .tile_x  (tile_x),
        .tile_y  (tile_y),
        .local_x (local_x),
        .local_y (local_y)
    );


    tile_address u_tile_address (
        .tile_x    (tile_x),
        .tile_y    (tile_y),
        .tile_addr (tile_addr)
    );


    video_layout u_video_layout (
        .tile_x_i  (tile_x),
        .tile_y_i  (tile_y),
        .region_o  (region),
        .board_x_o (board_x_unused),
        .board_y_o (board_y_unused)
    );


    video_ram u_video_ram (
        .clk_a   (clk_100mhz),
        .we_a    (video_we),
        .addr_a  (video_addr),
        .wdata_a (video_wdata),
        .rdata_a (video_rdata),

        .clk_b   (pixel_clk),
        .addr_b  (tile_addr),
        .rdata_b (tile_data)
    );


    // Texto de la celda actual: fila = pixel_y/16, columna = pixel_x/16
    hud_text u_hud_text (
        .row_i       (pixel_y[9:4]),
        .col_i       (pixel_x[9:4]),
        .phase_i     (phase),
        .orient_i    (orient),
        .turn_i      (turn),
        .j1_placed_i (j1_placed),
        .j2_placed_i (j2_placed),
        .shots_j1_i  (shots_j1),
        .hits_j1_i   (hits_j1),
        .shots_j2_i  (shots_j2),
        .hits_j2_i   (hits_j2),
        .char_o      (hud_char),
        .color_o     (hud_color)
    );


    // Etapa de alineación con la lectura síncrona de la Video RAM
    always_ff @(posedge pixel_clk) begin

        if (rst_vga) begin
            local_x_d      <= 5'd0;
            local_y_d      <= 5'd0;
            tile_x_d       <= 5'd0;
            tile_y_d       <= 4'd0;
            region_d       <= 2'b00;
            active_video_d <= 1'b0;
            hud_char_d     <= 7'h20;
            hud_color_d    <= 3'd0;
        end
        else begin
            local_x_d      <= local_x;
            local_y_d      <= local_y;
            tile_x_d       <= tile_x;
            tile_y_d       <= tile_y;
            region_d       <= region;
            active_video_d <= active_video;
            hud_char_d     <= hud_char;
            hud_color_d    <= hud_color;
        end

    end


    // --------------------------------------------------------
    // Lectura del estado del juego durante el barrido
    // --------------------------------------------------------

    // Primer píxel visible de cada tile: el tile se evalúa una
    // sola vez por cuadro.
    assign tile_first_px = active_video_d &&
                           (local_x_d == 5'd0) && (local_y_d == 5'd0);

    always_ff @(posedge pixel_clk) begin

        if (rst_vga) begin
            hud_phase    <= 3'd0;
            hud_orient   <= 3'd0;
            hud_turn     <= 3'd0;
            hud_j1_ship  <= 3'b000;
            hud_j2_ship  <= 3'b000;

            cnt_shots_j1 <= 7'd0;
            cnt_hits_j1  <= 7'd0;
            cnt_shots_j2 <= 7'd0;
            cnt_hits_j2  <= 7'd0;
            shots_j1     <= 7'd0;
            hits_j1      <= 7'd0;
            shots_j2     <= 7'd0;
            hits_j2      <= 7'd0;
        end
        else begin

            // Tiles del HUD escritos por el firmware
            if (tile_first_px) begin
                if (tile_y_d == 4'd11) begin
                    if (tile_x_d == 5'd1) hud_phase  <= tile_data[2:0];
                    if (tile_x_d == 5'd2) hud_orient <= tile_data[2:0];
                    if (tile_x_d == 5'd3) hud_turn   <= tile_data[2:0];
                end
                if ((tile_y_d == 4'd12) &&
                    (tile_x_d >= 5'd1) && (tile_x_d <= 5'd3))
                    hud_j1_ship[tile_x_d[1:0] - 2'd1] <= (tile_data[2:0] == 3'b001);
                if ((tile_y_d == 4'd13) &&
                    (tile_x_d >= 5'd1) && (tile_x_d <= 5'd3))
                    hud_j2_ship[tile_x_d[1:0] - 2'd1] <= (tile_data[2:0] == 3'b001);
            end

            // Conteo de fallos e impactos de cada tablero
            if (frame_start) begin
                shots_j1     <= cnt_shots_j1;
                hits_j1      <= cnt_hits_j1;
                shots_j2     <= cnt_shots_j2;
                hits_j2      <= cnt_hits_j2;
                cnt_shots_j1 <= 7'd0;
                cnt_hits_j1  <= 7'd0;
                cnt_shots_j2 <= 7'd0;
                cnt_hits_j2  <= 7'd0;
            end
            else if (tile_first_px && (tile_data[2:1] == 2'b01)) begin
                // 010 fallo, 011 impacto
                if (region_d == REGION_RIVAL) begin
                    cnt_shots_j1 <= cnt_shots_j1 + 7'd1;
                    if (tile_data[0])
                        cnt_hits_j1 <= cnt_hits_j1 + 7'd1;
                end
                else if (region_d == REGION_PROPIO) begin
                    cnt_shots_j2 <= cnt_shots_j2 + 7'd1;
                    if (tile_data[0])
                        cnt_hits_j2 <= cnt_hits_j2 + 7'd1;
                end
            end

        end

    end

    // Decodificación del HUD (el firmware escribe valor + 1)
    always_comb begin
        case (hud_phase)
            3'd2:    phase = 2'd1;
            3'd3:    phase = 2'd2;
            default: phase = 2'd0;
        endcase

        orient    = (hud_orient == 3'd2);
        turn      = (hud_turn   == 3'd2);
        j1_placed = {1'b0, hud_j1_ship[0]} + {1'b0, hud_j1_ship[1]} +
                    {1'b0, hud_j1_ship[2]};
        j2_placed = {1'b0, hud_j2_ship[0]} + {1'b0, hud_j2_ship[1]} +
                    {1'b0, hud_j2_ship[2]};
    end


    // Contador de cuadros para el parpadeo del cursor. Cambia al
    // inicio del cuadro, así todo el cuadro usa el mismo blink.
    always_ff @(posedge pixel_clk) begin

        if (rst_vga)
            frame_count <= 5'd0;
        else if (frame_start)
            frame_count <= frame_count + 5'd1;

    end

    assign blink = frame_count[4];


    tile_decoder u_tile_decoder (
        .tile_data (tile_data),
        .local_x   (local_x_d),
        .local_y   (local_y_d),
        .blink     (blink),
        .red       (tile_red),
        .green     (tile_green),
        .blue      (tile_blue)
    );


    // Las celdas de texto miden 16x16: la posición dentro de la
    // celda son los 4 bits bajos de la posición dentro del tile.
    text_renderer u_text_renderer (
        .text_cell_i ({5'd0, hud_color_d, 1'b0, hud_char_d}),
        .local_x_i   (local_x_d[3:0]),
        .local_y_i   (local_y_d[3:0]),
        .text_on_o   (text_on),
        .red_o       (text_red),
        .green_o     (text_green),
        .blue_o      (text_blue)
    );


    // Texto encima; los tiles solo dentro de los tableros
    always_comb begin
        mix_red   = 4'h0;
        mix_green = 4'h0;
        mix_blue  = 4'h0;

        if (text_on) begin
            mix_red   = text_red;
            mix_green = text_green;
            mix_blue  = text_blue;
        end
        else if ((region_d == REGION_PROPIO) ||
                 (region_d == REGION_RIVAL)) begin
            mix_red   = tile_red;
            mix_green = tile_green;
            mix_blue  = tile_blue;
        end
    end


    rgb_output u_rgb_output (
        .active_video (active_video_d),

        .red_in       (mix_red),
        .green_in     (mix_green),
        .blue_in      (mix_blue),

        .vga_red      (vga_red),
        .vga_green    (vga_green),
        .vga_blue     (vga_blue)
    );

endmodule
