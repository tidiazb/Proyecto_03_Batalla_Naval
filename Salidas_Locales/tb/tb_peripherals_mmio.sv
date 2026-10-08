`timescale 1ns / 1ps

//============================================================
// Testbench: tb_peripherals_mmio
// Issue #10 - Adaptación MMIO
//
// Verifica:
// 1. Reset de los registros.
// 2. Escritura y lectura del display.
// 3. Rango 00-99 del display.
// 4. Escritura y lectura del LED.
// 5. Escritura y lectura del buzzer.
// 6. Activación del buzzer mediante START.
// 7. Independencia entre periféricos.
// 8. Interfaz de datos de 32 bits.
//
// IMPORTANTE:
// La decodificación de:
//   0x0001_0130 -> Display
//   0x0001_0138 -> LED
//   0x0001_0140 -> Buzzer
//
// pertenece al bus del Issue #4.
//
// Aquí se verifican las señales WE que ese bus entrega
// a peripherals_mmio.
//============================================================

module tb_peripherals_mmio;

    //========================================================
    // Parámetros reducidos para simulación
    //========================================================

    localparam integer DISPLAY_REFRESH_BITS_TB = 4;
    localparam integer BUZZER_CLK_FREQ_TB      = 120_000;


    //========================================================
    // Señales
    //========================================================

    logic clk;
    logic rst;

    logic [31:0] bus_wdata_i;

    logic display_we_i;
    logic led_we_i;
    logic buzzer_we_i;

    logic [31:0] display_rdata_o;
    logic [31:0] led_rdata_o;
    logic [31:0] buzzer_rdata_o;

    logic [6:0] seg;
    logic [3:0] an;

    logic [2:0] led_rgb;

    logic buzzer;

    integer errors;


    //========================================================
    // DUT
    //========================================================

    peripherals_mmio #(
        .DISPLAY_REFRESH_BITS(DISPLAY_REFRESH_BITS_TB),
        .BUZZER_CLK_FREQ(BUZZER_CLK_FREQ_TB)
    ) dut (
        .clk               (clk),
        .rst               (rst),

        .bus_wdata_i       (bus_wdata_i),

        .display_we_i      (display_we_i),
        .led_we_i          (led_we_i),
        .buzzer_we_i       (buzzer_we_i),

        .display_rdata_o   (display_rdata_o),
        .led_rdata_o       (led_rdata_o),
        .buzzer_rdata_o    (buzzer_rdata_o),

        .seg               (seg),
        .an                (an),

        .led_rgb           (led_rgb),

        .buzzer            (buzzer)
    );


    //========================================================
    // Reloj
    //========================================================

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end


    //========================================================
    // Escritura al registro del DISPLAY
    //========================================================

    task automatic write_display(
        input logic [7:0] player1,
        input logic [7:0] player2
    );

        begin

            @(negedge clk);

            bus_wdata_i = {
                16'b0,
                player2,
                player1
            };

            display_we_i = 1'b1;

            @(negedge clk);

            display_we_i = 1'b0;

            bus_wdata_i = 32'b0;

        end

    endtask


    //========================================================
    // Escritura al registro del LED
    //========================================================

    task automatic write_led(
        input logic [1:0] state
    );

        begin

            @(negedge clk);

            bus_wdata_i = 32'b0;
            bus_wdata_i[1:0] = state;

            led_we_i = 1'b1;

            @(negedge clk);

            led_we_i = 1'b0;

            bus_wdata_i = 32'b0;

        end

    endtask


    //========================================================
    // Escritura al registro del BUZZER
    //
    // [3:1] = sound_sel
    // [0]   = start
    //========================================================

    task automatic write_buzzer(
        input logic [2:0] sound,
        input logic       start_bit
    );

        begin

            @(negedge clk);

            bus_wdata_i = 32'b0;

            bus_wdata_i[3:1] = sound;
            bus_wdata_i[0]   = start_bit;

            buzzer_we_i = 1'b1;

            @(negedge clk);

            buzzer_we_i = 1'b0;

            bus_wdata_i = 32'b0;

        end

    endtask


    //========================================================
    // Secuencia principal
    //========================================================

    initial begin

        //----------------------------------------------------
        // Inicialización
        //----------------------------------------------------

        errors = 0;

        rst = 1'b1;

        bus_wdata_i = 32'b0;

        display_we_i = 1'b0;
        led_we_i     = 1'b0;
        buzzer_we_i  = 1'b0;


        $display("");
        $display("========================================");
        $display(" ISSUE #10 - TEST PERIPHERALS MMIO");
        $display("========================================");


        //====================================================
        // PRUEBA 1 - RESET
        //====================================================

        repeat (5) @(posedge clk);

        rst = 1'b0;

        repeat (2) @(posedge clk);

        if (
            display_rdata_o === 32'h0000_0000 &&
            led_rdata_o[1:0] === 2'b00 &&
            buzzer_rdata_o[3:1] === 3'b000 &&
            buzzer_rdata_o[0] === 1'b0
        ) begin

            $display(
                "PASS | RESET | Registros MMIO inicializados"
            );

        end
        else begin

            $display(
                "FAIL | RESET | Valores incorrectos"
            );

            errors = errors + 1;

        end


        //====================================================
        // PRUEBA 2 - DISPLAY
        //
        // J1 = 37
        // J2 = 84
        //
        // Lectura esperada:
        // 0x00005425
        //
        // 84 decimal = 0x54
        // 37 decimal = 0x25
        //====================================================

        write_display(
            8'd37,
            8'd84
        );

        #1;

        if (
            display_rdata_o[7:0]  === 8'd37 &&
            display_rdata_o[15:8] === 8'd84
        ) begin

            $display(
                "PASS | DISPLAY | J1=37 J2=84 | RDATA=%h",
                display_rdata_o
            );

        end
        else begin

            $display(
                "FAIL | DISPLAY | RDATA=%h",
                display_rdata_o
            );

            errors = errors + 1;

        end


        //====================================================
        // PRUEBA 3 - DISPLAY RANGO > 99
        //
        // Ambos deben saturarse a 99.
        //====================================================

        write_display(
            8'd105,
            8'd120
        );

        #1;

        if (
            display_rdata_o[7:0]  === 8'd99 &&
            display_rdata_o[15:8] === 8'd99
        ) begin

            $display(
                "PASS | DISPLAY | Saturacion 00-99 correcta"
            );

        end
        else begin

            $display(
                "FAIL | DISPLAY | Saturacion incorrecta | RDATA=%h",
                display_rdata_o
            );

            errors = errors + 1;

        end


        //====================================================
        // PRUEBA 4 - LED COLOCACION
        //====================================================

        write_led(2'b00);

        #1;

        if (
            led_rdata_o[1:0] === 2'b00 &&
            led_rgb === 3'b001
        ) begin

            $display(
                "PASS | LED | COLOCACION | RGB=%b",
                led_rgb
            );

        end
        else begin

            $display(
                "FAIL | LED | COLOCACION | RGB=%b",
                led_rgb
            );

            errors = errors + 1;

        end


        //====================================================
        // PRUEBA 5 - LED BATALLA
        //====================================================

        write_led(2'b01);

        #1;

        if (
            led_rdata_o[1:0] === 2'b01 &&
            led_rgb === 3'b010
        ) begin

            $display(
                "PASS | LED | BATALLA | RGB=%b",
                led_rgb
            );

        end
        else begin

            $display(
                "FAIL | LED | BATALLA | RGB=%b",
                led_rgb
            );

            errors = errors + 1;

        end


        //====================================================
        // PRUEBA 6 - LED RESULTADO
        //====================================================

        write_led(2'b10);

        #1;

        if (
            led_rdata_o[1:0] === 2'b10 &&
            led_rgb === 3'b100
        ) begin

            $display(
                "PASS | LED | RESULTADO FINAL | RGB=%b",
                led_rgb
            );

        end
        else begin

            $display(
                "FAIL | LED | RESULTADO FINAL | RGB=%b",
                led_rgb
            );

            errors = errors + 1;

        end


        //====================================================
        // PRUEBA 7 - INDEPENDENCIA
        //
        // Una escritura al LED NO debe modificar el display.
        //
        // El display actualmente debe continuar en 99 / 99.
        //====================================================

        if (
            display_rdata_o[7:0]  === 8'd99 &&
            display_rdata_o[15:8] === 8'd99
        ) begin

            $display(
                "PASS | INDEPENDENCIA | LED no modifico DISPLAY"
            );

        end
        else begin

            $display(
                "FAIL | INDEPENDENCIA | DISPLAY fue modificado"
            );

            errors = errors + 1;

        end


        //====================================================
        // PRUEBA 8 - BUZZER IMPACTO
        //
        // sound_sel = 001
        // start = 1
        //
        // Registro escrito:
        // bits [3:1] = 001
        // bit  [0]   = 1
        //
        // valor = 0x00000003
        //====================================================

        write_buzzer(
            3'b001,
            1'b1
        );

        #1;

        if (
            buzzer_rdata_o[3:1] === 3'b001
        ) begin

            $display(
                "PASS | BUZZER | IMPACTO seleccionado"
            );

        end
        else begin

            $display(
                "FAIL | BUZZER | Seleccion incorrecta"
            );

            errors = errors + 1;

        end


        //====================================================
        // PRUEBA 9 - BUSY DEL BUZZER
        //====================================================

        repeat (2) @(posedge clk);

        #1;

        if (
            buzzer_rdata_o[0] === 1'b1
        ) begin

            $display(
                "PASS | BUZZER | BUSY activado"
            );

        end
        else begin

            $display(
                "FAIL | BUZZER | BUSY no se activo"
            );

            errors = errors + 1;

        end


        //====================================================
        // PRUEBA 10 - INDEPENDENCIA DEL BUZZER
        //
        // El buzzer NO debe modificar display ni LED.
        //====================================================

        if (
            display_rdata_o[7:0]  === 8'd99 &&
            display_rdata_o[15:8] === 8'd99 &&
            led_rdata_o[1:0]      === 2'b10
        ) begin

            $display(
                "PASS | INDEPENDENCIA | BUZZER no modifico DISPLAY/LED"
            );

        end
        else begin

            $display(
                "FAIL | INDEPENDENCIA | BUZZER modifico otro periferico"
            );

            errors = errors + 1;

        end


        //====================================================
        // PRUEBA 11 - ESPERAR FINAL DEL BUZZER
        //====================================================

        wait(buzzer_rdata_o[0] == 1'b0);

        #1;

        if (buzzer === 1'b0) begin

            $display(
                "PASS | BUZZER | Sonido finalizado correctamente"
            );

        end
        else begin

            $display(
                "FAIL | BUZZER | Salida no termino en cero"
            );

            errors = errors + 1;

        end


        //====================================================
        // PRUEBA 12 - ESCRITURA DISPLAY NO MODIFICA LED
        //====================================================

        write_display(
            8'd12,
            8'd34
        );

        #1;

        if (
            display_rdata_o[7:0]  === 8'd12 &&
            display_rdata_o[15:8] === 8'd34 &&
            led_rdata_o[1:0]      === 2'b10
        ) begin

            $display(
                "PASS | INDEPENDENCIA | DISPLAY no modifico LED"
            );

        end
        else begin

            $display(
                "FAIL | INDEPENDENCIA | Error entre DISPLAY/LED"
            );

            errors = errors + 1;

        end


        //====================================================
        // RESULTADO FINAL
        //====================================================

        $display("");
        $display("========================================");

        if (errors == 0) begin

            $display("       TEST PASSED");
            $display(" Todas las pruebas MMIO fueron correctas.");

        end
        else begin

            $display("       TEST FAILED");
            $display(
                " Numero total de errores: %0d",
                errors
            );

        end

        $display("========================================");
        $display("");

        #50;

        $finish;

    end

endmodule