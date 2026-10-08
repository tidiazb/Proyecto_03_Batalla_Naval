`timescale 1ns / 1ps

module tb_renderizado_final;

    logic        clk_100mhz;
    logic        rst;

    logic [31:0] addr_i;
    logic [31:0] wdata_i;
    logic        we_i;

    logic [31:0] video_rdata_o;

    logic        hsync;
    logic        vsync;

    logic [3:0]  vga_red;
    logic [3:0]  vga_green;
    logic [3:0]  vga_blue;

    integer errores;


    // ============================================================
    // DUT
    // ============================================================

    video_peripheral dut (
        .clk_100mhz   (clk_100mhz),
        .rst          (rst),

        .addr_i       (addr_i),
        .wdata_i      (wdata_i),
        .we_i         (we_i),

        .video_rdata_o(video_rdata_o),

        .hsync        (hsync),
        .vsync        (vsync),

        .vga_red      (vga_red),
        .vga_green    (vga_green),
        .vga_blue     (vga_blue)
    );


    // ============================================================
    // RELOJ 100 MHz
    // ============================================================

    initial begin
        clk_100mhz = 1'b0;

        forever #5 clk_100mhz = ~clk_100mhz;
    end


    // ============================================================
    // ESCRITURA MMIO
    // ============================================================

    task automatic escribir_tile(
        input logic [31:0] direccion,
        input logic [31:0] dato
    );
    begin

        @(negedge clk_100mhz);

        addr_i  = direccion;
        wdata_i = dato;
        we_i    = 1'b1;

        @(negedge clk_100mhz);

        we_i = 1'b0;

        $display(
            "WRITE: addr=%08h dato=%08h",
            direccion,
            dato
        );

    end
    endtask


    // ============================================================
    // VERIFICAR RGB
    // ============================================================

    task automatic verificar_rgb(
        input integer tile_x_esperado,
        input integer tile_y_esperado,

        input logic [3:0] red_esperado,
        input logic [3:0] green_esperado,
        input logic [3:0] blue_esperado,

        input [8*40-1:0] nombre
    );
    begin

        // Esperar a que VGA llegue aproximadamente al centro
        // del tile. local_x_d/local_y_d están alineados con
        // la salida síncrona de la Video RAM.

        wait (
            dut.u_vga_top.tile_x == tile_x_esperado &&
            dut.u_vga_top.tile_y == tile_y_esperado &&
            dut.u_vga_top.local_x_d == 5'd16 &&
            dut.u_vga_top.local_y_d == 5'd16
        );

        #1;

        if (
            vga_red   !== red_esperado   ||
            vga_green !== green_esperado ||
            vga_blue  !== blue_esperado
        ) begin

            $display(
                "FAIL %s: RGB=%h%h%h esperado=%h%h%h",
                nombre,
                vga_red,
                vga_green,
                vga_blue,
                red_esperado,
                green_esperado,
                blue_esperado
            );

            errores = errores + 1;

        end
        else begin

            $display(
                "PASS %s: tile=(%0d,%0d) RGB=%h%h%h",
                nombre,
                tile_x_esperado,
                tile_y_esperado,
                vga_red,
                vga_green,
                vga_blue
            );

        end

    end
    endtask


    // ============================================================
    // PRUEBA PRINCIPAL
    // ============================================================

    initial begin

        errores = 0;

        rst     = 1'b1;
        addr_i  = 32'd0;
        wdata_i = 32'd0;
        we_i    = 1'b0;


        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        repeat (10)
            @(posedge clk_100mhz);

        rst = 1'b0;


        // Esperar que el PLL se estabilice
        wait (dut.u_vga_top.locked === 1'b1);

        repeat (5)
            @(posedge clk_100mhz);


        // ========================================================
        // ESCRITURAS DEL CPU
        // ========================================================

        // Tablero propio
        // Tile (4,5)
        // Código 001 = barco
        escribir_tile(
            32'h0001_11A0,
            32'h0000_0001
        );


        // Tablero rival
        // Tile (14,6)
        // Código 011 = impacto
        escribir_tile(
            32'h0001_1218,
            32'h0000_0003
        );


        // Región HUD
        // Tile (5,12)
        // Código 100 = indicador/selección
        escribir_tile(
            32'h0001_13D4,
            32'h0000_0004
        );


        // ========================================================
        // VERIFICAR RENDERIZADO
        // ========================================================

        // 001 = barco = gris
        verificar_rgb(
            4,
            5,
            4'h8,
            4'h8,
            4'h8,
            "TABLERO PROPIO"
        );


        // 011 = impacto = rojo
        verificar_rgb(
            14,
            6,
            4'hF,
            4'h0,
            4'h0,
            "TABLERO RIVAL"
        );


        // 100 = selección = amarillo
        verificar_rgb(
            5,
            12,
            4'hF,
            4'hF,
            4'h0,
            "HUD"
        );


        // ========================================================
        // RESULTADO
        // ========================================================

        $display("");
        $display("==============================================");

        if (errores == 0)
            $display(
                "TB RENDERIZADO FINAL: TODAS LAS PRUEBAS PASARON"
            );
        else
            $display(
                "TB RENDERIZADO FINAL: %0d ERRORES",
                errores
            );

        $display("==============================================");
        $display("");

        $finish;

    end


    // ============================================================
    // TIMEOUT
    // ============================================================

    initial begin

        #25_000_000;

        $display("");
        $display("ERROR: TIMEOUT EN TB RENDERIZADO FINAL");
        $display("");

        $finish;

    end

endmodule