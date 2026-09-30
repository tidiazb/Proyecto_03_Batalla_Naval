`timescale 1ns / 1ps

// ============================================================
// Testbench: tb_vga_timing
// Descripción:
//   Verifica el funcionamiento del módulo vga_timing utilizando
//   un reloj de píxel de 25 MHz y una señal de reset.
//
//   Recorre un cuadro VGA completo y comprueba automáticamente
//   que las coordenadas horizontal y vertical permanezcan dentro
//   de los rangos esperados. También verifica que active_video
//   se encuentre activo únicamente dentro de los 640x480 píxeles
//   visibles y que hsync y vsync se activen en los intervalos
//   correspondientes a la temporización VGA.
//
//   Finalmente comprueba que, después de completar las 800
//   posiciones horizontales y las 525 líneas verticales, el
//   barrido regrese correctamente a la posición (0,0).
// ============================================================

module tb_vga_timing;

    logic       pixel_clk;
    logic       rst;

    logic [9:0] pixel_x;
    logic [9:0] pixel_y;
    logic       hsync;
    logic       vsync;
    logic       active_video;

    int errores;

    vga_timing dut (
        .pixel_clk    (pixel_clk),
        .rst          (rst),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .hsync        (hsync),
        .vsync        (vsync),
        .active_video (active_video)
    );

    initial begin
        pixel_clk = 1'b0;
        forever #20 pixel_clk = ~pixel_clk;
    end

    initial begin
        rst     = 1'b1;
        errores = 0;

        repeat (3) @(posedge pixel_clk);

        rst = 1'b0;

        @(negedge pixel_clk);

        repeat (800 * 525) begin

            if (pixel_x < 10'd640 && pixel_y < 10'd480) begin
                if (active_video !== 1'b1) begin
                    $error(
                        "active_video incorrecto en X=%0d Y=%0d",
                        pixel_x, pixel_y
                    );
                    errores++;
                end
            end
            else begin
                if (active_video !== 1'b0) begin
                    $error(
                        "active_video incorrecto en X=%0d Y=%0d",
                        pixel_x, pixel_y
                    );
                    errores++;
                end
            end

            if (pixel_x >= 10'd656 && pixel_x < 10'd752) begin
                if (hsync !== 1'b0) begin
                    $error(
                        "hsync incorrecto en X=%0d",
                        pixel_x
                    );
                    errores++;
                end
            end
            else begin
                if (hsync !== 1'b1) begin
                    $error(
                        "hsync incorrecto en X=%0d",
                        pixel_x
                    );
                    errores++;
                end
            end

            if (pixel_y >= 10'd490 && pixel_y < 10'd492) begin
                if (vsync !== 1'b0) begin
                    $error(
                        "vsync incorrecto en Y=%0d",
                        pixel_y
                    );
                    errores++;
                end
            end
            else begin
                if (vsync !== 1'b1) begin
                    $error(
                        "vsync incorrecto en Y=%0d",
                        pixel_y
                    );
                    errores++;
                end
            end

            if (pixel_x == 10'd799 && pixel_y == 10'd524) begin
                @(posedge pixel_clk);
                #1;

                if (pixel_x !== 10'd0 || pixel_y !== 10'd0) begin
                    $error(
                        "El cuadro no regreso al origen. X=%0d Y=%0d",
                        pixel_x, pixel_y
                    );
                    errores++;
                end

                break;
            end

            @(negedge pixel_clk);
        end

        if (errores == 0) begin
            $display("========================================");
            $display("TB VGA TIMING: TODAS LAS PRUEBAS PASARON");
            $display("========================================");
        end
        else begin
            $display("========================================");
            $display("TB VGA TIMING: %0d ERRORES", errores);
            $display("========================================");
        end

        $finish;
    end

endmodule