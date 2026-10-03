`timescale 1ns/1ps
// CPU real + ROM/RAM + decoder + UART fisica + botones + salidas + VGA.
module tb_batalla_naval_system;
 localparam integer BR=24;  //Antes era BR = 8, pero se ajustó los ciclos de instrucciones en factor de 3 asi que este será ahora 8*3
 localparam integer BIT_NS=BR*16*10;
 logic clk=0,reset=1,rx=1;
 logic [6:0] buttons=0;
 wire tx,dp,buzzer,hsync,vsync;
 wire [6:0] seg;
 wire [3:0] an,r,g,b;
 wire [2:0] leds;
 always #5 clk=~clk;
 batalla_naval_top #(.UART_BR_LIMIT(BR),.DEBOUNCE_MS(1),.BUTTON_CLK_HZ(1000),
  .BUZZER_CLK_HZ(10000),.DISPLAY_REFRESH_BITS(5)) dut(
  .clk_100mhz(clk),.reset_global_i(reset),
  .btn_up_i(buttons[0]),.btn_down_i(buttons[1]),.btn_left_i(buttons[2]),
  .btn_right_i(buttons[3]),.btn_sel_i(buttons[4]),.btn_ok_i(buttons[5]),.btn_restart_i(buttons[6]),
  .uart_rx_i(rx),.uart_tx_o(tx),.seg(seg),.an(an),.dp(dp),.led_state(leds),
  .buzzer_o(buzzer),.hsync(hsync),.vsync(vsync),.vga_red(r),.vga_green(g),.vga_blue(b));
 string frames[0:1023];
 integer produced=0,consumed=0;
 integer shot_writes=0,video_writes=0,buzzer_writes=0;
 string current_line="";
 logic [7:0] decoded_byte;
 initial begin
  forever begin
   @(negedge tx);
   #(BIT_NS/2);
   if(tx!==0) $fatal(1,"FAIL TX start");
   for(integer i=0;i<8;i=i+1) begin
    #(BIT_NS); decoded_byte[i]=tx;
   end
   #(BIT_NS);
   if(tx!==1) $fatal(1,"FAIL TX stop");
   if(decoded_byte==10) begin
    frames[produced]=current_line;
    produced=produced+1;
    current_line="";
   end else current_line={current_line,decoded_byte};
  end
 end
 task automatic expect_line(input string expected);
  integer timeout;
  begin
   timeout=0;
   while(produced<=consumed && timeout<300000) begin @(posedge clk); timeout++; end
   if(produced<=consumed) $fatal(1,"FAIL timeout esperando %s PC=%h",expected,dut.prog_addr);
   if(frames[consumed]!=expected)
    $fatal(1,"FAIL UART esperado '%s', recibido '%s' PC=%h",expected,frames[consumed],dut.prog_addr);
   $display("UART PASS %s",expected);
   consumed++;
  end
 endtask
 task automatic send_line(input string command);
  logic [7:0] value;
  begin
   for(integer n=0;n<=command.len();n++) begin
    value=(n==command.len()) ? 8'd10 : command[n];
    @(negedge clk); rx=0; #(BIT_NS);
    for(integer bitn=0;bitn<8;bitn++) begin rx=value[bitn]; #(BIT_NS); end
    rx=1; #(BIT_NS);
   end
  end
 endtask
 task automatic press(input integer index);
  begin
   @(negedge clk); buttons[index]=1;
   repeat(100) @(negedge clk);
   buttons[index]=0;
   // Permite ejecutar render y reconocer el evento anterior.
   repeat(10000) @(posedge clk);
  end
 endtask
 function automatic integer state_word(input integer byte_offset);
  return dut.u_mem.u_data_ram.ram[(32'h2200-32'h2000+byte_offset)/4];
 endfunction
 task automatic check_state(input integer offset,value,input string description);
  if(state_word(offset)!=value)
   $fatal(1,"FAIL %s esperado=%0d recibido=%0d",description,value,state_word(offset));
 endtask
 task automatic cursor(input integer row,column);
  integer watchdog;
  begin
   watchdog=0;
   while(state_word(8)!=row && watchdog<10) begin
    if(state_word(8)<row) press(1); else press(0);
    watchdog++;
   end
   if(state_word(8)!=row) $fatal(1,"FAIL cursor fila");
   watchdog=0;
   while(state_word(12)!=column && watchdog<10) begin
    if(state_word(12)<column) press(3); else press(2);
    watchdog++;
   end
   if(state_word(12)!=column) $fatal(1,"FAIL cursor columna");
  end
 endtask
 task automatic fleet1;
  begin
   cursor(0,0); press(5);
   cursor(1,0); press(4); press(5);
   cursor(1,1); press(4); press(5);
   check_state(20,3,"flota J1 completa");
  end
 endtask
 task automatic fleet2;
  begin
   send_line("PLACE,0,0,0,H"); expect_line("PLACE,0,OK");
   send_line("PLACE,1,1,0,V"); expect_line("PLACE,1,OK");
   send_line("PLACE,2,1,1,H"); expect_line("PLACE,2,OK");
  end
 endtask
 task automatic shot1(input integer row,column,input string result_ship);
  begin
   cursor(row,column); press(5);
   expect_line($sformatf("INCOMING,%0d,%0d,%s",row,column,result_ship));
  end
 endtask
 task automatic shot2(input integer row,column,input string result_ship);
  begin
   send_line($sformatf("FIRE,%0d,%0d",row,column));
   expect_line($sformatf("SHOT,%0d,%0d,%s",row,column,result_ship));
  end
 endtask
 // Invariantes de bus en TODOS los ciclos de ambas partidas.
 always @(posedge clk) if(!dut.rst) begin
  if(!$onehot0({dut.u_mem.ram_we,dut.uart_we,dut.gpio_we,dut.display_we,
               dut.led_we,dut.buzzer_we,dut.vga_we})) $fatal(1,"FAIL WE simultaneos");
  if(dut.vga_we) video_writes++;
  if(dut.buzzer_we) buzzer_writes++;
  if(dut.cpu_we && dut.data_addr>=32'h2000 && dut.data_addr<32'h2200 && dut.data_out[8]) shot_writes++;
  if(dut.cpu_we && dut.data_addr>=32'h2c00 && dut.data_addr<32'h3000 && dut.data_addr<32'h2d00)
   $fatal(1,"FAIL pila excede reserva");
 end
 // Verifica VGA contando ciclos de pixel, sin exigir igualdad exacta
 // entre tiempos reales del modelo PLL. Muestrea despues de los NBA.
 localparam realtime PIXEL_PERIOD_NS=40.0;
 localparam realtime PIXEL_TOLERANCE_NS=0.4; // 1 %; no acepta 50/100 MHz.
 integer pixel_cycles=0;
 integer last_hfall_cycle=-1,hfall_cycle=-1;
 integer last_vfall_cycle=-1,vfall_cycle=-1;
 integer hperiods=0,vperiods=0;
 logic previous_hsync=1'b1,previous_vsync=1'b1;
 realtime last_pixel_time=0,pixel_period=0;
 always @(posedge dut.u_video.pixel_clk) begin
  #0.001; // 1 ps: las salidas VGA registradas ya estan actualizadas.
  if(dut.u_video.rst_vga !== 1'b0 || dut.u_video.locked !== 1'b1) begin
   pixel_cycles=0;
   last_hfall_cycle=-1; hfall_cycle=-1;
   last_vfall_cycle=-1; vfall_cycle=-1;
   previous_hsync=1'b1; previous_vsync=1'b1;
   last_pixel_time=0;
   hperiods=0; vperiods=0;
  end else begin
   if(last_pixel_time>0) begin
    pixel_period=$realtime-last_pixel_time;
    if(pixel_period<PIXEL_PERIOD_NS-PIXEL_TOLERANCE_NS ||
       pixel_period>PIXEL_PERIOD_NS+PIXEL_TOLERANCE_NS)
     $fatal(1,"FAIL reloj pixel VGA: esperado 40 ns +/- 0.4 ns, recibido %0.3f ns",pixel_period);
   end
   last_pixel_time=$realtime;
   pixel_cycles++;
   if((^{hsync,vsync}) === 1'bx) $fatal(1,"FAIL sincronizacion VGA indefinida");
   if(previous_hsync && !hsync) begin
    if(last_hfall_cycle>=0) begin
     if(pixel_cycles-last_hfall_cycle!=800)
      $fatal(1,"FAIL periodo H VGA: esperado 800 ciclos, recibido %0d",pixel_cycles-last_hfall_cycle);
     hperiods++;
    end
    last_hfall_cycle=pixel_cycles; hfall_cycle=pixel_cycles;
   end
   if(!previous_hsync && hsync && hfall_cycle>=0)
    if(pixel_cycles-hfall_cycle!=96)
     $fatal(1,"FAIL ancho H VGA: esperado 96 ciclos, recibido %0d",pixel_cycles-hfall_cycle);
   if(previous_vsync && !vsync) begin
    if(last_vfall_cycle>=0) begin
     if(pixel_cycles-last_vfall_cycle!=800*525)
      $fatal(1,"FAIL periodo V VGA: esperado 420000 ciclos, recibido %0d",pixel_cycles-last_vfall_cycle);
     vperiods++;
    end
    last_vfall_cycle=pixel_cycles; vfall_cycle=pixel_cycles;
   end
   if(!previous_vsync && vsync && vfall_cycle>=0)
    if(pixel_cycles-vfall_cycle!=800*2)
     $fatal(1,"FAIL ancho V VGA: esperado 1600 ciclos, recibido %0d",pixel_cycles-vfall_cycle);
   previous_hsync=hsync; previous_vsync=vsync;
  end
 end
 initial begin
  #200; reset=0;
  expect_line("NEW");
  check_state(0,0,"inicializacion fase"); check_state(52,0,"victorias iniciales");
  press(6); expect_line("NEW"); check_state(0,0,"reinicio durante colocacion");
  if(dut.u_outputs.display_rdata_o!=0) $fatal(1,"FAIL display inicial");
  fork
   press(5);
   send_line("PLACE,0,0,7,H");
  join
  check_state(20,1,"colocacion J1 concurrente con UART");
  expect_line("PLACE,0,REJECT,OUT_OF_BOUNDS");
  send_line("PLACE,0,0,0,H"); expect_line("PLACE,0,OK");
  check_state(0,0,"colocacion concurrente sin inicio anticipado");
  press(5); check_state(20,1,"rechazo traslape J1 atomico");
  cursor(1,0); press(4); press(5);
  cursor(1,1); press(4); press(5);
  check_state(0,0,"solo J1 listo");
  send_line("PLACE,1,0,1,H"); expect_line("PLACE,1,REJECT,OVERLAP");
  send_line("PLACE,1,1,0,D"); expect_line("PLACE,1,REJECT,INVALID");
  send_line("PLACE,1,1,0,V"); expect_line("PLACE,1,OK");
  send_line("PLACE,2,1,1,H"); expect_line("PLACE,2,OK");
  expect_line("BATTLE"); expect_line("TURN,P1");
  // Reset de partida desde batalla, seguido de una partida nueva completa.
  press(6); expect_line("NEW");
  check_state(0,0,"reinicio desde batalla"); check_state(20,0,"reinicio borra flota J1");
  check_state(24,0,"reinicio borra flota J2");
  fleet1; fleet2; expect_line("BATTLE"); expect_line("TURN,P1");
  send_line("FIRE,7,6"); expect_line("SHOT_REJECT,7,6,NOT_TURN");
  shot1(1,1,"HIT,-"); expect_line("TURN,P2");
  shot2(7,7,"MISS,-"); expect_line("TURN,P1");
  press(5); check_state(4,0,"repetido J1 conserva turno"); check_state(28,1,"repetido J1 no cuenta");
  shot1(0,1,"HIT,-"); expect_line("TURN,P2");
  send_line("FIRE,7,7"); expect_line("SHOT_REJECT,7,7,REPEAT");
  check_state(4,1,"repetido J2 conserva turno"); check_state(32,1,"repetido J2 no cuenta");
  send_line("FIRE,8,0"); expect_line("ERROR,BAD_FRAME");
  send_line("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"); expect_line("ERROR,BAD_FRAME");
  shot2(7,6,"MISS,-"); expect_line("TURN,P1");
  shot1(0,0,"HIT,-"); expect_line("TURN,P2");
  shot2(7,5,"MISS,-"); expect_line("TURN,P1");
  shot1(0,2,"HIT,-"); expect_line("TURN,P2");
  shot2(7,4,"MISS,-"); expect_line("TURN,P1");
  shot1(0,3,"SUNK,0"); expect_line("TURN,P2");
  shot2(7,3,"MISS,-"); expect_line("TURN,P1");
  shot1(1,0,"HIT,-"); expect_line("TURN,P2");
  shot2(7,2,"MISS,-"); expect_line("TURN,P1");
  shot1(2,0,"HIT,-"); expect_line("TURN,P2");
  shot2(7,1,"MISS,-"); expect_line("TURN,P1");
  shot1(3,0,"SUNK,1"); expect_line("TURN,P2");
  shot2(7,0,"MISS,-"); expect_line("TURN,P1");
  shot1(1,2,"SUNK,2"); expect_line("END,P1,9,8,3,0");
  check_state(0,2,"resultado J1"); check_state(52,1,"victoria J1 acumulada");
  if(dut.u_outputs.display_rdata_o!=1 || dut.u_outputs.led_rdata_o!=2) $fatal(1,"FAIL salidas victoria J1");
  if(dut.u_video.u_video_ram.mem[3*20+13][2:0]!=3) $fatal(1,"FAIL VGA ultimo impacto");
  send_line("FIRE,0,0"); expect_line("SHOT_REJECT,0,0,NOT_TURN");
  press(6); expect_line("NEW"); check_state(52,1,"reinicio conserva J1");
  fleet1; fleet2; expect_line("BATTLE"); expect_line("TURN,P1");
  shot1(7,0,"MISS,-"); expect_line("TURN,P2"); shot2(0,0,"HIT,-"); expect_line("TURN,P1");
  shot1(7,1,"MISS,-"); expect_line("TURN,P2"); shot2(0,1,"HIT,-"); expect_line("TURN,P1");
  shot1(7,2,"MISS,-"); expect_line("TURN,P2"); shot2(0,2,"HIT,-"); expect_line("TURN,P1");
  shot1(7,3,"MISS,-"); expect_line("TURN,P2"); shot2(0,3,"SUNK,0"); expect_line("TURN,P1");
  shot1(7,4,"MISS,-"); expect_line("TURN,P2"); shot2(1,0,"HIT,-"); expect_line("TURN,P1");
  shot1(7,5,"MISS,-"); expect_line("TURN,P2"); shot2(2,0,"HIT,-"); expect_line("TURN,P1");
  shot1(7,6,"MISS,-"); expect_line("TURN,P2"); shot2(3,0,"SUNK,1"); expect_line("TURN,P1");
  shot1(7,7,"MISS,-"); expect_line("TURN,P2"); shot2(1,1,"HIT,-"); expect_line("TURN,P1");
  shot1(6,7,"MISS,-"); expect_line("TURN,P2"); shot2(1,2,"SUNK,2"); expect_line("END,P2,9,9,0,3");
  check_state(52,1,"conserva victoria J1"); check_state(56,1,"victoria J2 acumulada");
  if(dut.u_outputs.display_rdata_o!=32'h101) $fatal(1,"FAIL display acumulado");
  press(6); expect_line("NEW"); check_state(52,1,"reinicio conserva ambos J1"); check_state(56,1,"reinicio conserva ambos J2");
  if(shot_writes!=35 || video_writes<300 || buzzer_writes<5) $fatal(1,"FAIL cobertura de perifericos");
  if(dut.u_uart.rx_overrun_r || dut.u_uart.tx_overrun_r) $fatal(1,"FAIL perdida UART");
  // Observa al menos dos cuadros completos antes del reset global.
  wait(vperiods>=2);
  @(negedge clk); reset=1; #200; reset=0;
  expect_line("NEW"); check_state(52,0,"reset global limpia J1"); check_state(56,0,"reset global limpia J2");
  $display("PASS tb_batalla_naval_system: dos partidas completas, MMIO, UART, GPIO, salidas, VGA y reset");
  $finish;
 end
 initial begin #100_000_000; $fatal(1,"FAIL timeout global PC=%h",dut.prog_addr); end
endmodule
