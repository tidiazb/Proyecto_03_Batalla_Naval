# Issue #8: periférico UART con registros MMIO

Este issue permite que el procesador RISC-V intercambie bytes con la PC por UART, a 115200 baudios, mediante instrucciones `lw` y `sw`. La ROM y la RAM siguen atendiendo otras direcciones; el bus del Issue #4 entrega las señales `uart_sel_o`, `uart_we_o`, `uart_addr_o` y `bus_wdata_o`.

## 1. Idea básica

UART envía una trama de 8 bits de datos con un bit de inicio y un bit de parada (8N1). La transmisión tarda muchos ciclos de reloj. Una FIFO TX conserva los bytes que escribió el CPU mientras sale la trama actual. Una FIFO RX conserva los bytes recibidos hasta que el CPU los lee. Las FIFO tienen cuatro posiciones cada una por defecto.

El periférico usa una interfaz de 32 bits para el CPU aunque UART envía y recibe **solo el byte bajo** de cada registro de datos. El decoder MMIO ya asigna los offsets `00`, `01` y `10` a las tres direcciones absolutas.

| Dirección del CPU | `addr_i` | Registro | Operación habitual |
|---|---:|---|---|
| `0x0001_0040` | `2'd0` | CONTROL/ESTADO | `lw` para consultar y `sw` para reconocer/avanzar RX. |
| `0x0001_0044` | `2'd1` | DATA_TX | `sw` encola `wdata_i[7:0]`; `lw` devuelve último byte aceptado. |
| `0x0001_0048` | `2'd2` | DATA_RX | `lw` devuelve el byte más antiguo de RX; escritura ignorada. |

### Bits de CONTROL/ESTADO

| Bit | Nombre | Lectura | Escritura |
|---:|---|---|---|
| 0 | RX_VALID | Hay al menos un byte disponible en RX. | Ignorada. |
| 1 | TX_READY | Hay espacio en la FIFO TX. | Ignorada. |
| 2 | RX_FULL | FIFO RX llena. | Ignorada. |
| 3 | RX_OVERRUN | Llegó un byte mientras la FIFO RX estaba llena; se descartó. | Escribir 1 limpia la marca (W1C). |
| 4 | TX_OVERRUN | El CPU intentó escribir TX con la FIFO llena; se descartó. | Escribir 1 limpia la marca (W1C). |
| 8 | RX_POP | Siempre lee 0. | Escribir 1 retira el byte ya leído (pulso W1P). |

`TX_READY` indica **espacio en la cola**, incluso si una trama sigue saliendo por el pin. La escritura en `DATA_TX` encola automáticamente; no hace falta un comando SEND. Antes de cada escritura, el programa debe comprobar `TX_READY=1`. Para RX, primero debe comprobar `RX_VALID=1`, leer `DATA_RX` y luego escribir `0x0000_0100` en CONTROL para pasar al siguiente byte. Los errores de overrun permanecen activos hasta limpiar sus bits.

Ejemplo conceptual en RISC-V (base `t0 = 0x0001_0040`):

```asm
# Esperar espacio para transmitir el caracter 'A'.
esperar_tx:
    lw   t1, 0(t0)       # CONTROL
    andi t1, t1, 2       # bit TX_READY
    beq  t1, zero, esperar_tx
    li   t2, 65          # ASCII 'A'
    sw   t2, 4(t0)       # DATA_TX

# Cuando RX_VALID=1: leer byte y retirarlo de la cola.
    lw   t3, 8(t0)       # DATA_RX
    li   t2, 256         # RX_POP, bit 8
    sw   t2, 0(t0)       # CONTROL
```

El fragmento RX presupone que ya se comprobó RX_VALID. Las pseudoinstrucciones `li` deben ser aceptadas por el ensamblador del equipo.

## 2. Qué hace cada módulo

