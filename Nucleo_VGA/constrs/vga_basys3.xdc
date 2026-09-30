## ============================================================
## Constraints: Subsistema VGA - Basys 3
## Basado en Basys-3-Master.xdc proporcionado.
## Top actual esperado: vga_top
## ============================================================

## Clock principal de la Basys 3: 100 MHz
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk_100mhz]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk_100mhz]

## Reset: boton central BTNC
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports rst]

## VGA - Red
set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports {vga_red[0]}]
set_property -dict { PACKAGE_PIN H19 IOSTANDARD LVCMOS33 } [get_ports {vga_red[1]}]
set_property -dict { PACKAGE_PIN J19 IOSTANDARD LVCMOS33 } [get_ports {vga_red[2]}]
set_property -dict { PACKAGE_PIN N19 IOSTANDARD LVCMOS33 } [get_ports {vga_red[3]}]

## VGA - Green
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {vga_green[0]}]
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports {vga_green[1]}]
set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports {vga_green[2]}]
set_property -dict { PACKAGE_PIN D17 IOSTANDARD LVCMOS33 } [get_ports {vga_green[3]}]

## VGA - Blue
set_property -dict { PACKAGE_PIN N18 IOSTANDARD LVCMOS33 } [get_ports {vga_blue[0]}]
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports {vga_blue[1]}]
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports {vga_blue[2]}]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {vga_blue[3]}]

## VGA - Sincronismos
set_property -dict { PACKAGE_PIN P19 IOSTANDARD LVCMOS33 } [get_ports hsync]
set_property -dict { PACKAGE_PIN R19 IOSTANDARD LVCMOS33 } [get_ports vsync]

## Configuracion general de la Basys 3
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Configuracion del bitstream
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

## ============================================================
## NOTA SOBRE LA INTERFAZ DE VIDEO RAM
## ============================================================
## Los siguientes puertos del vga_top NO tienen asignacion fisica
## porque estan destinados a conectarse internamente con el SoC:
##
##   video_we
##   video_addr[8:0]
##   video_wdata[31:0]
##   video_rdata[31:0]
##
## Mientras vga_top sea usado temporalmente como top fisico del
## proyecto, Vivado seguira reportando UCIO-1/NSTD-1 para estas
## senales. En el top final del SoC dejaran de ser puertos externos.
## ============================================================
