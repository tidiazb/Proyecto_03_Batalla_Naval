`timescale 1ns/1ps

// Integracion de las memorias y la interconexion. Los perifericos externos
// conservan sus rdata_o y usan bus_wdata_o, sus WE y sus direcciones locales.
module memory_mmio_system #(
    parameter PROGRAM_FILE = ""
) (
    input  logic        clk_i,

    // Puertos dedicados del procesador RV32I.
    input  logic [31:0] ProgAddress_i,
    output logic [31:0] ProgIn_o,
    input  logic [31:0] DataAddress_i,
    input  logic [31:0] DataOut_i,
    input  logic        we_i,
    output logic [31:0] DataIn_o,

    // Interfaz para los perifericos implementados en otros issues.
    output logic [31:0] bus_wdata_o,
    output logic        uart_sel_o,
    output logic        uart_we_o,
    output logic [1:0]  uart_addr_o,
    input  logic [31:0] uart_rdata_i,
    output logic        gpio_sel_o,
    output logic        gpio_we_o,
    input  logic [31:0] gpio_rdata_i,
    output logic        display_sel_o,
    output logic        display_we_o,
    input  logic [31:0] display_rdata_i,
    output logic        led_sel_o,
    output logic        led_we_o,
    input  logic [31:0] led_rdata_i,
    output logic        buzzer_sel_o,
    output logic        buzzer_we_o,
    input  logic [31:0] buzzer_rdata_i,
    output logic        vga_sel_o,
    output logic        vga_we_o,
    output logic [8:0]  vga_addr_o,
    input  logic [31:0] vga_rdata_i
);
    logic        ram_sel;
    logic        ram_we;
    logic [9:0]  ram_addr;
    logic [31:0] ram_rdata;

    program_rom #(.INIT_FILE(PROGRAM_FILE)) u_program_rom (
        .prog_addr_i (ProgAddress_i),
        .prog_instr_o(ProgIn_o)
    );

    data_ram u_data_ram (
        .clk_i         (clk_i),
        .select_i      (ram_sel),
        .write_enable_i(ram_we),
        .word_addr_i   (ram_addr),
        .wdata_i       (bus_wdata_o),
        .rdata_o       (ram_rdata)
    );

    mmio_interconnect u_bus (
        .cpu_addr_i   (DataAddress_i),
        .cpu_wdata_i  (DataOut_i),
        .cpu_we_i     (we_i),
        .cpu_rdata_o  (DataIn_o),
        .bus_wdata_o  (bus_wdata_o),
        .ram_sel_o    (ram_sel),
        .ram_we_o     (ram_we),
        .ram_addr_o   (ram_addr),
        .ram_rdata_i  (ram_rdata),
        .uart_sel_o   (uart_sel_o),
        .uart_we_o    (uart_we_o),
        .uart_addr_o  (uart_addr_o),
        .uart_rdata_i (uart_rdata_i),
        .gpio_sel_o   (gpio_sel_o),
        .gpio_we_o    (gpio_we_o),
        .gpio_rdata_i (gpio_rdata_i),
        .display_sel_o(display_sel_o),
        .display_we_o (display_we_o),
        .display_rdata_i(display_rdata_i),
        .led_sel_o    (led_sel_o),
        .led_we_o     (led_we_o),
        .led_rdata_i  (led_rdata_i),
        .buzzer_sel_o (buzzer_sel_o),
        .buzzer_we_o  (buzzer_we_o),
        .buzzer_rdata_i(buzzer_rdata_i),
        .vga_sel_o    (vga_sel_o),
        .vga_we_o     (vga_we_o),
        .vga_addr_o   (vga_addr_o),
        .vga_rdata_i  (vga_rdata_i)
    );
endmodule
