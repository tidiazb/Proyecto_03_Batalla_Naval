# Informe técnico — Proyecto 3: Batalla Naval sobre FPGA

## 1. Introducción

Este proyecto implementa un sistema completo de Batalla Naval de 8 × 8 sobre una FPGA Basys 3. Se integra un procesador RISC-V desarrollado en SystemVerilog, memorias de programa y datos, periféricos mapeados en memoria, comunicación UART con una aplicación de PC, entradas físicas para el Jugador 1, salida VGA y periféricos de realimentación como displays, indicadores de estado y buzzer.

La lógica principal del juego se ejecuta como un programa en ensamblador RV32I. El procesador se encarga de consultar las entradas, validar colocaciones y disparos, administrar turnos, actualizar los tableros y comunicarse con los periféricos mediante accesos lw y sw.

Cada jugador coloca tres barcos de 4, 3 y 2 casillas. El Jugador 1 interactúa directamente con la FPGA y observa el juego mediante VGA, mientras que el Jugador 2 utiliza una aplicación de consola desarrollada en Python y conectada a la FPGA mediante UART. El sistema incluye, además, un contador acumulado de victorias, indicación visual de la fase de la partida y efectos sonoros.

El desarrollo se realizó de manera modular. Cada subsistema fue probado de forma independiente antes de integrarlo, lo que permitió detectar errores en etapas tempranas y reducir la complejidad de la depuración final.

---

## 2. Arquitectura general del sistema

La arquitectura puede entenderse como tres niveles que trabajan de forma coordinada:

1. **Procesamiento:** núcleo RISC-V RV32I, ROM y RAM.
2. **Interconexión:** bus de memoria y periféricos MMIO.
3. **Interacción:** VGA, UART, entradas del Jugador 1, displays, indicadores y buzzer.

///////////////////////////////IMAGEN DEL ENUNCIADO

El núcleo RISC-V es el centro del sistema y accede tanto a la RAM como a los periféricos mediante direcciones de memoria. El interconector MMIO se encarga de dirigir cada acceso al módulo correspondiente, permitiendo que el procesador controle VGA, UART, displays y otros periféricos simplemente leyendo o escribiendo registros.

---

# 3. Fundamentación teórica

## 3.1 Procesador RISC-V RV32I uniciclo

El procesador implementado pertenece a la arquitectura RISC-V RV32I de 32 bits y utiliza una organización uniciclo. En este tipo de arquitectura, una instrucción completa su recorrido lógico dentro de un mismo ciclo de reloj. En términos generales, durante ese ciclo se obtiene la instrucción desde memoria, se decodifica, se leen los operandos, se ejecuta la operación correspondiente y, cuando aplica, se escribe el resultado.

El núcleo se dividió en dos bloques principales: datapath y unidad de control. El datapath contiene los elementos que almacenan y transforman datos; la unidad de control interpreta los campos de cada instrucción y genera las señales que determinan el comportamiento de esos bloques.

La separación entre ambos evita que la lógica de datos y la lógica de decisión queden mezcladas en un único módulo difícil de verificar.

---

## 3.2 Datapath

El datapath integra:

- Program Counter.
- Lógica de siguiente PC.
- Banco de 32 registros de 32 bits.
- Generador de inmediatos.
- ALU.
- Unidad de branches.
- Multiplexores de selección.
- Interfaces hacia memoria de programa y memoria de datos.

El Program Counter inicia en 0x0000_0000 y, en condiciones normales, avanza cuatro bytes por instrucción. Para branches y saltos se selecciona una dirección alternativa. Se implementó como un bloque independiente de la ALU. Esta decisión simplificó la verificación de las comparaciones con signo y sin signo y permitió que la ALU se mantuviera enfocada en operaciones aritméticas, lógicas y desplazamientos.

---

## 3.3 Unidad de control

La unidad de control está formada por tres módulos:

- main_decoder.sv
- alu_decoder.sv
- control_unit.sv

El main_decoder identifica el tipo general de instrucción a partir del opcode; alu_decoder utiliza opcode, funct3 y funct7[5] para elegir la operación de ALU; y control_unit integra ambos.

Entre las señales generadas se encuentran:

| Señal | Función |
|---|---|
| reg_write | Habilita escritura en el Register File. |
| alu_src_b | Selecciona rs2 o un inmediato como operando B. |
| alu_ctrl | Determina la operación de la ALU. |
| imm_src | Selecciona el formato del inmediato. |
| result_src | Selecciona la fuente de write-back. |
| mem_write | Habilita escritura en memoria. |
| branch | Identifica una instrucción de salto condicional. |
| jump | Identifica jal. |
| jalr| Identifica jalr. |

