`timescale 1ns/1ps

// La direccion absoluta la decodifica mmio_interconnect.
// addr=0: CONTROL; addr=1: DATA_TX; addr=2: DATA_RX.
module uart_mmio_peripheral #(
    parameter integer BR_LIMIT = 54,
    parameter integer BR_BITS = 6,
    parameter integer FIFO_BITS = 2
) (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        select_i,
    input  logic        write_enable_i,
    input  logic [1:0]  addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,
    input  logic        uart_rx_i,
    output logic        uart_tx_o
);
    localparam logic [1:0] ADDR_CONTROL = 2'd0;
    localparam logic [1:0] ADDR_TX      = 2'd1;
    localparam logic [1:0] ADDR_RX      = 2'd2;

    logic sample_tick, rx_done, tx_done;
    logic [7:0] rx_byte, rx_head, tx_head, tx_last_r;
    logic rx_empty, rx_full, tx_empty, tx_full;
    logic rx_overrun_r, tx_overrun_r;
    logic write_control, write_tx, rx_pop, tx_push;
    logic rx_meta_r, rx_sync_r;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            rx_meta_r <= 1'b1;
            rx_sync_r <= 1'b1;
        end else begin
            rx_meta_r <= uart_rx_i;
            rx_sync_r <= rx_meta_r;
        end
    end

    assign write_control = select_i && write_enable_i && (addr_i == ADDR_CONTROL);
    assign write_tx      = select_i && write_enable_i && (addr_i == ADDR_TX);
    assign rx_pop        = write_control && wdata_i[8] && !rx_empty;
    assign tx_push       = write_tx && !tx_full;

    // A 100 MHz: 100e6 / (54 * 16) = 115740.7 baudios (error +0.47%).
    baud_rate_generator #(.M(BR_LIMIT), .N(BR_BITS)) u_baud (
        .clk_100MHz(clk_i), .reset(rst_i), .tick(sample_tick)
    );
    uart_receiver #(.DBITS(8), .SB_TICK(16)) u_rx (
        .clk_100MHz(clk_i), .reset(rst_i), .rx(rx_sync_r),
        .sample_tick(sample_tick), .data_ready(rx_done), .data_out(rx_byte)
    );
    uart_transmitter #(.DBITS(8), .SB_TICK(16)) u_tx (
        .clk_100MHz(clk_i), .reset(rst_i), .tx_start(!tx_empty),
        .sample_tick(sample_tick), .data_in(tx_head),
        .tx_done(tx_done), .tx(uart_tx_o)
    );
    uart_mmio_fifo #(.ADDR_BITS(FIFO_BITS)) u_rx_fifo (
        .clk_i(clk_i), .rst_i(rst_i),
        .push_i(rx_done), .wdata_i(rx_byte), .pop_i(rx_pop),
        .rdata_o(rx_head), .empty_o(rx_empty), .full_o(rx_full)
    );
    uart_mmio_fifo #(.ADDR_BITS(FIFO_BITS)) u_tx_fifo (
        .clk_i(clk_i), .rst_i(rst_i),
        .push_i(tx_push), .wdata_i(wdata_i[7:0]), .pop_i(tx_done),
        .rdata_o(tx_head), .empty_o(tx_empty), .full_o(tx_full)
    );

    // Los errores permanecen visibles hasta que el CPU escriba 1 para limpiarlos.
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_last_r    <= 8'b0;
            rx_overrun_r <= 1'b0;
            tx_overrun_r <= 1'b0;
        end else begin
            if (tx_push)
                tx_last_r <= wdata_i[7:0];
            if (write_control && wdata_i[3])
                rx_overrun_r <= 1'b0;
            if (write_control && wdata_i[4])
                tx_overrun_r <= 1'b0;
            if (rx_done && rx_full && !rx_pop)
                rx_overrun_r <= 1'b1;
            if (write_tx && tx_full)
                tx_overrun_r <= 1'b1;
        end
    end

    always_comb begin
        rdata_o = 32'b0;
        if (select_i) begin
            case (addr_i)
                ADDR_CONTROL: begin
                    rdata_o[0] = !rx_empty;  // RX_VALID
                    rdata_o[1] = !tx_full;   // TX_READY (espacio en cola)
                    rdata_o[2] = rx_full;    // RX_FULL
                    rdata_o[3] = rx_overrun_r;
                    rdata_o[4] = tx_overrun_r;
                end
                ADDR_TX: rdata_o[7:0] = tx_last_r;
                ADDR_RX: rdata_o[7:0] = rx_head;
                default: rdata_o = 32'b0;
            endcase
        end
    end
endmodule
