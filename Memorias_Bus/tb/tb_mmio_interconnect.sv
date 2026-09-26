`timescale 1ns/1ps

module tb_mmio_interconnect;
    logic [31:0] addr, wdata, rdata, bus_wdata;
    logic we;
    logic ram_sel, ram_we, uart_sel, uart_we, gpio_sel, gpio_we;
    logic display_sel, display_we, led_sel, led_we;
    logic buzzer_sel, buzzer_we, vga_sel, vga_we;
    logic [9:0] ram_addr;
    logic [1:0] uart_addr;
    logic [8:0] vga_addr;
    logic [31:0] ram_data, uart_data, gpio_data, display_data;
    logic [31:0] led_data, buzzer_data, vga_data;

    mmio_interconnect dut (
        .cpu_addr_i(addr), .cpu_wdata_i(wdata), .cpu_we_i(we),
        .cpu_rdata_o(rdata), .bus_wdata_o(bus_wdata),
        .ram_sel_o(ram_sel), .ram_we_o(ram_we),
        .ram_addr_o(ram_addr), .ram_rdata_i(ram_data),
        .uart_sel_o(uart_sel), .uart_we_o(uart_we),
        .uart_addr_o(uart_addr), .uart_rdata_i(uart_data),
        .gpio_sel_o(gpio_sel), .gpio_we_o(gpio_we), .gpio_rdata_i(gpio_data),
        .display_sel_o(display_sel), .display_we_o(display_we),
        .display_rdata_i(display_data),
        .led_sel_o(led_sel), .led_we_o(led_we), .led_rdata_i(led_data),
        .buzzer_sel_o(buzzer_sel), .buzzer_we_o(buzzer_we),
        .buzzer_rdata_i(buzzer_data),
        .vga_sel_o(vga_sel), .vga_we_o(vga_we),
        .vga_addr_o(vga_addr), .vga_rdata_i(vga_data)
    );

    // sel esperado = {VGA, BUZZER, LED, DISPLAY, GPIO, UART, RAM}.
    task automatic check_access(
        input logic [31:0] target,
        input logic write_request,
        input logic [6:0] expected_sel,
        input logic [31:0] expected_data,
        input string description
    );
        integer write_count;
        addr = target; we = write_request;
        #1;
        if ({vga_sel,buzzer_sel,led_sel,display_sel,gpio_sel,uart_sel,ram_sel}
                !== expected_sel)
            $fatal(1, "FAIL MMIO %s: seleccion incorrecta", description);
        if ({vga_we,buzzer_we,led_we,display_we,gpio_we,uart_we,ram_we}
                !== (write_request ? expected_sel : 7'b0))
            $fatal(1, "FAIL MMIO %s: write enable incorrecto", description);
        write_count = 0;
        if (vga_we)     write_count = write_count + 1;
        if (buzzer_we)  write_count = write_count + 1;
        if (led_we)     write_count = write_count + 1;
        if (display_we) write_count = write_count + 1;
        if (gpio_we)    write_count = write_count + 1;
        if (uart_we)    write_count = write_count + 1;
        if (ram_we)     write_count = write_count + 1;
        if (write_count > 1)
            $fatal(1, "FAIL MMIO %s: escritura simultanea", description);
        if (rdata !== expected_data || bus_wdata !== wdata)
            $fatal(1, "FAIL MMIO %s: lectura/dato bus incorrecto", description);
    endtask

    initial begin
        wdata = 32'hA5A5_C33C;
        ram_data = 32'h1111_1111; uart_data = 32'h2222_2222;
        gpio_data = 32'h3333_3333; display_data = 32'h4444_4444;
        led_data = 32'h5555_5555; buzzer_data = 32'h6666_6666;
        vga_data = 32'h7777_7777;

        check_access(32'h0000_2000, 1'b0, 7'b0000001, ram_data, "RAM inicio lectura");
        if (ram_addr !== 10'd0) $fatal(1, "FAIL RAM offset inicial");
        check_access(32'h0000_2FFC, 1'b1, 7'b0000001, ram_data, "RAM final escritura");
        if (ram_addr !== 10'd1023) $fatal(1, "FAIL RAM offset final");

        check_access(32'h0001_0040, 1'b1, 7'b0000010, uart_data, "UART control");
        if (uart_addr !== 2'd0) $fatal(1, "FAIL UART control offset");
        check_access(32'h0001_0044, 1'b1, 7'b0000010, uart_data, "UART TX");
        if (uart_addr !== 2'd1) $fatal(1, "FAIL UART TX offset");
        check_access(32'h0001_0048, 1'b0, 7'b0000010, uart_data, "UART RX");
        if (uart_addr !== 2'd2) $fatal(1, "FAIL UART RX offset");

        check_access(32'h0001_0120, 1'b1, 7'b0000100, gpio_data, "entradas J1");
        check_access(32'h0001_0130, 1'b1, 7'b0001000, display_data, "displays");
        check_access(32'h0001_0138, 1'b1, 7'b0010000, led_data, "LED");
        check_access(32'h0001_0140, 1'b1, 7'b0100000, buzzer_data, "buzzer");
        check_access(32'h0001_1000, 1'b1, 7'b1000000, vga_data, "VGA inicio");
        if (vga_addr !== 9'd0) $fatal(1, "FAIL VGA offset inicial");
        check_access(32'h0001_17FC, 1'b1, 7'b1000000, vga_data, "VGA final");
        if (vga_addr !== 9'd511) $fatal(1, "FAIL VGA offset final");

        check_access(32'h0000_1FFC, 1'b1, 7'b0, 32'b0, "ROM no entra al bus de datos");
        check_access(32'h0000_1FFF, 1'b1, 7'b0, 32'b0, "borde antes de RAM");
        check_access(32'h0000_3000, 1'b1, 7'b0, 32'b0, "fuera de RAM");
        check_access(32'h0001_004C, 1'b1, 7'b0, 32'b0, "cuarto registro UART reservado");
        check_access(32'h0001_0124, 1'b1, 7'b0, 32'b0, "fuera de GPIO");
        check_access(32'h0001_17FF, 1'b1, 7'b0, 32'b0, "VGA desalineado");
        check_access(32'h0001_1800, 1'b1, 7'b0, 32'b0, "fuera de VGA");
        check_access(32'hFFFF_FFFC, 1'b1, 7'b0, 32'b0, "direccion no mapeada");
        $display("PASS tb_mmio_interconnect");
        $finish;
    end
endmodule
