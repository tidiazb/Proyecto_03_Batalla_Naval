// ============================================================================
// tb_riscv_core.sv - Testbench autoverificable del NÚCLEO COMPLETO
// (control_unit real de Control_RISCV + datapath de Datapath_RISCV)
//
// Usa exactamente los mismos programas y el mismo modelo de referencia (ISS)
// que tb_datapath, pero el DUT se conecta únicamente por los puertos de la
// Figura 2 (ProgAddress_o, ProgIn_i, DataAddress_o, DataOut_o, DataIn_i, we_o).
// En cada ciclo se compara PC, los 32 registros y el bus de datos contra el
// ISS; al final la RAM completa y una firma calculada a mano.
// ============================================================================
`timescale 1ns/1ps
module tb_riscv_core;
  import riscv_pkg::*;
  import rv32i_enc_pkg::*;

  logic clk = 0, rst = 1;
  always #5 clk = ~clk;

  logic [31:0] prog_addr, instr, data_addr, data_wdata, data_rdata;
  logic        data_we;
  logic        ctl_branch, branch_taken;   // espiados solo para el chequeo

  riscv_core dut (
    .clk_i         (clk),
    .rst_i         (rst),
    .ProgAddress_o (prog_addr),
    .ProgIn_i      (instr),
    .DataAddress_o (data_addr),
    .DataOut_o     (data_wdata),
    .DataIn_i      (data_rdata),
    .we_o          (data_we)
  );

  assign ctl_branch   = dut.branch;
  assign branch_taken = dut.branch_taken;

`define DP      dut.u_dp
`define TB_NAME "tb_riscv_core"
`include "rv32i_lockstep.svh"

endmodule
