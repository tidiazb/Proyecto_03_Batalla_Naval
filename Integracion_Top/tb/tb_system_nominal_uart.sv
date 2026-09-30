`timescale 1ns/1ps
// Parametros UART de hardware. La PC simulada envia a 115200 exactos.
// Solo puertos externos: apto para simulacion RTL y netlist temporizado.
module tb_system_nominal_uart;
 logic clk=0,reset=1,rx=1;
 wire tx;
 always #5 clk=~clk;
 batalla_naval_top dut(.clk_100mhz(clk),.reset_global_i(reset),
  .btn_up_i(1'b0),.btn_down_i(1'b0),.btn_left_i(1'b0),.btn_right_i(1'b0),
  .btn_sel_i(1'b0),.btn_ok_i(1'b0),.btn_restart_i(1'b0),.uart_rx_i(rx),.uart_tx_o(tx),
  .seg(),.an(),.dp(),.led_state(),.buzzer_o(),.hsync(),.vsync(),.vga_red(),.vga_green(),.vga_blue());
 string frames[0:7],line="";
 integer produced=0;
 logic [7:0] value;
 initial forever begin
  @(negedge tx); #4320;
  if(tx!==0) $fatal(1,"FAIL start nominal");
  for(integer i=0;i<8;i++) begin #8640; value[i]=tx; end
  #8640;
  if(tx!==1) $fatal(1,"FAIL stop nominal");
  if(value==10) begin frames[produced]=line; produced++; line=""; end
  else line={line,value};
 end
 task automatic pc_frame(input string text);
  logic [7:0] ch;
  begin
   for(integer i=0;i<=text.len();i++) begin
    ch=(i==text.len()) ? 8'd10 : text[i];
    rx=0; #8680.555556;
    for(integer j=0;j<8;j++) begin rx=ch[j]; #8680.555556; end
    rx=1; #8680.555556;
   end
  end
 endtask
 initial begin
  #200; reset=0;
  wait(produced==1);
  if(frames[0]!="NEW") $fatal(1,"FAIL boot nominal");
  pc_frame("PLACE,0,7,0,H");
  wait(produced==2);
  if(frames[1]!="PLACE,0,OK") $fatal(1,"FAIL recepcion 115200: %s",frames[1]);
  pc_frame("PLACE,1,1,0,V");
  wait(produced==3);
  if(frames[2]!="PLACE,1,OK") $fatal(1,"FAIL segunda recepcion nominal: %s",frames[2]);
  $display("PASS tb_system_nominal_uart: CPU/MMIO, TX 115741 y RX PC 115200 8N1");
  $finish;
 end
 initial begin #10_000_000; $fatal(1,"FAIL timeout UART nominal"); end
endmodule
