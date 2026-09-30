# Integración de Batalla Naval — Proyecto 3

El sistema ejecuta Batalla Naval de 8×8 mediante el procesador RISC-V del equipo. El programa en ensamblador controla las reglas y accede a los periféricos por MMIO. Cada jugador coloca tres barcos de 4, 3 y 2 casillas. El Jugador 1 usa controles locales y VGA; el Jugador 2 utiliza la aplicación Python por UART.

## 1. Archivos principales

| Archivo | Función |
|---|---|
| `firmware/batalla_naval.S` | Programa completo RV32I: inicialización, colocación, disparos, turnos, victoria y comunicación. |
| `firmware/batalla_naval.mem` | Imagen de ROM lista para simulación y síntesis: 2048 palabras de 32 bits. |
| `firmware/link.ld` | Ubica código y constantes en los 8 KiB de Program ROM. |
| `firmware/batalla_naval.lst` | Desensamblado con instrucciones y direcciones. |
| `firmware/symbols.json` | Direcciones de las etiquetas para depuración. |
| `rtl/batalla_naval_top.sv` | Integra CPU, memorias, MMIO, UART, entradas, salidas y VGA. |
| `tb/tb_batalla_naval_system.sv` | Dos partidas completas sobre el CPU RTL, con entradas físicas simuladas y UART serial. |
| `tb/tb_system_nominal_uart.sv` | Comunicación con parámetros de hardware y PC a 115200 baudios. |
| `tb/tb_integration_memory.sv` | Lecturas ROM/RAM/VGA y protección de direcciones. |
| `tb/vga_clock_sim.sv` | Modelo de reloj utilizado únicamente por Verilator. |
| `scripts/create_project.tcl` | Crea el proyecto Vivado para Basys 3 y genera Clock Wizard. |
| `scripts/stage_rom.tcl` | Copia el `.mem` al directorio de ejecución de simulación o síntesis. |
| `scripts/run_vivado_tests.tcl` | Ejecuta los tres testbenches usando `run all`. |
| `scripts/implement.tcl` | Ejecuta síntesis/implementación y genera reportes y netlists. |
| `docs/PROGRAMA_Y_DATOS.md` | Fases, rutinas, registros, pila, RAM y protocolo. |
| `docs/INTEGRACION.md` | Conexiones del top, relojes, resets y modificaciones de integración. |
| `docs/VALIDACION.md` | Casos ejecutados y resultados de simulación. |

Las rutas de esta tabla son relativas a `Integracion/`. Los módulos originales permanecen en sus carpetas del proyecto. El listado exacto de modificaciones está en `docs/INTEGRACION.md`.

## 2. Qué se ejecuta y por qué

El archivo `.S` es el código fuente del juego. El ensamblador lo convierte a instrucciones RV32I y el archivo `.mem` guarda sus palabras en hexadecimal. La ROM entrega una instrucción al procesador cada ciclo. Al ejecutar `lw` y `sw`, el procesador consulta o modifica RAM y registros MMIO.

El `top` conecta señales; las reglas de colocación, impactos y victoria se ejecutan en el programa. La aplicación Python transmite entradas del Jugador 2 y representa únicamente la información recibida de la FPGA.

La imagen incluida utiliza **4072 bytes** de los 8192 disponibles. Emplea instrucciones de 32 bits sin extensión comprimida, sin multiplicación/división y sin accesos `lb`/`sb`. La extracción de caracteres se realiza con `lw`, máscaras y desplazamientos.



## 3. Correr la simulación

Con el proyecto abierto:

```tcl
set_property top tb_batalla_naval_system [get_filesets sim_1]
launch_simulation
run all
```

El testbench principal simula hasta al menos dos cuadros VGA, es decir, decenas de milisegundos de tiempo simulado. **`run 1000ns` no alcanza para completar esta prueba.**

Para ejecutar las tres pruebas:

```tcl
source {A:/Proyecto_03_Batalla_Naval_integrado/Integracion/scripts/run_vivado_tests.tcl}
```

Resultados esperados:

```text
PASS tb_integration_memory: constantes ROM, proteccion, RAM, VGA y rangos
PASS tb_system_nominal_uart: CPU/MMIO, TX 115741 y RX PC 115200 8N1
PASS tb_batalla_naval_system: dos partidas completas, MMIO, UART, GPIO, salidas, VGA y reset
```

Un `Fatal: FAIL ...` identifica una condición incumplida. Revisar el log de cada simulación; la ejecución del script Tcl por sí sola no reemplaza el mensaje PASS del testbench.

Vivado utiliza el **Clock Wizard real**. No agregar `tb/vga_clock_sim.sv` a sus fuentes: definiría por segunda vez el módulo `vga_clock`.

## 5. Señales para depurar

En `tb_batalla_naval_system/dut`:

- `prog_addr`, `prog_instr`: instrucción ejecutada y dirección del programa.
- `data_addr`, `data_out`, `data_in`, `cpu_we`: acceso de datos.
- `uart_sel`, `uart_we`, `gpio_sel`, `gpio_we`, `vga_we`: selección y escritura de periféricos.
- `u_mem/u_data_ram/ram`: tableros y estado del juego.
- `u_video/u_video_ram/mem`: estados visuales de los tiles.
- `u_video/pixel_clk`, `hsync`, `vsync`: temporización VGA.
- `u_uart/rx_overrun_r`, `u_uart/tx_overrun_r`: errores de capacidad UART.

