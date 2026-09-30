`timescale 1ns/1ps
// SOLO SIMULACION. Vivado implementa vga_clock con el Clock Wizard .xci.
module vga_clock(input logic clk_in1, reset,output logic pixel_clk,locked);
 logic [1:0] divider=0;
 logic [3:0] startup=0;
 always_ff @(posedge clk_in1 or posedge reset) begin
  if(reset) begin divider<=0; startup<=0; locked<=0; end
  else begin
   divider<=divider+1'b1;
   if(startup!=15) startup<=startup+1'b1;
   else locked<=1;
  end
 end
 assign pixel_clk=divider[1];
endmodule
