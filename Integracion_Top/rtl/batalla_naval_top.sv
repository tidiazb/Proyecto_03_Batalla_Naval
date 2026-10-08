`timescale 1ns/1ps
// Top fisico Basys 3. SW15: reset global; SW0: SEL; SW1: nueva partida.
module batalla_naval_top #(
 parameter PROGRAM_FILE = "batalla_naval.mem",
 parameter integer UART_BR_LIMIT=54,
 parameter integer UART_BR_BITS=6,
 parameter integer DEBOUNCE_MS=20,
 parameter integer BUTTON_CLK_HZ=100_000_000,
 parameter integer BUZZER_CLK_HZ=100_000_000,
 parameter integer DISPLAY_REFRESH_BITS=18
)(
 input logic clk_100mhz,
 input logic reset_global_i,
 input logic btn_up_i,btn_down_i,btn_left_i,btn_right_i,
 input logic btn_sel_i,btn_ok_i,btn_restart_i,
 input logic uart_rx_i,
 output logic uart_tx_o,
 output logic [6:0] seg,
 output logic [3:0] an,
 output logic dp,
 output logic [2:0] led_state,
 output logic buzzer_o,
 output logic hsync,vsync,
 output logic [3:0] vga_red,vga_green,vga_blue
);


 // Encendido definido y desactivacion de reset sincronizada a 100 MHz.
 (* ASYNC_REG="TRUE" *) logic [1:0] reset_sync=2'b11;
 logic [15:0] power_on=16'hffff;
 logic rst;
 always_ff @(posedge clk_100mhz or posedge reset_global_i) begin
   if(reset_global_i) reset_sync<=2'b11;
   else reset_sync<={reset_sync[0],1'b0};
 end
 always_ff @(posedge clk_100mhz) power_on<={power_on[14:0],1'b0};
 assign rst=reset_sync[1] | power_on[15];
 assign dp=1'b1;
 
 
 // NUEVO: clock enable del CPU (1 de cada 3 ciclos de 100 MHz)
 localparam int CPU_DIV = 3;
 logic [1:0] cpu_div_cnt;
 logic       cpu_en;
 always_ff @(posedge clk_100mhz) begin
   if (rst) begin
     cpu_div_cnt <= '0;
     cpu_en      <= 1'b0;
   end else begin
     cpu_div_cnt <= (cpu_div_cnt == CPU_DIV-1) ? '0 : cpu_div_cnt + 1'b1;
     cpu_en      <= (cpu_div_cnt == CPU_DIV-2);
   end
 end
 // FIN NUEVO
 
 
 
 logic [31:0] prog_addr,prog_instr,data_addr,data_out,data_in,bus_wdata;
 logic cpu_we,uart_sel,uart_we,gpio_sel,gpio_we;
 logic display_sel,display_we,led_sel,led_we,buzzer_sel,buzzer_we,vga_sel,vga_we;
 logic [1:0] uart_addr;
 logic [8:0] vga_addr;
 logic [31:0] uart_rdata,gpio_rdata,display_rdata,led_rdata,buzzer_rdata,vga_rdata;
 
 riscv_core u_cpu(.clk_i(clk_100mhz),.rst_i(rst),.en_i(cpu_en),
  .ProgAddress_o(prog_addr),.ProgIn_i(prog_instr),
  .DataAddress_o(data_addr),.DataOut_o(data_out),.DataIn_i(data_in),.we_o(cpu_we));
 memory_mmio_system #(.PROGRAM_FILE(PROGRAM_FILE)) u_mem(
  .clk_i(clk_100mhz),.ProgAddress_i(prog_addr),.ProgIn_o(prog_instr),
  .DataAddress_i(data_addr),.DataOut_i(data_out),.we_i(cpu_we && !rst),.DataIn_o(data_in),
  .bus_wdata_o(bus_wdata),.uart_sel_o(uart_sel),.uart_we_o(uart_we),
  .uart_addr_o(uart_addr),.uart_rdata_i(uart_rdata),
  .gpio_sel_o(gpio_sel),.gpio_we_o(gpio_we),.gpio_rdata_i(gpio_rdata),
  .display_sel_o(display_sel),.display_we_o(display_we),.display_rdata_i(display_rdata),
  .led_sel_o(led_sel),.led_we_o(led_we),.led_rdata_i(led_rdata),
  .buzzer_sel_o(buzzer_sel),.buzzer_we_o(buzzer_we),.buzzer_rdata_i(buzzer_rdata),
  .vga_sel_o(vga_sel),.vga_we_o(vga_we),.vga_addr_o(vga_addr),.vga_rdata_i(vga_rdata));
 uart_mmio_peripheral #(.BR_LIMIT(UART_BR_LIMIT),.BR_BITS(UART_BR_BITS), .FIFO_BITS(5)) u_uart(
  .clk_i(clk_100mhz),.rst_i(rst),.select_i(uart_sel),.write_enable_i(uart_we),
  .addr_i(uart_addr),.wdata_i(bus_wdata),.rdata_o(uart_rdata),
  .uart_rx_i(uart_rx_i),.uart_tx_o(uart_tx_o));
 j1_inputs_peripheral #(.CLK_FREQ_HZ(BUTTON_CLK_HZ),.DEBOUNCE_MS(DEBOUNCE_MS)) u_buttons(
  .clk_i(clk_100mhz),.rst_i(rst),.btn_up_raw_i(btn_up_i),.btn_down_raw_i(btn_down_i),
  .btn_left_raw_i(btn_left_i),.btn_right_raw_i(btn_right_i),.btn_sel_raw_i(btn_sel_i),
  .btn_ok_raw_i(btn_ok_i),.btn_rst_raw_i(btn_restart_i),
  .select_i(gpio_sel),.write_enable_i(gpio_we),.wdata_i(bus_wdata),.rdata_o(gpio_rdata));
 peripherals_mmio #(.DISPLAY_REFRESH_BITS(DISPLAY_REFRESH_BITS),.BUZZER_CLK_FREQ(BUZZER_CLK_HZ)) u_outputs(
  .clk(clk_100mhz),.rst(rst),.bus_wdata_i(bus_wdata),
  .display_we_i(display_we),.led_we_i(led_we),.buzzer_we_i(buzzer_we),
  .display_rdata_o(display_rdata),.led_rdata_o(led_rdata),.buzzer_rdata_o(buzzer_rdata),
  .seg(seg),.an(an),.led_rgb(led_state),.buzzer(buzzer_o));
 // El bus entrega la direccion de tile ya decodificada: se reutiliza el nucleo VGA.
 vga_top u_video(.clk_100mhz(clk_100mhz),.rst(rst),
  .video_we(vga_we),.video_addr(vga_addr),.video_wdata(bus_wdata),.video_rdata(vga_rdata),
  .hsync(hsync),.vsync(vsync),.vga_red(vga_red),.vga_green(vga_green),.vga_blue(vga_blue));
endmodule
