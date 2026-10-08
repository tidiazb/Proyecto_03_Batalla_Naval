`timescale 1ns / 1ps

// ============================================================
// Testbench: tb_video_ram
// Descripción:
//   Verifica el funcionamiento de la memoria de video de doble
//   puerto utilizada por el subsistema VGA.
//
//   El testbench realiza escrituras mediante el puerto A y
//   comprueba posteriormente que los datos puedan recuperarse
//   correctamente tanto desde el mismo puerto como desde el
//   puerto B utilizado por el sistema VGA.
//
//   Se prueban diferentes direcciones dentro del rango de 0 a
//   299 y distintos datos de 32 bits. También se verifica que
//   los datos almacenados en posiciones diferentes permanezcan
//   independientes y que las lecturas respeten el comportamiento
//   síncrono de la memoria.
// ============================================================

module tb_video_ram;

    logic        clk_a;
    logic        we_a;
    logic [8:0]  addr_a;
    logic [31:0] wdata_a;
    logic [31:0] rdata_a;

    logic        clk_b;
    logic [8:0]  addr_b;
    logic [31:0] rdata_b;

    int errores;

    video_ram dut (
        .clk_a   (clk_a),
        .we_a    (we_a),
        .addr_a  (addr_a),
        .wdata_a (wdata_a),
        .rdata_a (rdata_a),

        .clk_b   (clk_b),
        .addr_b  (addr_b),
        .rdata_b (rdata_b)
    );

    initial begin
        clk_a = 1'b0;
        forever #5 clk_a = ~clk_a;
    end

    initial begin
        clk_b = 1'b0;
        forever #20 clk_b = ~clk_b;
    end

    task automatic escribir (
        input logic [8:0]  direccion,
        input logic [31:0] dato
    );
        begin
            @(negedge clk_a);

            addr_a  = direccion;
            wdata_a = dato;
            we_a    = 1'b1;

            @(posedge clk_a);
            #1;

            @(negedge clk_a);
            we_a = 1'b0;
        end
    endtask

    task automatic verificar_puerto_a (
        input logic [8:0]  direccion,
        input logic [31:0] esperado
    );
        begin
            @(negedge clk_a);

            addr_a = direccion;
            we_a   = 1'b0;

            @(posedge clk_a);
            #1;

            if (rdata_a !== esperado) begin
                $error(
                    "Puerto A: direccion=%0d esperado=%h obtenido=%h",
                    direccion,
                    esperado,
                    rdata_a
                );

                errores++;
            end
        end
    endtask

    task automatic verificar_puerto_b (
        input logic [8:0]  direccion,
        input logic [31:0] esperado
    );
        begin
            @(negedge clk_b);

            addr_b = direccion;

            @(posedge clk_b);
            #1;

            if (rdata_b !== esperado) begin
                $error(
                    "Puerto B: direccion=%0d esperado=%h obtenido=%h",
                    direccion,
                    esperado,
                    rdata_b
                );

                errores++;
            end
        end
    endtask

    initial begin

        errores = 0;

        we_a    = 1'b0;
        addr_a  = 9'd0;
        wdata_a = 32'd0;

        addr_b  = 9'd0;

        // Escritura de diferentes posiciones de la memoria
        escribir(9'd0,   32'h12345678);
        escribir(9'd43,  32'hAABBCCDD);
        escribir(9'd159, 32'h11223344);
        escribir(9'd299, 32'hDEADBEEF);

        // Verificación mediante el puerto A
        verificar_puerto_a(9'd0,   32'h12345678);
        verificar_puerto_a(9'd43,  32'hAABBCCDD);
        verificar_puerto_a(9'd159, 32'h11223344);
        verificar_puerto_a(9'd299, 32'hDEADBEEF);

        // Verificación de los mismos datos mediante el puerto B
        verificar_puerto_b(9'd0,   32'h12345678);
        verificar_puerto_b(9'd43,  32'hAABBCCDD);
        verificar_puerto_b(9'd159, 32'h11223344);
        verificar_puerto_b(9'd299, 32'hDEADBEEF);

        // Modificación de una posición existente
        escribir(9'd43, 32'hCAFEBABE);

        // Verifica el nuevo valor
        verificar_puerto_a(9'd43, 32'hCAFEBABE);
        verificar_puerto_b(9'd43, 32'hCAFEBABE);

        // Comprueba que otras posiciones no fueron modificadas
        verificar_puerto_b(9'd0,   32'h12345678);
        verificar_puerto_b(9'd159, 32'h11223344);
        verificar_puerto_b(9'd299, 32'hDEADBEEF);

        if (errores == 0) begin
            $display("============================================");
            $display("TB VIDEO RAM: TODAS LAS PRUEBAS PASARON");
            $display("============================================");
        end
        else begin
            $display("============================================");
            $display("TB VIDEO RAM: %0d ERRORES", errores);
            $display("============================================");
        end

        $finish;

    end

endmodule
