`timescale 1ns / 1ps

//============================================================
// Módulo: seven_seg_decoder
// Issue #10 - Displays de 7 segmentos
//
// Función:
// Convierte un dígito decimal (0-9) en el patrón necesario
// para un display de 7 segmentos.
//
// Salida:
// seg[6:0] = {a,b,c,d,e,f,g}
//
// Se asume display ACTIVO EN BAJO:
//   0 = segmento encendido
//   1 = segmento apagado
//
// Para valores mayores que 9, el display se apaga.
//============================================================

module seven_seg_decoder (
    input  logic [3:0] digit,
    output logic [6:0] seg
);

    always_comb begin
        case (digit)

            4'd0: seg = 7'b0000001;
            4'd1: seg = 7'b1001111;
            4'd2: seg = 7'b0010010;
            4'd3: seg = 7'b0000110;
            4'd4: seg = 7'b1001100;
            4'd5: seg = 7'b0100100;
            4'd6: seg = 7'b0100000;
            4'd7: seg = 7'b0001111;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0000100;

            // Cualquier valor fuera de 0-9 apaga el display
            default: seg = 7'b1111111;

        endcase
    end

endmodule