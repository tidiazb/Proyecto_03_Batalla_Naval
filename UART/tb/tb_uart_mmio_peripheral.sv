`timescale 1ns/1ps
module tb_uart_mmio_peripheral;
    localparam integer DIV = 4;
    localparam integer BIT_CYCLES = DIV * 16;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst = 1, select = 1, we = 0, serial_rx = 1;
    logic [1:0] addr = 0;
    logic [31:0] wdata = 0, rdata;
    logic serial_tx;

    uart_mmio_peripheral #(.BR_LIMIT(DIV), .BR_BITS(3)) dut (
        .clk_i(clk), .rst_i(rst), .select_i(select),
        .write_enable_i(we), .addr_i(addr), .wdata_i(wdata), .rdata_o(rdata),
        .uart_rx_i(serial_rx), .uart_tx_o(serial_tx)
    );
    task automatic write_reg(input logic [1:0] a, input logic [31:0] v);
        @(negedge clk); addr=a; wdata=v; we=1;
        @(negedge clk); we=0; wdata=0;
    endtask
    task automatic read_check(input logic [1:0] a,
                              input logic [31:0] mask,
                              input logic [31:0] expected,
                              input string label_text);
        addr=a; #1;
        if ((rdata & mask) !== expected)
            $fatal(1,"FAIL UART %s esperado=%h obtenido=%h",label_text,
                   expected,rdata & mask);
    endtask
    task automatic capture_byte(input logic [7:0] expected);
        logic [7:0] actual;
        @(negedge serial_tx);
        repeat (BIT_CYCLES/2) @(posedge clk);
        #1;
        if (serial_tx !== 0) $fatal(1,"FAIL UART: start");
        repeat (BIT_CYCLES) @(posedge clk);
        #1;
        for (integer i=0; i<8; i=i+1) begin
            actual[i]=serial_tx;
            repeat (BIT_CYCLES) @(posedge clk);
            #1;
        end
        if (serial_tx !== 1 || actual !== expected)
            $fatal(1,"FAIL UART TX esperado=%h recibido=%h stop=%b",
                   expected,actual,serial_tx);
    endtask
    task automatic send_byte(input logic [7:0] value);
        @(negedge clk); serial_rx=0;
        repeat (BIT_CYCLES) @(negedge clk);
        for (integer i=0; i<8; i=i+1) begin
            serial_rx=value[i];
            repeat (BIT_CYCLES) @(negedge clk);
        end
        serial_rx=1;
        repeat (BIT_CYCLES) @(negedge clk);
    endtask
    initial begin
        repeat (5) @(negedge clk); rst=0;
        read_check(0,32'h3,32'h2,"TX lista y RX vacia");

        fork
            begin capture_byte(8'h41); capture_byte(8'h42); end
            begin write_reg(1,32'h41); write_reg(1,32'h42); end
        join
        read_check(1,32'hFF,32'h42,"ultimo TX aceptado");

        // El CPU no debe escribir cuando TX_READY=0; el intento queda registrado.
        for (integer k=0; k<5; k=k+1)
            write_reg(1,32'h0000_0030+k);
        read_check(0,32'h12,32'h10,"TX llena y overrun");
        write_reg(0,32'h0000_0010); // W1C TX_OVERRUN
        read_check(0,32'h10,32'h0,"limpieza TX overrun");

        send_byte(8'h58); send_byte(8'h59);
        repeat (5) @(negedge clk);
        read_check(0,32'h1,32'h1,"RX disponible");
        read_check(2,32'hFF,32'h58,"primero RX");
        write_reg(0,32'h0000_0100); // RX_POP
        read_check(2,32'hFF,32'h59,"segundo RX");
        write_reg(0,32'h0000_0100);
        read_check(0,32'h1,32'h0,"RX vacia tras dos pop");

        // Cuatro espacios disponibles. El quinto dato recibido indica overrun.
        for (integer j=0; j<5; j=j+1) send_byte(8'h30 + j);
        repeat (5) @(negedge clk);
        read_check(0,32'hD,32'hD,"RX llena y overrun");
        read_check(2,32'hFF,32'h30,"RX conserva primer dato");
        write_reg(0,32'h0000_0008); // W1C RX_OVERRUN
        read_check(0,32'h8,32'h0,"limpieza overrun");

        select=0; addr=2; #1;
        if (rdata !== 0) $fatal(1,"FAIL UART: lectura sin select");
        $display("PASS tb_uart_mmio_peripheral"); $finish;
    end
    initial begin
        #500000;
        $fatal(1,"FAIL UART: timeout");
    end
endmodule