Cuando el opcode es no reconocido. En ese caso se deshabilitan escrituras a memoria y registros, así como branches y saltos. Esto evita que una instrucción inválida modifique accidentalmente el estado del sistema.

---

## 3.4 Arquitectura uniciclo y memoria

La arquitectura uniciclo requiere que las lecturas de ROM y RAM estén disponibles en el mismo ciclo. Por ello se utilizaron memorias con lectura combinacional y escritura de RAM en el flanco ascendente. Si la memoria introdujera latencia, instrucciones como lw no podrían completarse en un solo ciclo.

---

## 3.5 Memoria mapeada y MMIO

El sistema utiliza Memory-Mapped I/O (MMIO). Los periféricos ocupan regiones dentro del espacio de direcciones y son accedidos por el procesador con las mismas instrucciones empleadas para RAM.

El mapa utilizado por el sistema es:

| Destino | Dirección o rango |
|---|---|
| Program ROM | 0x0000_0000 – 0x0000_1FFF |
| Data RAM | 0x0000_2000 – 0x0000_2FFF |
| UART CONTROL/ESTADO | 0x0001_0040 |
| UART DATA_TX | 0x0001_0044 |
| UART DATA_RX | 0x0001_0048 |
| Entradas Jugador 1 | 0x0001_0120 |
| Display de 7 segmentos | 0x0001_0130 |
| Indicadores de estado | 0x0001_0138 |
| Buzzer | 0x0001_0140 |
| Video RAM | 0x0001_1000 – 0x0001_17FF |

Los accesos de datos son de 32 bits y alineados a cuatro bytes. Una dirección desalineada o fuera de las regiones implementadas no habilita escritura y produce una lectura nula.

---

## 3.6 Comunicación UART

La comunicación con la aplicación del Jugador 2 se realiza mediante UART a 115200 baudios, 8 bits de datos, sin paridad y 1 bit de parada. Para evitar que el procesador tenga que esperar a que termine cada transmisión, se utilizan FIFO de envío y recepción. El baud rate se genera a partir del reloj de 100 MHz, obteniendo aproximadamente 115741 baudios, con un error cercano al 0,47 %. Mediante los registros MMIO, el procesador puede enviar y recibir bytes, consultar disponibilidad y detectar condiciones de desbordamiento.

---

## 3.7 Sistema VGA basado en tiles

La salida gráfica utiliza una resolución de:

640 × 480 píxeles

El reloj principal de la Basys 3 es de 100 MHz. Para el subsistema VGA se genera un reloj de píxel de 25 MHz mediante la IP Clocking Wizard configurada con PLL.

Para evitar que el procesador tenga que trabajar píxel por píxel, la pantalla se organiza en tiles de:

32 × 32 píxeles

El procesador guarda en la Video RAM la información de lo que debe mostrarse en cada casilla, y el sistema VGA se encarga de convertir esa información en los colores que aparecen en pantalla. Así, el procesador no tiene que controlar cada píxel individualmente, lo que simplifica mucho el funcionamiento del sistema. 

Cada palabra de Video RAM tiene 32 bits y los tres bits menos significativos codifican el estado visual principal:

| Código | Estado | RGB |
|---|---|---|
| 000 | Agua | 0,4,F |
| 001 | Barco | 8,8,8 |
| 010 | Fallo | 0,F,F |
| 011 | Impacto | F,0,0 |
| 100 | Selección | F,F,0 |
| 101–111 | Reservado | 0,0,0 |

La Video RAM funciona además como punto de comunicación entre el dominio principal del sistema y el dominio de 25 MHz utilizado por VGA.

---

## 3.8 Entradas físicas y debounce

El Jugador 1 utiliza siete entradas lógicas:

- Arriba.
- Abajo.
- Izquierda.
- Derecha.
- SEL.
- OK.
- RST de partida.

Las entradas pasan por sincronización y debounce. Con el reloj de 100 MHz, el valor predeterminado del filtro es de aproximadamente 20 ms.

El registro de entradas combina dos tipos de información:

- **Nivel filtrado:** indica si el control continúa activo.
- **Evento pendiente:** recuerda que ocurrió una pulsación aunque el botón ya haya sido liberado.

Con el esquema W1C (Write One to Clear), el procesador limpia cada evento escribiendo un 1 en su bit correspondiente, evitando que se pierdan pulsaciones breves.

---

## 3.9 Aplicación del Jugador 2

La aplicación de PC fue desarrollada en Python y mantiene únicamente la información que el Jugador 2 tiene derecho a conocer.

Presenta:

