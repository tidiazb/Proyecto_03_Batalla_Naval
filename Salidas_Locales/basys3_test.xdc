## ============================================================
## BASYS 3 - PRUEBA FISICA DE PERIFERICOS
##
## Modulos:
##   - seven_seg_display
##   - status_led
##   - buzzer_controller
##
## Top:
##   top_prueba.sv
##
## FPGA:
##   xc7a35tcpg236-1
## ============================================================


## ============================================================
## CLOCK - 100 MHz
## ============================================================

set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]

create_clock -add \
    -name sys_clk_pin \
    -period 10.00 \
    -waveform {0 5} \
    [get_ports clk]


## ============================================================
## SWITCHES SW0 - SW15
## ============================================================

## SW0
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[0]}]

## SW1
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[1]}]

## SW2
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[2]}]

## SW3
set_property -dict { PACKAGE_PIN W17 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[3]}]

## SW4
set_property -dict { PACKAGE_PIN W15 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[4]}]

## SW5
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[5]}]

## SW6
set_property -dict { PACKAGE_PIN W14 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[6]}]

## SW7
set_property -dict { PACKAGE_PIN W13 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[7]}]

## SW8
set_property -dict { PACKAGE_PIN V2 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[8]}]

## SW9
set_property -dict { PACKAGE_PIN T3 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[9]}]

## SW10
set_property -dict { PACKAGE_PIN T2 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[10]}]

## SW11
set_property -dict { PACKAGE_PIN R3 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[11]}]

## SW12
set_property -dict { PACKAGE_PIN W2 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[12]}]

## SW13
set_property -dict { PACKAGE_PIN U1 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[13]}]

## SW14
set_property -dict { PACKAGE_PIN T1 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[14]}]

## SW15
set_property -dict { PACKAGE_PIN R2 IOSTANDARD LVCMOS33 } \
    [get_ports {sw[15]}]


## ============================================================
## BOTONES
## ============================================================

## BTNC = RESET
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } \
    [get_ports btnC]

## BTNU = START DEL BUZZER
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } \
    [get_ports btnU]


## ============================================================
## LEDS DE ESTADO
##
## led[0] -> LD0
## led[1] -> LD1
## led[2] -> LD2
## ============================================================

## LD0
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } \
    [get_ports {led[0]}]

## LD1
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } \
    [get_ports {led[1]}]

## LD2
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } \
    [get_ports {led[2]}]


## ============================================================
## LED BUSY DEL BUZZER
##
## busy_led -> LD15
## ============================================================

set_property -dict { PACKAGE_PIN L1 IOSTANDARD LVCMOS33 } \
    [get_ports busy_led]


## ============================================================
## DISPLAY DE 7 SEGMENTOS
##
## IMPORTANTE:
##
## Tu seven_seg_decoder.sv utiliza:
##
##     seg[6:0] = {a,b,c,d,e,f,g}
##
## Por eso:
##
## seg[6] = A
## seg[5] = B
## seg[4] = C
## seg[3] = D
## seg[2] = E
## seg[1] = F
## seg[0] = G
##
## El orden de pines de abajo está INTENCIONALMENTE
## invertido respecto al índice típico del Master XDC.
## ============================================================


## Segmento A
set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } \
    [get_ports {seg[6]}]

## Segmento B
set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } \
    [get_ports {seg[5]}]

## Segmento C
set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } \
    [get_ports {seg[4]}]

## Segmento D
set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } \
    [get_ports {seg[3]}]

## Segmento E
set_property -dict { PACKAGE_PIN U5 IOSTANDARD LVCMOS33 } \
    [get_ports {seg[2]}]

## Segmento F
set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } \
    [get_ports {seg[1]}]

## Segmento G
set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } \
    [get_ports {seg[0]}]


## ============================================================
## ANODOS DEL DISPLAY
##
## AN0 = extremo derecho
## AN3 = extremo izquierdo
## ============================================================

## AN0
set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS33 } \
    [get_ports {an[0]}]

## AN1
set_property -dict { PACKAGE_PIN U4 IOSTANDARD LVCMOS33 } \
    [get_ports {an[1]}]

## AN2
set_property -dict { PACKAGE_PIN V4 IOSTANDARD LVCMOS33 } \
    [get_ports {an[2]}]

## AN3
set_property -dict { PACKAGE_PIN W4 IOSTANDARD LVCMOS33 } \
    [get_ports {an[3]}]


## ============================================================
## BUZZER
##
## Salida del buzzer -> PMOD JA1
## JA1 corresponde al pin J1 del FPGA.
## ============================================================

set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } \
    [get_ports buzzer]


## ============================================================
## CONFIGURACION GENERAL
## ============================================================

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]