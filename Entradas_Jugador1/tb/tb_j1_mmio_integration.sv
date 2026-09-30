`timescale 1ns/1ps

module tb_j1_mmio_integration;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst = 1;
    logic [6:0] raw = 0;
    logic [31:0] address = 0, cpu_wdata = 0, cpu_rdata, bus_wdata, gpio_rdata;
    logic cpu_we = 0, gpio_sel, gpio_we;

    mmio_interconnect bus (
        .cpu_addr_i(address), .cpu_wdata_i(cpu_wdata), .cpu_we_i(cpu_we),
        .cpu_rdata_o(cpu_rdata), .bus_wdata_o(bus_wdata),
        .ram_sel_o(), .ram_we_o(), .ram_addr_o(), .ram_rdata_i(32'b0),
        .uart_sel_o(), .uart_we_o(), .uart_addr_o(), .uart_rdata_i(32'b0),
        .gpio_sel_o(gpio_sel), .gpio_we_o(gpio_we), .gpio_rdata_i(gpio_rdata),
        .display_sel_o(), .display_we_o(), .display_rdata_i(32'b0),
        .led_sel_o(), .led_we_o(), .led_rdata_i(32'b0),
        .buzzer_sel_o(), .buzzer_we_o(), .buzzer_rdata_i(32'b0),
        .vga_sel_o(), .vga_we_o(), .vga_addr_o(), .vga_rdata_i(32'b0)
    );
    j1_inputs_peripheral #(.CLK_FREQ_HZ(1000), .DEBOUNCE_MS(3)) gpio (
        .clk_i(clk), .rst_i(rst),
        .btn_up_raw_i(raw[0]), .btn_down_raw_i(raw[1]),
        .btn_left_raw_i(raw[2]), .btn_right_raw_i(raw[3]),
        .btn_sel_raw_i(raw[4]), .btn_ok_raw_i(raw[5]),
        .btn_rst_raw_i(raw[6]),
        .select_i(gpio_sel), .write_enable_i(gpio_we),
        .wdata_i(bus_wdata), .rdata_o(gpio_rdata)
    );

    initial begin
        repeat (3) @(negedge clk);
        rst = 0;
        @(negedge clk); raw[5] = 1; // BTN OK
        repeat (8) @(negedge clk);
        address = 32'h0001_0120;
        #1;
        if (!gpio_sel || gpio_we || cpu_rdata !== 32'h0000_2020)
            $fatal(1, "FAIL MMIO J1: lectura de OK");

        // Escribir en otra direccion no limpia el evento de OK.
        address = 32'h0001_0124;
        cpu_wdata = 32'h0000_2000;
        cpu_we = 1;
        #1;
        if (gpio_sel || gpio_we || cpu_rdata !== 0)
            $fatal(1, "FAIL MMIO J1: direccion invalida");
        @(negedge clk);
        cpu_we = 0; address = 32'h0001_0120;
        #1;
        if (cpu_rdata !== 32'h0000_2020)
            $fatal(1, "FAIL MMIO J1: acceso invalido afecto estado");

        // CPU ejecuta sw con W1C: limpia evento, conserva nivel presionado.
        cpu_wdata = 32'h0000_2000; cpu_we = 1;
        #1;
        if (!gpio_we) $fatal(1, "FAIL MMIO J1: GPIO WE");
        @(negedge clk);
        cpu_we = 0;
        #1;
        if (cpu_rdata !== 32'h0000_0020)
            $fatal(1, "FAIL MMIO J1: limpieza W1C por CPU");
        raw = 0;
        repeat (8) @(negedge clk);
        #1;
        if (cpu_rdata !== 0) $fatal(1, "FAIL MMIO J1: liberacion");
        $display("PASS tb_j1_mmio_integration");
        $finish;
    end
endmodule
