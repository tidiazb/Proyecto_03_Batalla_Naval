`timescale 1ns / 1ps

// ============================================================
// Módulo: video_peripheral
//
// Descripción:
// Este módulo integra el periférico de video completo del sistema.
// Recibe las operaciones de escritura provenientes del procesador
// mediante el bus MMIO y utiliza video_mmio_interface para determinar
// si la dirección corresponde al espacio reservado para la memoria
// de video. Las escrituras válidas son enviadas al núcleo VGA,
// encargado de almacenar los tiles en la Video RAM y generar
// continuamente la imagen mediante las señales RGB, HSYNC y VSYNC.
// De esta forma, este módulo constituye la conexión entre el
// procesador RISC-V y todo el sistema gráfico VGA.
// ============================================================

module video_peripheral (
    input  logic        clk_100mhz,
    input  logic        rst,

    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    input  logic        we_i,

    output logic [31:0] video_rdata_o,

    output logic        hsync,
    output logic        vsync,
    output logic [3:0]  vga_red,
    output logic [3:0]  vga_green,
    output logic [3:0]  vga_blue
);

    logic        video_we;
    logic [8:0]  video_addr;
    logic [31:0] video_wdata;


    video_mmio_interface u_video_mmio_interface (
        .addr_i        (addr_i),
        .wdata_i       (wdata_i),
        .we_i          (we_i),
        .video_we_o    (video_we),
        .video_addr_o  (video_addr),
        .video_wdata_o (video_wdata)
    );


    vga_top u_vga_top (
        .clk_100mhz  (clk_100mhz),
        .rst         (rst),

        .video_we    (video_we),
        .video_addr  (video_addr),
        .video_wdata (video_wdata),
        .video_rdata (video_rdata_o),

        .hsync       (hsync),
        .vsync       (vsync),

        .vga_red     (vga_red),
        .vga_green   (vga_green),
        .vga_blue    (vga_blue)
    );

endmodule