- tablero propio;
- tablero rival conocido;
- barcos aceptados;
- impactos y fallos;
- turno actual;
- resultado de la partida.

La aplicación no decide si una colocación es válida, si un disparo acertó ni si existe una victoria. Esa responsabilidad permanece en el programa RISC-V.

La comunicación usa mensajes ASCII separados por saltos de línea. La aplicación reúne los bytes recibidos hasta completar un mensaje, lo valida y luego actualiza su estado, ya que UART puede entregar datos incompletos o varios mensajes en una misma lectura.

---

# 4. Implementación del sistema

## 4.1 Núcleo RISC-V

El núcleo RISC-V integra el datapath.sv y la control_unit.sv, conectados mediante señales definidas en riscv_pkg.sv. El datapath procesa los datos y direcciones, mientras que la unidad de control interpreta la instrucción y genera las señales necesarias. Esta separación permitió comprobar primero cada parte por separado y luego realizar la integración completa.

---

## 4.2 ROM, RAM e interconexión

memory_mmio_system reúne la ROM, la RAM y el interconector MMIO.

Los módulos principales son:

| Módulo | Función |
|---|---|
| program_rom.sv | Almacena hasta 2048 instrucciones. |
| data_ram.sv | RAM de 1024 palabras de 32 bits. |
| mmio_interconnect.sv | Decodifica direcciones y selecciona periféricos. |
| memory_mmio_system.sv | Integra ROM, RAM y bus. |

La ROM puede cargarse con el archivo hexadecimal generado a partir del firmware. Cada línea contiene una palabra de 32 bits en orden ascendente de dirección.

---

## 4.3 Firmware de Batalla Naval

La lógica de alto nivel del juego se encuentra en:

- firmware/batalla_naval.S

El ensamblador genera:

- firmware/batalla_naval.mem


que posteriormente se utiliza para inicializar la Program ROM.

La imagen documentada ocupa 4072 bytes de los 8192 bytes disponibles. El programa utiliza instrucciones de 32 bits, sin extensión comprimida, sin multiplicación o división y sin accesos lb/sb.

El firmware administra:

- inicialización;
- colocación de barcos;
- validación de posiciones;
- disparos;
- cambios de turno;
- impactos y fallos;
- detección de victoria;
- actualización de VGA;
- comunicación con el Jugador 2;
- contadores de victoria;
- estados de salida.


---

## 4.4 VGA y Video RAM

El subsistema VGA integra los módulos encargados del reloj, temporización, conversión de píxeles a tiles, memoria de video, decodificación y salida RGB. Además, utiliza una interfaz MMIO para que el procesador pueda actualizar la pantalla mediante escrituras en memoria. 

El flujo general es:

CPU → MMIO → Video RAM → Tile Decoder → RGB → Monitor

La pantalla se organiza en dos tableros de 8 × 8, uno para cada jugador, junto con una región destinada al HUD.

## 4.5 UART y aplicación de PC

El periférico UART integra los módulos de generación de baud rate, transmisión, recepción, FIFO e interfaz MMIO. El procesador intercambia datos mediante registros de 32 bits, aunque por UART se transmite un byte a la vez. En la PC, battle_client.py gestiona la comunicación serial, valida los mensajes y permite la interacción del Jugador 2 sin necesitar un segundo conjunto de controles físicos en la FPGA.

---

## 4.6 Entradas del Jugador 1

El módulo j1_inputs_peripheral.sv gestiona las siete entradas del Jugador 1 y permite consultar su estado mediante la dirección 0x0001_0120. Desde el firmware se leen las pulsaciones para realizar la navegación y las confirmaciones, mientras que el reset de partida se trata como una entrada del juego para que el programa decida qué datos conservar.

---

## 4.7 Periféricos de salida

El sistema incorpora tres salidas locales:

### Display de siete segmentos

El display de cuatro dígitos muestra las victorias acumuladas de ambos jugadores: dos dígitos para J2 y dos para J1, con valores entre 00 y 99.

### Indicadores de estado

El registro de estado selecciona una indicación distinta para:

Colocación
Batalla
Resultado final

En la integración física documentada para Basys 3, estos estados se llevan a LEDs independientes.

### Buzzer

El controlador de buzzer permite seleccionar diferentes efectos:

- impacto;
- fallo;
- barco hundido;
- colocación inválida;
- victoria.

Se realizó un circuito muy sencillo con un transistor 2N2222 y una resistencia de 1 kΩ para mejorar el sonido.

---

## 4.8 Módulo superior

La integración final se realiza mediante:

rtl/batalla_naval_top.sv

Este módulo reúne:

- CPU;
- ROM y RAM;
- MMIO;
- UART;
- entradas;
- periféricos de salida;
- Video RAM;
- VGA;
- señales físicas de la Basys 3.

El top funciona como punto de conexión. La arquitectura mantiene la lógica de juego en el firmware y la lógica especializada dentro de cada periférico.

---

# 5. Metodología de verificación

La verificación se realizó de forma progresiva, comenzando con pruebas individuales de cada módulo y avanzando luego hacia los subsistemas, las interfaces MMIO y la integración completa.

Los testbenches autoverificables comparan automáticamente los resultados obtenidos con los esperados y reportan PASS o FAIL, lo que facilita la detección de errores. En el caso del datapath también se utilizó un modelo de referencia en lockstep, permitiendo comparar ciclo a ciclo el PC, los registros y las operaciones de memoria.

Esta metodología ayudó a comprobar cada parte antes de integrarla y a identificar con mayor rapidez el origen de posibles fallas.

---

# 6. Presentación de resultados

## 6.1 Datapath

Las simulaciones se realizaron en Vivado mediante simulación de comportamiento. Cada testbench compara automáticamente los resultados obtenidos con los valores esperados y reporta PASS cuando no se encuentran errores.

### Prueba de la ALU

El testbench `tb_alu.sv` verificó las 11 operaciones implementadas en la ALU, incluyendo operaciones aritméticas, lógicas, comparaciones y desplazamientos. También se probaron valores límite y 5 000 combinaciones aleatorias por operación.

El resultado obtenido fue:

tb_alu: 55715 chequeos, 0 errores → TEST PASSED

![Resultado de la prueba de la ALU](imagenes/tb_alu.png)

---

### Prueba del generador de inmediatos

El testbench tb_imm_gen.sv comprobó la generación correcta de los inmediatos de tipo I, S, B, J y U, incluyendo valores positivos, negativos y extremos de cada formato. Para la verificación se codificaron inmediatos dentro de instrucciones y se comprobó que el módulo recuperara correctamente su valor y extensión de signo.

Resultado:

tb_imm_gen: 30014 chequeos, 0 errores → TEST PASSED

![Resultado del generador de inmediatos](imagenes/tb_imm_gen.png)

---

### Prueba del Register File

El testbench tb_reg_file.sv verificó el funcionamiento de los 32 registros del procesador, sus dos puertos de lectura y el puerto de escritura. También se comprobaron el reset, la protección del registro x0, la desactivación de escritura y el comportamiento durante una lectura y escritura del mismo registro.

Además, se ejecutaron 20 000 ciclos aleatorios contra un modelo de referencia.

Resultado:

tb_reg_file: 40199 chequeos, 0 errores → TEST PASSED

![Resultado del Register File](imagenes/tb_reg_file.png)

---

### Prueba de la unidad de branches

El testbench tb_branch_unit.sv verificó las condiciones de salto utilizadas por las instrucciones:

BEQ
BNE
BLT
BGE
BLTU
BGEU

Se probaron comparaciones con signo y sin signo, operandos iguales, valores límite y combinaciones aleatorias. Esto permitió comprobar que el datapath identifica correctamente cuándo debe realizarse un branch.

Resultado:

tb_branch_unit: 80396 chequeos, 0 errores → TEST PASSED

![Resultado de la unidad de branches](imagenes/tb_branch_unit.png)

---

### Prueba del Program Counter

El testbench tb_pc.sv comprobó el comportamiento del Program Counter y la selección de la siguiente dirección de ejecución.

Entre las condiciones verificadas se encuentran:

- Reset del PC a 0x0000_0000.
- Avance normal de PC + 4.
- Branch tomado y no tomado.
- Saltos hacia adelante y hacia atrás.
- Funcionamiento de jal.
- Funcionamiento de jalr.
- Eliminación del bit menos significativo en el destino de jalr.
- Prioridad entre las diferentes fuentes del siguiente PC.

Resultado:

tb_pc: 20067 chequeos, 0 errores → TEST PASSED

![Resultado del Program Counter](imagenes/tb_pc.png)

---

### Prueba integrada del datapath

Después de comprobar los módulos individualmente se ejecutó tb_datapath.sv, encargado de verificar el funcionamiento conjunto del datapath.

Durante esta prueba, el procesador ejecuta programas escritos con instrucciones RISC-V y su comportamiento se compara ciclo a ciclo con un modelo de referencia mediante lockstep.

En cada ciclo se comprueban:

- El Program Counter.
- Los 32 registros.
- Las operaciones de lectura y escritura de memoria.
- La dirección y los datos presentes en el bus.

La prueba incluye un programa dirigido que utiliza las instrucciones implementadas y, adicionalmente, 30 programas aleatorios de 400 instrucciones cada uno.

