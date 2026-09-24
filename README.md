# Proyecto 3 - Batalla Naval sobre RISC-V

Planteamiento de diseño modular del sistema digital para el Proyecto 3 de EL3313 Taller de Diseño Digital.



---

# Diagrama de Primer Nivel

El diagrama de primer nivel representa el sistema completo como un único bloque. En este nivel no se muestran los módulos internos, sino únicamente las entradas y salidas externas necesarias para que la FPGA interactúe con los dos jugadores y con los periféricos físicos.

```text
                              ┌───────────────────────────────────────┐
                              │                                       │
clk_100MHz [1 bit] ──────────►│                                       │────► UART_TX / RsTx [1 bit]
                              │                                       │
BTN_UP [1 bit] ──────────────►│                                       │────► VGA_R
BTN_DOWN [1 bit] ────────────►│                                       │────► VGA_G
BTN_LEFT [1 bit] ────────────►│         SISTEMA BATALLA NAVAL         │────► VGA_B
BTN_RIGHT [1 bit] ───────────►│                                       │────► VGA_HSYNC [1 bit]
BTN_SEL [1 bit] ─────────────►│        RISC-V + MEMORIAS +            │────► VGA_VSYNC [1 bit]
BTN_OK [1 bit] ──────────────►│             PERIFERICOS               │
BTN_RST [1 bit] ─────────────►│                                       │────► seg[6:0] [7 bits]
                              │                                       │────► an[3:0] [4 bits]
UART_RX / RsRx [1 bit] ──────►│                                       │────► dp [1 bit]
                              │                                       │────► led_estado
                              │                                       │────► buzzer [1 bit]
                              │                                       │
                              └───────────────────────────────────────┘
```

## Objetivo

Implementar una plataforma computacional sobre FPGA capaz de ejecutar un programa de Batalla Naval para dos jugadores. El sistema utiliza un microprocesador RISC-V de 32 bits, memorias de programa y datos y periféricos mapeados en memoria para manejar la interfaz local del Jugador 1, la comunicación UART con el Jugador 2 y la generación de video VGA.

## Entradas del sistema

- **clk_100MHz:** reloj principal del sistema. A partir de este reloj se generan las frecuencias internas requeridas, incluyendo el reloj de píxel del periférico VGA.
- **BTN_UP:** desplaza el cursor hacia arriba.
- **BTN_DOWN:** desplaza el cursor hacia abajo.
- **BTN_LEFT:** desplaza el cursor hacia la izquierda.
- **BTN_RIGHT:** desplaza el cursor hacia la derecha.
- **BTN_SEL:** permite seleccionar o rotar la orientación del barco durante la fase de colocación.
- **BTN_OK:** confirma una colocación o un disparo del Jugador 1.
- **BTN_RST:** reinicia la partida y permite regresar a una nueva fase de colocación.
- **UART_RX / RsRx:** recibe desde la aplicación de PC del Jugador 2 los mensajes asociados a colocación de barcos y disparos.

## Salidas del sistema

- **UART_TX / RsTx:** transmite hacia la aplicación de PC los eventos y respuestas producidos por la partida.
- **VGA_R, VGA_G y VGA_B:** señales de color utilizadas para generar la imagen mostrada en el monitor VGA.
- **VGA_HSYNC:** señal de sincronización horizontal del monitor VGA.
- **VGA_VSYNC:** señal de sincronización vertical del monitor VGA.
- **seg[6:0]:** controla los segmentos de los displays de 7 segmentos.
- **an[3:0]:** selecciona el dígito activo de los displays de 7 segmentos.
- **dp:** controla el punto decimal del display.
- **led_estado:** indica visualmente la fase general en la que se encuentra el sistema.
- **buzzer:** genera la retroalimentación sonora correspondiente a los eventos de la partida.

## Explicación general

El sistema utiliza un programa en lenguaje ensamblador que se ejecuta sobre el microprocesador RISC-V implementado dentro de la FPGA. El Jugador 1 interactúa directamente con la tarjeta mediante botones y recibe la información de la partida por VGA, displays, LED y buzzer. El Jugador 2 utiliza una aplicación de PC comunicada con la FPGA por UART.

La lógica de las reglas del juego se ejecuta en software dentro del procesador. Los módulos de hardware proporcionan los recursos de entrada y salida necesarios para leer botones, comunicarse por UART, acceder a memoria, actualizar la pantalla VGA y controlar los indicadores locales.

---

# Diagrama de Segundo Nivel

El diagrama de segundo nivel divide el sistema general en sus módulos principales. En este nivel se muestran el microprocesador, las memorias y los periféricos que forman la plataforma computacional, sin entrar todavía en los bloques funcionales internos de cada uno.

```text
                                         ┌──────────────────────────┐
                                         │    PROGRAM ROM           │
                                         │  Memoria de programa     │
                                         └────────────┬─────────────┘
                                                      │ ProgIn[31:0]
                                                      ▼
                                         ┌──────────────────────────┐
                                         │     PROCESADOR           │
                                         │    RISC-V RV32I          │
                                         └────────────┬─────────────┘
                                                      │
                               DataAddress[31:0]      │
                               DataOut[31:0]          │
                               we                     │
                                                      ▼
                                         ┌──────────────────────────┐
                                         │     BUS / DECODER        │
                                         │        MMIO              │
                                         └────────────┬─────────────┘
                                                      │
              ┌──────────────────┬────────────────────┼───────────────────┬────────────────────┐
              │                  │                    │                   │                    │
              ▼                  ▼                    ▼                   ▼                    ▼
    ┌─────────────────┐ ┌─────────────────┐ ┌──────────────────┐ ┌─────────────────┐ ┌──────────────────┐
    │    DATA RAM     │ │ PERIFERICO UART │ │ ENTRADAS JUGADOR │ │ PERIFERICO VGA  │ │ INDICADORES      │
    │ Memoria de datos│ │                 │ │        1         │ │                 │ │ LOCALES          │
    │                 │ │                 │ │ + DEBOUNCING     │ │                 │ │ 7SEG + LED + BUZ │
    └─────────────────┘ └───────┬─────────┘ └────────┬─────────┘ └────────┬────────┘ └─────────┬────────┘
                                │                    │                    │                    │
                                │                    │                    │                    │
                       UART_RX / UART_TX        Botones J1          VGA RGB / SYNC      seg / an / dp
                                │                                         │             led / buzzer
                                ▼                                         ▼
                       ┌─────────────────┐                      ┌─────────────────┐
                       │   PC JUGADOR 2  │                      │   MONITOR VGA   │
                       │ Aplicacion UART │                      │    JUGADOR 1    │
                       └─────────────────┘                      └─────────────────┘

clk_100MHz ─────────────────────► bloques secuenciales del sistema
rst        ─────────────────────► bloques que requieren reinicio
```

La memoria de programa se comunica con el procesador mediante un bus independiente de instrucciones. La RAM y los periféricos comparten el espacio de datos mediante el bus MMIO. El proyecto define esta separación entre el bus de programa y el bus utilizado por RAM y periféricos.

## Procesador RISC-V RV32I

**Objetivo:** ejecutar el programa en ensamblador que implementa la lógica completa de la partida.

**Entradas:** `clk`, `rst`, `ProgIn[31:0]` y `DataIn[31:0]`.

**Salidas:** `ProgAddress[31:0]`, `DataAddress[31:0]`, `DataOut[31:0]` y `we`.

**Explicación general:** el procesador busca instrucciones desde la ROM y ejecuta las operaciones necesarias para controlar el juego. Mediante el bus de datos accede a la RAM y a todos los periféricos mapeados en memoria.

## Memoria de programa - Program ROM

**Objetivo:** almacenar el programa en ensamblador que ejecutará el procesador.

**Entradas:** dirección de programa `ProgAddress[31:0]`.

**Salidas:** instrucción `ProgIn[31:0]`.

**Explicación general:** utiliza un bus dedicado e independiente del bus de datos. La ejecución del programa comienza en la dirección de reset definida dentro del espacio de memoria de programa.

## Memoria de datos - Data RAM

**Objetivo:** almacenar las variables utilizadas por el programa, incluyendo tableros, turnos, estado de barcos, contadores y datos auxiliares.

**Entradas:** dirección, dato de escritura y señal de escritura provenientes del bus de datos.

**Salidas:** dato leído hacia el procesador.

**Explicación general:** se accede utilizando el mismo bus que los periféricos, pero dentro del rango reservado para RAM.

## Bus / Decoder MMIO

**Objetivo:** determinar qué memoria o periférico debe atender cada acceso realizado por el procesador.

**Entradas:** `DataAddress[31:0]`, `DataOut[31:0]` y `we`.

**Salidas:** señales de selección y escritura hacia RAM/periféricos y `DataIn[31:0]` hacia el procesador.

**Explicación general:** decodifica la dirección generada por el CPU y dirige la operación al bloque correspondiente. Esto permite que el software controle los periféricos utilizando instrucciones normales de lectura y escritura.

## Periférico UART

**Objetivo:** permitir la comunicación bidireccional entre la FPGA y la aplicación de PC del Jugador 2.

**Entradas:** datos y señales de control desde el bus MMIO, además de `UART_RX`.

**Salidas:** datos hacia el procesador y `UART_TX` hacia la PC.

**Explicación general:** reutiliza el periférico UART desarrollado en el Proyecto 2 y lo adapta a la interfaz mapeada en memoria del nuevo sistema.

## Entradas del Jugador 1

**Objetivo:** acondicionar y presentar al procesador el estado de los botones utilizados por el Jugador 1.

**Entradas:** botones físicos de navegación, selección, confirmación y reset.

**Salidas:** registro de estado de entradas hacia el bus MMIO.

**Explicación general:** incluye debouncing para evitar que un único accionamiento físico sea interpretado como múltiples pulsaciones.

## Periférico VGA

**Objetivo:** generar una imagen VGA estable que muestre los tableros y la información de HUD del Jugador 1.

**Entradas:** reloj del sistema, reset, dirección de memoria de video, dato de escritura y `write_enable` desde el bus MMIO.

**Salidas:** señales RGB, HSYNC y VSYNC hacia el monitor, además del dato de lectura de memoria de video cuando corresponda.

**Explicación general:** utiliza una memoria de video basada en tiles. El procesador modifica las casillas de la pantalla escribiendo palabras de 32 bits y la lógica VGA lee continuamente dicha memoria para producir la imagen.

## Indicadores locales

**Objetivo:** proporcionar retroalimentación visual y sonora complementaria al Jugador 1.

**Entradas:** datos y señales de escritura provenientes del bus MMIO.

**Salidas:** displays de 7 segmentos, LED de estado y buzzer.

**Explicación general:** los displays muestran los contadores acumulados de victorias, el LED indica la fase de la partida y el buzzer produce sonidos diferentes según los eventos del juego.

## Explicación general del segundo nivel

La Program ROM se conecta al procesador mediante un bus independiente utilizado exclusivamente para instrucciones. Por otra parte, la Data RAM y los periféricos comparten el espacio de datos mediante el bus MMIO. De esta manera, el procesador puede controlar todo el sistema mediante instrucciones `lw` y `sw`, sin requerir conexiones de control especiales para cada periférico.

La separación entre procesador, memorias y periféricos permite desarrollar y verificar cada bloque de forma independiente antes de realizar la integración final.

---

# Diagrama de Tercer Nivel - Periférico VGA

El diagrama de tercer nivel desarrolla internamente el bloque **PERIFÉRICO VGA** mostrado en el diagrama de segundo nivel. En este nivel ya se presentan los bloques funcionales que permitirán generar la señal de video y acceder a la memoria de tiles.

El periférico debe generar video a **640 x 480 píxeles a 60 Hz**. Para evitar un framebuffer completo se utilizará una organización basada en tiles. Como propuesta se emplea una cuadrícula de **20 columnas x 15 filas**, donde cada tile corresponde a un bloque de **32 x 32 píxeles**:

- `20 x 32 = 640` píxeles horizontales.
- `15 x 32 = 480` píxeles verticales.
- `20 x 15 = 300` tiles en total.
- Cada tile se almacena en una palabra de 32 bits.

```text
                                                     clk_100MHz
                                                         │
                                                         ▼
                                               ┌───────────────────┐
                                               │ PLL / GENERADOR   │
                                               │ DE RELOJ VGA      │
                                               └─────────┬─────────┘
                                                         │ pixel_clk
                                                         ▼
                                               ┌───────────────────┐
                                               │ GENERADOR DE      │
                                               │ TIMING VGA        │
                                               │                   │
                                               │ Contador H        │
                                               │ Contador V        │
                                               └─────┬─────┬───────┘
                                                     │     │
                                              pixel_x│     │pixel_y
                                                     └──┬──┘
                                                        │
                                                        ▼
                                               ┌───────────────────┐
                                               │ CONVERSOR         │
                                               │ PIXEL A TILE      │
                                               └─────────┬─────────┘
                                                         │ tile_addr_read
                                                         ▼
CPU / BUS MMIO                                  ┌───────────────────┐
                                               │ VIDEO RAM         │
addr_i ───────────────────────────────────────►│ DUAL-PORT         │
wdata_i[31:0] ────────────────────────────────►│                   │
write_enable_i ───────────────────────────────►│ Puerto CPU 100MHz │
clk_100MHz ───────────────────────────────────►│ Puerto VGA pixel  │
                                               └──────┬─────┬──────┘
                                                      │     │
                                           rdata_o    │     │ tile_data[31:0]
                                             [31:0]   │     ▼
                                                      │  ┌───────────────────┐
                                                      │  │ DECODER / RENDER  │
                                                      │  │ DE TILE           │
                                                      │  └─────────┬─────────┘
                                                      │            │ color[2:0]
                                                      │            ▼
                                                      │  ┌───────────────────┐
                                                      │  │ GENERADOR RGB     │◄──── active_video
                                                      │  └─────────┬─────────┘
                                                      │            │
                                                      │      VGA_R / VGA_G / VGA_B
                                                      │
                                                      └──────────► Bus MMIO

Generador de timing ───────────────────────────────────────────────► VGA_HSYNC
Generador de timing ───────────────────────────────────────────────► VGA_VSYNC
```

## Señales externas principales del periférico VGA

### Entradas

- **clk_i:** reloj principal del sistema de 100 MHz.
- **rst_i:** reinicio del periférico.
- **write_enable_i:** habilita la escritura de una posición de la memoria de video.
- **addr_i:** dirección de la casilla de video que desea acceder el procesador. Debe tener el ancho suficiente para indexar la memoria de tiles.
- **wdata_i[31:0]:** palabra escrita por el procesador en una posición de la memoria de video.

### Salidas

