`timescale 1ns/1ps
module tb_integration_memory;
 logic clk=0;
 always #5 clk=~clk;
 logic [31:0] pa=0,da=0,wd=0,pi,di,vrd,vrb;
 logic we=0,vwe;
 logic [8:0] va;
 memory_mmio_system #(.PROGRAM_FILE("batalla_naval.mem")) mem(
  .clk_i(clk),.ProgAddress_i(pa),.ProgIn_o(pi),.DataAddress_i(da),.DataOut_i(wd),.we_i(we),.DataIn_o(di),
  .bus_wdata_o(),.uart_sel_o(),.uart_we_o(),.uart_addr_o(),.uart_rdata_i(32'h1111),
  .gpio_sel_o(),.gpio_we_o(),.gpio_rdata_i(32'h2222),
  .display_sel_o(),.display_we_o(),.display_rdata_i(32'h3333),
  .led_sel_o(),.led_we_o(),.led_rdata_i(32'h4444),
  .buzzer_sel_o(),.buzzer_we_o(),.buzzer_rdata_i(32'h5555),
  .vga_sel_o(),.vga_we_o(vwe),.vga_addr_o(va),.vga_rdata_i(vrd));
 video_ram video(.clk_a(clk),.we_a(vwe),.addr_a(va),.wdata_a(wd),.rdata_a(vrd),
  .clk_b(clk),.addr_b(9'd511),.rdata_b(vrb));
 task automatic store(input logic [31:0] address,data);
  @(negedge clk); da=address;wd=data;we=1;
  @(negedge clk); we=0; #1;
 endtask
 initial begin
  #1;
  if(pi!==32'h00003137 || di!==pi) $fatal(1,"FAIL doble lectura ROM");
  store(0,32'hffffffff);
  if(di!==pi || pi!==32'h00003137) $fatal(1,"FAIL proteccion ROM");
  da=4;pa=4;#1;if(di!==pi) $fatal(1,"FAIL constantes ROM");
  store(32'h2000,32'h12345678);
  if(di!==32'h12345678) $fatal(1,"FAIL RAM");
  store(32'h11000,32'h0000000b);
  if(di!==32'hb) $fatal(1,"FAIL lectura combinacional VGA");
  store(32'h114ac,32'h7); // indice299 ultimo valido
  if(di!==7) $fatal(1,"FAIL ultima casilla VGA");
  store(32'h114b0,32'hdeadbeef); // indice300: ventana reservada
  if(di!==0 || vrb!==5) $fatal(1,"FAIL fuera de memoria video");
  da=32'h2001;we=1;#1;
  if(di!==0 || mem.ram_we || vwe) $fatal(1,"FAIL acceso no alineado");
  da=32'h3000;#1;if(di!==0 || mem.ram_we || vwe) $fatal(1,"FAIL direccion no mapeada");
  we=0;da=32'h2000;#1;if(di!==32'h12345678) $fatal(1,"FAIL escritura accidental");
  $display("PASS tb_integration_memory: constantes ROM, proteccion, RAM, VGA y rangos");
  $finish;
 end
endmodule