El resultado final fue:

tb_datapath: ~12000 ciclos verificados en lockstep

0 errores → TEST PASSED

![Resultado de la prueba integrada del datapath](imagenes/tb_datapath.png)

### Cobertura de instrucciones

El testbench integrado también genera información de cobertura para comprobar que las instrucciones implementadas hayan sido ejecutadas durante las pruebas. En el caso de los branches se verifica tanto el caso tomado como el no tomado.

La prueba se considera válida únicamente cuando las instrucciones requeridas presentan cobertura.

![Cobertura de instrucciones del datapath](imagenes/tb_datapath_cobertura.png)

---

## 6.2 Unidad de control

La unidad de control se verificó mediante testbenches autoverificables. El objetivo fue comprobar que cada instrucción genere correctamente las señales necesarias para controlar el datapath.

### Prueba del main_decoder

El módulo main_decoder.sv se encarga de interpretar el opcode de la instrucción y generar las señales generales de control.

Durante la simulación se verificó la correcta decodificación de:

- Instrucciones R-type
- Instrucciones I-type
- lw
- sw
- Branches
- jal
- jalr
- lui
- auipc
- Opcodes no válidos

El resultado obtenido fue:

Pruebas ejecutadas : 10
Errores encontrados: 0

TODOS LOS TEST PASARON - PASS

![Resultado Main Decoder 1](imagenes/main_decoder1.png)

![Resultado Main Decoder 2](imagenes/main_decoder2.png)

---

### Prueba del alu_decoder

Durante las pruebas se verificaron operaciones aritméticas, lógicas, comparaciones y desplazamientos, además de las operaciones requeridas para los accesos a memoria.

Las simulaciones permitieron comprobar que la señal alu_ctrl selecciona correctamente la operación correspondiente para cada instrucción.

![Resultado ALU Decoder 1](imagenes/alu_controller1.png)

![Resultado ALU Decoder 2](imagenes/alu_controller2.png)

![Resultado ALU Decoder 3](imagenes/alu_controller3.png)

---

### Prueba integrada de control_unit

Después de verificar los dos decodificadores por separado, se realizó la prueba integrada de control_unit.sv, donde se comprobó el funcionamiento conjunto de main_decoder y alu_decoder.

La prueba integrada contempló un total de 27 casos, incluyendo distintos tipos de instrucciones y combinaciones de los campos utilizados para la decodificación.

El resultado obtenido fue:


Pruebas ejecutadas : 27

Errores encontrados: 0

TODOS LOS TEST PASARON - PASS


![Resultado Control Unit 1](imagenes/control_unit1.png)

![Resultado Control Unit 2](imagenes/control_unit2.png)

![Resultado Control Unit 3](imagenes/control_unit3.png)

---

## 6.3 Núcleo VGA

Se verificaron la generación del reloj de píxel, la temporización VGA, la conversión de coordenadas, la Video RAM, la decodificación de los tiles, la salida RGB y finalmente el funcionamiento conjunto mediante vga_top.sv.

### Configuración del reloj VGA

La Basys 3 dispone de un reloj principal de 100 MHz, mientras que el sistema VGA requiere un reloj de píxel de 25 MHz. Para obtenerlo se utilizó la IP Clocking Wizard de Vivado configurada mediante PLL.

La configuración final permitió obtener:

- Reloj de entrada: 100 MHz.
- Reloj de salida: 25 MHz.
- Fase: 0°.
- Duty cycle: 50 %.

![Configuración del reloj de píxel](Screen_I5/3_25MHz2.png)

---

### Prueba de temporización VGA

Se comprobó el reinicio de los contadores, los cambios de línea y el recorrido completo de un frame.

![Prueba de temporización VGA](Screen_I5/tb_vga_timing.png)

---

### Prueba de la Video RAM

Se verificó el funcionamiento de la memoria utilizada para almacenar la información gráfica de los tiles.

Se realizaron escrituras y lecturas mediante sus dos puertos, comprobando que ambos pudieran trabajar de manera independiente y recuperar correctamente los datos almacenados.

![Prueba de la Video RAM](Screen_I5/tb_videoram.png)

---

### Prueba integrada de vga_top

Después de verificar los módulos individualmente, se realizó una prueba integrada mediante tb_vga_top.sv.

Esta prueba comprobó el funcionamiento conjunto de la cadena completa:
También se verificaron las operaciones de lectura y escritura sobre la memoria de video.

![Prueba integrada del núcleo VGA](Screen_I5/tb_vga_top.png)

---

### Prueba física en FPGA

