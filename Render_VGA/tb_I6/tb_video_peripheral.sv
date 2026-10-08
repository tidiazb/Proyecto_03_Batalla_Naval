`timescale 1ns / 1ps

// ============================================================
// Testbench: tb_video_peripheral
//
// Descripción:
// Este testbench verifica el funcionamiento integrado del periférico
// de video. Se generan escrituras desde el lado del procesador
// utilizando direcciones MMIO y se comprueba que los datos válidos
// sean almacenados correctamente en la Video RAM.
//
// Se prueban varias posiciones consecutivas de memoria, además de
// accesos fuera del rango MMIO y direcciones no alineadas. En estos
// últimos casos se verifica que la memoria no sea modificada.
//
// La prueba es autoverificable: cada lectura se compara con el valor
// esperado y al finalizar se reporta automáticamente PASS o FAIL.
// ============================================================

module tb_video_peripheral;

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


    always #5 clk_100mhz = ~clk_100mhz;


    task automatic escribir_mmio(
        input logic [31:0] direccion,
        input logic [31:0] dato
    );
        begin
            @(negedge clk_100mhz);

            addr_i  = direccion;
            wdata_i = dato;
            we_i    = 1'b1;

            @(posedge clk_100mhz);
            #1;

            @(negedge clk_100mhz);
            we_i = 1'b0;
        end
    endtask


    task automatic verificar_lectura(
        input logic [31:0] direccion,
        input logic [31:0] esperado
    );
        begin
            @(negedge clk_100mhz);

            addr_i  = direccion;
            wdata_i = 32'h00000000;
            we_i    = 1'b0;

            @(posedge clk_100mhz);
            @(posedge clk_100mhz);
            #1;

            if (video_rdata_o !== esperado) begin
                $error(
                    "Direccion %h: esperado = %h, obtenido = %h",
                    direccion,
                    esperado,
                    video_rdata_o
                );

                errores = errores + 1;
            end
        end
    endtask


    initial begin

        clk_100mhz = 1'b0;
        rst        = 1'b1;

        addr_i     = 32'h00000000;
        wdata_i    = 32'h00000000;
        we_i       = 1'b0;

        errores    = 0;


        repeat (5) @(posedge clk_100mhz);

        rst = 1'b0;

        repeat (5) @(posedge clk_100mhz);


        escribir_mmio(
            32'h0001_1000,
            32'h11111111
        );

        verificar_lectura(
            32'h0001_1000,
            32'h11111111
        );


        escribir_mmio(
            32'h0001_1004,
            32'h22222222
        );

        verificar_lectura(
            32'h0001_1004,
            32'h22222222
        );


        escribir_mmio(
            32'h0001_1008,
            32'h33333333
        );

        verificar_lectura(
            32'h0001_1008,
            32'h33333333
        );


        escribir_mmio(
            32'h0001_1000,
            32'hAAAAAAAA
        );

        escribir_mmio(
            32'h0001_1800,
            32'hBBBBBBBB
        );

        verificar_lectura(
            32'h0001_1000,
            32'hAAAAAAAA
        );


        escribir_mmio(
            32'h0001_1002,
            32'hCCCCCCCC
        );

        verificar_lectura(
            32'h0001_1000,
            32'hAAAAAAAA
        );


        if (errores == 0) begin

            $display("==============================================");
            $display("TB VIDEO PERIPHERAL: TODAS LAS PRUEBAS PASARON");
            $display("==============================================");

        end
        else begin

            $display("==============================================");
            $display("TB VIDEO PERIPHERAL: %0d ERRORES", errores);
            $display("==============================================");

        end


        $finish;

    end

endmodule