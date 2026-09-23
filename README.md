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

<!--
Los demás diagramas de tercer y cuarto nivel pueden agregarse debajo de esta sección siguiendo la misma estructura de documentación.
-->


