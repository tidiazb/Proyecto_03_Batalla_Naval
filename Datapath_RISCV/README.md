# Datapath del núcleo RV32I unicicloEscribir readme y subir archivos aqui, no tocar el de afuera

Este documento describe el **datapath** del microprocesador: qué bloques lo forman, sus entradas y salidas, las señales internas principales y el **contrato de señales con la unidad de control**. También resume cómo se verificó.

---

## 1. Rol del datapath dentro del núcleo

El núcleo (`riscv_core`, Figura 2 del enunciado) se divide en dos bloques:

| Bloque | Responsabilidad |
|---|---|
| **datapath** (este documento) | PC, siguiente PC, Register File, generador de inmediatos, ALU, comparación de branches, multiplexores y buses hacia las memorias. |
| **unidad de control** | Decodifica `opcode/funct3/funct7` y genera las señales de control definidas en `riscv_pkg.sv`. |

Las memorias (ROM de programa, RAM de datos) y los periféricos **no** forman parte del datapath; se conectan por los buses del núcleo.

```mermaid
flowchart LR
  ROM[(ROM programa)] -- ProgIn_i --> DP
  DP -- ProgAddress_o --> ROM
  CU[Unidad de control] -- reg_write, alu_src_b, alu_ctrl,<br/>imm_src, result_src, mem_write,<br/>branch, jump, jalr --> DP[datapath]
  ROM -- instr --> CU
  DP -- DataAddress_o / DataOut_o / we_o --> BUS[(RAM + periféricos)]
  BUS -- DataIn_i --> DP
```

### Diagrama interno

```mermaid
flowchart LR
  PC[pc_reg] -->|pc| NPC[next_pc_logic]
  PC -->|prog_addr_o| OUT1((ROM))
  INSTR((instr_i)) --> IMM[imm_gen]
  INSTR -->|rs1,rs2,rd| RF[reg_file]
  RF -->|rs1_data| ALU
  RF -->|rs2_data| MUXB{mux_2_1<br/>alu_src_b}
  IMM -->|imm_ext| MUXB
  MUXB -->|alu_b| ALU[alu]
  RF -->|rs1,rs2| BR[branch_unit]
  INSTR -->|funct3| BR
  BR -->|branch_cond| NPC
  IMM --> NPC
  ALU -->|alu_result| NPC
  NPC -->|pc_next| PC
  ALU -->|alu_result| WB{mux_4_1<br/>result_src}
  DIN((data_rdata_i)) --> WB
  NPC -->|pc_plus4 / pc_target| WB
  WB -->|wb_data| RF
  ALU -->|data_addr_o| OUT2((RAM/MMIO))
  RF -->|data_wdata_o = rs2| OUT2
```

---

## 2. Archivos

| Archivo | Contenido |
|---|---|
| `rtl/core/riscv_pkg.sv` | **Contrato** datapath ↔ control: codificaciones de `alu_ctrl`, `imm_src`, `result_src`, opcodes. |
| `rtl/core/datapath.sv` | Top del datapath (instancia todo lo siguiente). |
| `rtl/core/pc_reg.sv` | Program Counter con vector de reset. |
| `rtl/core/next_pc_logic.sv` | PC+4, PC+imm, destino de `jalr` y selección del siguiente PC. |
| `rtl/core/branch_unit.sv` | Evalúa la condición de `beq/bne/blt/bge/bltu/bgeu`. |
| `rtl/core/reg_file.sv` | Banco de 32×32 bits, x0 fijo en cero. |
| `rtl/core/alu.sv` | ALU de 32 bits. |
| `rtl/core/imm_gen.sv` | Generador de inmediatos I/S/B/J/U con extensión de signo. |
| `rtl/core/mux_2_1.sv`, `mux_4_1.sv`, `adder.sv` | Bloques genéricos. |
| `tb/core/tb_*.sv` | Testbenches autoverificables. |
| `tb/common/rv32i_enc_pkg.sv` | Funciones para escribir programas de prueba "en ensamblador" (solo simulación). |
| `tb/common/ref_control.sv` | Modelo de referencia del control (solo simulación). |
| `scripts/run_tests.sh`, `scripts/lint.sh` | Correr todas las pruebas / lint. |

Orden de compilación: ver `scripts/rtl_files.f` (el paquete va primero).

---
## 3. Interfaz del módulo `datapath`

Parámetros: `WIDTH = 32`, `RST_VECTOR = 32'h0000_0000`.

