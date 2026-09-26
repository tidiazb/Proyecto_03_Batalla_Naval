#!/usr/bin/env bash
# Lint estricto (Verilator -Wall) del datapath, de cada submódulo y del núcleo.
# Detecta anchos de bus inconsistentes (WIDTH), latches (LATCH), señales sin
# usar o sin manejar, bloques combinacionales incompletos, etc.
set -u
cd "$(dirname "$0")/../.."
RTL=$(grep -v '^#' Datapath_RISCV/scripts/rtl_files.f)
CTRL="Control_RISCV/source/main_decoder.sv Control_RISCV/source/alu_decoder.sv Control_RISCV/source/control_unit.sv"
fail=0
lint() {  # $1 = top, resto = archivos
  local top=$1; shift
  if verilator --lint-only -Wall -Wno-EOFNEWLINE --top-module "$top" "$@" 2>/tmp/lint_$top.log; then
    echo "[LINT OK] $top"
  else
    echo "[LINT FAIL] $top"; cat /tmp/lint_$top.log; fail=1
  fi
}
for top in datapath alu imm_gen reg_file branch_unit next_pc_logic pc_reg mux_2_1 mux_4_1 adder; do
  lint "$top" $RTL
done
[ -f Core_RISCV/source/riscv_core.sv ] && lint riscv_core $RTL $CTRL Core_RISCV/source/riscv_core.sv
exit $fail
