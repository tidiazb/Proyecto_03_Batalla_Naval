#!/usr/bin/env bash
# Corre los testbenches autoverificables del datapath y del núcleo integrado.
# Uso (desde cualquier carpeta):
#   ./Datapath_RISCV/scripts/run_tests.sh             # Icarus Verilog
#   SIM=verilator ./Datapath_RISCV/scripts/run_tests.sh
set -u
cd "$(dirname "$0")/../.."          # raíz del repositorio
RTL=$(grep -v '^#' Datapath_RISCV/scripts/rtl_files.f)
CTRL="Control_RISCV/source/main_decoder.sv Control_RISCV/source/alu_decoder.sv Control_RISCV/source/control_unit.sv"
CORE="Core_RISCV/source/riscv_core.sv"
TBC="Datapath_RISCV/sim/common/rv32i_enc_pkg.sv Datapath_RISCV/sim/common/ref_control.sv"
INC="Datapath_RISCV/sim/common"
SIM=${SIM:-iverilog}
mkdir -p build
fail=0
run() {   # $1 = top, resto = archivos
  local t=$1; shift
  local out
  if [ "$SIM" = "verilator" ]; then
    verilator --binary --timing -Wno-fatal -Wno-lint -Wno-style -I"$INC" --top-module "$t" \
      "$@" --Mdir "build/obj_$t" -o "$t" >"build/$t.build.log" 2>&1 \
      && out=$("build/obj_$t/$t" 2>&1)
  else
    iverilog -g2012 -I "$INC" -o "build/$t.vvp" "$@" 2>"build/$t.build.log" \
      && out=$(vvp -n "build/$t.vvp" 2>&1)
  fi
  if [ $? -ne 0 ] || ! echo "$out" | grep -q "TEST PASSED"; then
    echo "[FAIL] $t"; echo "$out" | tail -20; grep -i error "build/$t.build.log"; fail=1
  else
    echo "[PASS] $(echo "$out" | grep 'TEST PASSED')"
  fi
}
for t in tb_alu tb_imm_gen tb_reg_file tb_branch_unit tb_pc tb_datapath; do
  run "$t" $RTL $TBC "Datapath_RISCV/sim/$t.sv"
done
if [ -f "$CORE" ] && [ -f Control_RISCV/source/control_unit.sv ]; then
  run tb_riscv_core $RTL $CTRL $TBC "$CORE" Core_RISCV/sim/tb_riscv_core.sv
fi
exit $fail