- **rdata_o[31:0]:** dato leído desde la posición seleccionada de la memoria de video.
- **VGA_R / VGA_G / VGA_B:** señales de color entregadas al monitor.
- **VGA_HSYNC:** sincronización horizontal.
- **VGA_VSYNC:** sincronización vertical.

---

## PLL / Generador de reloj VGA

**Objetivo:** generar el reloj de píxel requerido por el periférico VGA a partir del reloj principal de 100 MHz.

**Entradas:** `clk_i` de 100 MHz y señal de reset.

**Salidas:** `pixel_clk`, con una frecuencia cercana a 25 MHz.

**Explicación general:** el resto del sistema trabaja con el reloj principal de 100 MHz, mientras que la generación VGA requiere un dominio de reloj específico para recorrer los píxeles de la pantalla. El PLL crea este segundo dominio de reloj sin modificar el reloj utilizado por el CPU.

---

## Generador de timing VGA

**Objetivo:** generar las coordenadas actuales de píxel y las señales de sincronización requeridas por el monitor.

**Entradas:** `pixel_clk` y `rst_i`.

**Salidas:** `pixel_x`, `pixel_y`, `active_video`, `VGA_HSYNC` y `VGA_VSYNC`.

**Explicación general:** utiliza contadores horizontal y vertical. El contador horizontal avanza con cada ciclo del reloj de píxel y, al finalizar una línea, incrementa el contador vertical. A partir de ambos contadores se generan las señales de sincronización y se determina si el píxel actual pertenece al área visible de 640 x 480.

Como propuesta de temporización para VGA 640 x 480 se consideran los siguientes valores clásicos:

| Parámetro | Horizontal | Vertical |
|---|---:|---:|
| Área visible | 640 | 480 |
| Front porch | 16 | 10 |
| Pulso de sincronización | 96 | 2 |
| Back porch | 48 | 33 |
| Total | 800 | 525 |

---

## Conversor de coordenadas de píxel a tile

**Objetivo:** determinar qué posición de la cuadrícula de tiles corresponde al píxel que el monitor está solicitando en cada instante.

**Entradas:** `pixel_x` y `pixel_y`.

**Salidas:** fila de tile, columna de tile y dirección de lectura `tile_addr_read`.

**Explicación general:** debido a que cada tile posee 32 x 32 píxeles, la columna del tile se obtiene a partir de la coordenada horizontal y la fila a partir de la coordenada vertical. La dirección lineal de memoria se calcula como:

```text
tile_addr = fila * 20 + columna
```

La dirección completa mapeada en memoria se calcula como:

```text
direccion = VGA_BASE + (fila * 20 + columna) * 4
```

---

## Video RAM dual-port

**Objetivo:** almacenar el mapa de tiles utilizado para generar la pantalla y permitir el acceso del procesador y del controlador VGA mediante puertos independientes.

**Entradas del puerto del CPU:** `clk_i`, `addr_i`, `wdata_i[31:0]` y `write_enable_i`.

**Entrada del puerto VGA:** `pixel_clk` y `tile_addr_read`.

**Salidas:** `rdata_o[31:0]` hacia el CPU y `tile_data[31:0]` hacia el renderizado VGA.

**Explicación general:** la memoria utiliza dos puertos. El puerto del procesador trabaja con el reloj del sistema y permite escribir o leer casillas mediante el bus MMIO. El segundo puerto funciona con el reloj de píxel y realiza lecturas continuas para producir la imagen VGA.

La memoria propuesta requiere:

```text
300 tiles x 32 bits = 9600 bits
```

No se requiere una señal de `clear` en hardware. La limpieza de la pantalla se realiza desde software recorriendo la memoria de video y escribiendo el color de fondo en cada posición.

---

## Organización de una palabra de video

Cada casilla de la memoria de video utiliza una palabra de 32 bits.

```text
31                      8 7             3 2       0
┌────────────────────────┬───────────────┬─────────┐
│       Reservado        │ Reservado /   │  Color  │
│                        │ símbolo / HUD │ [2:0]   │
└────────────────────────┴───────────────┴─────────┘
```

- **bits [2:0]:** código de color del tile.
- **bits [7:3]:** espacio disponible para símbolos, caracteres o información adicional del HUD.
- **bits [31:8]:** reservado para futuras extensiones del equipo.

Como mínimo deben existir códigos diferentes para:

- Agua.
- Barco propio.
- Impacto.
- Fallo.

Los valores exactos de codificación pueden definirse durante la implementación mientras se documenten de forma consistente.

---

## Decoder / Render de tile

**Objetivo:** interpretar la palabra almacenada en la Video RAM y determinar el color que debe mostrarse para la casilla actual.

**Entradas:** `tile_data[31:0]`.

**Salidas:** código de color `color[2:0]` y, en caso de utilizarse, información adicional para HUD o símbolos.

**Explicación general:** en su versión mínima, este bloque extrae los bits `[2:0]` de la palabra almacenada y los utiliza para seleccionar el color correspondiente. Los bits restantes pueden utilizarse posteriormente para implementar caracteres, cursores u otros elementos gráficos.

---

## Generador RGB

**Objetivo:** convertir el código de color del tile en las señales físicas RGB que recibe el monitor.

**Entradas:** `color[2:0]` y `active_video`.

**Salidas:** señales `VGA_R`, `VGA_G` y `VGA_B`.

**Explicación general:** mientras `active_video` se encuentra activo, el bloque genera el color correspondiente al tile actual. Fuera del área visible fuerza las salidas RGB al nivel correspondiente al fondo negro para evitar dibujar durante los intervalos de sincronización.

---

## Explicación general del periférico VGA

El reloj principal de 100 MHz entra al bloque de generación de reloj VGA, donde se obtiene el reloj de píxel requerido. El generador de timing utiliza este reloj para recorrer todas las posiciones de la señal de video y producir `pixel_x`, `pixel_y`, `active_video`, `VGA_HSYNC` y `VGA_VSYNC`.

Las coordenadas del píxel se transforman en una fila y columna de tile. Con esa información se calcula la dirección que debe leerse en la Video RAM. La palabra obtenida se envía al bloque de renderizado, el cual extrae el código de color y lo entrega al generador RGB.

Al mismo tiempo, el procesador puede actualizar el contenido de la Video RAM mediante el puerto conectado al bus MMIO. De esta forma, el CPU no necesita escribir cada píxel individualmente: una única escritura modifica el estado de una casilla completa, mientras la lógica VGA continúa leyendo la memoria para mantener una imagen estable.

---

<!--
Los demás diagramas de tercer nivel pueden agregarse debajo de esta sección siguiendo la misma estructura de documentación:

# Diagrama de Tercer Nivel - [Nombre del subsistema]

- Objetivo.
- Entradas.
- Salidas.
- Explicación general.
- Diagrama de bloques con buses y señales relevantes.
-->


# Diagrama de Cuarto Nivel - Periférico VGA

El diagrama de cuarto nivel desarrolla de forma más específica los bloques funcionales presentados en el tercer nivel del periférico VGA. En este nivel se muestran los elementos internos necesarios para implementar la generación del reloj de píxel, los contadores de temporización, la conversión de coordenadas a tiles, el direccionamiento de la memoria de video y la conversión final del contenido de memoria a señales RGB.

La propuesta utiliza dos dominios de reloj:

- **100 MHz:** dominio principal del sistema y puerto de acceso del CPU a la memoria de video.
- **25 MHz:** dominio de píxel utilizado por la lógica de generación VGA.

```text
                                               clk_100MHz
                                                   │
                                                   ▼
                                      ┌────────────────────────┐
                                      │ CLOCKING WIZARD / PLL  │
                                      │     100 MHz -> 25 MHz  │
                                      └───────┬────────┬───────┘
                                              │        │
                                       pixel_clk     locked
                                              │        │
                                              │    ┌───▼──────────────┐
 rst_i ───────────────────────────────────────┼───►│ LOGICA DE RESET   │
                                              │    │ rst_vga = rst_i  │
                                              │    │        OR !locked│
                                              │    └──────┬───────────┘
                                              │           │ rst_vga
                                              ▼           ▼
                             ┌─────────────────────────────────────────┐
                             │        GENERACION DE TIMING VGA        │
                             │                                         │
                             │ ┌────────────────┐  end_line            │
                             │ │ CONTADOR H     │──────────────┐       │
                             │ │ 0 ... 799      │              │       │
                             │ └───────┬────────┘              ▼       │
                             │         │ h_count        ┌─────────────┐ │
                             │         │                │ CONTADOR V  │ │
                             │         │                │ 0 ... 524   │ │
                             │         │                └──────┬──────┘ │
                             │         │                       │ v_count│
                             │         ▼                       ▼        │
                             │ ┌──────────────┐        ┌──────────────┐ │
                             │ │ COMPARADORES │        │ COMPARADORES│ │
                             │ │ HORIZONTAL   │        │ VERTICAL    │ │
                             │ └──────┬───────┘        └──────┬──────┘ │
                             └────────┼───────────────────────┼────────┘
                                      │                       │
                          pixel_x / h_active / HSYNC   pixel_y / v_active / VSYNC
                                      │                       │
                                      └───────────┬───────────┘
                                                  │
                                                  ▼
                                         ┌─────────────────┐
                                         │ active_video    │
                                         │ h_active AND    │
                                         │ v_active        │
                                         └────────┬────────┘
                                                  │
                         pixel_x ─────────────────┼──────────────────┐
                         pixel_y ─────────────────┼──────────────┐   │
                                                  │              │   │
                                                  ▼              ▼   │
                                    ┌────────────────────┐  ┌───────────────┐
                                    │ DIVISION POR 32    │  │ DIVISION POR  │
                                    │ tile_col = x >> 5  │  │ 32            │
                                    └──────────┬─────────┘  │ tile_row=y>>5 │
                                               │            └──────┬────────┘
                                               │                   │
                                               └─────────┬─────────┘
                                                         ▼
                                         ┌─────────────────────────┐
                                         │ CALCULO DE INDICE TILE  │
                                         │ row*20 + col            │
                                         │ (row<<4)+(row<<2)+col   │
                                         └───────────┬─────────────┘
                                                     │ tile_addr[8:0]
                                                     ▼
CPU / BUS MMIO                         ┌───────────────────────────────┐
                                      │ VIDEO RAM 300 x 32 DUAL-PORT │
addr_i[8:0] ─────────────────────────►│ Puerto A: clk_100MHz R/W      │
wdata_i[31:0] ───────────────────────►│                               │
write_enable_i ──────────────────────►│ Puerto B: pixel_clk solo R    │
                                      └──────────────┬────────────────┘
                                                     │ tile_data[31:0]
                                                     ▼
                                      ┌───────────────────────────────┐
                                      │ REGISTRO DE ALINEACION        │
                                      │ dato + active_video + sync    │
                                      └──────────────┬────────────────┘
                                                     │
                                                     ▼
                                      ┌───────────────────────────────┐
                                      │ DECODER / RENDER DE TILE      │
                                      │ tile_data[2:0] -> color       │
                                      │ bits [7:3] -> HUD opcional    │
                                      └──────────────┬────────────────┘
                                                     │ color[2:0]
                                                     ▼
                                      ┌───────────────────────────────┐
                                      │ LUT / MULTIPLEXOR DE COLOR    │
                                      │ agua / barco / impacto / fallo│
                                      └──────────────┬────────────────┘
                                                     │ RGB interno
                                                     ▼
                                      ┌───────────────────────────────┐
                                      │ HABILITACION DE VIDEO         │
                                      │ active_video ? RGB : negro    │
                                      └──────────────┬────────────────┘
                                                     │
                                      VGA_R / VGA_G / VGA_B

                    HSYNC alineado ───────────────────────────────► VGA_HSYNC
                    VSYNC alineado ───────────────────────────────► VGA_VSYNC
```

## Generación del reloj de píxel

**Objetivo:** obtener el reloj utilizado por el subsistema VGA a partir del reloj de entrada de 100 MHz.

**Entradas:** `clk_100MHz` y `rst_i`.

**Salidas:** `pixel_clk` y `locked`.

**Explicación general:** se utiliza el recurso de generación de reloj de la FPGA, configurado para producir aproximadamente 25 MHz. La señal `locked` indica que el bloque de reloj alcanzó una condición estable. Para evitar que los contadores VGA comiencen a operar antes de que el reloj sea válido, el reinicio interno del periférico puede mantenerse activo mientras `locked = 0`.

```text
clk_100MHz ─────► CLOCKING WIZARD / PLL ─────► pixel_clk ≈ 25 MHz
                           │
                           └──────────────────► locked

rst_i ──────────────┐
                    ├── OR ──────────────────► rst_vga
NOT locked ─────────┘
```

---

## Contador horizontal y generación de HSYNC

**Objetivo:** recorrer todas las posiciones horizontales de una línea VGA y generar la señal de sincronización horizontal.

**Entradas:** `pixel_clk` y `rst_vga`.

**Salidas:** `h_count`, `pixel_x`, `h_active`, `end_line` y `VGA_HSYNC`.

**Explicación general:** el contador horizontal avanza una posición por cada ciclo de `pixel_clk`. En la temporización propuesta cuenta desde `0` hasta `799`. Los primeros 640 valores corresponden al área visible. Cuando alcanza el último valor, vuelve a cero y produce `end_line`, señal utilizada para incrementar el contador vertical.

```text
pixel_clk ─────────────────────────────────────────────────────┐
                                                              ▼
                                                    ┌────────────────┐
rst_vga ──────────────────────────────────────────►│ CONTADOR H     │
                                                    │ 10 bits        │
                                                    │ 0 ... 799      │
                                                    └───────┬────────┘
                                                            │ h_count[9:0]
                         ┌────────────────────┬───────────────┼──────────────────────┐
                         ▼                    ▼               ▼                      ▼
                ┌────────────────┐   ┌────────────────┐ ┌──────────────┐   ┌────────────────┐
                │ h_count < 640  │   │ 656 <= count  │ │ count == 799 │   │ pixel_x       │
                │ COMPARADOR     │   │ <= 751        │ │ COMPARADOR   │   │ = h_count     │
                └──────┬─────────┘   │ COMPARADORES  │ └──────┬───────┘   └──────┬─────────┘
                       │             └───────┬────────┘        │                  │
                   h_active                  │             end_line            pixel_x
                                            ▼
                                      ┌──────────────┐
                                      │ INVERSOR /   │
                                      │ LOGICA HSYNC │
                                      └──────┬───────┘
                                             │
                                          HSYNC
```

Con la propuesta de temporización utilizada en el nivel anterior:

- Área visible horizontal: `0 ... 639`.
- Front porch: `640 ... 655`.
- Pulso HSYNC: `656 ... 751`.
- Back porch: `752 ... 799`.

