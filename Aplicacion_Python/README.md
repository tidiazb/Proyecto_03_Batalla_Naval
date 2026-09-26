# Issue #9 — Aplicación de PC del Jugador 2

Aplicación de consola para Batalla Naval. Se comunica con la FPGA por UART a 115200 baudios y muestra dos tableros de 8×8: **propio** (barcos aceptados y disparos recibidos) y **rival conocido** (solo impactos/fallos de disparos propios). Las reglas del juego residen en el programa RISC-V.

Requiere Python 3.10 o posterior.

## Archivos

| Archivo | Función |
|---|---|
| `python/battle_client.py` | Puerto serial, lectura de mensajes, validación de entradas, estado visual y terminal. |
| `PROTOCOLO_UART.md` | Mensajes exactos que deben producir e interpretar FPGA y PC. |
| `tests/test_battle_client.py` | Pruebas automáticas sin hardware. |
| `requirements.txt` | Dependencia `pyserial`. |

## Conceptos del código

1. `LineFramer` reúne los bytes recibidos hasta encontrar `\n`. UART es un flujo de bytes: un `read()` puede traer media línea o varias líneas completas. Los bytes fuera de ASCII y las tramas demasiado largas se descartan sin bloquear el programa.
2. `parse_frame()` comprueba número de campos, coordenadas y nombres de eventos antes de tocar los tableros.
3. `BattleState` guarda **solo lo visible para el Jugador 2**. Una solicitud `PLACE` queda pendiente: el barco se dibuja únicamente al llegar `PLACE,id,OK` desde la FPGA. Un disparo actualiza el tablero rival solo cuando llega `SHOT`.
4. `InputWorker` ejecuta `input()` en un hilo: mientras la persona escribe una coordenada, el hilo principal sigue leyendo mensajes UART. Si llega una partida nueva, una entrada antigua se descarta mediante un identificador de solicitud.
5. `open_serial()` usa `pyserial` para abrir el puerto seleccionado con 115200, 8N1 y tiempos de espera cortos. El bucle `run()` mantiene abierta la aplicación durante partidas sucesivas.

Las longitudes 4, 3 y 2 solo se usan para **dibujar un barco después de que la FPGA aceptó su colocación**. El código no valida traslapes ni determina aciertos, turnos, hundimientos o victoria.

## Ejecutar las pruebas sin FPGA

Abre una terminal en esta carpeta y ejecuta:

```powershell
py -m unittest discover -s tests -v
```

Los tests comprueban tramas seriales fragmentadas, recuperación después de bytes inválidos, entradas fuera de rango, rechazo y reintento de barcos, actualización de vistas, turnos, resultados, resumen y nueva partida. No necesitan instalar `pyserial`.

## Ejecutar con la FPGA en Windows

1. Conecta el adaptador UART-USB y verifica que Windows le asignó un puerto COM.
2. Instala la dependencia desde esta carpeta: `py -m pip install -r requirements.txt`.
3. Inicia la aplicación con `py python/battle_client.py --port COM3`, reemplazando `COM3` por el puerto real. Si omites `--port`, la aplicación muestra los puertos detectados y solicita uno.
4. Configura el programa RISC-V para enviar `NEW\n` al comenzar. Abre primero la aplicación y luego inicia o reinicia la partida en la FPGA para recibir ese mensaje. La aplicación pedirá los barcos en formato `fila,columna,H/V`, por ejemplo `2,3,H`. Durante el turno P2 pedirá el disparo `fila,columna`, por ejemplo `4,6`.
5. La FPGA debe responder conforme a `PROTOCOLO_UART.md`. Si la colocación fue rechazada se vuelve a pedir; después de `END` la aplicación queda esperando el siguiente `NEW`. Usa `Ctrl+C` para salir.

En VS Code o PyCharm también puedes ejecutar `battle_client.py` con el argumento `--port COM3`. Si la terminal indica acceso denegado, cierra cualquier monitor serial que ya tenga abierto el puerto.

## Validación de integración física

| Comprobación | Resultado esperado |
|---|---|
| Abrir puerto a 115200, 8N1 | Se muestra `Esperando NEW de la FPGA`. |
| FPGA envía `NEW` | Se ven dos tableros limpios y se pide el barco 0. |
| Colocación rechazada | Se muestra motivo y se vuelve a pedir el mismo barco. |
| Colocación aceptada | Se dibuja en el tablero propio y se pasa al siguiente. |
| `TURN,P1` / `TURN,P2` | Se indica el turno; solo P2 solicita disparo. |
| `SHOT` e `INCOMING` | Se actualizan exclusivamente las casillas visibles correspondientes. |
| Coordenada inválida del usuario | Se explica el formato sin enviarla por UART. |
| Mensaje UART inválido | Se informa del error y continúa la aplicación. |
| `END` y luego BTN RST / `NEW` | Aparece el resumen y empieza una partida con tableros limpios. |

**Punto de integración:** este paquete define un protocolo ASCII por líneas. La persona que desarrolla el ensamblador debe usar esos mismos nombres de mensajes y campos. Si ya existe un protocolo distinto acordado por el equipo, cambien el documento y los tres puntos de codificación y decodificación indicados arriba antes de conectar la FPGA.
