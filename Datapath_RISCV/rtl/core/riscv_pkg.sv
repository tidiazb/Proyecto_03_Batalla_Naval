package riscv_pkg;
    localparam int XLEN        = 32;           // ancho de palabra
    localparam int REG_ADDR_W  = 5;            // 32 registros -> 5 bits
    localparam logic [31:0] RESET_VECTOR = 32'h0000_0000;  // spec: inicio en 0x0

endpackage