Finalmente, se realizó una prueba física utilizando la FPGA Basys 3 conectada a un monitor VGA.

Para verificar la salida se generó un patrón de barras de colores. El monitor reconoció correctamente la señal y mostró una imagen estable, sin pérdida de sincronización ni desplazamientos visibles.

![Prueba física del generador VGA](Screen_I5/prueba_fisica_vga.jpeg)

## 6.4 Video RAM y renderizado

La validación del sistema de video se realizó de forma progresiva, comenzando con la interfaz MMIO y avanzando hasta comprobar el recorrido completo de los datos desde el procesador hasta la salida VGA. También se realizó una prueba física utilizando la FPGA Basys 3 y un monitor.

### Prueba de la interfaz MMIO de video

El testbench tb_video_mmio_interface.sv verifica la comunicación entre el procesador y la Video RAM mediante direcciones mapeadas en memoria.

Durante la prueba se comprobó que:

- Las direcciones dentro del rango VGA sean reconocidas correctamente.
- Las direcciones fuera del rango no generen escrituras.
- La dirección del procesador se convierta correctamente en una dirección interna de Video RAM.
- Los datos escritos por el procesador lleguen correctamente a la memoria.
- La señal video_we_o solamente se active durante una escritura válida.

![Prueba de la interfaz MMIO de video](Screen_I6/tb_video_mmio.png)

---

### Prueba del periférico de video

El testbench tb_video_peripheral.sv verifica la integración entre video_mmio_interface y el núcleo VGA.

La prueba realiza escrituras desde la interfaz del procesador y comprueba que los datos lleguen correctamente hasta la memoria de video, verificando el recorrido:

CPU → MMIO → Video RAM

El núcleo VGA permanece activo durante la simulación para comprobar que ambas partes puedan trabajar de manera conjunta.

![Prueba del periférico de video](Screen_I6/tb_video_perip.png)

---

### Prueba de distribución de pantalla

Se verifica la organización lógica de la pantalla utilizada para Batalla Naval.

Se probaron diferentes coordenadas de tile_x y tile_y para comprobar la correcta identificación de las regiones:

- Fondo.
- Tablero propio.
- Tablero rival.
- HUD.

También se verificó el cálculo de board_x y board_y para las casillas pertenecientes a los tableros de 8 × 8.

![Prueba de distribución de pantalla](Screen_I6/tb_video_lay.png)

---

### Prueba de integración de Video RAM

Se verifica el recorrido completo de una escritura desde la interfaz MMIO hasta la Video RAM.
Durante la prueba se escribieron diferentes códigos de tile en varias posiciones de memoria y posteriormente se comprobó que los valores almacenados fueran correctos.

![Prueba de integración de Video RAM](Screen_I6/tb_integracion_video.png)

---

### Prueba final de renderizado

Se verifica el recorrido completo desde una escritura realizada por el procesador hasta la generación del color correspondiente en la salida VGA.

Durante la simulación se escribieron diferentes estados de tiles y se comprobó que las señales vga_red, vga_green y vga_blue coincidieran con el color definido para cada estado.

![Prueba final de renderizado](Screen_I6/tb_renderizado_final.png)

---

### Prueba física en FPGA

Después de completar las simulaciones se realizó una validación física utilizando la FPGA Basys 3 conectada a un monitor mediante VGA.

En el monitor se verificó correctamente:

- El tablero propio de 8 × 8 casillas.
- El tablero rival de 8 × 8 casillas.
- La región destinada al HUD.
- El fondo de la pantalla.
- La cuadrícula de tiles.
- Los colores correspondientes a agua, barcos, impactos, fallos y selección.

La imagen se mantuvo estable y correctamente sincronizada, permitiendo verificar el funcionamiento del sistema de video sobre el hardware real.

![Prueba física del sistema VGA](Screen_I6/prueba_fisica_vga.jpeg)

---

## 6.5 Memoria e interconexión MMIO



## 6.6 Entradas del Jugador 1



## 6.7 UART




## 6.8 Periféricos de salida


## 6.9 Aplicación de PC


## 6.10 Integración del sistema completo

La integración dispone de tres testbenches principales:

```text
tb_integration_memory
tb_system_nominal_uart
tb_batalla_naval_system
```

Sus criterios de aceptación documentados son:

```text
PASS tb_integration_memory:
constantes ROM, protección, RAM, VGA y rangos

PASS tb_system_nominal_uart:
CPU/MMIO, transmisión FPGA y recepción desde PC a 115200 8N1

PASS tb_batalla_naval_system:
dos partidas completas, MMIO, UART, GPIO, salidas, VGA y reset
```