Reset: **síncrono, activo en alto** (`rst_i`). Todo el datapath usa `posedge clk_i`.

| Señal | Dir. | Ancho | Conecta con | Descripción |
|---|---|---|---|---|
| `clk_i` | in | 1 | reloj del CPU | Flanco positivo. |
| `rst_i` | in | 1 | reset | Síncrono, activo en alto. PC ← 0, registros ← 0. |
| `prog_addr_o` | out | 32 | `ProgAddress_o` | PC actual. |
| `instr_i` | in | 32 | `ProgIn_i` | Instrucción leída de la ROM (**lectura combinacional**, mismo ciclo). |
| `data_addr_o` | out | 32 | `DataAddress_o` | Dirección efectiva = `rs1 + imm` (resultado de la ALU). |
| `data_wdata_o` | out | 32 | `DataOut_o` | Dato a escribir en `sw` (= `rs2`). |
| `data_we_o` | out | 1 | `we_o` | Escritura en memoria/periférico (= `mem_write_i`). |
| `data_rdata_i` | in | 32 | `DataIn_i` | Dato leído (RAM o periférico). **Debe estar disponible en el mismo ciclo** (lectura combinacional). |
| `reg_write_i` | in | 1 | control | Escribe `rd` en el siguiente flanco. |
| `alu_src_b_i` | in | 1 | control | 0: operando B = `rs2`; 1: operando B = inmediato. |
| `alu_ctrl_i` | in | 4 | control | Operación de la ALU (tabla 4.1). |
| `imm_src_i` | in | 3 | control | Formato del inmediato (tabla 4.2). |
| `result_src_i` | in | 2 | control | Fuente del write-back (tabla 4.3). |
| `mem_write_i` | in | 1 | control | La instrucción es `sw`. |
| `branch_i` | in | 1 | control | La instrucción es un branch condicional. |
| `jump_i` | in | 1 | control | La instrucción es `jal`. |
| `jalr_i` | in | 1 | control | La instrucción es `jalr`. |
| `branch_taken_o` | out | 1 | control / depuración | `branch_i` y la condición se cumplió. |
| `alu_zero_o` | out | 1 | depuración | Resultado de la ALU = 0. |

### 3.1 Señales internas principales

| Señal | Ancho | Origen → destino | Significado |
|---|---|---|---|
| `pc` | 32 | `pc_reg` → todo | PC de la instrucción en ejecución. |
| `pc_next` | 32 | `next_pc_logic` → `pc_reg` | PC del próximo ciclo. |
| `pc_plus4` | 32 | `next_pc_logic` → mux WB | Dirección de retorno de `jal/jalr`. |
| `pc_target` | 32 | `next_pc_logic` → mux WB | `PC + imm`: destino de branch/jal, resultado de `auipc`. |
| `rs1_addr`, `rs2_addr`, `rd_addr` | 5 | `instr[19:15]`, `instr[24:20]`, `instr[11:7]` | Direcciones del Register File. |
| `funct3` | 3 | `instr[14:12]` → `branch_unit` | Tipo de branch. |
| `rs1_data`, `rs2_data` | 32 | `reg_file` | Operandos leídos. |
| `imm_ext` | 32 | `imm_gen` | Inmediato ya extendido en signo. |
| `alu_b` | 32 | mux `alu_src_b` → ALU | Segundo operando de la ALU. |
| `alu_result` | 32 | ALU | Resultado / dirección efectiva / destino jalr. |
| `branch_cond` | 1 | `branch_unit` → `next_pc_logic` | Condición del branch cumplida. |
| `wb_data` | 32 | mux `result_src` → `reg_file` | Dato que se escribe en `rd`. |

---

## 4. Contrato con la unidad de control (`riscv_pkg.sv`)

### 4.1 `alu_ctrl[3:0]`

La codificación es `{funct7[5], funct3}` de RISC-V, así el decodificador de ALU es casi directo.

| `alu_ctrl` | Operación | Resultado |
|---|---|---|
| `0000` | ADD | `a + b` |
| `1000` | SUB | `a - b` |
| `0001` | SLL | `a << b[4:0]` |
| `0010` | SLT | `($signed(a) < $signed(b)) ? 1 : 0` |
| `0011` | SLTU | `(a < b) ? 1 : 0` |
| `0100` | XOR | `a ^ b` |
| `0101` | SRL | `a >> b[4:0]` (lógico) |
| `1101` | SRA | `a >>> b[4:0]` (aritmético) |
| `0110` | OR | `a \| b` |
| `0111` | AND | `a & b` |
| `1111` | PASS_B | `b` (para `lui`) |
| otros | — | `0` |