El pulso de sincronización se considera activo en bajo.

---

## Contador vertical y generación de VSYNC

**Objetivo:** recorrer las líneas que forman un frame VGA y generar la señal de sincronización vertical.

**Entradas:** `pixel_clk`, `rst_vga` y `end_line`.

**Salidas:** `v_count`, `pixel_y`, `v_active` y `VGA_VSYNC`.

**Explicación general:** el contador vertical solo se incrementa cuando el contador horizontal finaliza una línea. Para la temporización propuesta cuenta desde `0` hasta `524`, de los cuales los primeros 480 corresponden al área visible.

```text
end_line ───────────────────────────────────────────────┐
                                                       ▼
                                             ┌────────────────┐
rst_vga ────────────────────────────────────►│ CONTADOR V     │
                                             │ 10 bits        │
                                             │ 0 ... 524      │
                                             └───────┬────────┘
                                                     │ v_count[9:0]
                    ┌────────────────────┬────────────┼────────────────────┐
                    ▼                    ▼            ▼                    ▼
           ┌────────────────┐   ┌────────────────┐ ┌──────────────┐ ┌────────────────┐
           │ v_count < 480  │   │490 <= count   │ │count == 524 │ │ pixel_y       │
           │ COMPARADOR     │   │<= 491         │ │ COMPARADOR  │ │ = v_count     │
           └──────┬─────────┘   │COMPARADORES   │ └──────┬───────┘ └──────┬─────────┘
                  │             └───────┬────────┘        │                │
              v_active                  │              fin_frame        pixel_y
                                        ▼
                                  ┌──────────────┐
                                  │ INVERSOR /   │
                                  │ LOGICA VSYNC │
                                  └──────┬───────┘
                                         │
                                      VSYNC
```

Con la propuesta de temporización utilizada:

- Área visible vertical: `0 ... 479`.
- Front porch: `480 ... 489`.
- Pulso VSYNC: `490 ... 491`.
- Back porch: `492 ... 524`.

---

## Generación de `active_video`

**Objetivo:** indicar si las coordenadas actuales corresponden a la zona visible de la pantalla.

**Entradas:** `h_active` y `v_active`.

**Salida:** `active_video`.

**Explicación general:** la salida únicamente se activa cuando tanto la coordenada horizontal como la vertical pertenecen al área visible.

```text
h_active ──────┐
               ├──── AND ─────► active_video
v_active ──────┘
```

---

## Conversión de píxel a tile

**Objetivo:** transformar las coordenadas VGA en la fila y columna de la cuadrícula de 20 x 15 tiles.

**Entradas:** `pixel_x` y `pixel_y`.

**Salidas:** `tile_col[4:0]`, `tile_row[3:0]` y `tile_addr[8:0]`.

**Explicación general:** como cada tile mide 32 píxeles, dividir una coordenada entre 32 equivale a desplazarla cinco posiciones hacia la derecha. Esto permite evitar divisores de hardware.

```text
pixel_x[9:0] ─────► >> 5 ─────► tile_col[4:0]

pixel_y[9:0] ─────► >> 5 ─────► tile_row[3:0]
```

La dirección lineal se obtiene mediante:

```text
tile_addr = tile_row * 20 + tile_col
```

Para evitar un multiplicador general, el producto por 20 puede expresarse como:

```text
20 = 16 + 4

tile_row * 20 = (tile_row << 4) + (tile_row << 2)
```

Por lo tanto, la lógica puede implementarse como:

```text
                     tile_row
                       │
             ┌─────────┴─────────┐
             ▼                   ▼
           << 4                << 2
             │                   │
             └─────────┬─────────┘
                       ▼
                    SUMADOR
                       │ row*20
                       ▼
                    SUMADOR ◄──────── tile_col
                       │
                       ▼
                 tile_addr[8:0]
```

---

## Video RAM dual-port

**Objetivo:** almacenar 300 palabras de 32 bits y permitir que el CPU modifique la pantalla al mismo tiempo que el controlador VGA la lee.

**Entradas del puerto A:** `clk_100MHz`, `addr_i[8:0]`, `wdata_i[31:0]` y `write_enable_i`.

**Entradas del puerto B:** `pixel_clk` y `tile_addr[8:0]`.

**Salidas:** `rdata_o[31:0]` y `tile_data[31:0]`.

**Explicación general:** el puerto A pertenece al dominio del CPU y permite lectura/escritura. El puerto B pertenece al dominio de píxel y se utiliza únicamente para lectura continua. La memoria contiene 300 posiciones, suficientes para la cuadrícula de 20 x 15 tiles.

```text
                     PUERTO A - CPU 100 MHz

addr_i[8:0] ────────────────┐
wdata_i[31:0] ──────────────┼────►┌────────────────────────────┐
write_enable_i ─────────────┤     │                            │────► rdata_o[31:0]
clk_100MHz ─────────────────┘     │     VIDEO RAM 300 x 32     │
                                  │                            │
pixel_clk ───────────────────────►│                            │
tile_addr[8:0] ──────────────────►│                            │────► tile_data[31:0]
                                  └────────────────────────────┘

                     PUERTO B - VGA 25 MHz
```

Debido a que una memoria de bloques puede entregar el dato de lectura de forma síncrona, se considera un registro de alineación para mantener coordinados `tile_data`, `active_video`, `HSYNC` y `VSYNC` durante la etapa de renderizado.

---

## Registro de alineación

**Objetivo:** compensar la latencia introducida por la lectura síncrona de la Video RAM.

**Entradas:** `tile_data`, `active_video`, `VGA_HSYNC` y `VGA_VSYNC`.

**Salidas:** versiones alineadas de las señales anteriores.

**Explicación general:** si la Video RAM tarda un ciclo de `pixel_clk` en entregar el dato solicitado, las señales que describen el píxel actual deben retrasarse el mismo número de ciclos. De esta manera, el color obtenido de memoria corresponde a la misma posición de video que las señales de sincronización.

```text
tile_data ─────────────► REGISTRO ─────────────► tile_data_d
active_video ──────────► REGISTRO ─────────────► active_video_d
HSYNC ─────────────────► REGISTRO ─────────────► HSYNC_d
VSYNC ─────────────────► REGISTRO ─────────────► VSYNC_d

                         pixel_clk
```

---

## Decoder de tile y LUT de color

**Objetivo:** interpretar la palabra de 32 bits almacenada en memoria y generar el color correspondiente al tile actual.

**Entradas:** `tile_data_d[31:0]`.

**Salidas:** `color[2:0]` y señal RGB interna.

**Explicación general:** los bits `[2:0]` contienen el código mínimo de color de la casilla. Un multiplexor o bloque combinacional tipo `case` convierte este código en los niveles de rojo, verde y azul que se enviarán al monitor. Los bits `[7:3]` quedan disponibles para ampliar posteriormente el renderizado del HUD o incorporar símbolos.

```text
                         tile_data_d[31:0]
                                │
                                ▼
                         ┌───────────────┐
                         │ SELECCION     │
                         │ bits [2:0]    │
                         └──────┬────────┘
                                │ color[2:0]
                                ▼
              ┌─────────────────────────────────┐
              │ LUT / MUX DE COLOR             │
              │                                 │
              │ agua         -> RGB_agua       │
              │ barco propio -> RGB_barco      │
              │ impacto      -> RGB_impacto    │
              │ fallo        -> RGB_fallo      │
              │ HUD/reserva  -> RGB_adicional  │
              └────────────────┬────────────────┘
                               │
                               ▼
                         rgb_tile
```

---

## Habilitación de salida RGB

**Objetivo:** evitar que se generen colores durante los intervalos no visibles de la señal VGA.

**Entradas:** `rgb_tile` y `active_video_d`.

**Salidas:** `VGA_R`, `VGA_G` y `VGA_B`.

**Explicación general:** cuando `active_video_d = 1`, las salidas toman el color obtenido del tile. Fuera de la zona visible, las salidas RGB se fuerzan a negro.

```text
                         ┌─────────────────────┐
rgb_tile ───────────────►│                     │
                         │   MULTIPLEXOR RGB   │────► VGA_R
NEGRO ──────────────────►│                     │────► VGA_G
                         │                     │────► VGA_B
active_video_d ─────────►│       select        │
                         └─────────────────────┘
```

---

## Explicación general del cuarto nivel

El subsistema comienza generando el reloj de píxel a partir de los 100 MHz de la FPGA. Una vez que el bloque de reloj se encuentra estable, los contadores horizontal y vertical recorren la temporización completa del estándar VGA propuesto. Los comparadores asociados a estos contadores determinan las regiones visibles, generan `HSYNC` y `VSYNC` y producen las coordenadas `pixel_x` y `pixel_y`.

Las coordenadas visibles se dividen entre 32 mediante desplazamientos lógicos para obtener la fila y la columna del tile. Posteriormente se calcula un índice lineal entre 0 y 299 mediante sumadores y desplazamientos. Este índice alimenta el puerto de lectura de la Video RAM.

En paralelo, el procesador puede utilizar el puerto de 100 MHz para modificar cualquier palabra de la memoria de video. Así, una sola escritura del CPU actualiza una casilla completa de la cuadrícula sin detener la generación de video.

El dato leído desde la memoria se alinea temporalmente con las señales de sincronización, se decodifica para obtener el color y finalmente pasa por una etapa de habilitación que fuerza negro durante los intervalos no visibles. El resultado son las señales RGB, HSYNC y VSYNC que se entregan al monitor.

---
# Diagrama de Tercer Nivel - Unidad de Control RISC-V RV32I

El diagrama de tercer nivel desarrolla internamente el bloque correspondiente a la **unidad de control del procesador RISC-V RV32I**. Este bloque interpreta cada instrucción recibida desde la memoria de programa y genera las señales necesarias para controlar el datapath, la ALU, el acceso a memoria y la actualización del Program Counter.

La unidad de control utiliza principalmente los campos `opcode`, `funct3` y `funct7` de la instrucción. A partir de estos campos identifica el tipo de instrucción y determina las señales de control que deben aplicarse al datapath.

```text
                              instruction[31:0]
                                     │
                    ┌────────────────┼─────────────────┐
                    │                │                 │
                    ▼                ▼                 ▼
               opcode[6:0]      funct3[2:0]       funct7[6:0]
                    │                │                 │
                    │                └────────┬────────┘
                    │                         │
                    ▼                         ▼
          ┌────────────────────┐    ┌────────────────────┐
          │ DECODIFICADOR      │    │ DECODIFICADOR      │
          │ PRINCIPAL          │    │ DE ALU             │
          │ DE INSTRUCCIONES   │    │ funct3 / funct7    │
          └─────────┬──────────┘    └─────────┬──────────┘
                    │                         │
                    │                         └──────────────► ALUControl
                    │
                    ├────────► RegWrite
                    │
                    ├────────► ALUSrc
                    │
                    ├────────► ImmSrc
                    │
                    ├────────► ResultSrc
                    │
                    ├────────► MemWrite
                    │
                    ▼
          ┌──────────────────────────┐
          │ CONTROL DE FLUJO         │
          │ BRANCH / JUMP            │
          └───────────┬──────────────┘
                      │
                      ├────────► Branch
                      ├────────► BranchType
                      ├────────► Jump
                      └────────► Jalr

                              │
                              ▼
                    DATAPATH - ISSUE #2
```

## Entradas principales

- **instruction[31:0]:** instrucción completa recibida desde la memoria de programa.
- **opcode[6:0]:** identifica la familia principal de instrucción.
- **funct3[2:0]:** diferencia operaciones dentro de una misma familia.
- **funct7[6:0]:** permite distinguir algunas operaciones aritméticas y de desplazamiento.

## Salidas principales

- **RegWrite:** habilita la escritura en el Register File.
- **ALUSrc:** selecciona si el segundo operando de la ALU proviene del Register File o del generador de inmediatos.
- **ImmSrc:** selecciona el formato de inmediato requerido por la instrucción.
- **ResultSrc:** selecciona el dato que será escrito nuevamente en el Register File.
- **MemWrite:** habilita la escritura hacia memoria o periféricos MMIO.
- **ALUControl:** selecciona la operación que debe realizar la ALU.
- **Branch:** indica que la instrucción corresponde a un salto condicional.
- **BranchType:** identifica el tipo de comparación utilizada por una instrucción de branch.
- **Jump:** indica que la instrucción corresponde a un salto incondicional.
- **Jalr:** identifica específicamente una instrucción `jalr`.

## Decodificador principal de instrucciones

**Objetivo:** identificar la familia general de la instrucción a partir del campo `opcode[6:0]` y generar las señales principales requeridas por el datapath.

**Entrada:** `opcode[6:0]`.

**Salidas:** `RegWrite`, `ALUSrc`, `ImmSrc`, `ResultSrc`, `MemWrite` y señales auxiliares utilizadas por los bloques de control de ALU y de flujo.

**Explicación general:** el campo `opcode` permite diferenciar entre instrucciones aritméticas tipo R, instrucciones inmediatas, accesos a memoria, branches y jumps. Cada familia requiere una combinación diferente de señales de control.

Las familias principales consideradas son:

```text
R-type
I-type aritmético
LOAD
STORE
BRANCH
JAL
JALR
```

## Decodificador de ALU

**Objetivo:** determinar la operación específica que debe realizar la ALU.

**Entradas:** `funct3[2:0]`, `funct7[6:0]` e información proveniente del decodificador principal.

**Salida:** `ALUControl`.

**Explicación general:** las instrucciones de una misma familia pueden utilizar el mismo `opcode`, por lo que es necesario emplear los campos `funct3` y `funct7` para diferenciar operaciones individuales.

Entre las operaciones requeridas se incluyen:

```text
ADD
SUB
AND
OR
XOR
SLL
SRL
SRA
SLT
SLTU
```

Para instrucciones como `lw` y `sw`, la ALU se utiliza para sumar la dirección base con el desplazamiento inmediato y generar la dirección efectiva de memoria.

## Control de branches

**Objetivo:** identificar el tipo de salto condicional y proporcionar al datapath la información necesaria para determinar si debe modificarse el Program Counter.

**Entradas:** `opcode[6:0]` y `funct3[2:0]`.

**Salidas:** `Branch` y `BranchType`.

**Explicación general:** cuando el `opcode` corresponde a una instrucción de branch, el campo `funct3` permite determinar el tipo de comparación que debe realizarse.

El procesador debe soportar como mínimo:

```text
beq
bne
blt
bge
```

La evaluación final de la condición se realiza junto con el datapath utilizando los resultados de comparación correspondientes.

## Control de jumps