`tb_batalla_naval_system` está diseñado para recorrer dos partidas completas sobre el CPU RTL, incluyendo entradas físicas simuladas y tráfico UART serial.

> **Nota para la entrega final:** en los README integrados se documentan con claridad los mensajes de aceptación esperados para estos tres testbenches, pero no se adjunta en el material recibido un log final completo con las tres líneas de `PASS`. Antes de entregar el informe definitivo conviene incorporar una captura o el fragmento de consola de la última ejecución del sistema integrado. De esta forma, la sección de resultados queda respaldada por evidencia y no únicamente por el criterio esperado.

---

# 7. Análisis e interpretación de resultados

## 7.1 La verificación progresiva redujo el riesgo de integración

Los resultados muestran una estrategia consistente: primero se verificaron operaciones elementales y luego se aumentó el nivel de integración.

En el procesador, por ejemplo, no se comenzó directamente con el firmware completo. Primero se verificaron ALU, inmediatos, Register File, branches y PC. Después, el datapath completo ejecutó programas y se comparó contra un modelo de referencia. Finalmente, el procesador se conectó con memoria y periféricos.

Este orden es relevante porque un error observado en una partida completa puede tener múltiples causas. Si los bloques inferiores ya poseen pruebas fuertes, la depuración deja de ser una búsqueda abierta y puede concentrarse en contratos de interfaz, direcciones o secuencias de control.

---

## 7.2 El modelo uniciclo condicionó decisiones de memoria

Uno de los aspectos más delicados del diseño es la lectura de memoria en el mismo ciclo. La arquitectura del CPU exige que `lw` reciba el dato sin introducir ciclos adicionales.

Por esa razón, ROM y RAM se documentaron con lectura combinacional. Esta decisión es coherente con el datapath implementado y con el uso de un procesador uniciclo.

El punto no debe perderse durante una futura refactorización. Sustituir estas memorias por bloques con lectura registrada sin modificar el procesador cambiaría el comportamiento de `lw` y rompería la ejecución del firmware.

---

## 7.3 La interfaz MMIO simplificó la integración

El mapa de memoria permitió que periféricos muy distintos se presentaran al procesador bajo un mecanismo uniforme.

Desde el firmware, actualizar un display, enviar un byte, consultar un botón o cambiar un tile VGA son operaciones de memoria. La complejidad propia del periférico queda detrás de su interfaz local.

Esto también permitió desarrollar varios issues en paralelo. Mientras el contrato de direcciones, anchos y señales se mantuviera estable, cada módulo podía evolucionar sin requerir cambios en el resto del sistema.

---

## 7.4 El UART necesita desacoplar dos escalas de tiempo

El procesador trabaja a una velocidad muy superior a la transmisión serial. Las FIFO resuelven esta diferencia de escala: el CPU puede depositar o consumir bytes sin depender directamente del instante exacto en que cada bit aparece en el pin.

El baud rate calculado para hardware es aproximadamente 115741 baudios frente a 115200 en la PC, una diferencia cercana al 0,47 % según la documentación del periférico. Por sí sola, esa cifra no demuestra una integración correcta; por eso resulta importante la prueba nominal que ejecuta el sistema con los parámetros reales de hardware.

---

## 7.5 El uso de tiles fue una decisión adecuada para el video

Representar la pantalla como 300 tiles en lugar de tratar 307 200 píxeles de forma individual simplifica tanto la memoria como el firmware.

El procesador únicamente escribe el estado de una casilla. El núcleo VGA toma ese estado, identifica el tile durante el barrido y genera automáticamente el color.

La prueba física del Issue 6 es especialmente significativa porque verifica algo que una simulación funcional no puede demostrar por sí sola: que los sincronismos, la salida RGB y la organización visual son reconocidos correctamente por un monitor real.

---

## 7.6 La aplicación de PC respeta la separación de responsabilidades

La aplicación del Jugador 2 no contiene una segunda implementación de las reglas de Batalla Naval. Solo muestra la información autorizada y transmite solicitudes.

Esta separación evita dos fuentes independientes de verdad. La FPGA y el firmware determinan si una acción es válida; la PC refleja la respuesta recibida.

Además de simplificar la aplicación, esta arquitectura ayuda a evitar inconsistencias entre lo que el juego considera válido y lo que se muestra al Jugador 2.

---

## 7.7 Los resultados del datapath ofrecen una cobertura especialmente sólida

El datapath cuenta con pruebas dirigidas, decenas de miles de verificaciones, casos aleatorios, un modelo ISS en lockstep y pruebas de mutación.

