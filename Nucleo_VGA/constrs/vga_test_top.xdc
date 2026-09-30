## ============================================================
## Constraints - Prueba física VGA
##
## Este archivo contiene únicamente las asignaciones necesarias
## para probar físicamente el generador VGA en la Basys 3.
## Se utiliza el reloj principal de 100 MHz, el botón central
## como reset y las salidas VGA RGB, HSYNC y VSYNC.
## ============================================================


## ------------------------------------------------------------
## Reloj principal de la Basys 3 - 100 MHz
## ------------------------------------------------------------

set_property PACKAGE_PIN W5 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]

#create_clock -add -name sys_clk_pin -period 10.000 \
#    -waveform {0 5.000} [get_ports clk_100mhz]


## ------------------------------------------------------------
## Reset - Botón central BTNC
## ------------------------------------------------------------

set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]


## ------------------------------------------------------------
## VGA - Canal rojo
## ------------------------------------------------------------

set_property PACKAGE_PIN G19 [get_ports {vga_red[0]}]
set_property PACKAGE_PIN H19 [get_ports {vga_red[1]}]
set_property PACKAGE_PIN J19 [get_ports {vga_red[2]}]
set_property PACKAGE_PIN N19 [get_ports {vga_red[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[*]}]


## ------------------------------------------------------------
## VGA - Canal verde
## ------------------------------------------------------------

set_property PACKAGE_PIN N18 [get_ports {vga_green[0]}]
set_property PACKAGE_PIN L18 [get_ports {vga_green[1]}]
set_property PACKAGE_PIN K18 [get_ports {vga_green[2]}]
set_property PACKAGE_PIN J18 [get_ports {vga_green[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {vga_green[*]}]


## ------------------------------------------------------------
## VGA - Canal azul
## ------------------------------------------------------------

set_property PACKAGE_PIN J17 [get_ports {vga_blue[0]}]
set_property PACKAGE_PIN H17 [get_ports {vga_blue[1]}]
set_property PACKAGE_PIN G17 [get_ports {vga_blue[2]}]
set_property PACKAGE_PIN D17 [get_ports {vga_blue[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {vga_blue[*]}]


## ------------------------------------------------------------
## VGA - Sincronización
## ------------------------------------------------------------

set_property PACKAGE_PIN P19 [get_ports hsync]
set_property IOSTANDARD LVCMOS33 [get_ports hsync]

set_property PACKAGE_PIN R19 [get_ports vsync]
set_property IOSTANDARD LVCMOS33 [get_ports vsync]


## ------------------------------------------------------------
## Configuración del FPGA
## ------------------------------------------------------------

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]