**Objetivo:** identificar instrucciones de salto incondicional y seleccionar el mecanismo utilizado para calcular la siguiente dirección del Program Counter.

**Entradas:** `opcode[6:0]`.

**Salidas:** `Jump` y `Jalr`.

**Explicación general:** las instrucciones `jal` y `jalr` modifican el flujo normal de ejecución y almacenan `PC + 4` en el registro destino.

Para `jal`, la nueva dirección se obtiene a partir del Program Counter y un inmediato tipo J.

Para `jalr`, la dirección de destino se calcula utilizando un registro fuente más un inmediato tipo I.

## Selección del inmediato

**Objetivo:** indicar al generador de inmediatos del datapath qué formato debe producir.

**Entrada:** tipo de instrucción identificado por el decodificador principal.

**Salida:** `ImmSrc`.

Se propone la siguiente codificación:

```text
ImmSrc = 00 -> inmediato tipo I
ImmSrc = 01 -> inmediato tipo S
ImmSrc = 10 -> inmediato tipo B
ImmSrc = 11 -> inmediato tipo J
```

Esta señal se conecta directamente al generador de inmediatos implementado dentro del datapath.

## Selección del resultado hacia el Register File

**Objetivo:** seleccionar cuál resultado debe escribirse en el registro destino.

**Salida:** `ResultSrc`.

El Register File puede recibir datos desde tres fuentes principales:

```text
Resultado de ALU
Dato leído desde memoria
PC + 4
```

Esto permite soportar instrucciones aritméticas, `lw`, `jal` y `jalr`.

## Explicación general del tercer nivel

La instrucción recibida desde la memoria de programa se divide en sus campos principales de control. El campo `opcode` se utiliza para identificar la familia de instrucción, mientras que `funct3` y `funct7` permiten distinguir operaciones específicas.

El decodificador principal genera las señales generales del datapath. El decodificador de ALU determina la operación aritmética o lógica requerida, mientras que el bloque de control de flujo identifica branches y jumps.

Las señales generadas por la unidad de control se conectan al datapath desarrollado en el Issue #2, permitiendo controlar el Register File, la ALU, el generador de inmediatos, los multiplexores internos, el acceso a memoria y la selección de la siguiente dirección del Program Counter.

---

# Diagrama de Cuarto Nivel - Unidad de Control RISC-V RV32I

El diagrama de cuarto nivel desarrolla con mayor detalle los mecanismos utilizados para decodificar cada instrucción RV32I y generar las señales de control que gobiernan el datapath.

En este nivel se muestran las rutas de decodificación de `opcode`, `funct3` y `funct7`, así como la generación de señales para operaciones aritméticas, accesos a memoria, branches y jumps.

```text
                                instruction[31:0]
                                       │
                    ┌──────────────────┼───────────────────┐
                    │                  │                   │
                    ▼                  ▼                   ▼
                opcode[6:0]       funct3[2:0]        funct7[6:0]
                    │                  │                   │
                    ▼                  │                   │
          ┌────────────────────┐       │                   │
          │ DECODER OPCODE     │       │                   │
          └─────────┬──────────┘       │                   │
                    │                  │                   │
          ┌─────────┼──────────────────┼──────────────────────────────┐
          │         │                  │                              │
          ▼         ▼                  ▼                              ▼
       R-TYPE     I-TYPE             LOAD                           STORE
          │         │                  │                              │
          │         │                  │                              │
          └─────────┴──────────┬───────┴──────────────┬───────────────┘
                              │                      │
                              ▼                      ▼
                        CONTROL BASE              ImmSrc
                              │
              ┌───────────────┼────────────────┐
              │               │                │
              ▼               ▼                ▼
           RegWrite        ALUSrc          MemWrite
              │
              ▼
       ┌───────────────────────────┐
       │ DECODER OPERACIÓN ALU     │
       │ funct3 + funct7 + tipo    │
       └─────────────┬─────────────┘
                     │
                     ▼
                 ALUControl
```

El control de branches se implementa de forma paralela:

```text
                        opcode + funct3
                              │
                              ▼
                    ┌────────────────────┐
                    │ DECODER BRANCH     │
                    └─────────┬──────────┘
                              │
             ┌────────────────┼─────────────────┐
             │                │                 │
             ▼                ▼                 ▼
            BEQ              BNE             BLT / BGE
             │                │                 │
             └────────────────┼─────────────────┘
                              ▼
                         BranchType
```

El control de jumps utiliza el `opcode` para diferenciar `jal` y `jalr`:

```text
                          opcode[6:0]
                              │
                  ┌───────────┴───────────┐
                  │                       │
                  ▼                       ▼
                JAL                     JALR
                  │                       │
                  ▼                       ▼
               Jump = 1          Jump = 1 / Jalr = 1
```

## Decodificación principal por opcode

La primera etapa consiste en identificar el tipo general de instrucción.

```text
opcode
  │
  ├── R-type
  ├── I-type aritmético
  ├── LOAD
  ├── STORE
  ├── BRANCH
  ├── JAL
  └── JALR
```

Cada categoría genera una combinación específica de señales de control.

## Tabla general de señales de control

| Familia de instrucción | RegWrite | ALUSrc | MemWrite | ResultSrc | ImmSrc | Branch | Jump |
|---|---:|---:|---:|---|---|---:|---:|
| R-type | 1 | 0 | 0 | ALU | - | 0 | 0 |
| I-type aritmético | 1 | 1 | 0 | ALU | I | 0 | 0 |
| `lw` | 1 | 1 | 0 | MEM | I | 0 | 0 |
| `sw` | 0 | 1 | 1 | - | S | 0 | 0 |
| Branch | 0 | 0 | 0 | - | B | 1 | 0 |
| `jal` | 1 | 0 | 0 | PC+4 | J | 0 | 1 |
| `jalr` | 1 | 1 | 0 | PC+4 | I | 0 | 1 |

Los valores exactos utilizados por `ResultSrc`, `ImmSrc`, `ALUControl` y `BranchType` deben mantenerse consistentes con el diseño final del datapath.

## Decodificación de operaciones aritméticas y lógicas

Para instrucciones tipo R, `funct3` y `funct7` determinan la operación específica.

```text
opcode R-type
      │
      ▼
 funct3 / funct7
      │
      ├── ADD
      ├── SUB
      ├── AND
      ├── OR
      ├── XOR
      ├── SLL
      ├── SRL
      ├── SRA
      ├── SLT
      └── SLTU
```

Para instrucciones inmediatas, el mismo campo `funct3` permite seleccionar operaciones equivalentes utilizando un inmediato como segundo operando.

## Decodificación de accesos a memoria

Las instrucciones `lw` y `sw` utilizan la ALU para calcular la dirección efectiva.

```text
          rs1
           │
           ▼
      ┌─────────┐
      │         │
imm ─►│   ALU   │────► DataAddress
      │  ADD    │
      └─────────┘
```

Para `lw`:

```text
RegWrite  = 1
ALUSrc    = 1
MemWrite  = 0
ResultSrc = MEM
ImmSrc    = I
```

Para `sw`:

```text
RegWrite = 0
ALUSrc   = 1
MemWrite = 1
ImmSrc   = S
```

## Decodificación de branches

Las instrucciones de branch utilizan `funct3` para seleccionar el tipo de comparación.

```text
funct3
  │
  ├── beq
  ├── bne
  ├── blt
  └── bge
```

La unidad de control identifica el tipo de comparación mediante `BranchType`, mientras que el datapath produce el resultado de dicha comparación.

Si la condición resulta verdadera, el Program Counter selecciona:

```text
PC + inmediato tipo B
```

Si la condición resulta falsa, continúa con:

```text
PC + 4
```

## Decodificación de `jal`

Para una instrucción `jal`:

```text
Jump      = 1
Jalr      = 0
RegWrite  = 1
ResultSrc = PC + 4
ImmSrc    = J
```

La nueva dirección se obtiene mediante:

```text
PC_nuevo = PC + inmediato_J
```

Simultáneamente se almacena:

```text
rd = PC + 4
```

## Decodificación de `jalr`

Para una instrucción `jalr`:

```text
Jump      = 1
Jalr      = 1
RegWrite  = 1
ALUSrc    = 1
ResultSrc = PC + 4
ImmSrc    = I
```

La dirección de salto se calcula mediante:

```text
PC_nuevo = rs1 + inmediato_I
```

mientras que `PC + 4` se almacena en el registro destino.

## Comportamiento ante instrucciones no soportadas

**Objetivo:** evitar modificaciones no deseadas cuando el procesador recibe una instrucción inválida o no implementada.

Para una instrucción no reconocida, las señales de control deben colocarse en un estado seguro.

```text
RegWrite = 0
MemWrite = 0
Branch   = 0
Jump     = 0
Jalr     = 0
```

De esta manera, una instrucción no soportada no modifica el Register File, la memoria ni el flujo de ejecución mediante un salto no intencionado.

## Interfaz entre la unidad de control y el datapath

La unidad de control entrega las siguientes señales principales:

```text
RegWrite
ALUSrc
ALUControl
ImmSrc
ResultSrc
MemWrite
Branch
BranchType
Jump
Jalr
```

El datapath utiliza estas señales para controlar:

```text
Register File
Generador de inmediatos
ALU
Multiplexores de operandos
Interfaz de memoria
Multiplexor de write-back
Lógica de actualización del PC
```

## Explicación general del cuarto nivel

La instrucción se divide en los campos `opcode`, `funct3` y `funct7`. El `opcode` identifica inicialmente la familia de instrucción y activa las señales generales necesarias para su ejecución.

Para instrucciones aritméticas y lógicas, los campos `funct3` y `funct7` permiten seleccionar la operación correspondiente de la ALU. Para instrucciones de acceso a memoria, la unidad de control selecciona el inmediato adecuado y configura la ALU para calcular la dirección efectiva.

En las instrucciones de branch, el campo `funct3` determina el tipo de comparación que debe realizarse. Las instrucciones `jal` y `jalr` activan la lógica de salto y seleccionan `PC + 4` como valor de retorno hacia el Register File.

Las señales resultantes se transmiten al datapath, donde controlan los multiplexores, el Register File, la ALU, la interfaz de memoria y la lógica del Program Counter.

La división entre decodificador principal, decodificador de ALU y control de flujo permite mantener el diseño modular, facilitando su implementación en SystemVerilog y su posterior verificación mediante testbenches autoverificables.

# Diagrama de Tercer Nivel - Indicadores Locales: Displays, LED y Buzzer

El diagrama de tercer nivel desarrolla internamente el bloque **INDICADORES LOCALES** mostrado en el diagrama de segundo nivel. Este subsistema reúne los periféricos de salida local utilizados para proporcionar retroalimentación visual y sonora al Jugador 1.

Los tres periféricos se controlan desde el microprocesador RISC-V mediante registros mapeados en memoria. El procesador realiza escrituras utilizando la interfaz MMIO de 32 bits y cada periférico actualiza su salida física de acuerdo con el dato recibido.

Las direcciones definidas para estos periféricos son:

```text
Displays de 7 segmentos : 0x0001_0130
LED de estado           : 0x0001_0138
Buzzer                  : 0x0001_0140
```

```text
                                   CPU / BUS MMIO
                                         │
                         DataAddress[31:0] │
                         DataOut[31:0]     │
                         we                │
                                         ▼
                             ┌──────────────────────┐
                             │ DECODER DE DIRECCIÓN│
                             │ INDICADORES LOCALES │
                             └──────────┬───────────┘
                                        │
                  ┌─────────────────────┼─────────────────────┐
                  │                     │                     │
                  ▼                     ▼                     ▼
       ┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐
       │ PERIFÉRICO DISPLAY │  │ PERIFÉRICO LED     │  │ PERIFÉRICO BUZZER  │
       │ 7 SEGMENTOS        │  │ DE ESTADO          │  │                    │
       │ 0x0001_0130        │  │ 0x0001_0138        │  │ 0x0001_0140        │
       └─────────┬──────────┘  └─────────┬──────────┘  └─────────┬──────────┘
                 │                       │                       │
                 ▼                       ▼                       ▼
            seg[6:0]                led_estado                buzzer
            an[3:0]
            dp
```

## Entradas principales

- **clk_i:** reloj principal del sistema.
- **rst_i:** señal de reinicio.
- **write_enable_i:** indica una operación de escritura hacia el periférico seleccionado.
- **addr_i / DataAddress:** dirección utilizada para determinar qué periférico debe ser actualizado.
- **wdata_i[31:0]:** dato escrito por el procesador.
- **rdata_o[31:0]:** dato leído desde el periférico cuando corresponda.

## Salidas principales

- **seg[6:0]:** controla los siete segmentos del display.
- **an[3:0]:** selecciona cuál de los cuatro dígitos se encuentra activo.
- **dp:** controla el punto decimal.
- **led_estado:** indica visualmente la fase general de la partida.
- **buzzer:** produce la señal sonora correspondiente al evento seleccionado.

---

## Decoder de dirección MMIO

**Objetivo:** determinar cuál de los tres periféricos locales debe responder a una operación del procesador.

**Entradas:** `DataAddress[31:0]` y `we`.

**Salidas:** señales de selección o escritura independientes para display, LED y buzzer.

**Explicación general:** el procesador accede a cada periférico mediante una dirección fija dentro del espacio MMIO. El decoder compara la dirección presente en el bus con las direcciones reservadas para los indicadores locales.

```text
DataAddress
     │
     ▼
┌──────────────────────────────┐
│ COMPARACIÓN DE DIRECCIONES   │
└──────────────┬───────────────┘
               │
      ┌────────┼─────────┐
      │        │         │
      ▼        ▼         ▼
  0x0130    0x0138    0x0140
  DISPLAY     LED      BUZZER
```

Una escritura solo debe modificar el periférico cuya dirección coincida con la operación realizada por el CPU.

---

## Periférico de displays de 7 segmentos

**Objetivo:** mostrar simultáneamente el contador acumulado de victorias del Jugador 1 y del Jugador 2.

**Entradas:** `clk_i`, `rst_i`, `write_enable_i` y `wdata_i[31:0]`.

**Salidas:** `seg[6:0]`, `an[3:0]` y `dp`.

**Explicación general:** el periférico utiliza al menos cuatro dígitos. Se asignan dos dígitos al contador de victorias del Jugador 1 y dos dígitos al contador del Jugador 2.

Cada contador debe representar valores entre `00` y `99`.

La distribución propuesta es:

```text
Dígito 3     Dígito 2     Dígito 1     Dígito 0
   │            │            │            │
   ▼            ▼            ▼            ▼
J1 decenas   J1 unidades  J2 decenas   J2 unidades
```

