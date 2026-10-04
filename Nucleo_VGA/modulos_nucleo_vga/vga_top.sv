`timescale 1ns / 1ps

// ============================================================
// Módulo: vga_top
// Descripción:
//   Integra todos los bloques que forman el subsistema VGA.
//   A partir del reloj principal de 100 MHz, utiliza el PLL para
//   generar el reloj de píxel de 25 MHz y produce la temporización
//   necesaria para una salida VGA de 640x480.
//
//   Las coordenadas del barrido se convierten en posiciones de
//   tiles de 32x32 píxeles y posteriormente en direcciones para
//   acceder a la Video RAM de 300 palabras de 32 bits. El dato
//   leído de memoria se interpreta para generar el color RGB de
//   cada casilla y finalmente se habilita únicamente durante la
//   región visible de la pantalla.
//
//   Un contador de cuadros (frames) genera la señal blink que
//   hace parpadear el cursor (bit 3 del tile). Con 60 cuadros/s
//   y el bit 4 del contador, el cursor cambia cada 16 cuadros,
//   un parpadeo de ~1.9 Hz.
//
//   El módulo también expone el puerto A de la Video RAM para que
//   el sistema principal pueda actualizar los datos mostrados.
//   Debido a la lectura síncrona de la memoria, las coordenadas
//   internas y active_video se registran un ciclo para mantener
//   el pipeline de video alineado con el dato leído.
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

    logic pixel_clk;
    logic locked;
    logic rst_vga;

    logic [9:0] pixel_x;
    logic [9:0] pixel_y;
    logic       active_video;

    logic [4:0] tile_x;
    logic [3:0] tile_y;
    logic [4:0] local_x;
    logic [4:0] local_y;

    logic [8:0] tile_addr;

    logic [31:0] tile_data;

    logic [4:0] local_x_d;
    logic [4:0] local_y_d;
    logic       active_video_d;

    logic [4:0] frame_count;
    logic       blink;

    logic [3:0] red_internal;
    logic [3:0] green_internal;
    logic [3:0] blue_internal;


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


    always_ff @(posedge pixel_clk) begin

        if (rst_vga) begin
            local_x_d      <= 5'd0;
            local_y_d      <= 5'd0;
            active_video_d <= 1'b0;
        end
        else begin
            local_x_d      <= local_x;
            local_y_d      <= local_y;
            active_video_d <= active_video;
        end

    end


    // Contador de cuadros: avanza una vez por cuadro, en la
    // esquina (0,0) del barrido. Como cambia al inicio del
    // cuadro (ese primer píxel es borde blanco), todo el cuadro
    // se dibuja con el mismo valor de blink y el cursor nunca
    // cambia a mitad de pantalla.
    always_ff @(posedge pixel_clk) begin

        if (rst_vga)
            frame_count <= 5'd0;
        else if ((pixel_x == 10'd0) && (pixel_y == 10'd0))
            frame_count <= frame_count + 5'd1;

    end

    assign blink = frame_count[4];


    tile_decoder u_tile_decoder (
        .tile_data (tile_data),
        .local_x   (local_x_d),
        .local_y   (local_y_d),
        .blink     (blink),
        .red       (red_internal),
        .green     (green_internal),
        .blue      (blue_internal)
    );


    rgb_output u_rgb_output (
        .active_video (active_video_d),

        .red_in       (red_internal),
        .green_in     (green_internal),
        .blue_in      (blue_internal),

        .vga_red      (vga_red),
        .vga_green    (vga_green),
        .vga_blue     (vga_blue)
    );

endmodule
