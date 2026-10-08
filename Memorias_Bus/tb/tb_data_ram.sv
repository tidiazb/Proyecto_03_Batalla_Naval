`timescale 1ns/1ps

module tb_data_ram;
    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic select, we;
    logic [9:0] address;
    logic [31:0] wdata, rdata;

    data_ram dut (
        .clk_i(clk), .select_i(select), .write_enable_i(we),
        .word_addr_i(address), .wdata_i(wdata), .rdata_o(rdata)
    );

    task automatic expect_data(input logic [31:0] value, input string description);
        #1;
        if (rdata !== value)
            $fatal(1, "FAIL RAM %s: esperado=%h real=%h", description, value, rdata);
    endtask

    task automatic store(input logic [9:0] addr, input logic [31:0] value);
        @(negedge clk);
        select = 1'b1;
        we = 1'b1;
        address = addr;
        wdata = value;
        @(posedge clk);
        #1;
        we = 1'b0;
    endtask

    initial begin
        select = 1'b1; we = 1'b0; address = 10'd0; wdata = 32'b0;
        expect_data(32'b0, "estado de encendido");
        store(10'd0, 32'hDEAD_BEEF);
        expect_data(32'hDEAD_BEEF, "escritura en primera palabra");
        store(10'd1023, 32'hCAFE_1234);
        expect_data(32'hCAFE_1234, "escritura en ultima palabra");
        address = 10'd0;
        expect_data(32'hDEAD_BEEF, "palabras independientes");

        // Aunque WE este activo, sin seleccion no debe alterarse RAM.
        @(negedge clk);
        select = 1'b0; we = 1'b1; address = 10'd0; wdata = 32'h1111_1111;
        @(posedge clk);
        #1;
        expect_data(32'b0, "lectura deseleccionada");
        select = 1'b1; we = 1'b0;
        expect_data(32'hDEAD_BEEF, "escritura deseleccionada ignorada");
        $display("PASS tb_data_ram");
        $finish;
    end
endmodule
