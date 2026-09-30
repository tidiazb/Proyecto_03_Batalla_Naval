`timescale 1ns/1ps

module tb_debounce_button;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst = 1;
    logic raw = 0;
    logic level, pulse;
    integer pulses = 0;

    debounce_button #(.CLK_FREQ_HZ(1000), .DEBOUNCE_MS(3)) dut (
        .clk_i(clk), .rst_i(rst), .button_raw_i(raw),
        .button_level_o(level), .pressed_pulse_o(pulse)
    );

    always @(posedge clk) begin
        #1;
        if (pulse) pulses = pulses + 1;
    end

    task automatic drive(input logic value, input integer cycles);
        @(negedge clk);
        raw = value;
        repeat (cycles) @(negedge clk);
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst = 0;
        drive(1, 1); drive(0, 1); drive(1, 1); drive(0, 5);
        if (level !== 0 || pulses != 0) $fatal(1, "FAIL debounce: rebote corto");
        drive(1, 8);
        if (level !== 1 || pulses != 1) $fatal(1, "FAIL debounce: pulsacion");
        drive(0, 1); drive(1, 8);
        if (level !== 1 || pulses != 1) $fatal(1, "FAIL debounce: rebote presionado");
        drive(0, 8);
        if (level !== 0 || pulses != 1) $fatal(1, "FAIL debounce: liberacion");
        drive(1, 8);
        if (level !== 1 || pulses != 2) $fatal(1, "FAIL debounce: segunda pulsacion");
        $display("PASS tb_debounce_button");
        $finish;
    end
endmodule
