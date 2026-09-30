`timescale 1ns / 1ps

// ============================================================
// Testbench: tb_integracion_video
//
// Descripcion:
// Prueba de integracion del sistema de video del Issue 6.
//
// Se verifica:
// 1. Escritura MMIO en la Video RAM.
// 2. Lectura posterior de los datos escritos.
// 3. Escritura en diferentes posiciones de memoria.
// 4. Actualizacion individual de una casilla.
// 5. Rechazo de escrituras no alineadas.
// 6. Funcionamiento del VGA mientras el CPU escribe memoria.
// 7. Ausencia de valores X/Z en las salidas VGA.
//
// El testbench es autoverificable.
// ============================================================

module tb_integracion_video;

    // --------------------------------------------------------
    // Entradas
    // --------------------------------------------------------

    logic        clk_100mhz;
    logic        rst;

    logic [31:0] addr_i;
    logic [31:0] wdata_i;
    logic        we_i;

    // --------------------------------------------------------
    // Salidas
    // --------------------------------------------------------

    logic [31:0] video_rdata_o;

    logic        hsync;
    logic        vsync;

    logic [3:0]  vga_red;
    logic [3:0]  vga_green;
    logic [3:0]  vga_blue;

    // --------------------------------------------------------
    // Contador de errores
    // --------------------------------------------------------

    integer errores;

    // --------------------------------------------------------
    // Direcciones MMIO utilizadas
    // --------------------------------------------------------

    localparam logic [31:0] VIDEO_BASE = 32'h0001_1000;

    localparam logic [31:0] TILE_0  = VIDEO_BASE + 32'd0;
    localparam logic [31:0] TILE_1  = VIDEO_BASE + 32'd4;
    localparam logic [31:0] TILE_2  = VIDEO_BASE + 32'd8;
    localparam logic [31:0] TILE_10 = VIDEO_BASE + 32'd40;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // Reloj de 100 MHz
    //
    // Periodo = 10 ns
    // --------------------------------------------------------

    initial begin
        clk_100mhz = 1'b0;

        forever #5 clk_100mhz = ~clk_100mhz;
    end

    // ========================================================
    // TAREA: escritura MMIO
    // ========================================================

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

    // ========================================================
    // TAREA: verificar lectura
    // ========================================================

    task automatic verificar_lectura(
        input logic [31:0] direccion,
        input logic [31:0] esperado
    );

        begin

            @(negedge clk_100mhz);

            addr_i = direccion;
            we_i   = 1'b0;

            // La RAM tiene lectura sincrona.
            @(posedge clk_100mhz);
            #1;

            @(posedge clk_100mhz);
            #1;

            if (video_rdata_o !== esperado) begin

                $display(
                    "FAIL: addr=%h dato=%h esperado=%h",
                    direccion,
                    video_rdata_o,
                    esperado
                );

                errores = errores + 1;

            end
            else begin

                $display(
                    "PASS: addr=%h dato=%h",
                    direccion,
                    video_rdata_o
                );

            end

        end

    endtask

    // ========================================================
    // TAREA: comprobar salidas VGA
    // ========================================================

    task automatic verificar_vga_definido;

        begin

            if ($isunknown(hsync)     ||
                $isunknown(vsync)     ||
                $isunknown(vga_red)   ||
                $isunknown(vga_green) ||
                $isunknown(vga_blue)) begin

                $display(
                    "FAIL: existen valores X/Z en las salidas VGA"
                );

                errores = errores + 1;

            end
            else begin

                $display(
                    "PASS: salidas VGA correctamente definidas"
                );

            end

        end

    endtask

    // ========================================================
    // PRUEBAS
    // ========================================================

    initial begin

        errores = 0;

        rst     = 1'b1;
        addr_i  = 32'd0;
        wdata_i = 32'd0;
        we_i    = 1'b0;

        // ----------------------------------------------------
        // RESET
        // ----------------------------------------------------

        repeat (5)
            @(posedge clk_100mhz);

        rst = 1'b0;

        repeat (5)
            @(posedge clk_100mhz);

        // ====================================================
        // PRUEBA 1
        // Escritura y lectura del tile 0
        // ====================================================

        $display("");
        $display("PRUEBA 1: TILE 0");

        escribir_mmio(
            TILE_0,
            32'h0000_0001
        );

        verificar_lectura(
            TILE_0,
            32'h0000_0001
        );

        // ====================================================
        // PRUEBA 2
        // Escritura y lectura del tile 1
        // ====================================================

        $display("");
        $display("PRUEBA 2: TILE 1");

        escribir_mmio(
            TILE_1,
            32'h0000_0002
        );

        verificar_lectura(
            TILE_1,
            32'h0000_0002
        );

        // ====================================================
        // PRUEBA 3
        // Escritura y lectura del tile 2
        // ====================================================

        $display("");
        $display("PRUEBA 3: TILE 2");

        escribir_mmio(
            TILE_2,
            32'h0000_0003
        );

        verificar_lectura(
            TILE_2,
            32'h0000_0003
        );

        // ====================================================
        // PRUEBA 4
        // Verificar que los tiles anteriores mantienen
        // independientemente sus valores
        // ====================================================

        $display("");
        $display("PRUEBA 4: INDEPENDENCIA DE POSICIONES");

        verificar_lectura(
            TILE_0,
            32'h0000_0001
        );

        verificar_lectura(
            TILE_1,
            32'h0000_0002
        );

        verificar_lectura(
            TILE_2,
            32'h0000_0003
        );

        // ====================================================
        // PRUEBA 5
        // Actualizar solamente una casilla
        // ====================================================

        $display("");
        $display("PRUEBA 5: ACTUALIZACION DE UNA CASILLA");

        escribir_mmio(
            TILE_1,
            32'h0000_0004
        );

        // Tile 1 debe cambiar.

        verificar_lectura(
            TILE_1,
            32'h0000_0004
        );

        // Tile 0 debe conservar su valor.

        verificar_lectura(
            TILE_0,
            32'h0000_0001
        );

        // Tile 2 debe conservar su valor.

        verificar_lectura(
            TILE_2,
            32'h0000_0003
        );

        // ====================================================
        // PRUEBA 6
        // Posicion mas alejada
        // ====================================================

        $display("");
        $display("PRUEBA 6: OTRA POSICION DE MEMORIA");

        escribir_mmio(
            TILE_10,
            32'h1234_5678
        );

        verificar_lectura(
            TILE_10,
            32'h1234_5678
        );

        // ====================================================
        // PRUEBA 7
        // Escritura NO alineada.
        //
        // 0x00011002 no debe modificar TILE 0.
        // ====================================================

        $display("");
        $display("PRUEBA 7: DIRECCION NO ALINEADA");

        escribir_mmio(
            32'h0001_1002,
            32'hAAAA_AAAA
        );

        verificar_lectura(
            TILE_0,
            32'h0000_0001
        );

        // ====================================================
        // PRUEBA 8
        // CPU escribe mientras el sistema VGA se encuentra
        // funcionando.
        // ====================================================

        $display("");
        $display("PRUEBA 8: CPU + VGA");

        escribir_mmio(
            TILE_2,
            32'h0000_0002
        );

        repeat (20)
            @(posedge clk_100mhz);

        verificar_vga_definido();

        verificar_lectura(
            TILE_2,
            32'h0000_0002
        );

        // ====================================================
        // RESULTADO FINAL
        // ====================================================

        $display("");

        if (errores == 0) begin

            $display(
                "=================================================="
            );

            $display(
                "TB INTEGRACION VIDEO: TODAS LAS PRUEBAS PASARON"
            );

            $display(
                "=================================================="
            );

        end
        else begin

            $display(
                "=================================================="
            );

            $display(
                "TB INTEGRACION VIDEO: %0d ERRORES",
                errores
            );

            $display(
                "=================================================="
            );

        end

        $finish;

    end

endmodule