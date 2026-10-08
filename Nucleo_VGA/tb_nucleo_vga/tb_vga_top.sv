`timescale 1ns / 1ps

// ============================================================
// Testbench: tb_vga_top
// Descripción:
//   Verifica la integración completa del subsistema VGA,
//   incluyendo la generación del reloj de píxel, temporización,
//   conversión de coordenadas a tiles, direccionamiento de la
//   Video RAM, lectura de memoria, decodificación de los estados
//   de las casillas y generación de las señales RGB finales.
//
//   El testbench genera un reloj principal de 100 MHz, aplica
//   reset y escribe diferentes estados en la Video RAM mediante
//   el puerto destinado al sistema principal. Posteriormente
//   comprueba que el barrido VGA acceda a esas posiciones y
//   produzca los colores correspondientes.
//
//   También se verifican las señales de sincronización y que las
//   salidas RGB permanezcan apagadas fuera del área visible. La
//   simulación reporta automáticamente cualquier error detectado.
// ============================================================

module tb_vga_top;

    logic        clk_100mhz;
    logic        rst;

    logic        video_we;
    logic [8:0]  video_addr;
    logic [31:0] video_wdata;
    logic [31:0] video_rdata;

    logic        hsync;
    logic        vsync;

    logic [3:0]  vga_red;
    logic [3:0]  vga_green;
    logic [3:0]  vga_blue;

    int errores;


    vga_top dut (
        .clk_100mhz (clk_100mhz),
        .rst        (rst),

        .video_we   (video_we),
        .video_addr (video_addr),
        .video_wdata(video_wdata),
        .video_rdata(video_rdata),

        .hsync      (hsync),
        .vsync      (vsync),

        .vga_red    (vga_red),
        .vga_green  (vga_green),
        .vga_blue   (vga_blue)
    );


    initial begin
        clk_100mhz = 1'b0;
        forever #5 clk_100mhz = ~clk_100mhz;
    end


    task automatic escribir_video (
        input logic [8:0]  direccion,
        input logic [31:0] dato
    );
        begin

            @(negedge clk_100mhz);

            video_addr  = direccion;
            video_wdata = dato;
            video_we    = 1'b1;

            @(posedge clk_100mhz);
            #1;

            @(negedge clk_100mhz);

            video_we = 1'b0;

        end
    endtask


    task automatic verificar_color (
        input logic [8:0] direccion,
        input logic [3:0] red_esperado,
        input logic [3:0] green_esperado,
        input logic [3:0] blue_esperado
    );
        begin

            wait (
                dut.tile_addr == direccion &&
                dut.local_x_d == 5'd15 &&
                dut.local_y_d == 5'd15 &&
                dut.active_video_d == 1'b1
            );

            #1;

            if ((vga_red   !== red_esperado)   ||
                (vga_green !== green_esperado) ||
                (vga_blue  !== blue_esperado)) begin

                $error(
                    "Direccion=%0d RGB esperado=(%h,%h,%h) obtenido=(%h,%h,%h)",
                    direccion,
                    red_esperado,
                    green_esperado,
                    blue_esperado,
                    vga_red,
                    vga_green,
                    vga_blue
                );

                errores++;

            end

        end
    endtask


    initial begin

        errores = 0;

        rst         = 1'b1;
        video_we    = 1'b0;
        video_addr  = 9'd0;
        video_wdata = 32'd0;

        repeat (10) @(posedge clk_100mhz);

        rst = 1'b0;

        // Espera a que el PLL indique que el reloj es estable
        wait (dut.locked == 1'b1);

        // ----------------------------------------------------
        // Configuración de algunos tiles de prueba
        // ----------------------------------------------------

        // Tile 0 -> agua
        escribir_video(
            9'd0,
            32'h00000000
        );

        // Tile 1 -> barco
        escribir_video(
            9'd1,
            32'h00000001
        );

        // Tile 2 -> disparo fallido
        escribir_video(
            9'd2,
            32'h00000002
        );

        // Tile 3 -> barco impactado
        escribir_video(
            9'd3,
            32'h00000003
        );

        // Tile 4 -> casilla seleccionada
        escribir_video(
            9'd4,
            32'h00000004
        );


        // ----------------------------------------------------
        // Verificación de los colores generados
        // ----------------------------------------------------

        verificar_color(
            9'd0,
            4'h0,
            4'h4,
            4'hF
        );

        verificar_color(
            9'd1,
            4'h8,
            4'h8,
            4'h8
        );

        verificar_color(
            9'd2,
            4'h0,
            4'hF,
            4'hF
        );

        verificar_color(
            9'd3,
            4'hF,
            4'h0,
            4'h0
        );

        verificar_color(
            9'd4,
            4'hF,
            4'hF,
            4'h0
        );


        // ----------------------------------------------------
        // Verificación de blanking
        // ----------------------------------------------------

        wait (dut.active_video_d == 1'b0);

        #1;

        if ((vga_red   !== 4'h0) ||
            (vga_green !== 4'h0) ||
            (vga_blue  !== 4'h0)) begin

            $error(
                "RGB no se apago fuera del area visible: (%h,%h,%h)",
                vga_red,
                vga_green,
                vga_blue
            );

            errores++;

        end


        // ----------------------------------------------------
        // Verificación básica de sincronismos
        // ----------------------------------------------------

        wait (hsync == 1'b0);

        if (hsync !== 1'b0) begin
            $error("HSYNC no se activo correctamente");
            errores++;
        end

        wait (hsync == 1'b1);

        wait (vsync == 1'b0);

        if (vsync !== 1'b0) begin
            $error("VSYNC no se activo correctamente");
            errores++;
        end

        wait (vsync == 1'b1);


        // ----------------------------------------------------
        // Resultado final
        // ----------------------------------------------------

        if (errores == 0) begin
            $display("============================================");
            $display("TB VGA TOP: TODAS LAS PRUEBAS PASARON");
            $display("============================================");
        end
        else begin
            $display("============================================");
            $display("TB VGA TOP: %0d ERRORES", errores);
            $display("============================================");
        end

        $finish;

    end

endmodule