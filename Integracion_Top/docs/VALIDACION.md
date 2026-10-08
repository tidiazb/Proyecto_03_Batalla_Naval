# Validación funcional de Batalla Naval

## 1. Entorno y metodología

Las pruebas ejecutan el procesador RTL del equipo y la imagen ensamblada `batalla_naval.mem`. Se utilizó Verilator 5.020 para simulación SystemVerilog y GNU binutils RISC-V 2.42 para generar la imagen de instrucciones. La suite de la aplicación PC se ejecutó con `unittest` de Python.

La ROM contiene 2048 palabras. Código y constantes ocupan 4072 bytes. El sistema mantiene la frecuencia de reloj simulada de 100 MHz. En la prueba extensa se reduce el divisor UART y el tiempo de debounce para ejecutar las acciones rápidamente; otra prueba utiliza el divisor UART de hardware y una PC simulada a 115200 baudios.

El modelo `vga_clock_sim.sv` representa funcionalmente el reloj de píxel de 25 MHz y la señal de bloqueo en Verilator. El proyecto Vivado utiliza el Clock Wizard PLL correspondiente. Los testbenches comprueban condiciones mediante comparaciones y `$fatal`; solamente emiten PASS al completar todos sus casos.

## 2. Prueba del sistema completo

**Testbench:** `tb_batalla_naval_system`.

| Caso ejecutado | Comprobación | Resultado |
|---|---|---|
| Arranque desde ROM | Mensaje NEW, fase de colocación y contadores iniciales. | PASS |
| Colocación local durante recepción UART | Se atienden la pulsación J1 y el comando J2. | PASS |
| Barco fuera del tablero | Rechazo OUT_OF_BOUNDS. | PASS |
| Traslape de J1 | No incrementa colocaciones ni escribe un barco parcial. | PASS |
| Traslape de J2 | Rechazo OVERLAP y posterior colocación aceptada. | PASS |
| Orientación inválida de J2 | Rechazo INVALID. | PASS |
| Orientación horizontal y vertical | Se colocan las flotas completas. | PASS |
| Solo un jugador listo | Permanece en colocación. | PASS |
| Ambos jugadores listos | Emite BATTLE y TURN,P1. | PASS |
| Reinicio en colocación/batalla/resultado | Regresa a colocación y limpia estructuras de partida. | PASS |
| Disparo fuera de turno | Emite SHOT_REJECT con NOT_TURN. | PASS |
| Disparo repetido de J1 | Conserva turno y contador de disparos. | PASS |
| Disparo repetido de J2 | Emite REPEAT y conserva turno/disparos. | PASS |
| Coordenada inválida | Emite ERROR,BAD_FRAME sin modificar la partida. | PASS |
| Trama demasiado larga | Descarta hasta LF y recupera comunicación. | PASS |
| Impacto y fallo | Actualiza RAM y transmite HIT/MISS. | PASS |
| Hundimiento | Reporta SUNK con identificador 0, 1 o 2. | PASS |
| Victoria J1 | END,P1,9,8,3,0 y contador acumulado J1=1. | PASS |
| Victoria J2 en partida siguiente | END,P2,9,9,0,3 y contadores J1=1/J2=1. | PASS |
| Displays y LED | Registros correspondientes a victorias y fase de resultado. | PASS |
| Buzzer | Se observan escrituras de eventos sonoros durante las partidas. | PASS |
| VGA | Tile del impacto final y escrituras de los tableros. | PASS |
| Sincronismos VGA | H: 800 píxeles/96 de pulso; V: 525 líneas/2 de pulso. | PASS |
| Reinicio de partida | Conserva las victorias de ambos jugadores. | PASS |
| Reset global | Emite NEW y limpia ambas victorias. | PASS |
| Exclusión de destinos de escritura | Verificación onehot0 de los WE en todos los ciclos activos. | PASS |
| FIFO UART | Sin indicadores de RX/TX overrun al finalizar. | PASS |
| Ejecución continua | Dos partidas completas con 35 disparos válidos y avance hasta el final. | PASS |

Mensaje de cierre:

```text
PASS tb_batalla_naval_system: dos partidas completas, MMIO, UART, GPIO, salidas, VGA y reset
```

## 3. UART con parámetros de hardware

**Testbench:** `tb_system_nominal_uart`.

La salida UART se decodifica como 8N1 con periodo de bit de 8640 ns, correspondiente al divisor 54 del sistema de 100 MHz. La entrada de la PC simulada utiliza 8680.556 ns por bit, correspondiente a 115200 baudios.

Se comprueba NEW, recepción de `PLACE,0,7,0,H`, aceptación `PLACE,0,OK` y una segunda colocación con respuesta `PLACE,1,OK`. La prueba utiliza exclusivamente puertos externos y admite el netlist temporizado.

```text
PASS tb_system_nominal_uart: CPU/MMIO, TX 115741 y RX PC 115200 8N1
```

## 4. Memorias y direcciones

**Testbench:** `tb_integration_memory`.

| Caso | Resultado |
|---|---|
| Lectura de instrucciones y constantes por los dos puertos ROM. | PASS |
| Escritura sobre ROM sin modificar su contenido. | PASS |
| Escritura/lectura RAM. | PASS |
| Lectura VGA combinacional hacia el CPU. | PASS |
| Escritura de última posición de video, índice 299. | PASS |
| Índice de video 300 y lectura de índice 511 protegidos. | PASS |
| Dirección desalineada sin WE ni dato válido. | PASS |
| Dirección no mapeada sin modificar la RAM. | PASS |

```text
PASS tb_integration_memory: constantes ROM, proteccion, RAM, VGA y rangos
```

## 5. Aplicación Python

Se ejecutaron nueve pruebas de `Aplicacion_Python/tests/test_battle_client.py`: reconstrucción de líneas parciales/CRLF, recuperación de tramas inválidas o largas, configuración serial, coordenadas y orientación, validación de mensajes, representación de una partida y nueva partida, protección ante mensajes inválidos, reintento tras error y espera del siguiente TURN después de SHOT.

```text
Ran 9 tests
OK
```

## 6. Elaboración y revisión estática

La elaboración del top completo terminó sin errores. En la revisión de Verilator no se reportaron advertencias LATCH, MULTIDRIVEN ni UNOPTFLAT. Las advertencias de anchos de algunos módulos reutilizados se registran en el log de elaboración. Los registros del bus se validan con los casos funcionales y las comprobaciones continuas del sistema.

## 7. Evidencias reproducibles

Los logs de las pruebas ejecutadas se encuentran en `evidencias/`. Cada log registra las respuestas UART esperadas y el mensaje final de su testbench. Los scripts de `Integracion/scripts/` regeneran el programa, ejecutan simulación y generan reportes del flujo de implementación en Vivado.

El flujo de implementación exporta utilización, DRC, timing, CDC, interacción de relojes, netlists y SDF. El procedimiento de prueba física descrito en `Integracion/README.md` permite verificar controles, monitor VGA, aplicación PC y buzzer sobre la placa.
