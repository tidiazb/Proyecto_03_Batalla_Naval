# Diagrama de Tercer Nivel - Datapath RISC-V RV32I

El diagrama de tercer nivel desarrolla internamente el bloque correspondiente al Datapath del procesador RISC-V RV32I. Este subsistema contiene los elementos necesarios para ejecutar las instrucciones soportadas por el procesador, realizar operaciones aritméticas y lógicas, acceder a memoria, actualizar el Register File y determinar la siguiente dirección del Program Counter (PC).

El Datapath recibe las señales de control generadas por la Unidad de Control RISC-V y las utiliza para seleccionar los operandos, determinar la operación de la ALU, seleccionar el formato del inmediato, definir el dato que será escrito en el Register File y determinar la siguiente dirección del Program Counter.

El diseño está orientado a un procesador de 32 bits y debe permitir la ejecución de las instrucciones definidas para el subconjunto RV32I utilizado en el proyecto. El enunciado especifica buses de 32 bits para la dirección de programa, la instrucción, la dirección de datos, el dato de salida y el dato de entrada.

## Objetivo

Diseñar e implementar el Datapath de 32 bits del procesador RISC-V RV32I, proporcionando las rutas de datos necesarias para:

- Mantener y actualizar el Program Counter (PC).
- Leer operandos desde un Register File de 32 registros de 32 bits.
- Garantizar que el registro x0 permanezca permanentemente en cero.
- Generar inmediatos para los formatos de instrucción I, S, B y J.
- Ejecutar operaciones aritméticas y lógicas mediante una ALU de 32 bits.
- Realizar desplazamientos lógicos y aritméticos.
- Realizar comparaciones signed y unsigned.
- Calcular direcciones efectivas para las instrucciones de acceso a memoria.
- Evaluar las condiciones de las instrucciones de branch.
- Calcular las direcciones de destino de jal y jalr.
- Seleccionar el valor que será escrito en el Register File.
- Generar la dirección de acceso a la memoria de datos.
- Integrarse con la Unidad de Control mediante las señales de control correspondientes.

El Datapath debe mantenerse modular y sintetizable en SystemVerilog, de manera que sus submódulos puedan verificarse individualmente antes de realizar la integración completa.

## Entradas

Las principales entradas externas y señales de control del Datapath son:

- clk: reloj principal del procesador.
- rst: señal de reinicio.
- ProgIn[31:0]: instrucción proveniente de la memoria de programa.
- DataIn[31:0]: dato leído desde la memoria de datos o desde un periférico MMIO.
- RegWrite: habilita la escritura en el Register File.
- ALUSrc: selecciona el segundo operando de la ALU entre un registro y un inmediato.
- ALUControl: indica la operación que debe realizar la ALU.
- ImmSrc[1:0]: selecciona el formato del inmediato.
- ResultSrc[1:0]: selecciona el resultado que será escrito en el Register File.
- MemWrite: indica una operación de escritura hacia memoria o periféricos.
- Branch: indica que la instrucción corresponde a un branch.
- BranchType: determina el tipo de comparación utilizado por el branch.
- Jump: indica una instrucción de salto.
- Jalr: identifica el mecanismo de salto utilizado por jalr.

## Salidas

Las principales salidas del Datapath son:

- ProgAddress[31:0]: dirección de la siguiente instrucción hacia la memoria de programa.
- DataAddress[31:0]: dirección generada para acceder a memoria de datos o periféricos.
- DataOut[31:0]: dato que será escrito en memoria.
- we / MemWrite: señal de escritura hacia la interfaz de memoria.
- BranchTaken: resultado de la evaluación de una condición de branch.
- PCPlus4[31:0]: valor de PC + 4.

## Explicación general

El Datapath recibe la instrucción de 32 bits proveniente de la memoria de programa. A partir de esta instrucción se extraen los campos necesarios para acceder al Register File y generar el inmediato correspondiente.

El campo rs1 selecciona el primer registro fuente, rs2 selecciona el segundo registro fuente y rd identifica el registro destino.

El Register File proporciona dos operandos de 32 bits. El primer operando se conecta directamente a la ALU. El segundo pasa por un multiplexor controlado por ALUSrc, que permite seleccionar entre ReadData2 y el inmediato generado.

El generador de inmediatos recibe la instrucción completa y la señal ImmSrc, y genera el inmediato correspondiente a los formatos I, S, B o J.

La ALU realiza las siguientes operaciones:

- ADD
- SUB
- AND
- OR
- XOR
- SLL
- SRL
- SRA
- SLT
- SLTU

Para las instrucciones lw y sw, la dirección efectiva se obtiene mediante:


DataAddress = rs1 + inmediato


Para sw, el dato que será escrito en memoria corresponde al segundo operando del Register File:


DataOut = rs2