El dato escrito por el procesador se almacena en un registro interno y posteriormente se convierte a dígitos decimales. Un circuito de multiplexado activa los cuatro dígitos de forma alternada a una frecuencia suficientemente alta para que el usuario los observe encendidos simultáneamente.

---

## Periférico LED de estado

**Objetivo:** indicar visualmente la fase general en la que se encuentra el sistema.

**Entradas:** `clk_i`, `rst_i`, `write_enable_i` y `wdata_i[31:0]`.

**Salida:** `led_estado`.

**Explicación general:** el procesador escribe un código de estado en el registro del periférico. Dicho código representa la fase actual de la partida.

Como propuesta se utilizan los siguientes estados:

```text
00 -> fase de colocación
01 -> fase de batalla
10 -> resultado final
11 -> reservado
```

El valor almacenado se decodifica para generar una salida visual claramente distinguible.

Si durante la implementación se dispone de más de un LED físico, el código puede representarse mediante varios LEDs. Si se utiliza únicamente una salida `led_estado`, los estados pueden diferenciarse mediante encendido, apagado o patrones de parpadeo documentados por el equipo.

---

## Periférico buzzer

**Objetivo:** generar retroalimentación sonora distinta para los principales eventos de la partida.

**Entradas:** `clk_i`, `rst_i`, `write_enable_i` y `wdata_i[31:0]`.

**Salida:** `buzzer`.

**Explicación general:** el procesador escribe un código de evento en el registro de control del buzzer. El periférico interpreta dicho código y selecciona el patrón sonoro correspondiente.

Se deben distinguir al menos los siguientes eventos:

```text
Disparo con impacto
Disparo con fallo
Barco hundido
Colocación inválida
Victoria / fin de partida
```

Como propuesta de codificación:

```text
000 -> silencio
001 -> impacto
010 -> fallo
011 -> barco hundido
100 -> colocación inválida
101 -> victoria
110 -> reservado
111 -> reservado
```

El periférico debe convertir el código recibido en una señal periódica apropiada para el buzzer. Los diferentes eventos pueden distinguirse mediante frecuencia, duración o secuencias de tonos.

---

## Explicación general del tercer nivel

El procesador controla los indicadores locales mediante operaciones normales de escritura en memoria. El decoder MMIO identifica cuál periférico corresponde a la dirección utilizada y genera una señal de escritura específica.

El periférico de displays almacena los contadores de victorias y genera las señales necesarias para representar ambos valores entre `00` y `99`. El periférico LED almacena el estado general del juego y produce una indicación visual correspondiente. El periférico buzzer almacena el código de evento y genera una señal sonora distinta para cada situación relevante.

La separación en tres bloques permite implementar, simular y verificar cada periférico de manera independiente antes de integrarlos con el bus MMIO y el procesador.

---

# Diagrama de Cuarto Nivel - Indicadores Locales: Displays, LED y Buzzer

El diagrama de cuarto nivel desarrolla con mayor detalle los bloques internos utilizados para implementar los tres periféricos de indicadores locales.

En este nivel se muestran los registros MMIO, la conversión de los contadores a dígitos decimales, el multiplexado de los displays, la lógica del LED de estado y los bloques requeridos para generar las señales del buzzer.

```text
                                     CPU / BUS MMIO
                                           │
                         ┌─────────────────┼─────────────────┐
                         │                 │                 │
                         ▼                 ▼                 ▼
                 addr_i / address      wdata_i[31:0]    write_enable_i
                         │                 │                 │
                         └─────────────────┼─────────────────┘
                                           ▼
                                ┌──────────────────────┐
                                │ DECODER DE DIRECCIÓN│
                                └──────────┬───────────┘
                                           │
                   ┌───────────────────────┼────────────────────────┐
                   │                       │                        │
                   ▼                       ▼                        ▼
          ┌─────────────────┐     ┌─────────────────┐      ┌─────────────────┐
          │ REGISTRO DISPLAY│     │ REGISTRO LED    │      │ REGISTRO BUZZER │
          │ 0x0001_0130     │     │ 0x0001_0138     │      │ 0x0001_0140     │
          └────────┬────────┘     └────────┬────────┘      └────────┬────────┘
                   │                       │                        │
                   ▼                       ▼                        ▼
          ┌─────────────────┐     ┌─────────────────┐      ┌─────────────────┐
          │ CONVERSIÓN      │     │ DECODER DE      │      │ DECODER DE      │
          │ A DÍGITOS       │     │ ESTADO          │      │ EVENTO          │
          └────────┬────────┘     └────────┬────────┘      └────────┬────────┘
                   │                       │                        │
                   ▼                       │                        ▼
          ┌─────────────────┐              │              ┌─────────────────┐
          │ DECODER         │              │              │ SELECTOR DE     │
          │ 7 SEGMENTOS     │              │              │ TONO / PATRÓN   │
          └────────┬────────┘              │              └────────┬────────┘
                   │                       │                        │
                   ▼                       │                        ▼
          ┌─────────────────┐              │              ┌─────────────────┐
          │ MULTIPLEXOR     │              │              │ DIVISOR DE      │
          │ DE 4 DÍGITOS    │              │              │ FRECUENCIA      │
          └────────┬────────┘              │              └────────┬────────┘
                   │                       │                        │
             ┌─────┼─────┐                 │                        ▼
             ▼     ▼     ▼                 ▼              ┌─────────────────┐
           seg    an     dp            led_estado         │ CONTROL DE      │
                                                         │ DURACIÓN        │
                                                         └────────┬────────┘
                                                                  │
                                                                  ▼
                                                               buzzer
```

## Registros MMIO

Cada periférico posee un registro interno actualizado únicamente cuando el procesador realiza una escritura sobre su dirección correspondiente.

```text
Display -> 0x0001_0130
LED     -> 0x0001_0138
Buzzer  -> 0x0001_0140
```

El funcionamiento general de una escritura es:

```text
write_enable_i = 1
        │
        ▼
¿dirección coincide?
        │
   ┌────┴────┐
   │         │
  NO        SÍ
   │         │
sin cambio   ▼
          registro <= wdata_i
```

Esto evita que una operación dirigida a un periférico modifique los registros de los demás.

---

## Registro y organización de datos para displays

El registro del display almacena la información necesaria para representar los contadores de ambos jugadores.

Como propuesta, puede utilizarse la siguiente organización:

```text
31                      16 15             8 7              0
┌─────────────────────────┬────────────────┬────────────────┐
│       Reservado         │ Victorias J2   │ Victorias J1   │
└─────────────────────────┴────────────────┴────────────────┘
```

- **bits [7:0]:** contador de victorias del Jugador 1.
- **bits [15:8]:** contador de victorias del Jugador 2.
- **bits [31:16]:** reservados.

Cada contador debe mantenerse en el rango de `0` a `99`.

---

## Conversión de contador a decenas y unidades

Cada contador se divide en dos dígitos decimales:

```text
contador J1 ─────► decenas J1
            └────► unidades J1

contador J2 ─────► decenas J2
            └────► unidades J2
```

Conceptualmente:

```text
decenas  = contador / 10
unidades = contador % 10
```

El resultado son cuatro dígitos BCD:

```text
digit3 = decenas J1
digit2 = unidades J1
digit1 = decenas J2
digit0 = unidades J2
```

Durante la implementación esta conversión puede realizarse mediante lógica combinacional adecuada al rango reducido de `00` a `99`.

---

## Decoder de 7 segmentos

**Objetivo:** convertir cada dígito decimal entre `0` y `9` al patrón correspondiente de siete segmentos.

**Entrada:** `digit[3:0]`.

**Salida:** `seg_pattern[6:0]`.

```text
digit[3:0]
     │
     ▼
┌───────────────────┐
│ DECODER 7 SEG     │
│                   │
│ 0 -> patrón "0"   │
│ 1 -> patrón "1"   │
│ ...               │
│ 9 -> patrón "9"   │
└─────────┬─────────┘
          │
          ▼
     seg_pattern[6:0]
```

La polaridad exacta de los segmentos debe ajustarse a la tarjeta FPGA utilizada.

---

## Multiplexado de los cuatro dígitos

**Objetivo:** utilizar las mismas líneas `seg[6:0]` para representar cuatro dígitos diferentes.

El sistema utiliza un contador de refresco que selecciona secuencialmente uno de los cuatro dígitos.

```text
clk_i
  │
  ▼
┌─────────────────────┐
│ DIVISOR / CONTADOR  │
│ DE REFRESCO         │
└──────────┬──────────┘
           │ select[1:0]
           ▼
┌───────────────────────────┐
│ MULTIPLEXOR DE DÍGITOS    │
│                           │
│ 00 -> digit0              │
│ 01 -> digit1              │
│ 10 -> digit2              │
│ 11 -> digit3              │
└──────────┬────────────────┘
           │
           ├────────► decoder 7 segmentos ─────► seg[6:0]
           │
           └────────► decoder de ánodos ───────► an[3:0]
```

La frecuencia de refresco debe ser suficientemente alta para evitar parpadeo perceptible.

El punto decimal `dp` puede mantenerse desactivado si no se requiere para representar los contadores.

---

## Registro y decoder del LED de estado

El registro del LED almacena el código correspondiente a la fase actual de la partida.

```text
wdata_i[1:0]
     │
     ▼
┌────────────────┐
│ REGISTRO ESTADO│
└────────┬───────┘
         │ state[1:0]
         ▼
┌─────────────────────────┐
│ DECODER DE ESTADO       │
│                         │
│ 00 -> colocación        │
│ 01 -> batalla           │
│ 10 -> resultado final   │
│ 11 -> reservado         │
└──────────┬──────────────┘
           │
           ▼
       led_estado
```

Si se requiere distinguir tres estados utilizando un único LED, se pueden definir patrones como:

```text
Colocación      -> LED apagado
Batalla         -> LED encendido
Resultado final -> LED intermitente
```

La representación final debe documentarse de acuerdo con los recursos físicos disponibles en la tarjeta.

---

## Registro de eventos del buzzer

El periférico del buzzer almacena un código de evento escrito por el procesador.

```text
wdata_i[2:0]
     │
     ▼
┌────────────────────┐
│ REGISTRO DE EVENTO │
└─────────┬──────────┘
          │ event[2:0]
          ▼
┌──────────────────────────┐
│ DECODER DE EVENTO        │
│                          │
│ 000 -> silencio          │
│ 001 -> impacto           │
│ 010 -> fallo             │
│ 011 -> barco hundido     │
│ 100 -> colocación invál. │
│ 101 -> victoria          │
└──────────┬───────────────┘
           │
           ▼
     selección de patrón
```

---

## Generación de frecuencia para el buzzer

El buzzer requiere una señal periódica cuya frecuencia sea audible.

El reloj de 100 MHz se divide mediante un contador:

```text
clk_100MHz
     │
     ▼
┌──────────────────────┐
│ CONTADOR / DIVISOR   │◄──── valor_divisor
└──────────┬───────────┘
           │
           ▼
       tone_signal
```

La relación general puede expresarse como:

```text
f_buzzer = f_clk / (2 * N)
```

donde:

- `f_clk` es la frecuencia del reloj del sistema.
- `N` es el valor máximo utilizado por el contador.
- `f_buzzer` es la frecuencia del tono generado.

El valor de `N` cambia dependiendo del evento seleccionado.

---

## Selector de tono o patrón

El decoder de eventos determina la frecuencia y duración asociadas a cada sonido.

```text
event[2:0]
    │
    ▼
┌────────────────────────┐
│ SELECTOR DE PARÁMETROS │
├────────────────────────┤
│ impacto  -> N1         │
│ fallo    -> N2         │
│ hundido  -> N3         │
│ inválido -> N4         │
│ victoria -> secuencia  │
└───────────┬────────────┘
            │
            ▼
       valor_divisor
```

Los valores exactos de frecuencia pueden definirse durante la implementación, siempre que los eventos sean claramente distinguibles y queden documentados.

---

## Control de duración

**Objetivo:** evitar que un evento deje el buzzer activo indefinidamente.

Cuando el CPU escribe un nuevo código de evento, se inicia un contador de duración.

```text
evento nuevo
     │
     ▼
┌────────────────────┐
│ CONTADOR DURACIÓN  │
└─────────┬──────────┘
          │
     ┌────┴─────┐
     │          │
 activo      terminado
     │          │
     ▼          ▼
 habilita     buzzer = 0
 buzzer
```

Al finalizar el intervalo definido, el periférico regresa automáticamente al estado de silencio.

---

## Secuencia sonora de victoria

La victoria requiere una señal sonora distintiva. Puede implementarse mediante una pequeña secuencia de tonos.

```text
START
  │
  ▼
TONO 1
  │
  ▼
TONO 2
  │
  ▼
TONO 3
  │
  ▼
SILENCIO
```

Una implementación posible utiliza una máquina de estados sencilla:

```text
┌──────────┐
│ IDLE     │
└────┬─────┘
     │ evento victoria
     ▼
┌──────────┐
│ TONE_1   │
└────┬─────┘
     │ tiempo
     ▼
┌──────────┐
│ TONE_2   │
└────┬─────┘
     │ tiempo
     ▼
┌──────────┐
│ TONE_3   │
└────┬─────┘
     │ tiempo
     ▼
┌──────────┐
│ IDLE     │
└──────────┘
```

Los tonos y duraciones exactos se definirán durante la implementación.

---

## Interfaz de los periféricos con el bus MMIO

Los tres periféricos mantienen la interfaz estándar de registros utilizada por el sistema:

```text
clk_i
rst_i
write_enable_i
addr_i[1:0]
wdata_i[31:0]
rdata_o[31:0]
```

El decoder general del bus determina qué periférico se encuentra seleccionado utilizando la dirección completa del procesador.

Dentro de cada periférico, `addr_i[1:0]` puede utilizarse para seleccionar registros internos cuando sea necesario. En la implementación mínima de estos bloques se utiliza un único registro principal por periférico.

---

## Lectura de registros

Aunque los periféricos son utilizados principalmente mediante escrituras, sus registros pueden reflejarse en `rdata_o[31:0]` para permitir al procesador consultar su valor actual.

Como propuesta:

```text
Display rdata_o -> registro de contadores
LED     rdata_o -> código de estado
Buzzer  rdata_o -> código de evento actual
```

Esto permite verificar mediante software y simulación el valor almacenado en cada periférico.

---

## Comportamiento durante reset

Durante `rst_i`, todos los periféricos deben regresar a un estado seguro.

```text
Display:
    contadores / registro = 0

LED:
    estado = colocación o valor inicial definido

Buzzer:
    evento = silencio
    buzzer = 0
```

El buzzer debe permanecer inactivo durante el reset.

---