Regla para el control:
- Tipo R: `alu_ctrl = {instr[30], instr[14:12]}`
- Tipo I aritmético: `alu_ctrl = {1'b0, instr[14:12]}`, **excepto** `funct3 = 101` (srli/srai): `{instr[30], 3'b101}`
- `lw`, `sw`, `jalr`: `ALU_ADD`. `lui`: `ALU_PASS_B`.

>  En `addi`, `slti`, etc. **no** se debe usar `instr[30]` para decidir: el bit 30 forma parte del inmediato. Solo en `srai` indica la variante aritmética.

### 4.2 `imm_src[2:0]`

| `imm_src` | Formato | Instrucciones | Inmediato |
|---|---|---|---|
| `000` | I | addi, slti, sltiu, xori, ori, andi, slli, srli, srai, lw, jalr | `{{20{i[31]}}, i[31:20]}` |
| `001` | S | sw | `{{20{i[31]}}, i[31:25], i[11:7]}` |
| `010` | B | beq, bne, blt, bge, bltu, bgeu | `{{19{i[31]}}, i[31], i[7], i[30:25], i[11:8], 0}` |
| `011` | J | jal | `{{11{i[31]}}, i[31], i[19:12], i[20], i[30:21], 0}` |
| `100` | U | lui, auipc | `{i[31:12], 12'b0}` |

### 4.3 `result_src[1:0]`

| `result_src` | Se escribe en `rd` | Instrucciones |
|---|---|---|
| `00` | `alu_result` | tipo R, tipo I, lui |
| `01` | `data_rdata_i` (DataIn) | lw |
| `10` | `PC + 4` | jal, jalr |
| `11` | `PC + imm` | auipc |

### 4.4 Selección del siguiente PC (se resuelve dentro del datapath)

| Condición (prioridad de arriba hacia abajo) | `pc_next` |
|---|---|
| `jalr_i = 1` | `(rs1 + imm) & ~1` |
| `jump_i = 1` o (`branch_i = 1` y condición cumplida) | `PC + imm` |
| resto | `PC + 4` |

El control **no** necesita conocer el resultado de la comparación: solo indica que la instrucción es un branch; el datapath decide si se toma.

### 4.5 Tabla de verdad esperada del control

| Instr. | opcode | reg_write | alu_src_b | alu_ctrl | imm_src | result_src | mem_write | branch | jump | jalr |
|---|---|---|---|---|---|---|---|---|---|---|
| tipo R | 0110011 | 1 | 0 | {f7[5],f3} | x | 00 | 0 | 0 | 0 | 0 |
| tipo I | 0010011 | 1 | 1 | {0,f3} / srai | 000 | 00 | 0 | 0 | 0 | 0 |
| lw | 0000011 | 1 | 1 | 0000 | 000 | 01 | 0 | 0 | 0 | 0 |
| sw | 0100011 | 0 | 1 | 0000 | 001 | x | 1 | 0 | 0 | 0 |
| branch | 1100011 | 0 | x | x | 010 | x | 0 | 1 | 0 | 0 |
| jal | 1101111 | 1 | x | x | 011 | 10 | 0 | 0 | 1 | 0 |
| jalr | 1100111 | 1 | 1 | 0000 | 000 | 10 | 0 | 0 | 0 | 1 |
| lui | 0110111 | 1 | 1 | 1111 | 100 | 00 | 0 | 0 | 0 | 0 |
| auipc | 0010111 | 1 | x | x | 100 | 11 | 0 | 0 | 0 | 0 |
| otro | — | 0 | 0 | 0000 | 000 | 00 | 0 | 0 | 0 | 0 |

`tb/common/ref_control.sv` implementa exactamente esta tabla y sirve como especificación ejecutable: la unidad de control real debería pasar el mismo `tb_datapath`.

**¿Por qué incluir `lui` y `auipc` si el enunciado no los lista?** Las pseudoinstrucciones del ensamblador los generan: `li` con constantes grandes → `lui + addi`, `la` y `call` → `auipc`. Sin ellos, direcciones como `0x0001_0040` (UART) o `0x0001_1000` (VGA) no se pueden cargar de forma cómoda. El costo en hardware es un código de ALU y una entrada de mux.

---
## 5. Submódulos

### 5.1 `pc_reg`
Registro de 32 bits. En `rst_i` carga `RESET_VECTOR` (0x0000_0000, vector de reset del enunciado). Sin enable: en un uniciclo el PC cambia en cada flanco.

