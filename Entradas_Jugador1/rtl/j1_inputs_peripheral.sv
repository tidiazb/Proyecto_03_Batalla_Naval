`timescale 1ns/1ps

// Registro ESTADO en 0x0001_0120, seleccionado por el decoder del Issue #4.
// Bits 6:0: niveles estables; bits 14:8: pulsaciones pendientes (W1C).
module j1_inputs_peripheral #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer DEBOUNCE_MS = 20
) (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        btn_up_raw_i,
    input  logic        btn_down_raw_i,
    input  logic        btn_left_raw_i,
    input  logic        btn_right_raw_i,
    input  logic        btn_sel_raw_i,
    input  logic        btn_ok_raw_i,
    input  logic        btn_rst_raw_i,
    input  logic        select_i,
    input  logic        write_enable_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o
);
    // Bit i en las tres palabras representa el mismo boton.
    logic [6:0] raw_buttons;
    logic [6:0] levels;
    logic [6:0] press_pulses;
    logic [6:0] pending_r;

    assign raw_buttons = {btn_rst_raw_i, btn_ok_raw_i, btn_sel_raw_i,
                          btn_right_raw_i, btn_left_raw_i,
                          btn_down_raw_i, btn_up_raw_i};

    for (genvar i = 0; i < 7; i = i + 1) begin : g_buttons
        debounce_button #(
            .CLK_FREQ_HZ(CLK_FREQ_HZ), .DEBOUNCE_MS(DEBOUNCE_MS)
        ) u_debounce (
            .clk_i(clk_i), .rst_i(rst_i),
            .button_raw_i(raw_buttons[i]),
            .button_level_o(levels[i]),
            .pressed_pulse_o(press_pulses[i])
        );
    end

    // Escribir 1 en bits 14:8 reconoce eventos previos.
    // Si una pulsacion nueva coincide con la escritura, prevalece el evento.
    always_ff @(posedge clk_i) begin
        if (rst_i)
            pending_r <= '0;
        else begin
            pending_r <= (pending_r &
                         ~({7{select_i && write_enable_i}} & wdata_i[14:8]))
                         | press_pulses;
        end
    end

    assign rdata_o = select_i ? {17'b0, pending_r, 1'b0, levels} : 32'b0;
endmodule
