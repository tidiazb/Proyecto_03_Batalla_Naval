`timescale 1ns / 1ps

/*
 * Módulo: video_mmio_interface
 *
 * Descripción:
 * Implementa la interfaz entre el bus MMIO del procesador RISC-V y
 * la memoria de video utilizada por el núcleo VGA.
 *
 * El módulo detecta las escrituras realizadas dentro del rango
 * 0x0001_1000 - 0x0001_17FF y convierte la dirección de memoria
 * utilizada por el procesador en una dirección interna de palabra
 * de 9 bits para la Video RAM.
 *
 * Cada posición de la Video RAM corresponde a una palabra de
 * 32 bits, por lo que las direcciones consecutivas se encuentran
 * separadas por 4 bytes.
 *
 * Las escrituras realizadas fuera del rango de Video RAM son
 * ignoradas y no generan una señal de escritura hacia el núcleo VGA.
 *
 * Este módulo es combinacional. La escritura física de la memoria
 * ocurre posteriormente dentro de video_ram utilizando el reloj
 * correspondiente al puerto de escritura.
 */

module video_mmio_interface (

    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    input  logic        we_i,

    output logic        video_we_o,
    output logic [8:0]  video_addr_o,
    output logic [31:0] video_wdata_o

);

    localparam logic [31:0] VIDEO_BASE = 32'h0001_1000;
    localparam logic [31:0] VIDEO_END  = 32'h0001_17FF;

    logic address_valid;

    always_comb begin

        address_valid = 1'b0;

        video_we_o    = 1'b0;
        video_addr_o  = 9'd0;
        video_wdata_o = wdata_i;

        if ((addr_i >= VIDEO_BASE) &&
            (addr_i <= VIDEO_END)  &&
            (addr_i[1:0] == 2'b00)) begin

            address_valid = 1'b1;

            video_addr_o =
                (addr_i - VIDEO_BASE) >> 2;

            if (we_i)
                video_we_o = 1'b1;

        end

    end

endmodule