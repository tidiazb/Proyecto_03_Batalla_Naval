`timescale 1ns/1ps

// FIFO de bytes, profundidad 2**ADDR_BITS. Acepta push y pop en el mismo ciclo.
module uart_mmio_fifo #(
    parameter integer ADDR_BITS = 2
) (
    input  logic       clk_i,
    input  logic       rst_i,
    input  logic       push_i,
    input  logic [7:0] wdata_i,
    input  logic       pop_i,
    output logic [7:0] rdata_o,
    output logic       empty_o,
    output logic       full_o
);
    localparam integer DEPTH = 1 << ADDR_BITS;
    logic [7:0] memory [0:DEPTH-1];
    logic [ADDR_BITS-1:0] write_ptr_r, read_ptr_r;
    logic [ADDR_BITS:0] count_r;
    logic do_push, do_pop;

    assign empty_o = (count_r == 0);
    assign full_o  = (count_r == DEPTH);
    assign do_pop  = pop_i && !empty_o;
    assign do_push = push_i && (!full_o || do_pop);
    assign rdata_o = empty_o ? 8'b0 : memory[read_ptr_r];

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            write_ptr_r <= '0;
            read_ptr_r  <= '0;
            count_r     <= '0;
        end else begin
            if (do_push) begin
                memory[write_ptr_r] <= wdata_i;
                write_ptr_r <= write_ptr_r + 1'b1;
            end
            if (do_pop)
                read_ptr_r <= read_ptr_r + 1'b1;
            case ({do_push, do_pop})
                2'b10: count_r <= count_r + 1'b1;
                2'b01: count_r <= count_r - 1'b1;
                default: count_r <= count_r;
            endcase
        end
    end
endmodule
