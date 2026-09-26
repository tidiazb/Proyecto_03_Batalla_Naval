# Issue #4 - ROM, RAM e interconexion MMIO

Primer conjunto de modulos del Proyecto 3. Se entrega aislado para que el equipo pueda revisar la interfaz con el CPU antes de conectar los perifericos fisicos. Todo el control de Batalla Naval pertenecera al programa en ensamblador; estos modulos solo almacenan datos y encaminan accesos.

## Archivos

| Archivo | Funcion |
|---|---|
| `rtl/program_rom.sv` | ROM de 2048 instrucciones; carga opcional con `$readmemh`. |
| `rtl/data_ram.sv` | RAM de 1024 palabras de 32 bits. |
| `rtl/mmio_interconnect.sv` | Decoder, write enables independientes y mux de lectura. |
| `rtl/memory_mmio_system.sv` | Instancia ROM, RAM y bus para conectar al procesador. |
| `sim/tb_*.sv` | Cuatro pruebas autoverificables. |
| `sim/program_test.hex` | Tres instrucciones de prueba; no es el programa del juego. |

## Conexion con el procesador

| Salida/entrada del CPU | Puerto de `memory_mmio_system` | Funcion |
|---|---|---|
| `ProgAddress_o[31:0]` | `ProgAddress_i` | Direccion byte de instruccion. |
| `ProgIn_i[31:0]` | `ProgIn_o` | Instruccion procedente de la ROM. |
| `DataAddress_o[31:0]` | `DataAddress_i` | Direccion byte para `lw` / `sw`. |
| `DataOut_o[31:0]` | `DataOut_i` | Dato del CPU para `sw`. |
| `we_o` | `we_i` | Habilitacion de escritura. |
| `DataIn_i[31:0]` | `DataIn_o` | Resultado para `lw`. |

Se implementan accesos **de palabra de 32 bits, alineados a 4 bytes**. El RAM escribe en el flanco ascendente del reloj y entrega lectura combinacional; la ROM tambien lee combinacionalmente. Esta eleccion corresponde a un procesador con lectura de memoria en el mismo ciclo. Antes de integrar hay que confirmar la latencia prevista por el disenador del CPU: una RAM de lectura sincrona o ROM inferida como BRAM requeriria ajustar su control de ciclos. No hay handshake de espera ni instrucciones `lb`/`sb` en esta interfaz inicial.

La RAM no recibe el `BTN_RST` de partida: los contadores de victorias deben conservarse cuando el programa comienza una nueva partida. La inicializacion a cero corresponde al encendido/configuracion de FPGA; el programa es responsable de inicializar y limpiar las estructuras de cada partida.

## Mapa de memoria implementado

| Destino | Direccion/rango | Interfaz local |
|---|---|---|
| Program ROM | `0x0000_0000-0x0000_1FFF` | `ProgAddress_i[12:2]`, independiente de MMIO. |
| Data RAM | `0x0000_2000-0x0000_2FFF` | `ram_addr_o[9:0]`, 1024 palabras. |
| UART control, TX, RX | `0x0001_0040`, `0x0001_0044`, `0x0001_0048` | `uart_addr_o[1:0]` = `00`, `01`, `10`. |
| Entradas J1 | `0x0001_0120` | Un registro, direccion local `00`. |
| Display 7 segmentos | `0x0001_0130` | Un registro, direccion local `00`. |
| LED | `0x0001_0138` | Un registro, direccion local `00`. |
| Buzzer | `0x0001_0140` | Un registro, direccion local `00`. |
| Memoria VGA | `0x0001_1000-0x0001_17FF` | `vga_addr_o[8:0]`, 512 posiciones posibles. |

Para UART, botones, displays, LED, buzzer y VGA, `memory_mmio_system` expone `bus_wdata_o`, `*_we_o` y `*_rdata_i`. El top del equipo conectara esas senales a los perifericos correspondientes. `*_sel_o` tambien indica que el periférico esta seleccionado, incluso durante una lectura; los registros simples usan `addr_i=2'b00`. El rango VGA admite 512 palabras; una cuadrícula de 20 x 15 tiles utiliza 300 y el resto queda reservado en el espacio de video.

Las direcciones fuera del mapa o desalineadas producen `DataIn_o=0` y todos los `*_we_o=0`. La ROM responde con una instruccion NOP ante una direccion de programa invalida. La interfaz no implementa excepciones del procesador para dichos accesos.

## Inicializacion de la ROM

El ensamblador y su conversor deben producir un archivo hexadecimal con **una palabra de 32 bits por linea, en orden de direcciones ascendentes**. Por ejemplo:

```text
00000013
00100093
00208113
```

El primer renglon corresponde a `0x0000_0000`, el segundo a `0x0000_0004`. Al instanciar `memory_mmio_system`, pase la ruta con `PROGRAM_FILE`, por ejemplo `.PROGRAM_FILE("program.hex")`; agregue ese archivo como fuente de inicializacion en Vivado. Mientras no se proporcione el programa final, `PROGRAM_FILE=""` llena la ROM con NOP, suficiente para elaborar el RTL, pero no ejecuta Batalla Naval.

## Pruebas

Desde la carpeta principal de este paquete, en un sistema con Icarus Verilog:

```bash
bash sim/run_tests.sh
```

La prueba ROM carga `sim/program_test.hex`; el script cambia primero al directorio `sim/` para que la ruta relativa sea valida. En Vivado agregue `sim/program_test.hex` como fuente de simulacion y ajuste el parametro `INIT_FILE` de los testbenches a la ruta que utilice el simulador. Los testbenches cubren las primeras y ultimas posiciones, accesos fuera de rango, escrituras individuales, lectura de cada periférico, seleccion exclusiva y preservacion de RAM tras un store invalido. Cada uno imprime `PASS` si concluye sin errores, y usa `$fatal` cuando una comparacion falla.

Para integrar el UART reutilizado del Proyecto 2, recuerde que su decoder interno anterior asignaba TX a `00`, RX a `01` y control a `10`: el contrato nuevo exige **control `00`, TX `01`, RX `10`**. El ajuste pertenece al Issue #8 o a un adaptador documentado.
