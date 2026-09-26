# Issue #7 — Entradas del Jugador 1

Este paquete implementa siete botones con sincronizacion, debounce y un registro MMIO en `0x0001_0120`. Reutiliza la tecnica de debounce del Proyecto 2 y conecta con `gpio_sel_o`, `gpio_we_o`, `gpio_rdata_i` y `bus_wdata_o` del Issue #4.

## Contenido

| Archivo | Uso |
|---|---|
| `rtl/debounce_button.sv` | Sincroniza y filtra un boton; genera un pulso por pulsacion. |
| `rtl/j1_inputs_peripheral.sv` | Siete instancias del filtro y registro ESTADO MMIO. |
| `sim/tb_debounce_button.sv` | Comprueba rebotes, pulsacion, liberacion y segunda pulsacion. |
| `sim/tb_j1_inputs_peripheral.sv` | Comprueba todos los bits, pulsaciones pendientes y escritura W1C. |
| `sim/tb_j1_mmio_integration.sv` | Comprueba lectura y escritura a traves del decoder del Issue #4. |

## Registro ESTADO (`0x0001_0120`)

| Boton | Nivel filtrado, RO | Evento pendiente, W1C |
|---|---:|---:|
| Arriba | 0 | 8 |
| Abajo | 1 | 9 |
| Izquierda | 2 | 10 |
| Derecha | 3 | 11 |
| SEL | 4 | 12 |
| OK | 5 | 13 |
| RST | 6 | 14 |

Los bits 7 y 31:15 son cero. Un bit de **nivel** vale 1 mientras el boton se mantiene presionado tras el filtrado. Un bit de **evento** pasa a 1 con una pulsacion y sigue asi aunque se suelte el boton. Para reconocerlo, el procesador escribe un 1 en ese bit de evento; los demas eventos quedan intactos. Si una nueva pulsacion coincide con esa escritura, la nueva pulsacion prevalece.

Por ejemplo, al presionar OK la lectura puede devolver `0x0000_2020`; al soltarlo devuelve `0x0000_2000`. Para reconocer la pulsacion, el programa ejecuta `sw` de `0x0000_2000` en `0x0001_0120`. Si el boton sigue presionado al reconocerla, la lectura posterior es `0x0000_0020`; no aparece otro evento hasta soltarlo y presionarlo otra vez.

En el programa RISC-V conviene procesar los eventos pendientes (`estado & 0x0000_7F00`), guardar ese valor y escribir **solo los eventos atendidos** para reconocerlos. La lectura de niveles permite comprobar si se mantiene presionado un boton.

## Reloj, reset y pulsadores

Los valores por defecto usan reloj de **100 MHz** y `DEBOUNCE_MS=20`. Por tanto, un cambio debe mantenerse estable durante unos 20 ms antes de aceptarse. Se requiere que las entradas fisicas valgan 1 al presionar; si algun boton es activo en bajo, inviertelo una vez al conectarlo al `top`.

`rst_i` es el reset global sincronico del periférico. `btn_rst_raw_i` es el boton de **reinicio de partida**, cuyo nivel y evento llegan al programa mediante MMIO. No lo conectes directamente a `rst_i`: hacerlo eliminaria el evento antes de que el procesador lo lea. El programa decide como reiniciar la partida y que datos en RAM conservar o limpiar. Si el diseño requiere un reset electrico del procesador, debe definirse independientemente del evento de BTN RST.

## Conexion al bus del Issue #4

En el `top` del proyecto, conecta las salidas ya existentes de `memory_mmio_system` asi:

```systemverilog
logic [31:0] bus_wdata;
logic [31:0] gpio_rdata;
logic gpio_sel, gpio_we;

memory_mmio_system u_memory (
    // ... puertos del procesador y demas perifericos ...
    .bus_wdata_o(bus_wdata),
    .gpio_sel_o(gpio_sel),
    .gpio_we_o(gpio_we),
    .gpio_rdata_i(gpio_rdata)
    // ...
);

j1_inputs_peripheral u_j1_inputs (
    .clk_i(clk_100mhz),
    .rst_i(system_reset),
    .btn_up_raw_i(btn_up),
    .btn_down_raw_i(btn_down),
    .btn_left_raw_i(btn_left),
    .btn_right_raw_i(btn_right),
    .btn_sel_raw_i(btn_sel),
    .btn_ok_raw_i(btn_ok),
    .btn_rst_raw_i(btn_rst),
    .select_i(gpio_sel),
    .write_enable_i(gpio_we),
    .wdata_i(bus_wdata),
    .rdata_o(gpio_rdata)
);
```

La direccion absoluta se decodifica en el bus; el periférico recibe `select_i` y no necesita `addr_i`. Los datos de escritura se comparten entre perifericos, pero `gpio_we` solo se activa para `0x0001_0120`.

## Pruebas en Vivado

1. Agrega `rtl/debounce_button.sv` y `rtl/j1_inputs_peripheral.sv` a **Design Sources**. Usa la version de `debounce_button.sv` de este paquete si el Proyecto 3 todavia no contiene otra.
2. Agrega los tres archivos `sim/tb_*.sv` a **Simulation Sources**.
3. Para la prueba de integracion agrega `rtl/mmio_interconnect.sv` del paquete del Issue #4 a **Design Sources**; si ya esta en el proyecto, no lo dupliques.
4. Selecciona como *Simulation Top* cada testbench y ejecuta *Run Behavioral Simulation*. Cada uno termina con `PASS` o `$fatal`.

Los testbenches aceleran el filtro usando parametros de simulacion (`CLK_FREQ_HZ=1000`, `DEBOUNCE_MS=3`). Los valores de hardware siguen en 100 MHz y 20 ms.
