#!/usr/bin/env bash
# Linux/WSL con Verilator y g++. Windows/Vivado: run_vivado_tests.tcl.
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build/integracion
root_dir="$PWD"
for top in tb_integration_memory tb_system_nominal_uart tb_batalla_naval_system; do
    verilator --binary --timing -Wno-fatal --top-module "$top" \
      -f Integracion/scripts/rtl_files.f Integracion/tb/vga_clock_sim.sv \
      "Integracion/tb/$top.sv" --Mdir "$root_dir/build/integracion/$top" -j 4 \
      >"build/integracion/$top.build.log" 2>&1
    (cd Integracion/firmware && "$root_dir/build/integracion/$top/V$top") \
      >"build/integracion/$top.run.log" 2>&1
    rg "PASS $top" "build/integracion/$top.run.log"
done
python3 -m unittest discover -s Aplicacion_Python/tests -v