Para lw, el dato recibido mediante DataIn se incorpora al camino de write-back.

La actualización del Program Counter puede seguir las siguientes rutas:


PC_nuevo = PC + 4
PC_nuevo = PC + inmediato_B
PC_nuevo = PC + inmediato_J
PC_nuevo = rs1 + inmediato_I


Además, PC + 4 se utiliza como valor de retorno para las instrucciones jal y jalr.

![Multiplexor Write Back](/Planteamiento_Diseno/datapath/N3_datapath.png)
Figura adaptada/basada en: "FIGURE 4.19 The datapath of Figure 4.11 with all necessary multiplexors and all control lines identified", Patterson & Hennessy, Computer Organization and Design: RISC-V Edition.

# Diagramas de Cuarto Nivel

Los siguientes bloques corresponden a la descomposición interna de los principales elementos del Datapath definidos en el tercer nivel.

# Diagrama de Cuarto Nivel - Program Counter

## Objetivo

Diseñar el bloque secuencial encargado de almacenar la dirección actual de ejecución y proporcionar la dirección de la instrucción a la memoria de programa.

## Entradas

- clk
- rst
- PC_next[31:0]

## Salidas

- PC[31:0]
- ProgAddress[31:0]
![Multiplexor Write Back](/Planteamiento_Diseno/datapath/N4_pc_reg.png)



# Diagrama de Cuarto Nivel - Generación de PC + 4

## Objetivo

Calcular la dirección secuencial de la siguiente instrucción.

## Entrada

- PC[31:0]

## Salida

- PCPlus4[31:0]
![Multiplexor Write Back](/Planteamiento_Diseno/datapath/N4_next_pc_logic.png)



# Diagrama de Cuarto Nivel - Register File

## Objetivo

Implementar el banco de registros utilizado para almacenar los operandos y resultados de las instrucciones.

## Entradas

- clk
- rst
- rs1[4:0]
- rs2[4:0]
- rd[4:0]
- WriteData[31:0]
- RegWrite

## Salidas

- ReadData1[31:0]
- ReadData2[31:0]
- 
![Multiplexor Write Back](/Planteamiento_Diseno/datapath/N4_reg_file.png)


# Diagrama de Cuarto Nivel - Generador de Inmediatos

## Objetivo

Extraer y reconstruir los campos de inmediato de las instrucciones RISC-V y generar un valor de 32 bits con extensión de signo.

## Entradas

- instruction[31:0]
- ImmSrc[1:0]

## Salida

- ImmExt[31:0]


![Multiplexor Write Back](/Planteamiento_Diseno/datapath/N4_imm_gen.png)


# Diagrama de Cuarto Nivel - ALU

## Objetivo

Realizar las operaciones aritméticas, lógicas, de desplazamiento y comparación requeridas por el procesador.

## Entradas

-  A[31:0]
- B[31:0]
- ALUControl

## Salidas

-  ALUResult[31:0]
-  Señales de comparación utilizadas por el Datapath.

![Multiplexor Write Back](/Planteamiento_Diseno/datapath/N4_alu.png)



# Diagrama de Cuarto Nivel - Multiplexor de operandos de ALU

## Objetivo

Seleccionar el segundo operando que será utilizado por la ALU.

## Entradas

-  ReadData2[31:0]
-  ImmExt[31:0]
-  ALUSrc

## Salida

-  ALU_B[31:0]


![Multiplexor Write Back](/Planteamiento_Diseno/datapath/N4_mux_alu_b.png)



# Diagrama de Cuarto Nivel - Comparador de Branch

## Objetivo

Evaluar la condición de las instrucciones de branch y generar la señal que determina si debe modificarse el Program Counter.

## Entradas

-  ReadData1[31:0]
- ReadData2[31:0]
- Branch
- BranchType

## Salida

- BranchTaken

![Multiplexor Write Back](/Planteamiento_Diseno/datapath/N4_branch_unit.png)




# Diagrama de Cuarto Nivel - Interfaz de memoria de datos

## Objetivo

Conectar el Datapath con la memoria de datos para implementar las operaciones de lectura y escritura.

## Entradas

- ALUResult[31:0]
- ReadData2[31:0]
- DataIn[31:0]
- MemWrite

## Salidas

- DataAddress[31:0]
- DataOut[31:0]
- we

![Multiplexor Write Back](/Planteamiento_Diseno/datapath/N4_interfaz_memoria.png)




# Diagrama de Cuarto Nivel - Multiplexor de Write-Back

## Objetivo

Seleccionar el resultado que será escrito en el registro destino del Register File.

## Entradas

- ALUResult[31:0]
- DataIn[31:0]
- PCPlus4[31:0]
- ResultSrc

## Salida

- WriteData[31:0]


![Multiplexor Write Back](/Planteamiento_Diseno/datapath/N4_mux_writeback.png)

