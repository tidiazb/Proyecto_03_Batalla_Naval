"""Terminal UART del Jugador 2. La FPGA ejecuta todas las reglas de Batalla Naval."""

from __future__ import annotations

import argparse
from dataclasses import dataclass, field
import queue
import re
import threading
from typing import Callable


BOARD_SIZE = 8
SHIP_LENGTHS = (4, 3, 2)  # Solo para dibujar una colocacion aceptada.
MAX_FRAME = 128
RESULTS = {"HIT", "MISS", "SUNK"}


class ProtocolError(ValueError):
    """Mensaje incompleto, desconocido o incompatible con el estado."""


class LineFramer:
    """Forma lineas ASCII desde lecturas seriales parciales; descarta tramas largas."""

    def __init__(self, max_length: int = MAX_FRAME) -> None:
        self.buffer = bytearray()
        self.max_length = max_length
        self.discarding = False

    def feed(self, chunk: bytes) -> tuple[list[str], list[str]]:
        lines: list[str] = []
        errors: list[str] = []
        for byte in chunk:
            if byte == 10:  # LF; CRLF tambien se acepta.
                if self.discarding:
                    self.discarding = False
                else:
                    try:
                        lines.append(self.buffer.rstrip(b"\r").decode("ascii"))
                    except UnicodeDecodeError:
                        errors.append("trama con bytes fuera de ASCII")
                self.buffer.clear()
            elif self.discarding:
                continue
            elif len(self.buffer) >= self.max_length:
                self.buffer.clear()
                self.discarding = True
                errors.append("trama demasiado larga; descartada hasta el siguiente LF")
            else:
                self.buffer.append(byte)
        return lines, errors


def coord(value: str) -> int:
    if not re.fullmatch(r"[0-7]", value):
        raise ProtocolError("coordenada fuera del rango 0..7")
    return int(value)


def parse_frame(line: str) -> tuple[str, tuple]:
    """Valida la trama completa antes de modificar el tablero."""
    parts = line.split(",")
    kind = parts[0]
    if kind in {"NEW", "BATTLE"} and len(parts) == 1:
        return kind, ()
    if kind == "TURN" and len(parts) == 2 and parts[1] in {"P1", "P2"}:
        return kind, (parts[1],)
    if kind == "PLACE" and len(parts) in {3, 4}:
        ship = parts[1]
        if ship not in {"0", "1", "2"}:
            raise ProtocolError("identificador de barco inválido")
        if len(parts) == 3 and parts[2] == "OK":
            return "PLACE_OK", (int(ship),)
        if len(parts) == 4 and parts[2] == "REJECT" and parts[3] in {
            "OVERLAP", "OUT_OF_BOUNDS", "INVALID"
        }:
            return "PLACE_REJECT", (int(ship), parts[3])
    if kind == "SHOT" and len(parts) == 5:
        row, column = coord(parts[1]), coord(parts[2])
        result, ship = parts[3], parts[4]
        if result in RESULTS and (ship == "-" or ship in {"0", "1", "2"}):
            return kind, (row, column, result, ship)
    if kind == "SHOT_REJECT" and len(parts) == 4:
        row, column = coord(parts[1]), coord(parts[2])
        if parts[3] in {"REPEAT", "NOT_TURN", "INVALID"}:
            return kind, (row, column, parts[3])
    if kind == "INCOMING" and len(parts) == 5:
        row, column = coord(parts[1]), coord(parts[2])
        if parts[3] in RESULTS and (parts[4] == "-" or parts[4] in {"0", "1", "2"}):
            return kind, (row, column, parts[3], parts[4])
    if kind == "END" and len(parts) == 6 and parts[1] in {"P1", "P2"}:
        values = parts[2:]
        if all(re.fullmatch(r"[0-9]{1,3}", n) for n in values):
            return kind, (parts[1], *(int(n) for n in values))
    if kind == "ERROR" and len(parts) == 2 and re.fullmatch(r"[A-Z_]{1,32}", parts[1]):
        return kind, (parts[1],)
    raise ProtocolError(f"trama no reconocida: {line[:60]!r}")


def parse_placement(text: str) -> tuple[int, int, str]:
    match = re.fullmatch(r"\s*([0-7])\s*,\s*([0-7])\s*,\s*([hHvV])\s*", text)
    if not match:
        raise ValueError("usa fila,columna,H/V; por ejemplo 2,3,H (filas y columnas 0..7)")
    return int(match[1]), int(match[2]), match[3].upper()


def parse_shot(text: str) -> tuple[int, int]:
    match = re.fullmatch(r"\s*([0-7])\s*,\s*([0-7])\s*", text)
    if not match:
        raise ValueError("usa fila,columna; por ejemplo 2,3 (ambas de 0..7)")
    return int(match[1]), int(match[2])