### 5.2 `next_pc_logic`
Dos sumadores (`PC+4`, `PC+imm`) y un `mux_4_1` que implementa la tabla 4.4. Salida adicional `pc_redirect_o` = el flujo no continúa en PC+4 (útil para depuración).

### 5.3 `branch_unit`
Comparador independiente de la ALU (`==`, `<` con signo, `<` sin signo) y selección por `funct3`. `funct3` 010/011 no existen en RV32I → condición 0.

### 5.4 `reg_file`
- 2 lecturas combinacionales, 1 escritura síncrona.
- **x0 siempre en cero** con doble protección: nunca se escribe y la lectura de la dirección 0 devuelve 0.
- Reset síncrono que limpia los 32 registros (resultado determinista en simulación). Se implementa con flip-flops (≈992 FF), cantidad aceptable en una Artix-7.
- Lectura y escritura del mismo registro en el mismo ciclo devuelve el valor viejo (correcto para uniciclo).
- `sp` (x2) arranca en 0: el programa en ensamblador debe inicializarlo (p. ej. `li sp, 0x3000`, tope de la RAM).

### 5.5 `alu`
Tabla 4.1. Los desplazamientos solo usan `b[4:0]`. `SRA` se escribe como sentencia propia (`$signed(a) >>> shamt`) y **no dentro de un operador ternario**: si una rama del `?:` es sin signo, SystemVerilog convierte toda la expresión a sin signo y `>>>` se vuelve un desplazamiento lógico (ver sección 7).

### 5.6 `imm_gen`
Tabla 4.2. Recibe `instr[31:7]` (el opcode no se usa). Los shifts inmediatos usan formato I: los bits [11:5] traen `funct7`, pero la ALU solo mira `b[4:0]`.

---
## 6. Integración en el núcleo (referencia)

Conexión esperada en `riscv_core.sv` con los nombres de la Figura 2:

```systemverilog
module riscv_core (
  input  logic        clk_i, rst_i,
  output logic [31:0] ProgAddress_o,
  input  logic [31:0] ProgIn_i,
  output logic [31:0] DataAddress_o, DataOut_o,
  input  logic [31:0] DataIn_i,
  output logic        we_o
);
  logic reg_write, alu_src_b, mem_write, branch, jump, jalr;
  logic [3:0] alu_ctrl; logic [2:0] imm_src; logic [1:0] result_src;

  control_unit u_ctrl ( .instr_i(ProgIn_i), .reg_write_o(reg_write), /* ... */ );

  datapath u_dp (
    .clk_i(clk_i), .rst_i(rst_i),
    .prog_addr_o(ProgAddress_o), .instr_i(ProgIn_i),
    .data_addr_o(DataAddress_o), .data_wdata_o(DataOut_o),
    .data_we_o(we_o), .data_rdata_i(DataIn_i),
    .reg_write_i(reg_write), .alu_src_b_i(alu_src_b), .alu_ctrl_i(alu_ctrl),
    .imm_src_i(imm_src), .result_src_i(result_src), .mem_write_i(mem_write),
    .branch_i(branch), .jump_i(jump), .jalr_i(jalr),
    .branch_taken_o(), .alu_zero_o()
  );
endmodule
```

### Requisitos que el datapath impone a las memorias
Al ser **uniciclo**, `lw` lee y escribe `rd` en el mismo ciclo, por lo que:
1. `DataIn_i` debe ser **combinacional** respecto a `DataAddress_o` (RAM distribuida/LUTRAM, 1024×32 = 4 KiB para 0x2000–0x2FFF), o una BRAM con reloj invertido documentada. Una RAM con lectura registrada (1 o 2 ciclos de latencia) **rompe `lw`**.
2. `ProgIn_i` igual: ROM combinacional, o BRAM síncrona direccionada con `pc_next` (truco clásico) que habría que exponer.
3. Los periféricos de lectura (p. ej. estado de botones, UART) se leen por el mismo `DataIn_i` sin latencia; el decodificador de direcciones del bus selecciona la fuente.

### Reloj
El enunciado exige una sola entrada de 100 MHz. Un uniciclo tiene un camino crítico largo (ROM → RF → ALU → RAM → mux → RF), así que conviene alimentar el CPU con un reloj derivado del PLL (p. ej. 25 MHz, el mismo del píxel, o 50 MHz si el timing post-implementación lo permite) y confirmarlo con el reporte de timing de Vivado.

---




