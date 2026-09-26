`timescale 1ns/1ps

module tb_j1_inputs_peripheral;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst = 1;
    logic [6:0] raw = 0;
    logic sel = 0, we = 0;
    logic [31:0] wdata = 0, rdata;

    j1_inputs_peripheral #(.CLK_FREQ_HZ(1000), .DEBOUNCE_MS(3)) dut (
        .clk_i(clk), .rst_i(rst),
        .btn_up_raw_i(raw[0]), .btn_down_raw_i(raw[1]),
        .btn_left_raw_i(raw[2]), .btn_right_raw_i(raw[3]),
        .btn_sel_raw_i(raw[4]), .btn_ok_raw_i(raw[5]),
        .btn_rst_raw_i(raw[6]),
        .select_i(sel), .write_enable_i(we), .wdata_i(wdata), .rdata_o(rdata)
    );

    task automatic drive(input logic [6:0] value, input integer cycles);
        @(negedge clk);
        raw = value;
        repeat (cycles) @(negedge clk);
    endtask

    task automatic check(input logic [31:0] expected, input string label_text);
        #1;
        if (rdata !== expected)
            $fatal(1, "FAIL J1 %s esperado=%h obtenido=%h", label_text,
                   expected, rdata);
    endtask

    task automatic acknowledge(input logic [6:0] mask);
        @(negedge clk);
        wdata = {17'b0, mask, 8'b0};
        we = 1;
        @(negedge clk);
        we = 0;
        wdata = 0;
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst = 0; sel = 1;
        check(0, "estado inicial");

        // Una escritura sin select no afecta los eventos.
        for (integer i = 0; i < 7; i = i + 1) begin
            drive(7'b0, 8);
            drive(7'b1 << i, 1);
            drive(7'b0, 1);
            drive(7'b1 << i, 8);
            check((32'h0000_0101 << i), "nivel y evento para cada boton");
            drive(7'b0, 8);
            check(32'h0000_0100 << i, "evento persistente tras soltar");
            sel = 0;
            check(0, "lectura sin seleccion");
            @(negedge clk);
            we = 1; wdata = 32'h0000_7F00;
            @(negedge clk);
            we = 0; wdata = 0; sel = 1;
            check(32'h0000_0100 << i, "escritura sin seleccion");
            acknowledge(7'b1 << i);
            check(0, "W1C reconoce evento");
        end

        drive(7'b0010011, 8);  // Arriba, abajo y SEL a la vez.
        check(32'h0000_1313, "botones simultaneos");
        drive(7'b0, 8);
        acknowledge(7'h7F);
        check(0, "limpieza simultanea");

        drive(7'b1000000, 8); // BTN RST es visible al software.
        check(32'h0000_4040, "BTN RST no borra periferico");
        @(negedge clk); rst = 1;
        @(negedge clk); rst = 0; raw = 0;
        check(0, "reset fisico independiente");
        $display("PASS tb_j1_inputs_peripheral");
        $finish;
    end
endmodule
