`timescale 1ns/1ps
module tb_uart_mmio_fifo;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst = 1, push = 0, pop = 0;
    logic [7:0] wdata = 0, rdata;
    logic empty, full;
    uart_mmio_fifo #(.ADDR_BITS(1)) dut (
        .clk_i(clk), .rst_i(rst), .push_i(push), .wdata_i(wdata),
        .pop_i(pop), .rdata_o(rdata), .empty_o(empty), .full_o(full)
    );
    task automatic step(input logic p, input logic q, input logic [7:0] b);
        @(negedge clk); push=p; pop=q; wdata=b;
        @(negedge clk); push=0; pop=0;
    endtask
    initial begin
        repeat (3) @(negedge clk); rst=0;
        if (!empty || full) $fatal(1,"FAIL FIFO: estado inicial");
        step(1,0,8'h41); step(1,0,8'h42);
        if (!full || rdata !== 8'h41) $fatal(1,"FAIL FIFO: llena/orden");
        step(1,0,8'h58);
        if (rdata !== 8'h41) $fatal(1,"FAIL FIFO: escritura llena");
        step(1,1,8'h43);
        if (!full || rdata !== 8'h42) $fatal(1,"FAIL FIFO: push/pop llena");
        step(0,1,0);
        if (rdata !== 8'h43) $fatal(1,"FAIL FIFO: segundo dato");
        step(0,1,0);
        if (!empty || rdata !== 0) $fatal(1,"FAIL FIFO: vacia");
        step(1,1,8'h44); // Cuando esta vacia, push se acepta y pop se ignora.
        if (empty || rdata !== 8'h44) $fatal(1,"FAIL FIFO: push/pop vacia");
        $display("PASS tb_uart_mmio_fifo"); $finish;
    end
endmodule
