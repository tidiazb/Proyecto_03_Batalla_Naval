`timescale 1ns/1ps

// Interconexion combinacional para accesos lw/sw de 32 bits.
// La ROM de programa tiene un puerto independiente y no pasa por este modulo.
module mmio_interconnect (
    input  logic [31:0] cpu_addr_i,
    input  logic [31:0] cpu_wdata_i,
    input  logic        cpu_we_i,
    output logic [31:0] cpu_rdata_o,

    output logic [31:0] bus_wdata_o,

    output logic        ram_sel_o,
    output logic        ram_we_o,
    output logic [9:0]  ram_addr_o,
    input  logic [31:0] ram_rdata_i,

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
    localparam logic [31:0] RAM_FIRST = 32'h0000_2000;
    localparam logic [31:0] RAM_LAST  = 32'h0000_2FFF;
    localparam logic [31:0] VGA_FIRST = 32'h0001_1000;
    localparam logic [31:0] VGA_LAST  = 32'h0001_17FF;

    // El dato de escritura se distribuye a todos; solo un WE puede habilitarse.
    assign bus_wdata_o = cpu_wdata_i;

    always_comb begin
        cpu_rdata_o   = 32'b0;
        ram_sel_o     = 1'b0;
        uart_sel_o    = 1'b0;
        gpio_sel_o    = 1'b0;
        display_sel_o = 1'b0;
        led_sel_o     = 1'b0;
        buzzer_sel_o  = 1'b0;
        vga_sel_o     = 1'b0;
        ram_addr_o    = 10'b0;
        uart_addr_o   = 2'b0;
        vga_addr_o    = 9'b0;

        // Solo se admiten accesos de palabra alineados (lw/sw).
        if (cpu_addr_i[1:0] == 2'b00) begin
            if ((cpu_addr_i >= RAM_FIRST) && (cpu_addr_i <= RAM_LAST)) begin
                ram_sel_o   = 1'b1;
                ram_addr_o  = cpu_addr_i[11:2];
                cpu_rdata_o = ram_rdata_i;
            end else if ((cpu_addr_i >= VGA_FIRST) &&
                         (cpu_addr_i <= VGA_LAST)) begin
                vga_sel_o   = 1'b1;
                vga_addr_o  = cpu_addr_i[10:2];
                cpu_rdata_o = vga_rdata_i;
            end else begin
                case (cpu_addr_i)
                    32'h0001_0040, 32'h0001_0044, 32'h0001_0048: begin
                        uart_sel_o   = 1'b1;
                        uart_addr_o  = cpu_addr_i[3:2]; // 00, 01, 10
                        cpu_rdata_o  = uart_rdata_i;
                    end
                    32'h0001_0120: begin
                        gpio_sel_o   = 1'b1;
                        cpu_rdata_o  = gpio_rdata_i;
                    end
                    32'h0001_0130: begin
                        display_sel_o = 1'b1;
                        cpu_rdata_o   = display_rdata_i;
                    end
                    32'h0001_0138: begin
                        led_sel_o     = 1'b1;
                        cpu_rdata_o   = led_rdata_i;
                    end
                    32'h0001_0140: begin
                        buzzer_sel_o  = 1'b1;
                        cpu_rdata_o   = buzzer_rdata_i;
                    end
                    default: begin
                        // Sin destino: lectura cero y ninguna escritura.
                    end
                endcase
            end
        end
    end

    // Cada periferico recibe su propio pulso de escritura.
    assign ram_we_o     = cpu_we_i && ram_sel_o;
    assign uart_we_o    = cpu_we_i && uart_sel_o;
    assign gpio_we_o    = cpu_we_i && gpio_sel_o;
    assign display_we_o = cpu_we_i && display_sel_o;
    assign led_we_o     = cpu_we_i && led_sel_o;
    assign buzzer_we_o  = cpu_we_i && buzzer_sel_o;
    assign vga_we_o     = cpu_we_i && vga_sel_o;
endmodule