## 6. Controles en Basys 3

| Elemento físico | Acción |
|---|---|
| BTNU, BTND, BTNL, BTNR | Mover cursor dentro del tablero. |
| BTNC | OK: colocar el siguiente barco o confirmar un disparo propio. |
| SW0: subir y volver a bajar | SEL: alternar orientación horizontal/vertical en colocación. |
| SW1: subir y volver a bajar | Nueva partida desde cualquier fase; conserva victorias. |
| SW15 en 1 | Reset global: reinicia CPU/periféricos y limpia victorias. Volver a 0 para ejecutar. |
| LED0, LED1, LED2 | Colocación, batalla y resultado, respectivamente. |
| Cuatro displays | Dos dígitos por jugador para victorias acumuladas visibles. |
| VGA | Tablero propio a la izquierda y tablero rival conocido a la derecha. |
| JA1 | Señal del buzzer pasivo externo. |

Mantener las acciones de SW0/SW1 y las pulsaciones durante al menos 20 ms. Cada transición estable de 0 a 1 produce un evento; dejar un switch en 1 no repite la acción. Para usar pulsadores externos en SEL/RST, cambiar sus pins en los constraints y conservar los puertos del top.

El buzzer se conecta mediante una interfaz compatible con 3.3 V y GND común. La Basys 3 no incorpora un buzzer ni un LED RGB; el diseño utiliza un buzzer externo y tres LEDs independientes.

## 7. Probar con FPGA y Python

1. Ejecutar síntesis e implementación, revisar los reportes y generar/programar el bitstream del top `batalla_naval_top`.
2. Conectar el monitor VGA y la interfaz del buzzer.
3. Abrir la terminal de Python antes de pedir una nueva partida:

```powershell
cd A:\Proyecto_03_Batalla_Naval_integrado\Aplicacion_Python
python -m pip install -r requirements.txt
python python\battle_client.py --port COM3
```

4. Cambiar `COM3` por el puerto de la placa. UART utiliza 115200, 8 bits, sin paridad y un bit de parada.
5. Accionar SW1 para emitir `NEW`. Ambos jugadores pueden colocar sus flotas en paralelo. J1 navega, alterna orientación con SW0 y confirma con BTNC. J2 introduce `fila,columna,H/V` cuando la terminal lo solicita.
6. Al completar ambas flotas, comienza J1. Un disparo válido, incluso un impacto, alterna el turno. Un repetido conserva el turno.
7. Tras la victoria, SW1 inicia otra partida conservando las victorias. SW15 realiza un reset global.

VGA utiliza azul para agua, gris para barco propio, cian para fallo y rojo para impacto. El borde amarillo marca el cursor. Los tres indicadores de flota de cada jugador pasan de negro a gris al colocar cada barco; el HUD codifica fase, orientación y turno mediante tiles de color.

### Indicadores del HUD

| Tile | Gris | Cian | Rojo |
|---|---|---|---|
| Fila 11, columna 1: fase | Colocación | Batalla | Resultado |
| Fila 11, columna 2: orientación | Horizontal | Vertical | — |
| Fila 11, columna 3: turno | J1 | J2 | — |

Las filas 12 y 13 muestran los tres barcos colocados de J1 y J2, respectivamente: negro pendiente y gris completado.

## 8. Síntesis, implementación y evidencias

```tcl
source {A:/Proyecto_03_Batalla_Naval_integrado/Integracion/scripts/implement.tcl}
```

El script revisa la finalización de los runs, latches, errores DRC y slack de setup/hold. Genera en `vivado_integrado/reports/` utilización, timing, DRC, CDC, interacción de relojes, netlist sintetizado, netlist temporizado y SDF. Revisar también advertencias, rutas no restringidas, conexiones externas y comportamiento del hardware. Para simulación temporizada en Vivado, seleccionar `tb_system_nominal_uart` como simulation top y **Run Post-Implementation Timing Simulation** después de completar la implementación. Este testbench utiliza únicamente puertos externos y ejecuta un fragmento del programa completo sobre el netlist. Usar `run all` y comprobar su mensaje PASS. El testbench de dos partidas utiliza observación de memorias internas y está destinado a simulación behavioral.

## 9. Regenerar el programa

El `.mem` ya está incluido; no hace falta un ensamblador para la primera prueba en Vivado. Para modificar el programa, instalar GNU binutils para RISC-V y Python 3 y ejecutar desde la raíz del proyecto:

```bash
python3 Integracion/scripts/build_firmware.py
```

El script utiliza `riscv64-unknown-elf-as`, `ld`, `objcopy`, `objdump` y `nm` con `-march=rv32i -mabi=ilp32`. También admite `--prefix riscv32-unknown-elf-` o un prefijo de ruta completo. No se utiliza un compilador C ni un sistema operativo sobre el procesador.

Pruebas en Linux/WSL con Verilator y compilador C++:

```bash
bash Integracion/scripts/run_tests.sh
```

## 10. Referencia de pins

Las asignaciones de la Basys 3 provienen del [archivo oficial Digilent Basys-3-Master.xdc](https://github.com/Digilent/digilent-xdc/blob/master/Basys-3-Master.xdc). El top y los constraints de este paquete están configurados para esa placa.
