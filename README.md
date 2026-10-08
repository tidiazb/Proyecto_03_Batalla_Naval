# Proyecto_03_Batalla_Naval
## Descripción de las branches del proyecto

En la siguiente tabla se presentan las branches junto con una descripción de su función dentro del sistema.

| Branch | Descripción |
|---|---|
| main | Rama principal del repositorio. |
| docs/informe-final | Documentación del informe técnico. |
| docs/planteamiento-diseno | Documentación del diseño. |
| develop | Rama de desarrollo utilizada para integrar al main. |
| feature/salidas-locales | Desarrollo y control de las salidas físicas de la FPGA, como displays de siete segmentos, LED y buzzer. |
| feature/memorias-bus | Implementación del sistema de memorias y del bus de comunicación utilizado para transferir datos entre el procesador y los periféricos. |
| feature/integracion-top | Integración de los diferentes módulos del proyecto mediante un módulo top, conectando procesador, memorias y periféricos. |
| feature/render-vga | Implementación de la lógica de renderizado para visualizar los elementos gráficos del juego en un monitor VGA. |
| feature/nucleo-vga | Desarrollo del núcleo VGA encargado de generar las señales de sincronización horizontal y vertical y controlar la salida de video. |
| feature/entradas-jugador1 | Implementación del manejo de entradas físicas del jugador 1, utilizadas para seleccionar posiciones y realizar acciones del juego. |
| feature/aplicacion-python | Desarrollo de la aplicación en Python para la interacción con el juego mediante una interfaz externa. |
| feature/uart | Implementación del módulo de comunicación UART para el intercambio serial de información entre la FPGA y dispositivos externos. |
| feature/datapath-riscv | Desarrollo del datapath del procesador RISC-V, incluyendo registros, ALU y rutas de datos necesarias para ejecutar instrucciones. |
| feature/control-riscv | Implementación de la unidad de control del procesador RISC-V, encargada de decodificar instrucciones y generar las señales de control. |
| Avance_1 | El primer avance del proyecto. |
