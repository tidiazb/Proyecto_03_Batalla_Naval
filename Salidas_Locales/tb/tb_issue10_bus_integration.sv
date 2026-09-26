`timescale 1ns / 1ps

//============================================================
// Testbench: tb_issue10_bus_integration
// Issue #10 + Issue #4
//
// Verificación final de integración.
//
// Comprueba:
//   0x0001_0130 -> Display
//   0x0001_0138 -> LED
//   0x0001_0140 -> Buzzer
//
// Se conecta:
//   memory_mmio_system (Issue #4)
//              +
//   peripherals_mmio   (Issue #10)
//
// El TB realiza accesos equivalentes a SW/LW del procesador.
//============================================================

module tb_issue10_bus_integration;

    //========================================================
    // Direcciones MMIO
    //========================================================

    localparam logic [31:0] ADDR_DISPLAY =
        32'h0001_0130;

    localparam logic [31:0] ADDR_LED =
        32'h0001_0138;

    localparam logic [31:0] ADDR_BUZZER =
        32'h0001_0140;


    //========================================================
    // Señales del procesador
    //========================================================

    logic clk;

    logic [31:0] ProgAddress;
    logic [31:0] ProgIn;

    logic [31:0] DataAddress;
    logic [31:0] DataOut;
    logic        we;
    logic [31:0] DataIn;


    //========================================================
    // Bus MMIO
    //========================================================

    logic [31:0] bus_wdata;

    logic uart_sel;
    logic uart_we;
    logic [1:0] uart_addr;
    logic [31:0] uart_rdata;

    logic gpio_sel;
    logic gpio_we;
    logic [31:0] gpio_rdata;

    logic display_sel;
    logic display_we;
    logic [31:0] display_rdata;

    logic led_sel;
    logic led_we;
    logic [31:0] led_rdata;

    logic buzzer_sel;
    logic buzzer_we;
    logic [31:0] buzzer_rdata;

    logic vga_sel;
    logic vga_we;
    logic [8:0] vga_addr;
    logic [31:0] vga_rdata;


    //========================================================
    // Periféricos físicos
    //========================================================

    logic [6:0] seg;
    logic [3:0] an;

    logic [2:0] led_rgb;

    logic buzzer;


    //========================================================
    // Reset de peripherals_mmio
    //========================================================

    logic rst;

    integer errors;


    //========================================================
    // ISSUE #4
    // Sistema de memoria + bus MMIO
    //========================================================

    memory_mmio_system u_memory_system (

        .clk_i(clk),

        .ProgAddress_i(ProgAddress),
        .ProgIn_o(ProgIn),

        .DataAddress_i(DataAddress),
        .DataOut_i(DataOut),
        .we_i(we),
        .DataIn_o(DataIn),

        .bus_wdata_o(bus_wdata),

        .uart_sel_o(uart_sel),
        .uart_we_o(uart_we),
        .uart_addr_o(uart_addr),
        .uart_rdata_i(uart_rdata),

        .gpio_sel_o(gpio_sel),
        .gpio_we_o(gpio_we),
        .gpio_rdata_i(gpio_rdata),

        .display_sel_o(display_sel),
        .display_we_o(display_we),
        .display_rdata_i(display_rdata),

        .led_sel_o(led_sel),
        .led_we_o(led_we),
        .led_rdata_i(led_rdata),

        .buzzer_sel_o(buzzer_sel),
        .buzzer_we_o(buzzer_we),
        .buzzer_rdata_i(buzzer_rdata),

        .vga_sel_o(vga_sel),
        .vga_we_o(vga_we),
        .vga_addr_o(vga_addr),
        .vga_rdata_i(vga_rdata)
    );


    //========================================================
    // ISSUE #10
    // Periféricos
    //========================================================

    peripherals_mmio #(

        // Valores pequeños para acelerar simulación
        .DISPLAY_REFRESH_BITS(4),
        .BUZZER_CLK_FREQ(120_000)

    ) u_peripherals (

        .clk(clk),
        .rst(rst),

        .bus_wdata_i(bus_wdata),

        .display_we_i(display_we),
        .led_we_i(led_we),
        .buzzer_we_i(buzzer_we),

        .display_rdata_o(display_rdata),
        .led_rdata_o(led_rdata),
        .buzzer_rdata_o(buzzer_rdata),

        .seg(seg),
        .an(an),

        .led_rgb(led_rgb),

        .buzzer(buzzer)
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
    // Escritura MMIO
    //
    // Simula una operación SW del procesador.
    //========================================================

    task automatic mmio_write(
        input logic [31:0] address,
        input logic [31:0] data
    );

        begin

            @(negedge clk);

            DataAddress = address;
            DataOut     = data;
            we          = 1'b1;

            @(negedge clk);

            we          = 1'b0;
            DataAddress = 32'b0;
            DataOut     = 32'b0;

        end

    endtask


    //========================================================
    // Lectura MMIO
    //
    // Simula una operación LW del procesador.
    //========================================================

    task automatic mmio_read(
        input  logic [31:0] address,
        output logic [31:0] data
    );

        begin

            DataAddress = address;
            we          = 1'b0;

            #1;

            data = DataIn;

            DataAddress = 32'b0;

        end

    endtask


    //========================================================
    // Variables auxiliares
    //========================================================

    logic [31:0] read_data;


    //========================================================
    // Secuencia principal
    //========================================================

    initial begin

        errors = 0;

        //----------------------------------------------------
        // Valores iniciales
        //----------------------------------------------------

        rst = 1'b1;

        ProgAddress = 32'b0;

        DataAddress = 32'b0;
        DataOut     = 32'b0;
        we          = 1'b0;

        // Periféricos de otros issues no utilizados
        uart_rdata = 32'b0;
        gpio_rdata = 32'b0;
        vga_rdata  = 32'b0;


        $display("");
        $display("========================================");
        $display(" ISSUE #10 - INTEGRACION FINAL MMIO");
        $display(" ISSUE #4  - BUS DE MEMORIA");
        $display("========================================");


        //====================================================
        // RESET
        //====================================================

        repeat (5) @(posedge clk);

        rst = 1'b0;

        repeat (2) @(posedge clk);

        $display("");
        $display("PASS | RESET completado");


        //====================================================
        // TEST 1
        // DISPLAY @ 0x0001_0130
        //
        // J1 = 37 = 0x25
        // J2 = 84 = 0x54
        //
        // dato = 0x00005425
        //====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST DISPLAY @ 0x0001_0130");
        $display("----------------------------------------");

        mmio_write(
            ADDR_DISPLAY,
            32'h0000_5425
        );


        //----------------------------------------------------
        // Verificar selección correcta del registro
        //----------------------------------------------------

        DataAddress = ADDR_DISPLAY;

        #1;

        if (
            display_sel === 1'b1 &&
            led_sel     === 1'b0 &&
            buzzer_sel  === 1'b0
        ) begin

            $display(
                "PASS | DISPLAY | Direccion decodificada correctamente"
            );

        end
        else begin

            $display(
                "FAIL | DISPLAY | Error de decodificacion"
            );

            errors = errors + 1;

        end

        DataAddress = 32'b0;


        //----------------------------------------------------
        // Leer registro
        //----------------------------------------------------

        mmio_read(
            ADDR_DISPLAY,
            read_data
        );

        if (
            read_data[7:0]  === 8'd37 &&
            read_data[15:8] === 8'd84
        ) begin

            $display(
                "PASS | DISPLAY | LW correcto | RDATA=%h",
                read_data
            );

        end
        else begin

            $display(
                "FAIL | DISPLAY | RDATA=%h",
                read_data
            );

            errors = errors + 1;

        end


        //====================================================
        // TEST 2
        // LED @ 0x0001_0138
        //
        // 10 = Resultado final
        //====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST LED @ 0x0001_0138");
        $display("----------------------------------------");

        mmio_write(
            ADDR_LED,
            32'h0000_0002
        );


        //----------------------------------------------------
        // Verificar decodificación
        //----------------------------------------------------

        DataAddress = ADDR_LED;

        #1;

        if (
            display_sel === 1'b0 &&
            led_sel     === 1'b1 &&
            buzzer_sel  === 1'b0
        ) begin

            $display(
                "PASS | LED | Direccion decodificada correctamente"
            );

        end
        else begin

            $display(
                "FAIL | LED | Error de decodificacion"
            );

            errors = errors + 1;

        end

        DataAddress = 32'b0;


        //----------------------------------------------------
        // Leer registro y comprobar RGB
        //----------------------------------------------------

        mmio_read(
            ADDR_LED,
            read_data
        );

        if (
            read_data[1:0] === 2'b10 &&
            led_rgb        === 3'b100
        ) begin

            $display(
                "PASS | LED | LW correcto | Estado=RESULTADO | RGB=%b",
                led_rgb
            );

        end
        else begin

            $display(
                "FAIL | LED | RDATA=%h RGB=%b",
                read_data,
                led_rgb
            );

            errors = errors + 1;

        end


        //====================================================
        // TEST 3
        // BUZZER @ 0x0001_0140
        //
        // Impacto:
        //
        // sound_sel = 001
        // start     = 1
        //
        // [3:1] = 001
        // [0]   = 1
        //
        // valor = 0x00000003
        //====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST BUZZER @ 0x0001_0140");
        $display("----------------------------------------");

        mmio_write(
            ADDR_BUZZER,
            32'h0000_0003
        );


        //----------------------------------------------------
        // Verificar decodificación
        //----------------------------------------------------

        DataAddress = ADDR_BUZZER;

        #1;

        if (
            display_sel === 1'b0 &&
            led_sel     === 1'b0 &&
            buzzer_sel  === 1'b1
        ) begin

            $display(
                "PASS | BUZZER | Direccion decodificada correctamente"
            );

        end
        else begin

            $display(
                "FAIL | BUZZER | Error de decodificacion"
            );

            errors = errors + 1;

        end

        DataAddress = 32'b0;


        //----------------------------------------------------
        // Verificar que el sonido seleccionado sea IMPACTO
        //----------------------------------------------------

        mmio_read(
            ADDR_BUZZER,
            read_data
        );

        if (read_data[3:1] === 3'b001) begin

            $display(
                "PASS | BUZZER | Sonido IMPACTO seleccionado"
            );

        end
        else begin

            $display(
                "FAIL | BUZZER | Seleccion incorrecta | RDATA=%h",
                read_data
            );

            errors = errors + 1;

        end


        //----------------------------------------------------
       //----------------------------------------------------
// BUSY debe estar activo
//
// Esperamos algunos ciclos para permitir que
// buzzer_controller procese el pulso START.
// Luego realizamos una nueva lectura MMIO.
//----------------------------------------------------

repeat (2) @(posedge clk);
#1;

mmio_read(
    ADDR_BUZZER,
    read_data
);

if (read_data[0] === 1'b1) begin

    $display(
        "PASS | BUZZER | BUSY activo"
    );

end
else begin

    $display(
        "FAIL | BUZZER | BUSY no se activo | RDATA=%h",
        read_data
    );

    errors = errors + 1;

end


        //====================================================
        // TEST 4
        // Independencia de registros
        //
        // Display debe seguir 37 / 84
        // LED debe seguir en resultado final.
        //====================================================

        mmio_read(
            ADDR_DISPLAY,
            read_data
        );

        if (
            read_data[7:0]  === 8'd37 &&
            read_data[15:8] === 8'd84
        ) begin

            $display(
                "PASS | INDEPENDENCIA | DISPLAY conserva J1=37 J2=84"
            );

        end
        else begin

            $display(
                "FAIL | INDEPENDENCIA | DISPLAY fue alterado"
            );

            errors = errors + 1;

        end


        mmio_read(
            ADDR_LED,
            read_data
        );

        if (
            read_data[1:0] === 2'b10
        ) begin

            $display(
                "PASS | INDEPENDENCIA | LED conserva RESULTADO FINAL"
            );

        end
        else begin

            $display(
                "FAIL | INDEPENDENCIA | LED fue alterado"
            );

            errors = errors + 1;

        end


        //====================================================
        // TEST 5
        // Dirección no válida
        //
        // Ningún periférico debe seleccionarse.
        //====================================================

        DataAddress = 32'h0001_0134;

        #1;

        if (
            display_sel === 1'b0 &&
            led_sel     === 1'b0 &&
            buzzer_sel  === 1'b0 &&
            DataIn      === 32'b0
        ) begin

            $display(
                "PASS | BUS | Direccion no valida ignorada"
            );

        end
        else begin

            $display(
                "FAIL | BUS | Direccion no valida selecciono periferico"
            );

            errors = errors + 1;

        end

        DataAddress = 32'b0;


        //====================================================
        // Esperar finalización del buzzer
        //====================================================

        wait(buzzer_rdata[0] == 1'b0);

        #1;

        if (buzzer === 1'b0) begin

            $display(
                "PASS | BUZZER | Sonido finalizado correctamente"
            );

        end
        else begin

            $display(
                "FAIL | BUZZER | Salida final incorrecta"
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
            $display(" INTEGRACION ISSUE #4 + ISSUE #10 OK");

            $display("");
            $display(" DISPLAY @ 0x0001_0130 : PASS");
            $display(" LED     @ 0x0001_0138 : PASS");
            $display(" BUZZER  @ 0x0001_0140 : PASS");
            $display(" BUS MMIO 32 bits       : PASS");

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