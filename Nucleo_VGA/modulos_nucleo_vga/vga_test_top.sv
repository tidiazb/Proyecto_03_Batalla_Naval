`timescale 1ns / 1ps

/*
 * Módulo: vga_test_top
 *
 * Descripción:
 * Módulo superior utilizado para realizar la prueba física del generador VGA.
 * Recibe el reloj principal de 100 MHz de la FPGA y utiliza el Clocking Wizard
 * para generar el reloj de píxel de 25 MHz. La señal locked del PLL se utiliza
 * para mantener el sistema VGA en reset hasta que el reloj sea estable.
 *
 * El módulo vga_timing genera las coordenadas de píxel, las señales HSYNC y
 * VSYNC y la indicación de video activo correspondiente a una resolución
 * VGA de 640x480. Durante la región visible se genera un patrón sencillo de
 * barras verticales de colores que permite comprobar físicamente que la
 * temporización y las salidas RGB funcionan correctamente en un monitor VGA.
 * Fuera del área visible las señales RGB permanecen en cero.
 */

module vga_test_top (
    input  logic       clk_100mhz,
    input  logic       rst,

    output logic       hsync,
    output logic       vsync,

    output logic [3:0] vga_red,
    output logic [3:0] vga_green,
    output logic [3:0] vga_blue
);

    logic       pixel_clk;
    logic       locked;
    logic       rst_vga;

    logic [9:0] pixel_x;
    logic [9:0] pixel_y;
    logic       active_video;


    vga_clock u_vga_clock (
        .clk_in1   (clk_100mhz),
        .reset     (rst),
        .pixel_clk (pixel_clk),
        .locked    (locked)
    );


    assign rst_vga = rst | ~locked;


    vga_timing u_vga_timing (
        .pixel_clk    (pixel_clk),
        .rst          (rst_vga),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .hsync        (hsync),
        .vsync        (vsync),
        .active_video (active_video)
    );


    always_comb begin

        vga_red   = 4'h0;
        vga_green = 4'h0;
        vga_blue  = 4'h0;

        if (active_video) begin

            if (pixel_x < 10'd80) begin
                vga_red   = 4'hF;
                vga_green = 4'h0;
                vga_blue  = 4'h0;
            end

            else if (pixel_x < 10'd160) begin
                vga_red   = 4'h0;
                vga_green = 4'hF;
                vga_blue  = 4'h0;
            end

            else if (pixel_x < 10'd240) begin
                vga_red   = 4'h0;
                vga_green = 4'h0;
                vga_blue  = 4'hF;
            end

            else if (pixel_x < 10'd320) begin
                vga_red   = 4'hF;
                vga_green = 4'hF;
                vga_blue  = 4'h0;
            end

            else if (pixel_x < 10'd400) begin
                vga_red   = 4'h0;
                vga_green = 4'hF;
                vga_blue  = 4'hF;
            end

            else if (pixel_x < 10'd480) begin
                vga_red   = 4'hF;
                vga_green = 4'h0;
                vga_blue  = 4'hF;
            end

            else if (pixel_x < 10'd560) begin
                vga_red   = 4'hF;
                vga_green = 4'hF;
                vga_blue  = 4'hF;
            end

            else begin
                vga_red   = 4'h8;
                vga_green = 4'h8;
                vga_blue  = 4'h8;
            end

        end

    end

endmodule