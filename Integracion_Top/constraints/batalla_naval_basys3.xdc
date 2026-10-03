# Basys 3 rev B. Fuente: Digilent Basys-3-Master.xdc.
# BTN SEL=SW0, BTN RST de partida=SW1, reset global=SW15.
# Buzzer pasivo externo: JA1 (J1) y GND, interfaz de 3.3 V.
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports {clk_100mhz}]
set_property -dict { PACKAGE_PIN R2 IOSTANDARD LVCMOS33 } [get_ports {reset_global_i}]
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports {btn_up_i}]
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports {btn_down_i}]
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports {btn_left_i}]
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports {btn_right_i}]
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports {btn_sel_i}]
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports {btn_ok_i}]
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports {btn_restart_i}]
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports {uart_rx_i}]
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports {uart_tx_o}]
set_property -dict { PACKAGE_PIN V7 IOSTANDARD LVCMOS33 } [get_ports {dp}]
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports {buzzer_o}]
set_property -dict { PACKAGE_PIN P19 IOSTANDARD LVCMOS33 } [get_ports {hsync}]
set_property -dict { PACKAGE_PIN R19 IOSTANDARD LVCMOS33 } [get_ports {vsync}]
set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } [get_ports {seg[0]}]
set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } [get_ports {seg[1]}]
set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports {seg[2]}]
set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports {seg[3]}]
set_property -dict { PACKAGE_PIN U5 IOSTANDARD LVCMOS33 } [get_ports {seg[4]}]
set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } [get_ports {seg[5]}]
set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } [get_ports {seg[6]}]
set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS33 } [get_ports {an[0]}]
set_property -dict { PACKAGE_PIN U4 IOSTANDARD LVCMOS33 } [get_ports {an[1]}]
set_property -dict { PACKAGE_PIN V4 IOSTANDARD LVCMOS33 } [get_ports {an[2]}]
set_property -dict { PACKAGE_PIN W4 IOSTANDARD LVCMOS33 } [get_ports {an[3]}]
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {led_state[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {led_state[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {led_state[2]}]
set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports {vga_red[0]}]
set_property -dict { PACKAGE_PIN H19 IOSTANDARD LVCMOS33 } [get_ports {vga_red[1]}]
set_property -dict { PACKAGE_PIN J19 IOSTANDARD LVCMOS33 } [get_ports {vga_red[2]}]
set_property -dict { PACKAGE_PIN N19 IOSTANDARD LVCMOS33 } [get_ports {vga_red[3]}]
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {vga_green[0]}]
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports {vga_green[1]}]
set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports {vga_green[2]}]
set_property -dict { PACKAGE_PIN D17 IOSTANDARD LVCMOS33 } [get_ports {vga_green[3]}]
set_property -dict { PACKAGE_PIN N18 IOSTANDARD LVCMOS33 } [get_ports {vga_blue[0]}]
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports {vga_blue[1]}]
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports {vga_blue[2]}]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {vga_blue[3]}]
create_clock -name sys_clk_pin -period 10.000 [get_ports clk_100mhz]
# Entradas asincronas: excepcion solo hasta el primer sincronizador.
set_false_path -from [get_ports {btn_up_i btn_down_i btn_left_i btn_right_i btn_sel_i btn_ok_i btn_restart_i}] -to [get_cells -hier -filter {NAME =~ *sync_1_r_reg}]
set_false_path -from [get_ports uart_rx_i] -to [get_cells -hier -filter {NAME =~ *rx_meta_r_reg}]
set_false_path -from [get_ports reset_global_i] -to [get_cells -hier -filter {NAME =~ *reset_sync_reg*}]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]


# CPU con clock enable 1 de cada 3 ciclos: el estado del CPU (PC, banco de
# registros, RAM de datos) solo cambia en flancos con cpu_en=1.
set cpu_mc_src [get_cells -hierarchical -filter { \
    NAME =~ "u_cpu/u_dp/u_pc/pc_o_reg*" || \
    NAME =~ "u_cpu/u_dp/u_rf/regs_reg*" || \
    NAME =~ "u_mem/u_data_ram/ram_reg*" }]
set_multicycle_path -setup 3 -from $cpu_mc_src
set_multicycle_path -hold  2 -from $cpu_mc_src
