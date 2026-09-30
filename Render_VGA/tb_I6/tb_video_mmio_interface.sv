`timescale 1ns / 1ps

/*
 * Testbench: tb_video_mmio_interface
 *
 * Descripción:
 * Verifica el funcionamiento de la interfaz MMIO de video encargada
 * de convertir las direcciones utilizadas por el procesador RISC-V
 * en direcciones internas de la Video RAM.
 *
 * Se comprueba la primera y última dirección válida, direcciones
 * intermedias, propagación correcta de los datos de escritura,
 * funcionamiento de write enable, rechazo de direcciones fuera
 * del rango asignado y rechazo de direcciones no alineadas a
 * palabras de 32 bits.
 *
 * El testbench es autoverificable y reporta automáticamente si
 * todas las pruebas pasaron o si se detectaron errores.
 */

module tb_video_mmio_interface;

    logic [31:0] addr_i;
    logic [31:0] wdata_i;
    logic        we_i;

    logic        video_we_o;
    logic [8:0]  video_addr_o;
    logic [31:0] video_wdata_o;

    integer errores;


    video_mmio_interface dut (

        .addr_i        (addr_i),
        .wdata_i       (wdata_i),
        .we_i          (we_i),

        .video_we_o    (video_we_o),
        .video_addr_o  (video_addr_o),
        .video_wdata_o (video_wdata_o)

    );


    task automatic comprobar(
        input logic [31:0] direccion,
        input logic [31:0] dato,
        input logic        escritura,
        input logic        we_esperado,
        input logic [8:0]  addr_esperada
    );

        begin

            addr_i  = direccion;
            wdata_i = dato;
            we_i    = escritura;

            #1;

            if (video_we_o !== we_esperado) begin

                $display(
                    "ERROR WE: addr=%h esperado=%b obtenido=%b",
                    direccion,
                    we_esperado,
                    video_we_o
                );

                errores = errores + 1;

            end


            if (video_addr_o !== addr_esperada) begin

                $display(
                    "ERROR ADDR: addr=%h esperado=%0d obtenido=%0d",
                    direccion,
                    addr_esperada,
                    video_addr_o
                );

                errores = errores + 1;

            end


            if (video_wdata_o !== dato) begin

                $display(
                    "ERROR DATA: esperado=%h obtenido=%h",
                    dato,
                    video_wdata_o
                );

                errores = errores + 1;

            end

        end

    endtask


    initial begin

        errores = 0;

        addr_i  = 32'd0;
        wdata_i = 32'd0;
        we_i    = 1'b0;

        #1;


        // Primera dirección de Video RAM
        comprobar(
            32'h0001_1000,
            32'h0000_0001,
            1'b1,
            1'b1,
            9'd0
        );


        // Segunda palabra
        comprobar(
            32'h0001_1004,
            32'h0000_0002,
            1'b1,
            1'b1,
            9'd1
        );


        // Dirección correspondiente al tile 4
        comprobar(
            32'h0001_1010,
            32'h1234_5678,
            1'b1,
            1'b1,
            9'd4
        );


        // Dirección intermedia
        comprobar(
            32'h0001_1100,
            32'hCAFE_BABE,
            1'b1,
            1'b1,
            9'd64
        );


        // Última palabra válida
        comprobar(
            32'h0001_17FC,
            32'hDEAD_BEEF,
            1'b1,
            1'b1,
            9'd511
        );


        // Dirección válida pero sin escritura
        comprobar(
            32'h0001_1020,
            32'hAAAA_5555,
            1'b0,
            1'b0,
            9'd8
        );


        // Dirección inferior al rango
        comprobar(
            32'h0001_0FFC,
            32'h1111_1111,
            1'b1,
            1'b0,
            9'd0
        );


        // Dirección superior al rango
        comprobar(
            32'h0001_1800,
            32'h2222_2222,
            1'b1,
            1'b0,
            9'd0
        );


        // Dirección no alineada
        comprobar(
            32'h0001_1002,
            32'h3333_3333,
            1'b1,
            1'b0,
            9'd0
        );


        #1;


        $display("");
        $display("============================================");

        if (errores == 0) begin

            $display(
                "TB VIDEO MMIO INTERFACE: TODAS LAS PRUEBAS PASARON"
            );

        end
        else begin

            $display(
                "TB VIDEO MMIO INTERFACE: %0d ERRORES",
                errores
            );

        end

        $display("============================================");
        $display("");

        $finish;

    end

endmodule