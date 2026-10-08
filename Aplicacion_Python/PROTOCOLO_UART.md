# Protocolo de aplicación UART — Proyecto 3

Este documento define el contrato entre el programa RISC-V de la FPGA y la aplicación Python del Jugador 2. Cada mensaje contiene caracteres ASCII imprimibles y termina en `LF` (`0x0A`). La aplicación también acepta `CRLF`. Los campos se separan con coma, sin espacios. UART físico: **115200 baudios, 8 bits, sin paridad, 1 bit de parada**.

Las coordenadas `fila` y `columna` son números decimales de **0 a 7**. Las identidades de barco son `0`, `1` y `2`, con longitudes respectivas **4, 3 y 2**. Las orientaciones son `H` (horizontal) y `V` (vertical). Se transmite un mensaje completo por cada línea; no se incluyen direcciones MMIO en el texto serial.

## PC → FPGA

| Mensaje | Ejemplo | Descripción |
|---|---|---|
| `PLACE,id,fila,columna,orientación` | `PLACE,0,2,3,H\n` | Solicitud de colocación del barco del Jugador 2. |
| `FIRE,fila,columna` | `FIRE,4,6\n` | Disparo del Jugador 2 durante su turno. |

La PC valida sintaxis, coordenadas y orientación antes de transmitir. **El programa RISC-V** valida traslapes, salida del tablero, turnos, casillas repetidas, impactos, hundimientos y victoria. Si una colocación o un disparo se rechaza, la FPGA envía el evento de rechazo correspondiente y la PC vuelve a solicitar la entrada.

## FPGA → PC

| Mensaje | Ejemplo | Efecto en la aplicación |
|---|---|---|
| `NEW` | `NEW\n` | Inicia colocación; limpia las vistas de la partida anterior. |
| `PLACE,id,OK` | `PLACE,0,OK\n` | Dibuja el barco aceptado en el tablero propio y solicita el siguiente. |
| `PLACE,id,REJECT,motivo` | `PLACE,0,REJECT,OVERLAP\n` | Muestra motivo y solicita el mismo barco. Motivos: `OVERLAP`, `OUT_OF_BOUNDS`, `INVALID`. |
| `BATTLE` | `BATTLE\n` | Indica que ambos jugadores colocaron la flota. |
| `TURN,jugador` | `TURN,P2\n` | Muestra el turno; solicita disparo solo cuando corresponde a `P2`. |
| `SHOT,fila,columna,resultado,barco` | `SHOT,4,6,SUNK,2\n` | Resultado del disparo propio del Jugador 2; actualiza tablero rival conocido. |
| `SHOT_REJECT,fila,columna,motivo` | `SHOT_REJECT,4,6,REPEAT\n` | Muestra rechazo; solicita otra casilla si sigue el turno P2. Motivos: `REPEAT`, `NOT_TURN`, `INVALID`. |
| `INCOMING,fila,columna,resultado,barco` | `INCOMING,2,3,HIT,-\n` | Disparo del Jugador 1 contra tablero propio; actualiza su vista. |
| `END,ganador,disparosP1,disparosP2,hundidosP1,hundidosP2` | `END,P2,15,13,2,3\n` | Muestra ganador y resumen; espera `NEW` tras BTN RST. |
| `ERROR,código` | `ERROR,BAD_FRAME\n` | Avisa un comando inválido sin detener la aplicación. |

Los resultados de disparo son `HIT`, `MISS` o `SUNK`. El último campo es `0`, `1` o `2` cuando se quiere identificar el barco hundido; se usa `-` cuando no corresponde. Para `SHOT`, **no** se transmiten posiciones ocultas de barcos del Jugador 1. Para `INCOMING`, la FPGA comunica solo el disparo y el resultado del Jugador 1 sobre el tablero del Jugador 2.

## Orden de ejemplo

```text
FPGA: NEW
PC:   PLACE,0,0,0,H
FPGA: PLACE,0,OK
PC:   PLACE,1,2,2,V
FPGA: PLACE,1,REJECT,OVERLAP
PC:   PLACE,1,3,4,V
FPGA: PLACE,1,OK
PC:   PLACE,2,6,5,H
FPGA: PLACE,2,OK
FPGA: BATTLE
FPGA: TURN,P1
FPGA: INCOMING,0,0,HIT,-
FPGA: TURN,P2
PC:   FIRE,4,6
FPGA: SHOT,4,6,MISS,-
FPGA: TURN,P1
...
FPGA: END,P2,15,13,2,3
FPGA: NEW
```

`NEW` debe enviarse al comienzo de cada nueva partida, incluso después del reinicio de partida con BTN RST. La FPGA debe descartar cualquier mensaje que no respete el protocolo sin alterar el juego. El programa RISC-V debe transmitir una respuesta para cada `PLACE` o `FIRE` válido en sintaxis, para que la interfaz sepa cuándo solicitar otra entrada.

## Límite entre software y hardware

En el CPU, UART se atiende mediante los registros MMIO CONTROL `0x0001_0040`, TX `0x0001_0044` y RX `0x0001_0048`. El programa ensamblador construye y analiza estas líneas ASCII byte por byte. La aplicación Python abre el puerto serie y muestra la vista privada del Jugador 2. **La aplicación no determina** si un barco cabe, si hubo impacto, si se hundió un barco ni quién ganó: acepta los eventos del CPU como fuente de verdad.

Este contrato es una propuesta completa para integrar las dos partes. Si el equipo ya definió otro protocolo en el ensamblador, adapte juntos `parse_frame()`, `placement_command()` y `shot_command()` antes de la prueba física.
