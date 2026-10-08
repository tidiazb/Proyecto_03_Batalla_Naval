// ============================================================================
// tb_datapath.sv - Testbench autoverificable del DATAPATH INTEGRADO
//
// Arquitectura del testbench:
//
//   ROM (arreglo) --instr--> [datapath DUT] <--control-- [ref_control]
//                                 |   ^
//                    DataAddress  |   | DataIn   (RAM 0x2000-0x2FFF, lectura
//                    DataOut, we  v   |           combinacional, escritura sínc.)
//                               RAM (arreglo)
//
//   ISS (modelo de referencia del conjunto de instrucciones, escrito en SV
//   comportamental dentro de este archivo) ejecuta el MISMO programa.
//
// Chequeo en "lockstep": en cada ciclo se compara
//   - PC del DUT vs PC del ISS
//   - los 32 registros del DUT vs los del ISS
//   - we / DataAddress / DataOut del DUT vs lo esperado por el ISS
// Al final del programa se compara la RAM completa y una "firma" de
// resultados calculados a mano (independiente del ISS).
//
// Programas:
//   1) Programa dirigido: usa TODAS las instrucciones del enunciado
//      (+ lui/auipc), cada branch tomado y no tomado, lazos, llamadas a
//      subrutina con jal/jalr (ret), lw/sw con offsets positivos/negativos,
//      escritura a x0.
//   2) N_RAND_PROGS programas aleatorios de N_RAND_INSTR instrucciones
//      (ALU R/I, lui, auipc, lw/sw, branches y jal hacia adelante).
//
// Se reporta cobertura por instrucción y se exige que todas se ejecuten.
// ============================================================================
`timescale 1ns/1ps
module tb_datapath;
  import riscv_pkg::*;
  import rv32i_enc_pkg::*;


  // --------------------------------------------------------------------------
  // Reloj, reset y señales hacia el DUT
  // --------------------------------------------------------------------------
  logic clk = 0, rst = 1;
  always #5 clk = ~clk;

  logic [31:0] prog_addr, instr, data_addr, data_wdata, data_rdata;
  logic        data_we, branch_taken, alu_zero;
  logic        ctl_reg_write, ctl_alu_src_b, ctl_mem_write, ctl_branch, ctl_jump, ctl_jalr;
  logic [3:0]  ctl_alu_ctrl;
  logic [2:0]  ctl_imm_src;
  logic [1:0]  ctl_result_src;


  ref_control u_ctrl (
    .instr_i(instr), .reg_write_o(ctl_reg_write), .alu_src_b_o(ctl_alu_src_b),
    .alu_ctrl_o(ctl_alu_ctrl), .imm_src_o(ctl_imm_src), .result_src_o(ctl_result_src),
    .mem_write_o(ctl_mem_write), .branch_o(ctl_branch), .jump_o(ctl_jump), .jalr_o(ctl_jalr));

  datapath dut (
    .clk_i(clk), .rst_i(rst),
    .prog_addr_o(prog_addr), .instr_i(instr),
    .data_addr_o(data_addr), .data_wdata_o(data_wdata), .data_we_o(data_we),
    .data_rdata_i(data_rdata),
    .reg_write_i(ctl_reg_write), .alu_src_b_i(ctl_alu_src_b), .alu_ctrl_i(ctl_alu_ctrl),
    .imm_src_i(ctl_imm_src), .result_src_i(ctl_result_src), .mem_write_i(ctl_mem_write),
    .branch_i(ctl_branch), .jump_i(ctl_jump), .jalr_i(ctl_jalr),
    .branch_taken_o(branch_taken), .alu_zero_o(alu_zero));


`define DP      dut
`define TB_NAME "tb_datapath"
`include "rv32i_lockstep.svh"

endmodule