## Explicación general del cuarto nivel

Cuando el procesador realiza una escritura sobre el bus MMIO, el decoder de dirección determina si la operación corresponde al display, al LED o al buzzer. El dato escrito se almacena únicamente en el registro del periférico seleccionado.

En el periférico de displays, los contadores de victorias de ambos jugadores se separan en decenas y unidades. Los cuatro dígitos resultantes pasan por un decoder de siete segmentos y son mostrados mediante multiplexado temporal.

En el periférico LED, el código escrito por el procesador se almacena en un registro y se decodifica para representar las fases de colocación, batalla y resultado final.

En el periférico buzzer, el código de evento selecciona un patrón sonoro. Un divisor de frecuencia genera la señal audible y un contador de duración limita el tiempo durante el cual permanece activo. Para la condición de victoria se puede utilizar una secuencia de varios tonos controlada mediante una pequeña máquina de estados.

La separación entre registros MMIO, lógica de decodificación y bloques físicos de salida permite verificar cada parte de forma independiente mediante testbenches autoverificables antes de integrar los periféricos con el bus general del procesador.


<!--
Los demás diagramas de tercer y cuarto nivel pueden agregarse debajo de esta sección siguiendo la misma estructura de documentación.
-->

# Diagrama de Tercer Nivel - Memorias y Bus MMIO