def blank_board() -> list[list[str]]:
    return [["." for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]


@dataclass
class BattleState:
    phase: str = "WAITING"
    turn: str | None = None
    own: list[list[str]] = field(default_factory=blank_board)
    rival: list[list[str]] = field(default_factory=blank_board)
    next_ship: int = 0
    pending_place: tuple[int, int, int, str] | None = None
    pending_shot: tuple[int, int] | None = None
    summary: tuple | None = None
    generation: int = 0

    def reset_for_new_game(self) -> None:
        self.phase = "PLACING"
        self.turn = None
        self.own = blank_board()
        self.rival = blank_board()
        self.next_ship = 0
        self.pending_place = None
        self.pending_shot = None
        self.summary = None
        self.generation += 1

    def wanted_prompt(self) -> tuple[str, int] | None:
        if self.phase == "PLACING" and self.next_ship < len(SHIP_LENGTHS) and self.pending_place is None:
            return "PLACE", self.next_ship
        if self.phase == "BATTLE" and self.turn == "P2" and self.pending_shot is None:
            return "FIRE", 0
        return None

    def placement_command(self, text: str) -> str:
        if self.wanted_prompt() is None or self.wanted_prompt()[0] != "PLACE":
            raise ValueError("no corresponde colocar un barco ahora")
        row, column, orientation = parse_placement(text)
        ship = self.next_ship
        self.pending_place = ship, row, column, orientation
        return f"PLACE,{ship},{row},{column},{orientation}"

    def shot_command(self, text: str) -> str:
        if self.wanted_prompt() != ("FIRE", 0):
            raise ValueError("todavía no corresponde disparar")
        row, column = parse_shot(text)
        self.pending_shot = row, column
        return f"FIRE,{row},{column}"

    def apply(self, line: str) -> str:
        kind, args = parse_frame(line)
        if kind == "NEW":
            self.reset_for_new_game()
            return "Nueva partida: coloca tus tres barcos."
        if kind == "PLACE_OK":
            ship, = args
            if self.pending_place is None or self.pending_place[0] != ship:
                raise ProtocolError("confirmación de barco no solicitado")
            _, row, column, orientation = self.pending_place
            for offset in range(SHIP_LENGTHS[ship]):
                r = row + (offset if orientation == "V" else 0)
                c = column + (offset if orientation == "H" else 0)
                if 0 <= r < BOARD_SIZE and 0 <= c < BOARD_SIZE:
                    self.own[r][c] = "B"
            self.next_ship = ship + 1
            self.pending_place = None
            return f"Barco {ship} aceptado por la FPGA."
        if kind == "PLACE_REJECT":
            ship, reason = args
            if self.pending_place is None or self.pending_place[0] != ship:
                raise ProtocolError("rechazo de barco no solicitado")
            self.pending_place = None
            return f"Barco {ship} rechazado por la FPGA: {reason}. Inténtalo de nuevo."
        if kind == "BATTLE":
            self.phase = "BATTLE"
            return "Ambas flotas están listas. Inicia la batalla."
        if kind == "TURN":
            if self.phase != "BATTLE":
                raise ProtocolError("turno recibido fuera de batalla")
            self.turn, = args
            return "Tu turno (Jugador 2)." if self.turn == "P2" else "Turno del Jugador 1."
        if kind in {"SHOT", "SHOT_REJECT"}:
            row, column = args[:2]
            if self.pending_shot != (row, column):
                raise ProtocolError("resultado de disparo no solicitado")
            self.pending_shot = None
            if kind == "SHOT_REJECT":
                if args[2] == "NOT_TURN":
                    self.turn = "P1"
                return f"Disparo rechazado por la FPGA: {args[2]}."
            result, ship = args[2:]
            self.rival[row][column] = "o" if result == "MISS" else "X"
            return f"Disparo propio ({row},{column}): {result}" + (
                f", barco {ship}." if result == "SUNK" else "."
            )
        if kind == "INCOMING":
            row, column, result, ship = args
            self.own[row][column] = "o" if result == "MISS" else "X"
            return f"Disparo recibido ({row},{column}): {result}" + (
                f", barco {ship}." if result == "SUNK" else "."
            )
        if kind == "END":
            self.phase, self.turn, self.summary = "RESULT", None, args
            winner, shots1, shots2, sunk1, sunk2 = args
            return (f"Fin: ganó {winner}. Disparos P1/P2: {shots1}/{shots2}; "
                    f"barcos hundidos P1/P2: {sunk1}/{sunk2}. Esperando una nueva partida.")
        if kind == "ERROR":
            self.pending_place = None
            self.pending_shot = None
            return f"La FPGA informó un mensaje inválido: {args[0]}. Puedes reintentar."
        raise ProtocolError("evento incompatible")

    def render(self) -> str:
        def fmt(board: list[list[str]]) -> list[str]:
            return [f"{r} " + " ".join(board[r]) for r in range(BOARD_SIZE)]
        own, rival = fmt(self.own), fmt(self.rival)
        header = "    0 1 2 3 4 5 6 7"
        rows = "\n".join(f"{a}      {b}" for a, b in zip(own, rival))
        turn = self.turn or "sin turno asignado"
        return (f"\nFase: {self.phase} | Turno: {turn}\n"
                f"Tablero propio (B=barco)    Rival conocido\n"
                f"{header}      {header}\n{rows}\n"
                "Leyenda: .=sin disparar, X=impacto, o=fallo\n")


@dataclass(frozen=True)
class Prompt:
    token: int
    generation: int
    kind: str
    ship: int


class InputWorker:
    """input() corre en otro hilo; la lectura serial sigue activa."""

    def __init__(self, ask: Callable[[str], str] = input) -> None:
        self.ask = ask
        self.requests: queue.Queue[Prompt] = queue.Queue()
        self.replies: queue.Queue[tuple[Prompt, str]] = queue.Queue()
        self.current_token = 0
        threading.Thread(target=self._run, daemon=True).start()

    def _run(self) -> None:
        while True:
            prompt = self.requests.get()
            if prompt.token != self.current_token:
                continue
            label = (f"Barco {prompt.ship} ({SHIP_LENGTHS[prompt.ship]} casillas), "
                     "fila,columna,H/V: " if prompt.kind == "PLACE" else
                     "Tu disparo, fila,columna: ")
            try:
                value = self.ask(label)
            except EOFError:
                value = ""
            self.replies.put((prompt, value))


def available_ports() -> list[str]:
    try:
        from serial.tools import list_ports
    except ImportError as exc:
        raise RuntimeError("Instala pyserial: python -m pip install -r requirements.txt") from exc
    return [port.device for port in list_ports.comports()]


def choose_port() -> str:
    ports = available_ports()
    if ports:
        print("Puertos encontrados: " + ", ".join(ports))
    return input("Puerto serial (por ejemplo COM3): ").strip()


def open_serial(port: str):
    try:
        import serial
    except ImportError as exc:
        raise RuntimeError("Instala pyserial: python -m pip install -r requirements.txt") from exc
    return serial.Serial(port=port, baudrate=115200, bytesize=serial.EIGHTBITS,
                         parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE,
                         timeout=0.05, write_timeout=2)


def run(port: str) -> None:
    state = BattleState()
    framer = LineFramer()
    worker = InputWorker()
    active: Prompt | None = None
    sequence = 0
    with open_serial(port) as link:
        print(f"Conectado a {port} (115200, 8N1). Esperando NEW de la FPGA. Ctrl+C para salir.")
        while True:
            data = link.read(64)
            lines, errors = framer.feed(data)
            for error in errors:
                print(f"[UART] {error}")
            for line in lines:
                try:
                    notice = state.apply(line)
                except ProtocolError as exc:
                    print(f"[UART] {exc}")
                    continue
                print("\n" + notice)
                print(state.render())
                if line.startswith(("NEW", "BATTLE", "TURN,", "END,")):
                    active = None  # Una entrada escrita para la fase anterior queda obsoleta.

            while True:
                try:
                    prompt, value = worker.replies.get_nowait()
                except queue.Empty:
                    break
                if active != prompt or prompt.generation != state.generation:
                    continue
                active = None
                try:
                    frame = (state.placement_command(value) if prompt.kind == "PLACE"
                             else state.shot_command(value))
                except ValueError as exc:
                    print(f"Entrada inválida: {exc}")
                    continue
                try:
                    link.write((frame + "\n").encode("ascii"))
                except Exception:
                    # El envio no se confirmó: restaura el estado para poder reintentar.
                    if prompt.kind == "PLACE":
                        state.pending_place = None
                    else:
                        state.pending_shot = None
                    raise
                print(f"Enviado: {frame}. Esperando respuesta de la FPGA.")

            wanted = state.wanted_prompt()
            if wanted is not None and active is None:
                sequence += 1
                active = Prompt(sequence, state.generation, wanted[0], wanted[1])
                worker.current_token = sequence
                worker.requests.put(active)


def main() -> None:
    parser = argparse.ArgumentParser(description="Batalla Naval: terminal del Jugador 2")
    parser.add_argument("--port", help="Puerto serial, por ejemplo COM3")
    args = parser.parse_args()
    try:
        port = args.port or choose_port()
        if not port:
            raise RuntimeError("Debes indicar un puerto serial")
        run(port)
    except KeyboardInterrupt:
        print("\nAplicación cerrada.")
    except (RuntimeError, OSError) as exc:
        parser.exit(1, f"Error: {exc}\n")


if __name__ == "__main__":
    main()
