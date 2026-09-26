`timescale 1ns/1ps

module tb_program_rom;
    logic [31:0] address;
    logic [31:0] instruction;

    program_rom #(.INIT_FILE("program_test.mem")) dut (
        .prog_addr_i(address), .prog_instr_o(instruction)
    );

    task automatic expect_instruction(
        input logic [31:0] addr,
        input logic [31:0] value,
        input string description
    );
        address = addr;
        #1;
        if (instruction !== value)
            $fatal(1, "FAIL ROM %s: addr=%h esperado=%h real=%h",
                   description, addr, value, instruction);
    endtask

    initial begin
        expect_instruction(32'h0000_0000, 32'h0000_0013, "vector de reset");
        expect_instruction(32'h0000_0004, 32'h0010_0093, "segunda instruccion");
        expect_instruction(32'h0000_0008, 32'h0020_8113, "tercera instruccion");
        expect_instruction(32'h0000_000C, 32'h0000_0013, "relleno NOP");
        expect_instruction(32'h0000_1FFC, 32'h0000_0013, "ultima palabra ROM");
        expect_instruction(32'h0000_0002, 32'h0000_0013, "desalineada");
        expect_instruction(32'h0000_2000, 32'h0000_0013, "fuera de ROM");
        $display("PASS tb_program_rom");
        $finish;
    end
endmodule