| Archivo | Función |
|---|---|
| `rtl/baud_rate_generator.sv` | Genera un tick de muestreo a 16 veces la tasa de bits. Reutilizado del Proyecto 2. |
| `rtl/uart_receiver.sv` | Detecta inicio, reconstruye 8 bits y reconoce parada. Reutilizado del Proyecto 2. |
| `rtl/uart_transmitter.sv` | Serializa cada byte como trama UART. Reutilizado del Proyecto 2. |
| `rtl/uart_mmio_fifo.sv` | Cola de cuatro bytes; controla índices de lectura/escritura y cantidad almacenada. |
| `rtl/uart_mmio_peripheral.sv` | Conecta núcleo físico, FIFO y registros MMIO de 32 bits. |

`uart_mmio_peripheral` también sincroniza el pin RX asíncrono con dos flip-flops antes de enviarlo al receptor. Con reloj de 100 MHz, `BR_LIMIT=54` genera `100 000 000 / (54 × 16) ≈ 115 741` baudios: error aproximado de +0,47 % respecto de 115200. En simulación se usa `BR_LIMIT=4` para que las pruebas tarden menos; en hardware se dejan los parámetros por defecto.

Se reutilizan los bloques físicos del Proyecto 2. La FIFO y los registros se adaptaron al contrato de lectura y escritura del procesador; la organización anterior de registros TX/RX/CONTROL no coincide con este mapa MMIO.

## 3. Cómo conectarlo al bus existente

En el `top`, las señales UART del `memory_mmio_system` se conectan así:

```systemverilog
logic [31:0] bus_wdata, uart_rdata;
logic uart_sel, uart_we;
logic [1:0] uart_addr;

memory_mmio_system u_memory (
    // ... procesador, RAM y otros perifericos ...
    .bus_wdata_o(bus_wdata),
    .uart_sel_o(uart_sel),
    .uart_we_o(uart_we),
    .uart_addr_o(uart_addr),
    .uart_rdata_i(uart_rdata)
    // ...
);

uart_mmio_peripheral u_uart (
    .clk_i(clk_100mhz), .rst_i(system_reset),
    .select_i(uart_sel), .write_enable_i(uart_we),
    .addr_i(uart_addr), .wdata_i(bus_wdata), .rdata_o(uart_rdata),
    .uart_rx_i(serial_rx_pin), .uart_tx_o(serial_tx_pin)
);
```

No agregues dos archivos con la misma definición de `baud_rate_generator`, `uart_receiver` o `uart_transmitter` al mismo proyecto. Si el equipo ya añadió esos bloques del Proyecto 2, conserva una sola copia de cada uno.

## 4. Pruebas en Vivado

1. Agrega los cinco `.sv` de `rtl/` a **Design Sources**. Agrega los tres `.sv` de `sim/` a **Simulation Sources**. `tb_uart_mmio_bus` necesita también el `mmio_interconnect.sv` del Issue #4, ya añadido al proyecto.
2. En **Simulation Sources**, clic derecho en `tb_uart_mmio_fifo` → **Set as Top** → **Run Behavioral Simulation** → **Run All**. Debe aparecer `PASS tb_uart_mmio_fifo`.
3. Repite con `tb_uart_mmio_peripheral`. Observa `PASS tb_uart_mmio_peripheral`: se comprueban bytes transmitidos por el pin, dos bytes recibidos consecutivos, lectura/pop de RX, llenado de colas y marcas de overrun.
4. Repite con `tb_uart_mmio_bus`. Observa `PASS tb_uart_mmio_bus`: comprueba direcciones correctas, un byte TX por el pin, dato de lectura y acceso inválido.

Usa **Run All**, porque las tramas UART necesitan más tiempo que el `run 1000ns` inicial de XSim. Un `PASS` de estos testbenches demuestra la simulación del periférico y del bus; la prueba física con PC requiere conectarlo al `top`, asignar pines y comprobar comunicación a 115200 baudios.
