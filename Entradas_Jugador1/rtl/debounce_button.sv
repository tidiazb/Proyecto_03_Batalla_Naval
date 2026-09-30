`timescale 1ns/1ps

// Sincroniza una entrada fisica, filtra rebotes y produce un pulso por pulsacion.
module debounce_button #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer DEBOUNCE_MS = 20
) (
    input  logic clk_i,
    input  logic rst_i,
    input  logic button_raw_i,
    output logic button_level_o,
    output logic pressed_pulse_o
);
    localparam integer CYCLES_CALC = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
    localparam integer CYCLES = (CYCLES_CALC < 1) ? 1 : CYCLES_CALC;
    localparam integer COUNT_W = (CYCLES <= 1) ? 1 : $clog2(CYCLES);
    localparam logic [COUNT_W-1:0] LAST_COUNT = CYCLES - 1;

    logic sync_1_r, sync_2_r;
    logic [COUNT_W-1:0] stable_count_r;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            sync_1_r <= 1'b0;
            sync_2_r <= 1'b0;
        end else begin
            sync_1_r <= button_raw_i;
            sync_2_r <= sync_1_r;
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            button_level_o  <= 1'b0;
            pressed_pulse_o <= 1'b0;
            stable_count_r  <= '0;
        end else begin
            pressed_pulse_o <= 1'b0;
            if (sync_2_r == button_level_o) begin
                stable_count_r <= '0;
            end else if (stable_count_r == LAST_COUNT) begin
                button_level_o <= sync_2_r;
                stable_count_r <= '0;
                if (sync_2_r)
                    pressed_pulse_o <= 1'b1;
            end else begin
                stable_count_r <= stable_count_r + 1'b1;
            end
        end
    end
endmodule
