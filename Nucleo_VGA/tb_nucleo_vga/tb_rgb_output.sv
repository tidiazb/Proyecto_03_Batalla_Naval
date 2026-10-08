`timescale 1ns / 1ps

// ============================================================
// Testbench: tb_rgb_output
// Descripción:
//   Verifica el funcionamiento del módulo rgb_output mediante
//   diferentes combinaciones de colores RGB y estados de la
//   señal active_video.
//
//   El testbench comprueba que, cuando active_video está activo,
//   los valores RGB de entrada sean transferidos sin cambios a
//   las salidas VGA. También verifica que, cuando active_video
//   está desactivado, las tres componentes de color se fuercen
//   a cero independientemente del color presente en la entrada.
//
//   La simulación prueba varios colores y reporta automáticamente
//   si todas las condiciones fueron verificadas correctamente.
// ============================================================

module tb_rgb_output;

    logic       active_video;

    logic [3:0] red_in;
    logic [3:0] green_in;
    logic [3:0] blue_in;

    logic [3:0] vga_red;
    logic [3:0] vga_green;
    logic [3:0] vga_blue;

    int errores;

    rgb_output dut (
        .active_video (active_video),

        .red_in       (red_in),
        .green_in     (green_in),
        .blue_in      (blue_in),

        .vga_red      (vga_red),
        .vga_green    (vga_green),
        .vga_blue     (vga_blue)
    );

    task automatic verificar (
        input logic       active,
        input logic [3:0] r_in,
        input logic [3:0] g_in,
        input logic [3:0] b_in,
        input logic [3:0] r_esperado,
        input logic [3:0] g_esperado,
        input logic [3:0] b_esperado
    );
        begin

            active_video = active;

            red_in   = r_in;
            green_in = g_in;
            blue_in  = b_in;

            #1;

            if ((vga_red   !== r_esperado) ||
                (vga_green !== g_esperado) ||
                (vga_blue  !== b_esperado)) begin

                $error(
                    "active=%b RGB entrada=(%h,%h,%h) esperado=(%h,%h,%h) obtenido=(%h,%h,%h)",
                    active,
                    r_in,
                    g_in,
                    b_in,
                    r_esperado,
                    g_esperado,
                    b_esperado,
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

        // Negro dentro del área visible
        verificar(
            1'b1,
            4'h0, 4'h0, 4'h0,
            4'h0, 4'h0, 4'h0
        );

        // Rojo
        verificar(
            1'b1,
            4'hF, 4'h0, 4'h0,
            4'hF, 4'h0, 4'h0
        );

        // Verde
        verificar(
            1'b1,
            4'h0, 4'hF, 4'h0,
            4'h0, 4'hF, 4'h0
        );

        // Azul
        verificar(
            1'b1,
            4'h0, 4'h0, 4'hF,
            4'h0, 4'h0, 4'hF
        );

        // Color combinado
        verificar(
            1'b1,
            4'hA, 4'h5, 4'hC,
            4'hA, 4'h5, 4'hC
        );

        // Fuera del área visible: rojo debe convertirse en negro
        verificar(
            1'b0,
            4'hF, 4'h0, 4'h0,
            4'h0, 4'h0, 4'h0
        );

        // Fuera del área visible: blanco debe convertirse en negro
        verificar(
            1'b0,
            4'hF, 4'hF, 4'hF,
            4'h0, 4'h0, 4'h0
        );

        // Fuera del área visible: color arbitrario debe ser negro
        verificar(
            1'b0,
            4'h7, 4'hB, 4'h3,
            4'h0, 4'h0, 4'h0
        );

        if (errores == 0) begin
            $display("============================================");
            $display("TB RGB OUTPUT: TODAS LAS PRUEBAS PASARON");
            $display("============================================");
        end
        else begin
            $display("============================================");
            $display("TB RGB OUTPUT: %0d ERRORES", errores);
            $display("============================================");
        end

        $finish;

    end

endmodule
