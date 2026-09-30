# Núcleo RISC-V RV32I uniciclo

`source/riscv_core.sv` integra la unidad de control (`../Control_RISCV`) y el datapath (`../Datapath_RISCV`). Sus puertos son exactamente los de la Figura 2 del enunciado:

| Puerto | Dir. | Descripción |
|---|---|---|
| `clk_i` | in | Reloj del CPU (flanco positivo). |
| `rst_i` | in | Reset síncrono, activo en alto. PC ← `0x0000_0000`, registros ← 0. |
| `ProgAddress_o[31:0]` | out | PC → ROM de programa. |
| `ProgIn_i[31:0]` | in | Instrucción desde la ROM (lectura combinacional). |
| `DataAddress_o[31:0]` | out | Dirección efectiva (`rs1 + imm`) → RAM y periféricos. |
| `DataOut_o[31:0]` | out | Dato a escribir (`rs2`) en `sw`. |
| `DataIn_i[31:0]` | in | Dato leído de RAM o periférico, **en el mismo ciclo**. |
| `we_o` | out | Escritura (`sw`). |

```text
                 ProgIn_i
                    |
        +-----------+------------+
        v                        v
  control_unit  --señales-->  datapath  --> ProgAddress_o, DataAddress_o,
  (opcode, funct3, funct7_5)             DataOut_o, we_o   <-- DataIn_i
```

Instrucciones soportadas: `lw, sw, add, sub, and, or, xor, sll, srl, sra, slt, sltu, addi, andi, ori, xori, slli, srli, srai, slti, sltiu, beq, bne, blt, bge, bltu, bgeu, jal, jalr, lui, auipc`.

## Requisitos para quien integre memorias y periféricos
- La ROM y la RAM deben responder **en el mismo ciclo** que la dirección, porque el núcleo es uniciclo. Una RAM con lectura registrada rompe `lw`.
- Regiones: ROM `0x0000_0000–0x0000_1FFF`, RAM `0x0000_2000–0x0000_2FFF`, periféricos `0x0001_0000–0x0001_FFFF`.
- El programa debe inicializar `sp` (por ejemplo `li sp, 0x3000`), porque tras el reset todos los registros valen 0.

## Verificación
`sim/tb_riscv_core.sv` conecta el núcleo solo por los puertos de la Figura 2 y ejecuta en lockstep contra un modelo de referencia (ISS) un programa dirigido con todas las instrucciones y 30 programas aleatorios. En cada ciclo compara el PC, los 32 registros y el bus de datos. Resultado: ≈12 000 ciclos con 0 errores, en Icarus y Verilator.

```bash
./Datapath_RISCV/scripts/run_tests.sh      # incluye tb_riscv_core
```

Detalle de las señales internas y del contrato con el control: [`../Datapath_RISCV/README.md`](../Datapath_RISCV/README.md).