El diagrama de tercer nivel desarrolla el bloque **MEMORIAS Y BUS MMIO** del sistema (Issue #4).

**Objetivo:** Dividir el subsistema de almacenamiento e interconexión en ROM, RAM y bus MMIO.

```text
  +------------------------+
  | Program ROM            |
  | 2048 x 32 bits         |
  +-----------+------------+
              ^  | ProgIn_i
 ProgAddress_o|  v
  +-----------+------------+
  | Procesador RISC-V      |
  +-----------+------------+
              ^  | DataAddress_o, DataOut_o, we_o
    DataIn_i  |  v
  +-----------+------------+
  | Interconexion MMIO     |
  | decoder + mux lectura  |
  +-----------+------------+
              |
              +---> Data RAM        0x0000_2000 - 0x0000_2FFF
              +---> UART            0x0001_0040 - 0x0001_0048
              +---> Entradas J1     0x0001_0120
              +---> Displays        0x0001_0130
              +---> LED             0x0001_0138
              +---> Buzzer          0x0001_0140
              +---> Memoria VGA     0x0001_1000 - 0x0001_17FF
```

## Entradas principales

`ProgAddress_o[31:0]`, `DataAddress_o[31:0]`, `DataOut_o[31:0]`, `we_o` y `clk_i`.

## Salidas principales

`ProgIn_i[31:0]`, `DataIn_i[31:0]`, selecciones y escrituras hacia RAM y periféricos.

## Bloques funcionales

**Program ROM:** entrega la instrucción solicitada por el CPU. **Data RAM:** almacena los tableros y variables. **Bus MMIO:** distribuye cada lectura o escritura a un solo destino.

## Explicación general del tercer nivel

La ROM tiene un bus exclusivo de instrucciones; RAM y periféricos comparten el bus de datos. El procesador entrega dirección, dato y habilitación de escritura. El decoder elige el destino y el multiplexor devuelve un único dato al CPU. La ROM ocupa `0x0000_0000-0x0000_1FFF`, la RAM `0x0000_2000-0x0000_2FFF` y la memoria VGA `0x0001_1000-0x0001_17FF`.

---

# Diagrama de Cuarto Nivel - Memorias y Bus MMIO

El diagrama de cuarto nivel desarrolla el bloque **MEMORIAS Y BUS MMIO** del sistema (Issue #4).

**Objetivo:** Detallar la selección de destinos, el control de escritura y la lectura de datos.

```text
 DataAddress_o[31:0]
         |
         v
+--------------------------+     direccion invalida o desalineada
| Comparar rangos y        |-------------------------------> sin destino
| exigir alineacion de 4 B |
+------------+-------------+
             |
             v
+--------------------------+
| Seleccion exclusiva      |----> sel_RAM, sel_UART, sel_GPIO,
| (a lo sumo un destino)   |      sel_7SEG, sel_LED, sel_BUZZ, sel_VGA
+------------+-------------+
             |
    +--------+-------------------------+
    |                                  |
    v                                  v
+------------------+            +----------------------+
| we_o AND sel_X   |            | Mux de rdata_X       |
| => write_enable_X|            | => DataIn_i[31:0]    |
+--------+---------+            +----------+-----------+
         |                                 |
         v                                 v
  Solo X puede escribir           CPU recibe dato de X

Direccion invalida: todos los write_enable_X = 0 y DataIn_i = 0.
```

## Entradas principales

`DataAddress_o[31:0]`, `DataOut_o[31:0]`, `we_o` y `rdata_o[31:0]` de cada destino.

## Salidas principales

`sel_X`, `write_enable_X`, `addr_i`, `wdata_i[31:0]` y `DataIn_i[31:0]`.

## Bloques funcionales

**Comparador:** verifica rango y alineación a palabra. **Selector exclusivo:** produce a lo sumo una selección. **Compuertas de escritura:** combinan `we_o` y `sel_X`. **Mux de lectura:** selecciona `rdata_o` del destino o cero para direcciones invalidas.

## Mapa de direcciones o bits

| Destino | Dirección o rango |
|---|---|
| ROM de programa | `0x0000_0000-0x0000_1FFF` |
| RAM | `0x0000_2000-0x0000_2FFF` |
| UART | `0x0001_0040`, `0x0001_0044`, `0x0001_0048` |
| Entradas J1 | `0x0001_0120` |
| Displays / LED / buzzer | `0x0001_0130`, `0x0001_0138`, `0x0001_0140` |
| VGA | `0x0001_1000-0x0001_17FF` |

## Explicación general del cuarto nivel

Cuando el CPU genera una dirección, la interconexión comprueba a que region pertenece y habilita solo ese bloque. Una escritura invalida o desalineada no modifica RAM ni periféricos; una lectura invalida devuelve cero. La ROM no pasa por este decoder porque utiliza el puerto de programa. La latencia de lectura de ROM y RAM debe coincidir con el contrato del procesador.

---

# Diagrama de Tercer Nivel - Entradas del Jugador 1

El diagrama de tercer nivel desarrolla el bloque **ENTRADAS DEL JUGADOR 1** del sistema (Issue #7).

**Objetivo:** Conectar los siete botones físicos a un registro legible por el procesador.

```text
+--------------------------+       +-------------------------+
| ARRIBA, ABAJO, IZQ, DER  |------>|                         |
+--------------------------+       | 7 x debounce_button     |
+--------------------------+       | (uno por cada boton)    |
| SEL, OK, RST             |------>|                         |
+--------------------------+       +-----------+-------------+
                                               |
                                 +-------------+-------------+
                                 |                           |
                                 v                           v
                          Niveles estables             Pulsos de pulsacion
                                 |                           |
                                 |                           v
                                 |                   +-------------------+
                                 |                   | Eventos pendientes|
                                 |                   +---------+---------+
                                 |                             |
                                 +------------+----------------+
                                              v
                                  +------------------------+
                                  | ESTADO[31:0]          |
                                  | direccion 0x0001_0120 |
                                  +-----------+------------+
                                              ^
                                              | lectura / limpieza W1C
                                              v
                                        Procesador
```

## Entradas principales

BTN_UP, BTN_DOWN, BTN_LEFT, BTN_RIGHT, BTN_SEL, BTN_OK y BTN_RST; `clk_i`, `rst_i`, `addr_i[1:0]`, `wdata_i[31:0]`, `write_enable_i`.

## Salidas principales

`rdata_o[31:0]` con niveles filtrados y eventos pendientes.

## Bloques funcionales

**Siete debouncers:** filtran los botones individuales. **Registro de eventos:** conserva las pulsaciones breves. **Registro ESTADO:** presenta niveles y eventos a la interfaz MMIO.

## Explicación general del tercer nivel

Se reutiliza `debounce_button` del Proyecto 2 siete veces, una por botón. Los niveles indican que botones permanecen presionados y los eventos retenidos permiten detectar cada pulsación mediante `lw`, aunque el CPU no lea el registro justo en el ciclo del pulso. La dirección del periférico es `0x0001_0120`.

---

# Diagrama de Cuarto Nivel - Entradas del Jugador 1

El diagrama de cuarto nivel desarrolla el bloque **ENTRADAS DEL JUGADOR 1** del sistema (Issue #7).

**Objetivo:** Explicar la sincronizacion, la eliminacion de rebotes y la captura de un evento.

```text
Boton fisico --> FF1 --> FF2 --> contador de estabilidad (20 ms)
                                            |
                                            v
                                    +---------------+
                                    | Nivel filtrado |------------+
                                    +-------+-------+            |
                                            |                    v
                                            v             ESTADO: bits [0:6]
                                    +---------------+
                                    | Flanco 0 a 1  |
                                    +-------+-------+
                                            |
                                            v
                                    +---------------+
                CPU -- W1C -------> | Evento retenido|----> ESTADO: bits [8:14]
                                    +---------------+

                       CPU -- lw / sw --> ESTADO @ 0x0001_0120
```

## Entradas principales

Botón físico asíncrono, reloj de 100 MHz y escritura de confirmacion desde el CPU.

## Salidas principales

Nivel filtrado y bit de evento pendiente dentro de `ESTADO[31:0]`.

## Bloques funcionales

**Sincronizador:** dos flip-flops reducen riesgo de metastabilidad. **Contador:** acepta un nivel cuando permanece estable 20 ms. **Detector:** identifica el flanco de pulsación. **Bit pendiente:** mantiene el evento hasta la limpieza por escritura de uno (`W1C`).

## Mapa de direcciones o bits

| Botón | Nivel | Evento |
|---|---:|---:|
| Arriba | 0 | 8 |
| Abajo | 1 | 9 |
| Izquierda | 2 | 10 |
| Derecha | 3 | 11 |
| SEL | 4 | 12 |
| OK | 5 | 13 |
| RST | 6 | 14 |

## Explicación general del cuarto nivel

Cada pulsación valida cambia el nivel filtrado y genera un solo evento. Los bits `0..6` son niveles y los bits `8..14` conservan las pulsaciones correspondientes. BTN_RST debe pedir al programa iniciar otra partida sin borrar victorias; el reset general del procesador es una señal separada. Si coinciden limpieza y pulsación nueva, prevalece la captura.

---

# Diagrama de Tercer Nivel - Periférico UART

El diagrama de tercer nivel desarrolla el bloque **PERIFÉRICO UART** del sistema (Issue #8).

**Objetivo:** Reutilizar el UART del Proyecto 2 como dispositivo accesible por el CPU mediante MMIO.

```text
                                  CAMINO DE TRANSMISION
CPU -- sw --> [Registros MMIO] --> [FIFO TX] --> [UART TX] --> PC Jugador 2

                                  CAMINO DE RECEPCION
CPU <-- lw -- [Registros MMIO] <-- [FIFO RX] <-- [UART RX] <-- PC Jugador 2

               UART TX y UART RX comparten el enlace a 115200 baudios.
```

## Entradas principales

`clk_i`, `rst_i`, `uart_rx`, `addr_i[1:0]`, `wdata_i[31:0]` y `write_enable_i`.

## Salidas principales

`uart_tx` y `rdata_o[31:0]` con datos y estado.

## Bloques funcionales

**Registros MMIO:** interfaz de control, TX y RX. **FIFOs:** almacenan bytes cuando CPU y puerto serie trabajan a distinta velocidad. **Transmisor/receptor:** convierten bytes a tramas UART y viceversa.

## Explicación general del tercer nivel

El CPU escribe bytes de salida en TX y lee bytes de entrada desde RX. Los núcleos UART y las FIFOs del proyecto anterior se aprovechan; las reglas y los mensajes de Batalla Naval los construye e interpreta el programa ensamblador. El enlace con la PC opera a 115200 baudios.

---

# Diagrama de Cuarto Nivel - Periférico UART

El diagrama de cuarto nivel desarrolla el bloque **PERIFÉRICO UART** del sistema (Issue #8).

**Objetivo:** Detallar el orden de registros y los indicadores necesarios para operar el puerto serie.

```text
                   CPU: DataAddress_o / DataOut_o / DataIn_i
                                      |
                                      v
                      +-------------------------------+
                      | Decoder UART: addr_i[1:0]     |
                      +-------+-----------+-----------+
                              |           |           |
                            00|         01|         10|
                              v           v           v
                     +-----------+  +---------+  +---------+
                     | CONTROL / |  | DATOS TX|  | DATOS RX|
                     | ESTADO    |  |  byte   |  |  byte   |
                     +-----+-----+  +----+----+  +----+----+
                           ^             |            ^
                           |             v            |
                  tx_ready, rx_valid  [FIFO TX]    [FIFO RX]
                                           |            ^
                                           v            |
                                        UART TX      UART RX
```

## Entradas principales

Dirección local `addr_i[1:0]`, `wdata_i[31:0]`, `write_enable_i`, estado de FIFOs y datos recibidos.

## Salidas principales

`rdata_o[31:0]`, solicitud de envio y dato de escritura para TX.

## Bloques funcionales

**Decoder de registros:** selecciona control (`00`), TX (`01`) o RX (`10`). **Estado:** expone disponibilidad de TX y RX. **TX/RX:** intercambian bytes con sus FIFOs.

## Mapa de direcciones o bits

| Registro | Dirección |
|---|---|
| Control/Estado | `0x0001_0040` |
| Datos TX | `0x0001_0044` |
| Datos RX | `0x0001_0048` |

## Explicación general del cuarto nivel

El Proyecto 3 ubica control/estado en `0x0001_0040`, TX en `0x0001_0044` y RX en `0x0001_0048`. El periférico del Proyecto 2 usa otro orden interno: TX=`00`, RX=`01`, control=`10`; esta conversion debe implementarse o documentarse en un adaptador. Hay que acordar los bits de estado y cuando un byte RX deja de estar pendiente.

---

# Diagrama de Tercer Nivel - Aplicación de PC del Jugador 2

El diagrama de tercer nivel desarrolla el bloque **APLICACIÓN DE PC DEL JUGADOR 2** del sistema (Issue #9).

**Objetivo:** Separar la interfaz de entrada, el puerto serie y las vistas de ambos tableros.

```text
          ACCIONES DEL JUGADOR 2

Jugador 2 --> [Pantalla de entrada] --> [Validar formato]
                                            |
                                            v
                                    [Transporte serial] ---> FPGA

          NOTIFICACIONES DE LA FPGA

FPGA ---> [Transporte serial] ---> [Decodificar evento]
                                            |
                                            v
                                  [Actualizar vista local] ---> Jugador 2
```

## Entradas principales

Colocaciones y disparos del usuario; mensajes recibidos desde la FPGA por UART.

## Salidas principales

Mensajes hacia la FPGA y tableros/turno/resultados visibles en la PC.

## Bloques funcionales

**Interfaz de entrada:** solicita coordenadas y orientaciones. **Transporte serial:** envia/recibe tramas. **Decoder y vista:** interpretan eventos de la FPGA y actualizan lo mostrado.

## Explicación general del tercer nivel

El Jugador 2 escribe colocaciones y disparos en la PC. La aplicación valida su formato y envia los mensajes a la FPGA; luego muestra las respuestas. La aceptacion, el resultado de los disparos, los turnos y la victoria los decide el programa del procesador RISC-V, no Python.

---

# Diagrama de Cuarto Nivel - Aplicación de PC del Jugador 2

El diagrama de cuarto nivel desarrolla el bloque **APLICACIÓN DE PC DEL JUGADOR 2** del sistema (Issue #9).

**Objetivo:** Describir el tratamiento de una solicitud del usuario y de una respuesta de la FPGA.

```text
    SOLICITUD                                              RESPUESTA

+------------------+                                 +-------------------+
| Entrada usuario  |                                 | Trama desde FPGA  |
+--------+---------+                                 +---------+---------+
         |                                                     |
         v                                                     v
+------------------+                                 +-------------------+
| Validar formato  |                                 | Verificar trama   |
| y rango 0..7     |                                 | y tipo de evento  |
+--------+---------+                                 +---------+---------+
         |                                                     |
         v                                                     v
+------------------+                                 +-------------------+
| Codificar y      |                                 | Actualizar estado |
| enviar solicitud |                                 | visible local     |
+--------+---------+                                 +---------+---------+
         |                                                     |
         v                                                     v
   UART hacia FPGA                                   Mostrar ambos tableros
```

## Entradas principales

Entrada de teclado y tramas UART recibidas.

## Salidas principales

Solicitudes serializadas y estado visible de ambos tableros.

## Bloques funcionales

**Validador:** comprueba formato y coordenadas `0..7`. **Codificador:** construye la solicitud. **Parser:** verifica la trama de respuesta. **Modelo de vista:** guarda barcos propios aceptados, resultados conocidos del rival y turno. **Presentacion:** redibuja los tableros.

## Explicación general del cuarto nivel

La PC solo actualiza el tablero rival al recibir los resultados de disparos propios y nunca muestra barcos rivales no descubiertos. Una colocación rechazada se solicita de nuevo. Una trama invalida se descarta sin modificar las vistas; el puerto permanece abierto para partidas sucesivas.









































































# Diagrama de Tercer Nivel - Datapath RISC-V RV32I

El diagrama de tercer nivel desarrolla internamente el bloque correspondiente al **DATAPATH del procesador RISC-V RV32I**. Este subsistema contiene los elementos necesarios para ejecutar las instrucciones soportadas por el procesador, realizar operaciones aritméticas y lógicas, acceder a memoria, actualizar el Register File y determinar la siguiente dirección del Program Counter.

El datapath recibe las señales de control generadas por la **Unidad de Control RISC-V** y las utiliza para seleccionar los operandos, la operación de la ALU, el formato del inmediato, el dato que será escrito en el Register File y la dirección siguiente del Program Counter.

El diseño está orientado a un procesador de **32 bits** y debe permitir la ejecución de las instrucciones definidas para el subconjunto RV32I utilizado en el proyecto. El enunciado especifica buses de 32 bits para la dirección de programa, instrucción, dirección de datos, dato de salida y dato de entrada.

---

## Objetivo

Diseñar e implementar el datapath de 32 bits del procesador RISC-V RV32I, proporcionando las rutas de datos necesarias para:

- Mantener y actualizar el **Program Counter (PC)**.
- Leer operandos desde un **Register File de 32 registros de 32 bits**.
- Garantizar que el registro `x0` permanezca permanentemente en cero.
- Generar inmediatos para los formatos de instrucciones **I, S, B y J**.
- Ejecutar operaciones aritméticas y lógicas mediante una **ALU de 32 bits**.
- Realizar desplazamientos lógicos y aritméticos.
- Realizar comparaciones signed y unsigned.
- Calcular direcciones efectivas para instrucciones de acceso a memoria.
- Evaluar las condiciones de branch.
- Calcular las direcciones de `jal` y `jalr`.
- Seleccionar el valor que será escrito en el Register File.
- Generar la dirección de acceso a memoria de datos.
- Integrarse con la Unidad de Control mediante señales de control.

El datapath debe mantenerse modular y sintetizable en SystemVerilog, permitiendo verificar sus submódulos individualmente antes de realizar la integración completa.

---

## Entradas

Las principales entradas externas y señales de control del datapath son:

- **`clk`**: reloj principal del procesador.
- **`rst`**: señal de reinicio.
- **`ProgIn[31:0]`**: instrucción proveniente de la memoria de programa.
- **`DataIn[31:0]`**: dato leído desde la memoria de datos o desde un periférico MMIO.
- **`RegWrite`**: habilita la escritura en el Register File.
- **`ALUSrc`**: selecciona el segundo operando de la ALU entre un registro y un inmediato.
- **`ALUControl`**: indica la operación que debe realizar la ALU.
- **`ImmSrc[1:0]`**: selecciona el formato de inmediato.
- **`ResultSrc[1:0]`**: selecciona el resultado que será escrito en el Register File.
- **`MemWrite`**: indica una operación de escritura hacia memoria o periféricos.
- **`Branch`**: indica que la instrucción corresponde a un branch.
- **`BranchType`**: determina el tipo de comparación del branch.
- **`Jump`**: indica una instrucción de salto.
- **`Jalr`**: identifica el mecanismo de salto utilizado por `jalr`.

---

## Salidas

Las principales salidas del datapath son:

- **`ProgAddress[31:0]`**: dirección de la siguiente instrucción hacia la memoria de programa.
- **`DataAddress[31:0]`**: dirección generada para acceder a memoria de datos o periféricos.
- **`DataOut[31:0]`**: dato que será escrito en memoria.
- **`we` / `MemWrite`**: señal de escritura hacia la interfaz de memoria.
- **`BranchTaken`**: resultado de la evaluación de una condición de branch.
- **`PCPlus4[31:0]`**: valor de `PC + 4`.

---

## Explicación general

El datapath comienza recibiendo la instrucción de 32 bits desde la memoria de programa. A partir de la instrucción se extraen los campos necesarios para acceder al Register File y generar el inmediato correspondiente.

```text
instruction[31:0]

31                    25 24    20 19    15 14    12 11     7 6       0
┌──────────────────────┬────────┬────────┬────────┬────────┬─────────┐
│       funct7         │   rs2  │   rs1  │ funct3 │   rd   │ opcode  │
└──────────────────────┴────────┴────────┴────────┴────────┴─────────┘
```

El campo `rs1` selecciona el primer registro fuente, `rs2` selecciona el segundo registro fuente y `rd` identifica el registro destino.

El Register File entrega dos operandos de 32 bits. El primer operando se conecta directamente a la ALU. El segundo pasa por un multiplexor controlado por `ALUSrc`, permitiendo seleccionar entre `ReadData2` o el inmediato generado.

El generador de inmediatos recibe la instrucción completa y `ImmSrc`, generando el inmediato correspondiente a los formatos I, S, B o J.

La ALU realiza:

```text
ADD
SUB
AND
OR
XOR
SLL
SRL
SRA
SLT
SLTU
```

Para instrucciones `lw` y `sw`:

```text
DataAddress = rs1 + inmediato
```

Para `sw`:

```text
DataOut = rs2
```

Para `lw`, `DataIn` se incorpora al camino de write-back.

La actualización del Program Counter utiliza:

```text
PC_nuevo = PC + 4
```

o, dependiendo del flujo de control:

```text
PC_nuevo = PC + inmediato_B
PC_nuevo = PC + inmediato_J
PC_nuevo = rs1 + inmediato_I
```

`PC + 4` también se utiliza como valor de retorno para `jal` y `jalr`.

---

## Diagrama de bloques

```text
                         ┌─────────────────────┐
                         │   PROGRAM COUNTER    │
                         │       PC[31:0]      │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │       PC + 4        │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │     NEXT PC MUX     │◄──── BranchTaken
                         │                     │◄──── Jump
                         │ PC+4                │
                         │ BranchTarget        │
                         │ JumpTarget          │
                         └──────────┬──────────┘
                                    │
                                    ▼
                              PC_next[31:0]
                                    │
                                    └────────► PC


 ProgIn[31:0]
       │
       ▼
┌──────────────────────┐
│ Extracción de campos │
└──────────┬───────────┘
           │
     ┌─────┼───────────────┐
     │     │               │
    rs1   rs2             rd
     │     │               │
     ▼     ▼               │
┌────────────────────────┐  │
│     REGISTER FILE      │  │
│      32 x 32 bits      │  │
└───────┬───────┬────────┘  │
        │       │           │
   ReadData1  ReadData2     │
        │       │           │
        │       └─────┐     │
        │             │     │
        │             ▼     │
        │      ┌───────────┐│
        │      │ ALU MUX   ││◄── ALUSrc
        │      └─────┬─────┘│
        │            │      │
        │            ▼      │
        └──────────► ALU ◄──┘
                     │
                     │
               ALUResult
                     │
          ┌──────────┴──────────┐
          ▼                     ▼
   DataAddress             WriteBack MUX
                                ▲
                                │
                       ┌────────┼────────┐
                       │        │        │
                    ALUResult DataIn PCPlus4
                       │        │        │
                       └────────┼────────┘
                                │
                                ▼
                           WriteData
                                │
                                └────► Register File


 ProgIn[31:0]
       │
       ▼
┌─────────────────────┐
│ Immediate Generator │◄──── ImmSrc
└──────────┬──────────┘
           │
        ImmExt
           │
           ├────────► ALU MUX
           │
           ├────────► Branch Target
           │
           └────────► Jump Target


 ReadData1 ───────┐
                   ▼
              ┌──────────────┐
 ReadData2 ───►│   Branch     │◄──── BranchType
              │  Comparator  │◄──── Branch
              └──────┬───────┘
                     │
                BranchTaken
                     │
                     ▼
                NEXT PC MUX


 ReadData2 ─────────────────────────► DataOut
 MemWrite ──────────────────────────► we
 DataIn ────────────────────────────► WriteBack MUX
```

---

# Diagramas de Cuarto Nivel

Los siguientes diagramas representan la descomposición interna de los bloques principales del Datapath definidos en el tercer nivel.

---

# Diagrama de Cuarto Nivel - Program Counter

## Objetivo

Diseñar el bloque secuencial encargado de almacenar la dirección actual de ejecución y entregar la dirección de la instrucción al sistema de memoria de programa.

## Entradas

- `clk`
- `rst`
- `PC_next[31:0]`

## Salidas

- `PC[31:0]`
- `ProgAddress[31:0]`

## Explicación general

El Program Counter es un registro de 32 bits que almacena la dirección de la instrucción actual.

En cada flanco activo del reloj, el registro carga el valor calculado por la lógica de siguiente PC.

La salida del registro se conecta directamente con la dirección de la memoria de programa:

```text
ProgAddress = PC
```

La actualización normal del PC utiliza:

```text
PCPlus4 = PC + 32'd4
```

## Diagrama de bloques

```text
                 ┌──────────────────────┐
 PC_next[31:0] ─►│                      │
                 │   REGISTER PC        │
 clk ───────────►│                      │
 rst ───────────►│                      │
                 └──────────┬───────────┘
                            │
                         PC[31:0]
                            │
                            ├──────────────► ProgAddress
                            │
                            ▼
                      ┌───────────┐
                      │   ADD 4   │
                      └─────┬─────┘
                            │
                       PCPlus4[31:0]
```

---

# Diagrama de Cuarto Nivel - Generación de PC + 4

## Objetivo

Calcular la dirección secuencial de la siguiente instrucción.

## Entradas

- `PC[31:0]`

## Salida

- `PCPlus4[31:0]`

## Explicación general

El bloque realiza una suma constante de cuatro bytes:

```text
PCPlus4 = PC + 32'd4
```

Este resultado representa el siguiente valor normal del Program Counter y también constituye una de las entradas del multiplexor de write-back.

## Diagrama de bloques

```text
 PC[31:0]
     │
     ▼
┌───────────────┐
│     ADDER     │
│               │
│   A + 32'd4   │
└───────┬───────┘
        │
        ▼
 PCPlus4[31:0]
```

---

# Diagrama de Cuarto Nivel - Multiplexor de siguiente PC

## Objetivo

Seleccionar entre la dirección secuencial, la dirección de branch y las direcciones de salto.

## Entradas

- `PCPlus4[31:0]`
- `BranchTarget[31:0]`
- `JumpTarget[31:0]`
- `BranchTaken`
- `Jump`
- `Jalr`

## Salida

- `PC_next[31:0]`

## Explicación general

Este bloque determina qué dirección será cargada en el Program Counter.

La selección conceptual es:

```text
PC + 4       → ejecución normal
BranchTarget → branch tomado
JumpTarget   → JAL/JALR
```

Para `jal`:

```text
PC + ImmJ
```

Para `jalr`:

```text
rs1 + ImmI
```

## Diagrama de bloques

```text
 PCPlus4[31:0] ───────────┐
                          │
 BranchTarget[31:0] ──────┤
                          ▼
                     ┌──────────────┐
 JumpTarget[31:0] ───►│              │
                     │   NEXT PC    │
 BranchTaken ────────►│     MUX      │
 Jump ───────────────►│              │
 Jalr ───────────────►│              │
                     └──────┬───────┘
                            │
                            ▼
                       PC_next[31:0]
```

---

# Diagrama de Cuarto Nivel - Register File

## Objetivo

Implementar el banco de registros utilizado para almacenar los operandos y resultados de las instrucciones.

## Entradas

- `clk`
- `rst`
- `rs1[4:0]`
- `rs2[4:0]`
- `rd[4:0]`
- `WriteData[31:0]`
- `RegWrite`

## Salidas

- `ReadData1[31:0]`
- `ReadData2[31:0]`

## Explicación general

El Register File está compuesto por 32 registros de 32 bits.

Posee dos puertos de lectura:

```text
rs1 → ReadData1
rs2 → ReadData2
```

y un puerto de escritura:

```text
rd ← WriteData
```

La escritura se realiza cuando:

```text
RegWrite = 1
```

El registro `x0` debe permanecer permanentemente en cero.

Por ello:

```text
rs1 = 0 → ReadData1 = 0
rs2 = 0 → ReadData2 = 0
```

y:

```text
rd = 0 → no modificar x0
```

## Diagrama de bloques

```text
                     ┌──────────────────────────┐
                     │      REGISTER FILE       │
                     │        32 x 32           │
                     │                          │
 rs1[4:0] ──────────►│ Read Port 1              │
                     │          │               │
                     │          ▼               │
                     │    ReadData1[31:0]       │
                     │                          │
 rs2[4:0] ──────────►│ Read Port 2              │
                     │          │               │
                     │          ▼               │
                     │    ReadData2[31:0]       │
                     │                          │
 rd[4:0] ───────────►│ Write Port               │
                     │          ▲               │
 WriteData[31:0] ───►│          │               │
 RegWrite ──────────►│ Write Enable             │
                     │                          │
                     │ x0 = 0                   │
                     └──────────────────────────┘
```

---

# Diagrama de Cuarto Nivel - Generador de Inmediatos

## Objetivo

Extraer y reconstruir los campos de inmediato de las instrucciones RISC-V y generar un valor de 32 bits extendido con signo.

## Entradas

- `instruction[31:0]`
- `ImmSrc[1:0]`

## Salida

- `ImmExt[31:0]`

## Explicación general

El bloque identifica el formato de inmediato mediante `ImmSrc`.

```text
00 → I
01 → S
10 → B
11 → J
```

La reconstrucción de cada formato utiliza los campos específicos de la instrucción y realiza extensión de signo.

## Diagrama de bloques

```text
                         instruction[31:0]
                                │
                                ▼
                     ┌──────────────────────┐
                     │ Extracción de campos │
                     └──────────┬───────────┘
                                │
                  ┌─────────────┼─────────────┐
                  │             │             │
                  ▼             ▼             ▼
               I-type        S-type        B-type
                  │             │             │
                  └─────────────┼─────────────┘
                                │
                              J-type
                                │
                                ▼
                     ┌──────────────────────┐
 ImmSrc[1:0] ───────►│ Selección de formato  │
                     └──────────┬───────────┘
                                │
                                ▼
                     ┌──────────────────────┐
                     │ Extensión de signo   │
                     └──────────┬───────────┘
                                │
                                ▼
                         ImmExt[31:0]
```

---

# Diagrama de Cuarto Nivel - ALU

## Objetivo

Realizar las operaciones aritméticas, lógicas, de desplazamiento y comparación requeridas por el procesador.

## Entradas

- `A[31:0]`
- `B[31:0]`
- `ALUControl`

## Salidas

- `ALUResult[31:0]`
- señales de comparación utilizadas por el datapath

## Explicación general

La ALU recibe dos operandos de 32 bits y una señal de control que determina la operación.

Las operaciones requeridas son:

```text
ADD
SUB
AND
OR
XOR
SLL
SRL
SRA
SLT
SLTU
```

Para las operaciones de desplazamiento, la cantidad de desplazamiento se obtiene de los bits correspondientes del segundo operando.

`SRA` realiza desplazamiento aritmético, conservando el bit de signo.

`SLT` realiza comparación signed y `SLTU` comparación unsigned.

## Diagrama de bloques

```text
                 A[31:0]
                    │
                    ▼
             ┌──────────────┐
             │              │
 B[31:0] ───►│     ALU      │◄──── ALUControl
             │              │
             │ ADD          │
             │ SUB          │
             │ AND          │
             │ OR           │
             │ XOR          │
             │ SLL          │
             │ SRL          │
             │ SRA          │
             │ SLT          │
             │ SLTU         │
             └──────┬───────┘
                    │
                    ▼
             ALUResult[31:0]
```

---

# Diagrama de Cuarto Nivel - Multiplexor de operandos de ALU

## Objetivo

Seleccionar el segundo operando que será utilizado por la ALU.

## Entradas

- `ReadData2[31:0]`
- `ImmExt[31:0]`
- `ALUSrc`

## Salida

- `ALU_B[31:0]`

## Explicación general

Cuando:

```text
ALUSrc = 0
```

se utiliza:

```text
ALU_B = ReadData2
```

Cuando:

```text
ALUSrc = 1
```

se utiliza:

```text
ALU_B = ImmExt
```

El primer operando de la ALU proviene de `ReadData1`.

## Diagrama de bloques

```text
 ReadData2[31:0] ────────┐
                         │
                         ▼
                    ┌──────────┐
 ImmExt[31:0] ─────►│  ALU B   │
                    │   MUX    │◄──── ALUSrc
                    └────┬─────┘
                         │
                         ▼
                    ALU_B[31:0]
```

---

# Diagrama de Cuarto Nivel - Comparador de Branch

## Objetivo

Evaluar la condición de las instrucciones de branch y generar la señal que determina si debe modificarse el Program Counter.

## Entradas

- `ReadData1[31:0]`
- `ReadData2[31:0]`
- `Branch`
- `BranchType`

## Salida

- `BranchTaken`

## Explicación general

El comparador analiza los operandos de los registros fuente según el tipo de branch.

Las condiciones mínimas requeridas son:

```text
BEQ → rs1 == rs2
BNE → rs1 != rs2
BLT → rs1 < rs2   signed
BGE → rs1 >= rs2  signed
```

Conceptualmente:

```text
BranchTaken = Branch AND Condition
```

## Diagrama de bloques

```text
 ReadData1[31:0] ───────┐
                        │
                        ▼
                  ┌───────────────┐
                  │               │
 ReadData2[31:0] ─►│  COMPARATOR   │
                  │               │
 BranchType ─────►│ BEQ           │
                  │ BNE           │
                  │ BLT           │
                  │ BGE           │
                  └───────┬───────┘
                          │
                       Condition
                          │
                          ▼
                    ┌───────────┐
 Branch ───────────►│    AND    │
                    └─────┬─────┘
                          │
                          ▼
                    BranchTaken
```

---

# Diagrama de Cuarto Nivel - Generación de destino de Branch

## Objetivo

Calcular la dirección destino de una instrucción de branch.

## Entradas

- `PC[31:0]`
- `ImmExt[31:0]`

## Salida

- `BranchTarget[31:0]`

## Explicación general

Para un branch, el inmediato correspondiente es el inmediato B.

El destino se obtiene mediante:

```text
BranchTarget = PC + ImmB
```

La selección de este destino se realiza cuando `BranchTaken` es verdadero.

## Diagrama de bloques

```text
 PC[31:0] ───────────────┐
                         │
                         ▼
                    ┌─────────┐
 ImmExt[31:0] ─────►│  ADDER  │
                    └────┬────┘
                         │
                         ▼
                  BranchTarget[31:0]
```

---

# Diagrama de Cuarto Nivel - Generación de destino de Jump

## Objetivo

Calcular la dirección destino de las instrucciones `jal` y `jalr`.

## Entradas

- `PC[31:0]`
- `ReadData1[31:0]`
- `ImmExt[31:0]`
- `Jalr`

## Salida

- `JumpTarget[31:0]`

## Explicación general

El bloque implementa dos rutas diferentes.

Para `jal`:

```text
JumpTarget = PC + ImmJ
```

Para `jalr`:

```text
JumpTarget = rs1 + ImmI
```

La señal `Jalr` determina cuál de los dos operandos base se utiliza.

## Diagrama de bloques

```text
                       ┌───────────────┐
 PC[31:0] ────────────►│               │
                       │   ADDER JAL   │──────┐
 ImmExt[31:0] ────────►│               │      │
                       └───────────────┘      │
                                              │
                                              ▼
                                       ┌────────────┐
 ReadData1[31:0] ─────────────────────►│  JUMP MUX  │◄──── Jalr
                                       │            │
                                       └─────┬──────┘
                                             │
                                             ▼
                                      JumpTarget[31:0]
```

---

# Diagrama de Cuarto Nivel - Interfaz de memoria de datos

## Objetivo

Conectar el datapath con la memoria de datos para implementar las operaciones de lectura y escritura.

## Entradas

- `ALUResult[31:0]`
- `ReadData2[31:0]`
- `DataIn[31:0]`
- `MemWrite`

## Salidas

- `DataAddress[31:0]`
- `DataOut[31:0]`
- `we`

## Explicación general

La ALU genera la dirección efectiva:

```text
DataAddress = ALUResult
```

En una operación `sw`, el dato a escribir es:

```text
DataOut = ReadData2
```

La señal de escritura se obtiene de:

```text
we = MemWrite
```

En una operación `lw`, la memoria devuelve el dato mediante:

```text
DataIn[31:0]
```

que posteriormente se dirige al multiplexor de write-back.

## Diagrama de bloques

```text
 ALUResult[31:0] ─────────────────► DataAddress[31:0]

 ReadData2[31:0] ─────────────────► DataOut[31:0]

 MemWrite ────────────────────────► we


                         ┌────────────────────┐
                         │    DATA MEMORY     │
                         │                    │
 DataAddress ───────────►│ Address            │
 DataOut ───────────────►│ Write Data         │
 we ────────────────────►│ Write Enable       │
                         │                    │
 DataIn[31:0] ◄──────────│ Read Data          │
                         └────────────────────┘
```

---

# Diagrama de Cuarto Nivel - Multiplexor de Write-Back

## Objetivo

Seleccionar el resultado que será escrito en el registro destino del Register File.

## Entradas

- `ALUResult[31:0]`
- `DataIn[31:0]`
- `PCPlus4[31:0]`
- `ResultSrc`

## Salida

- `WriteData[31:0]`

## Explicación general

El multiplexor permite seleccionar entre las tres fuentes principales de resultado:

```text
ALUResult → operaciones ALU
DataIn    → instrucciones de lectura de memoria
PCPlus4   → jal / jalr
```

La selección está controlada mediante `ResultSrc`.

## Diagrama de bloques

```text
 ALUResult[31:0] ────────┐
                         │
 DataIn[31:0] ───────────┤
                         ▼
 PCPlus4[31:0] ─────────►│
                    ┌──────────────┐
 ResultSrc ────────►│ WRITE-BACK   │
                    │     MUX      │
                    └──────┬───────┘
                           │
                           ▼
                    WriteData[31:0]
                           │
                           ▼
                         rd
```

---

# Diagrama de Cuarto Nivel - Interfaz Datapath / Unidad de Control

## Objetivo

Definir la conexión entre la unidad encargada de generar las señales de control y los bloques internos del datapath.

## Entradas

Las señales provenientes de la Unidad de Control son:

```text
RegWrite
ALUSrc
ALUControl
ImmSrc
ResultSrc
MemWrite
Branch
BranchType
Jump
Jalr
```

## Salidas

Las señales son distribuidas hacia:

```text
Register File
ALU Operand MUX
Immediate Generator
ALU
Branch Comparator
Next PC MUX
Write-Back MUX
Memory Interface
```

## Explicación general

La Unidad de Control genera las señales que determinan el comportamiento del datapath.

La conexión conceptual es:

```text
                   ┌──────────────────────┐
                   │    UNIDAD DE         │
                   │      CONTROL         │
                   └──────────┬───────────┘
                              │
                 señales de control
                              │
       ┌──────────────────────┼────────────────────────┐
       │          │           │           │            │
       ▼          ▼           ▼           ▼            ▼
   RegFile      ALU       ImmGen      Next PC      WriteBack
       │          │           │           │            │
       └──────────┴───────────┴───────────┴────────────┘
                              │
                              ▼
                         DATAPATH
```

---

# Diagrama de Cuarto Nivel - Ruta completa de ejecución

## Objetivo

Representar la interacción entre los bloques internos del datapath durante la ejecución de una instrucción.

## Entradas

- `clk`
- `rst`
- `ProgIn`
- `DataIn`
- señales de control

## Salidas

- `ProgAddress`
- `DataAddress`
- `DataOut`
- `we`

## Explicación general

Este diagrama reúne los bloques de cuarto nivel y muestra cómo fluye la información desde la instrucción hasta el resultado y la actualización del PC.

La ruta general es:

```text
PC
 ↓
Program Memory
 ↓
Instruction
 ↓
Register File + Immediate Generator
 ↓
ALU / Comparator
 ↓
Memory / Write-Back
 ↓
Register File
```

En paralelo:

```text
PC + 4
Branch Target
Jump Target
       ↓
   Next PC MUX
       ↓
       PC
```

## Diagrama de bloques

```text
                           ┌────────────────┐
                           │      PC        │
                           └───────┬────────┘
                                   │
                                   ▼
                           ┌────────────────┐
                           │ PROGRAM MEMORY │
                           └───────┬────────┘
                                   │
                              ProgIn[31:0]
                                   │
             ┌─────────────────────┼─────────────────────┐
             │                     │                     │
             ▼                     ▼                     ▼
       ┌───────────┐       ┌──────────────┐       ┌─────────────┐
       │ Register  │       │ Immediate    │       │ Instruction │
       │   File    │       │ Generator    │       │   Fields    │
       └─────┬─────┘       └──────┬───────┘       └─────────────┘
             │                    │
       ┌─────┴──────┐             │
       │            │             │
       ▼            ▼             ▼
    ReadData1   ReadData2      ImmExt
       │            │             │
       │            └──────┐      │
       │                   ▼      ▼
       │              ┌──────────────┐
       └─────────────►│   ALU MUX    │
                      └──────┬───────┘
                             │
                             ▼
                       ┌───────────┐
                       │    ALU    │
                       └─────┬─────┘
                             │
                       ALUResult
                         │       │
                         │       └──────────────► DataAddress
                         │
                         ▼
                  ┌────────────────┐
                  │ Write-Back MUX │◄──── DataIn
                  │                │◄──── PCPlus4
                  └───────┬────────┘
                          │
                      WriteData
                          │
                          ▼
                    Register File


  ReadData1 ───────┐
                   ▼
               ┌───────────┐
 ReadData2 ───►│ Branch    │
               │ Comparator│
               └─────┬─────┘
                     │
                BranchTaken
                     │
                     ▼

 PC ──────────►┌────────────────┐
 ImmB ────────►│ Branch Target  │
               └───────┬────────┘
                       │
                 BranchTarget


 PC ───────────────►┌────────────────┐
 ImmJ / rs1 ───────►│  Jump Target   │
                    └───────┬────────┘
                            │
                       JumpTarget


 PC ───────────────►┌────────────────┐
                    │    PC + 4      │
                    └───────┬────────┘
                            │
                            ▼
                    ┌────────────────┐
 BranchTarget ─────►│                │
 JumpTarget ───────►│   NEXT PC MUX  │
 PCPlus4 ──────────►│                │
                    └───────┬────────┘
                            │
                            ▼
                         PC_next
                            │
                            └────────► PC
```

---


---




