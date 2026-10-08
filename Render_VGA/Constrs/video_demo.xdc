## ============================================================
## CLOCK 100 MHz
## ============================================================

set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk_100mhz]

create_clock -add -name sys_clk_pin -period 10.000 \
    -waveform {0.000 5.000} [get_ports clk_100mhz]


## ============================================================
## RESET - BOTÓN CENTRAL BTNC
## ============================================================

set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports rst]


## ============================================================
## VGA - ROJO
## ============================================================

set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports {vga_red[0]}]
set_property -dict { PACKAGE_PIN H19 IOSTANDARD LVCMOS33 } [get_ports {vga_red[1]}]
set_property -dict { PACKAGE_PIN J19 IOSTANDARD LVCMOS33 } [get_ports {vga_red[2]}]
set_property -dict { PACKAGE_PIN N19 IOSTANDARD LVCMOS33 } [get_ports {vga_red[3]}]


## ============================================================
## VGA - VERDE
## ============================================================

set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {vga_green[0]}]
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports {vga_green[1]}]
set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports {vga_green[2]}]
set_property -dict { PACKAGE_PIN D17 IOSTANDARD LVCMOS33 } [get_ports {vga_green[3]}]


## ============================================================
## VGA - AZUL
## ============================================================

set_property -dict { PACKAGE_PIN N18 IOSTANDARD LVCMOS33 } [get_ports {vga_blue[0]}]
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports {vga_blue[1]}]
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports {vga_blue[2]}]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {vga_blue[3]}]


## ============================================================
## VGA - SINCRONISMOS
## ============================================================

set_property -dict { PACKAGE_PIN P19 IOSTANDARD LVCMOS33 } [get_ports hsync]
set_property -dict { PACKAGE_PIN R19 IOSTANDARD LVCMOS33 } [get_ports vsync]


## ============================================================
## CONFIGURACIÓN FPGA
## ============================================================

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]