La combinación es importante. Un gran número de vectores aleatorios ayuda a explorar combinaciones difíciles de anticipar; el programa dirigido garantiza que se cubran casos concretos; el lockstep compara el estado arquitectónico completo; y las mutaciones demuestran que los testbenches realmente reaccionan ante errores introducidos.

Por este motivo, la evidencia del núcleo de procesamiento es una de las partes más fuertes de la validación disponible.

---

## 7.8 Resultados de síntesis e implementación

En el material integrado se dispone de cifras concretas de síntesis para el datapath y de confirmación de síntesis correcta para el subsistema VGA.

Para el sistema completo existe además un script de implementación que genera reportes de:

- utilización;
- timing;
- DRC;
- CDC;
- interacción de relojes;
- netlist sintetizado;
- netlist temporizado;
- SDF.

Sin embargo, los README proporcionados no incluyen los valores finales globales de utilización ni los slacks finales del diseño integrado. Por esa razón, este informe no asigna cifras al sistema completo que no estén respaldadas por evidencia.

Antes de la entrega final conviene incorporar, como mínimo:

```text
Utilización total de LUT
Utilización total de FF
Utilización de BRAM
Worst Negative Slack / setup
Hold slack
Resultado DRC
```

si estos datos forman parte de los requisitos de evaluación del curso.

---

# 8. Conclusiones y aprendizaje obtenido

El proyecto permitió integrar en una sola plataforma conceptos que normalmente se estudian por separado: arquitectura de computadores, diseño digital, comunicación serial, memoria mapeada, procesamiento de entradas físicas y generación de video.

El resultado más relevante no es únicamente que cada periférico pueda funcionar de forma aislada. La arquitectura construida permite que un programa RISC-V controle el juego completo utilizando un mapa de memoria coherente y que esa información llegue finalmente a interfaces físicas muy diferentes.

La separación entre datapath y unidad de control hizo posible verificar el procesador de manera ordenada. De forma similar, la separación entre núcleo VGA, Video RAM e interfaz MMIO permitió probar primero la generación de video y después su control desde el procesador.

También quedó clara la importancia de definir interfaces antes de integrar. Direcciones MMIO, codificaciones compartidas y señales de selección funcionan como contratos entre módulos. Cuando estos contratos se mantienen, el trabajo desarrollado en issues distintos puede unirse sin reconstruir el sistema desde cero.

Otro aprendizaje importante fue la diferencia entre una simulación que “se ve bien” y una verificación realmente útil. Los testbenches autoverificables, el lockstep del datapath y las pruebas de mutación ofrecen un nivel de confianza mucho mayor que una inspección manual de formas de onda. Al mismo tiempo, las pruebas físicas de VGA demuestran que la validación en simulación debe complementarse con hardware real cuando existen interfaces externas.

Finalmente, mantener las reglas de Batalla Naval en firmware resultó una decisión coherente con la arquitectura general. El hardware se especializa en ejecutar instrucciones, almacenar información, comunicar y mostrar resultados; el programa define el comportamiento del juego. Esto hace que el sistema sea más fácil de modificar y evita convertir el módulo superior en una colección de reglas específicas difíciles de mantener.

En conjunto, el proyecto muestra una integración progresiva y modular: desde operaciones elementales de la ALU hasta una partida controlada por un procesador propio, con entrada local, comunicación con una PC y salida gráfica en un monitor.

---

# 9. Reproducción de pruebas

## 9.1 Simulación del sistema integrado en Vivado

Con el proyecto abierto:

```tcl
set_property top tb_batalla_naval_system [get_filesets sim_1]
launch_simulation
run all
```

Para ejecutar las pruebas principales mediante el script del proyecto:

```tcl
source {Integracion/scripts/run_vivado_tests.tcl}
```

El testbench del sistema completo necesita más tiempo que una simulación de `1000 ns`; debe utilizarse `run all`.

---

## 9.2 Implementación

El flujo de implementación se encuentra automatizado mediante:

```tcl
source {Integracion/scripts/implement.tcl}
```

El script ejecuta síntesis e implementación y genera los reportes necesarios para revisar recursos, timing y DRC.

---

## 9.3 Aplicación del Jugador 2

Requiere Python 3.10 o posterior.

```powershell
python -m pip install -r requirements.txt
python python\battle_client.py --port COM3
```

`COM3` debe reemplazarse por el puerto asignado a la FPGA.

---

## 9.4 Regeneración del firmware

El archivo `.mem` utilizado por la ROM ya forma parte del proyecto. Si se modifica el ensamblador:

```bash
python3 Integracion/scripts/build_firmware.py
```

El flujo documentado utiliza herramientas GNU para RISC-V con:

```text
-march=rv32i
-mabi=ilp32
```

---


