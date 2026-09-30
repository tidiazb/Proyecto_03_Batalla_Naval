`timescale 1ns/1ps

module tb_memory_mmio_system;
    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic [31:0] prog_addr, instr, data_addr, data_out, data_in;
    logic we;
    logic [31:0] bus_wdata;
    logic uart_sel, uart_we, gpio_sel, gpio_we;
    logic display_sel, display_we, led_sel, led_we;
    logic buzzer_sel, buzzer_we, vga_sel, vga_we;
    logic [1:0] uart_addr;
    logic [8:0] vga_addr;

    memory_mmio_system #(.PROGRAM_FILE("program_test.mem")) dut (
        .clk_i(clk),
        .ProgAddress_i(prog_addr), .ProgIn_o(instr),
        .DataAddress_i(data_addr), .DataOut_i(data_out),
        .we_i(we), .DataIn_o(data_in),
        .bus_wdata_o(bus_wdata),
        .uart_sel_o(uart_sel), .uart_we_o(uart_we),
        .uart_addr_o(uart_addr), .uart_rdata_i(32'h1234_0001),
        .gpio_sel_o(gpio_sel), .gpio_we_o(gpio_we),
        .gpio_rdata_i(32'h1234_0002),
        .display_sel_o(display_sel), .display_we_o(display_we),
        .display_rdata_i(32'h1234_0003),
        .led_sel_o(led_sel), .led_we_o(led_we),
        .led_rdata_i(32'h1234_0004),
        .buzzer_sel_o(buzzer_sel), .buzzer_we_o(buzzer_we),
        .buzzer_rdata_i(32'h1234_0005),
        .vga_sel_o(vga_sel), .vga_we_o(vga_we),
        .vga_addr_o(vga_addr), .vga_rdata_i(32'h1234_0006)
    );

    task automatic check_read(input logic [31:0] value, input string description);
        #1;
        if (data_in !== value)
            $fatal(1, "FAIL sistema %s: esperado=%h real=%h", description, value, data_in);
    endtask

    initial begin
        prog_addr = 32'h0000_0004;
        data_addr = 32'b0; data_out = 32'b0; we = 1'b0;
        #1;
        if (instr !== 32'h0010_0093)
            $fatal(1, "FAIL sistema: ROM no entrega instruccion");

        // El CPU escribe y luego lee una palabra de RAM.
        @(negedge clk);
        data_addr = 32'h0000_2010;
        data_out  = 32'hABCD_5678;
        we = 1'b1;
        @(posedge clk);
        #1;
        we = 1'b0;
        check_read(32'hABCD_5678, "RAM a traves del bus");

        data_addr = 32'h0001_0044;
        check_read(32'h1234_0001, "UART rdata");
        if (!uart_sel || uart_addr !== 2'd1 || uart_we)
            $fatal(1, "FAIL sistema: UART offset o seleccion");
        data_addr = 32'h0001_0120;
        check_read(32'h1234_0002, "GPIO rdata");
        data_addr = 32'h0001_1008;
        check_read(32'h1234_0006, "VGA rdata");
        if (vga_addr !== 9'd2)
            $fatal(1, "FAIL sistema: direccion de tile VGA");

        // Un store fuera de rango no debe modificar la palabra RAM anterior.
        @(negedge clk);
        data_addr = 32'h0000_3000;
        data_out = 32'hDEAD_BEEF;
        we = 1'b1;
        #1;
        if (uart_we || gpio_we || display_we || led_we || buzzer_we || vga_we)
            $fatal(1, "FAIL sistema: escritura en periferico incorrecto");
        @(posedge clk);
        #1;
        we = 1'b0;
        check_read(32'b0, "direccion no mapeada");
        data_addr = 32'h0000_2010;
        check_read(32'hABCD_5678, "RAM sin alteracion por acceso invalido");

        // Los demas perifericos siguen devolviendo su dato independiente.
        data_addr = 32'h0001_0130;
        check_read(32'h1234_0003, "display rdata");
        data_addr = 32'h0001_0138;
        check_read(32'h1234_0004, "LED rdata");
        data_addr = 32'h0001_0140;
        check_read(32'h1234_0005, "buzzer rdata");
        $display("PASS tb_memory_mmio_system");
        $finish;
    end
endmodule
