#!/usr/bin/env python3
"""Genera ELF, listado, simbolos y MEM RV32I. Requiere GNU binutils RISC-V."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess


def build(prefix: str = "riscv64-unknown-elf-") -> None:
    firmware = Path(__file__).resolve().parents[1] / "firmware"
    def run(name, *args):
        tool = shutil.which(prefix + name)
        if tool is None:
            raise RuntimeError(f"No se encuentra {prefix + name}; instala binutils RISC-V o usa --prefix")
        return subprocess.check_output([tool, *map(str, args)], text=True)
    run("as", "-march=rv32i", "-mabi=ilp32", "-o", firmware / "batalla_naval.o",
        firmware / "batalla_naval.S")
    run("ld", "-m", "elf32lriscv", "--no-relax", "-T", firmware / "link.ld",
        "-o", firmware / "batalla_naval.elf", firmware / "batalla_naval.o")
    run("objcopy", "-O", "binary", firmware / "batalla_naval.elf", firmware / "batalla_naval.bin")
    (firmware / "batalla_naval.lst").write_text(
        run("objdump", "-d", "-M", "no-aliases", firmware / "batalla_naval.elf"))
    symbols = {}
    for line in run("nm", "-n", firmware / "batalla_naval.elf").splitlines():
        fields = line.split()
        if len(fields) == 3:
            symbols[fields[2]] = int(fields[0], 16)
    (firmware / "symbols.json").write_text(json.dumps(symbols, indent=2) + "\n")
    raw = (firmware / "batalla_naval.bin").read_bytes()
    if len(raw) > 8192:
        raise RuntimeError("Programa excede 8 KiB")
    raw += bytes((-len(raw)) % 4)
    words = [int.from_bytes(raw[i:i+4], "little") for i in range(0, len(raw), 4)]
    words += [0x13] * (2048 - len(words))
    (firmware / "batalla_naval.mem").write_text("".join(f"{word:08x}\n" for word in words))
    print(f"PASS build_firmware: {len(raw)} bytes, imagen de 2048 palabras generada")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prefix", default="riscv64-unknown-elf-")
    build(parser.parse_args().prefix)
