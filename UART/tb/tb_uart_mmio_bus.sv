`timescale 1ns/1ps
module tb_uart_mmio_bus;
    localparam integer BIT_CYCLES=64;
    localparam logic [7:0] EXPECTED_TX=8'h4B;
    logic clk=0;
    always #5 clk=~clk;
    logic rst=1, cpu_we=0, rx=1, tx, uart_sel, uart_we;
    logic [31:0] cpu_addr=0,cpu_wdata=0,cpu_rdata,bus_wdata,uart_rdata;
    logic [1:0] uart_addr;
    mmio_interconnect bus (
        .cpu_addr_i(cpu_addr),.cpu_wdata_i(cpu_wdata),.cpu_we_i(cpu_we),
        .cpu_rdata_o(cpu_rdata),.bus_wdata_o(bus_wdata),
        .ram_sel_o(),.ram_we_o(),.ram_addr_o(),.ram_rdata_i(32'b0),
        .uart_sel_o(uart_sel),.uart_we_o(uart_we),
        .uart_addr_o(uart_addr),.uart_rdata_i(uart_rdata),
        .gpio_sel_o(),.gpio_we_o(),.gpio_rdata_i(32'b0),
        .display_sel_o(),.display_we_o(),.display_rdata_i(32'b0),
        .led_sel_o(),.led_we_o(),.led_rdata_i(32'b0),
        .buzzer_sel_o(),.buzzer_we_o(),.buzzer_rdata_i(32'b0),
        .vga_sel_o(),.vga_we_o(),.vga_addr_o(),.vga_rdata_i(32'b0)
    );
    uart_mmio_peripheral #(.BR_LIMIT(4),.BR_BITS(3)) uart (
        .clk_i(clk),.rst_i(rst),.select_i(uart_sel),
        .write_enable_i(uart_we),.addr_i(uart_addr),
        .wdata_i(bus_wdata),.rdata_o(uart_rdata),
        .uart_rx_i(rx),.uart_tx_o(tx)
    );
    task automatic bus_write(input logic [31:0] a,input logic [31:0] v);
        @(negedge clk);cpu_addr=a;cpu_wdata=v;cpu_we=1;
        @(negedge clk);cpu_we=0;
    endtask
    initial begin
        repeat (4) @(negedge clk);rst=0;
        cpu_addr=32'h0001_0040;
        #1;
        if (!uart_sel || uart_addr!==0 || cpu_rdata[1]!==1)
            $fatal(1,"FAIL bus UART: control");
        bus_write(32'h0001_004C,32'h5A); // Direccion fuera del UART.
        if (uart_sel || uart_we || cpu_rdata!==0)
            $fatal(1,"FAIL bus UART: acceso invalido");
        fork
            begin
                @(negedge tx);
                repeat (BIT_CYCLES/2) @(posedge clk);
                #1;
                if (tx!==0) $fatal(1,"FAIL bus UART: start");
                repeat (BIT_CYCLES) @(posedge clk);
                #1;
                for(integer i=0;i<8;i=i+1) begin
                    if(tx!==EXPECTED_TX[i]) $fatal(1,"FAIL bus UART: bit TX %0d",i);
                    repeat (BIT_CYCLES) @(posedge clk);
                    #1;
                end
                if(tx!==1) $fatal(1,"FAIL bus UART: stop");
            end
            begin
                bus_write(32'h0001_0044,32'h4B);
                if(!uart_sel || uart_addr!==1) $fatal(1,"FAIL bus UART: TX addr");
            end
        join
        cpu_addr=32'h0001_0044;
        #1;
        if(cpu_rdata[7:0]!==8'h4B) $fatal(1,"FAIL bus UART: TX readback");
        cpu_addr=32'h0001_0048;
        #1;
        if(!uart_sel || uart_addr!==2 || cpu_rdata[7:0]!==0)
            $fatal(1,"FAIL bus UART: RX addr");
        $display("PASS tb_uart_mmio_bus");$finish;
    end
    initial begin
        #200000;
        $fatal(1,"FAIL bus UART: timeout");
    end
endmodule
