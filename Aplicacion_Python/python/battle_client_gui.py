"""Batalla Naval: ventana Pygame y terminal del Jugador 2. Reglas a cargo de la FPGA.

Ejecutar: py -3.13 battle_client_gui.py
Modo original: py -3.13 battle_client_gui.py --terminal --port COM3
Dependencias: py -3.13 -m pip install pygame pyserial
"""
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


# ================= INTERFAZ PYGAME =================
class SerialWorker:
    """UART en un hilo. El estado del juego y Tkinter se actualizan en el hilo principal."""

    def __init__(self, port: str, opener=open_serial) -> None:
        self.port = port
        self.opener = opener
        self.events = queue.Queue()
        self.commands = queue.Queue()
        self.stop = threading.Event()
        self.thread = threading.Thread(target=self._run, daemon=True)
        self.thread.start()

    def _run(self) -> None:
        framer = LineFramer()
        try:
            with self.opener(self.port) as link:
                self.events.put(("CONNECTED", self.port))
                while not self.stop.is_set():
                    try:
                        frame = self.commands.get_nowait()
                    except queue.Empty:
                        frame = None
                    if frame is not None:
                        encoded = (frame + "\n").encode("ascii")
                        if link.write(encoded) != len(encoded):
                            raise OSError("No se pudo enviar la trama completa; reconecta y comienza una nueva partida.")
                    data = link.read(64)
                    lines, errors = framer.feed(data)
                    for error in errors:
                        self.events.put(("WARNING", error))
                    for line in lines:
                        self.events.put(("FRAME", line))
        except Exception as exc:
            if not self.stop.is_set():
                self.events.put(("ERROR", str(exc)))
        finally:
            self.events.put(("CLOSED", ""))


class PixelFont:
    """Fuente de mapa de bits 5x7 incluida en el programa, sin archivos externos."""

    GLYPHS = {
        "A": "01110/10001/10001/11111/10001/10001/10001",
        "B": "11110/10001/10001/11110/10001/10001/11110",
        "C": "01111/10000/10000/10000/10000/10000/01111",
        "D": "11110/10001/10001/10001/10001/10001/11110",
        "E": "11111/10000/10000/11110/10000/10000/11111",
        "F": "11111/10000/10000/11110/10000/10000/10000",
        "G": "01111/10000/10000/10111/10001/10001/01111",
        "H": "10001/10001/10001/11111/10001/10001/10001",
        "I": "11111/00100/00100/00100/00100/00100/11111",
        "J": "00111/00010/00010/00010/10010/10010/01100",
        "K": "10001/10010/10100/11000/10100/10010/10001",
        "L": "10000/10000/10000/10000/10000/10000/11111",
        "M": "10001/11011/10101/10101/10001/10001/10001",
        "N": "10001/11001/10101/10011/10001/10001/10001",
        "Ñ": "01010/10101/10001/11001/10101/10011/10001",
        "O": "01110/10001/10001/10001/10001/10001/01110",
        "P": "11110/10001/10001/11110/10000/10000/10000",
        "Q": "01110/10001/10001/10001/10101/10010/01101",
        "R": "11110/10001/10001/11110/10100/10010/10001",
        "S": "01111/10000/10000/01110/00001/00001/11110",
        "T": "11111/00100/00100/00100/00100/00100/00100",
        "U": "10001/10001/10001/10001/10001/10001/01110",
        "V": "10001/10001/10001/10001/10001/01010/00100",
        "W": "10001/10001/10001/10101/10101/10101/01010",
        "X": "10001/10001/01010/00100/01010/10001/10001",
        "Y": "10001/10001/01010/00100/00100/00100/00100",
        "Z": "11111/00001/00010/00100/01000/10000/11111",
        "0": "01110/10001/10011/10101/11001/10001/01110",
        "1": "00100/01100/00100/00100/00100/00100/01110",
        "2": "01110/10001/00001/00010/00100/01000/11111",
        "3": "11110/00001/00001/01110/00001/00001/11110",
        "4": "00010/00110/01010/10010/11111/00010/00010",
        "5": "11111/10000/10000/11110/00001/00001/11110",
        "6": "01110/10000/10000/11110/10001/10001/01110",
        "7": "11111/00001/00010/00100/01000/01000/01000",
        "8": "01110/10001/10001/01110/10001/10001/01110",
        "9": "01110/10001/10001/01111/00001/00001/01110",
        " ": "00000/00000/00000/00000/00000/00000/00000",
        ".": "00000/00000/00000/00000/00000/00110/00110",
        ",": "00000/00000/00000/00000/00110/00110/00100",
        ":": "00000/00110/00110/00000/00110/00110/00000",
        ";": "00000/00110/00110/00000/00110/00110/00100",
        "·": "00000/00000/00000/00100/00000/00000/00000",
        "-": "00000/00000/00000/11111/00000/00000/00000",
        "_": "00000/00000/00000/00000/00000/00000/11111",
        "/": "00001/00001/00010/00100/01000/10000/10000",
        "\\": "10000/10000/01000/00100/00010/00001/00001",
        "(": "00010/00100/01000/01000/01000/00100/00010",
        ")": "01000/00100/00010/00010/00010/00100/01000",
        "[": "01110/01000/01000/01000/01000/01000/01110",
        "]": "01110/00010/00010/00010/00010/00010/01110",
        "?": "01110/10001/00001/00010/00100/00000/00100",
        "!": "00100/00100/00100/00100/00100/00000/00100",
        "'": "00100/00100/00000/00000/00000/00000/00000",
        '"': "01010/01010/00000/00000/00000/00000/00000",
        "|": "00100/00100/00100/00100/00100/00100/00100",
        "+": "00000/00100/00100/11111/00100/00100/00000",
        "=": "00000/00000/11111/00000/11111/00000/00000",
        "*": "00000/10101/01110/11111/01110/10101/00000",
        "<": "00010/00100/01000/10000/01000/00100/00010",
        ">": "01000/00100/00010/00001/00010/00100/01000",
    }

    def __init__(self, pygame, scale: int) -> None:
        self.pg = pygame
        self.scale = scale
        self.cache = {}

    def normalized(self, value: str) -> str:
        import unicodedata
        # El estilo VGA usa mayúsculas; conserva Ñ y simplifica los acentos.
        value = value.upper().replace("…", "...").replace("¡", "!").replace("¿", "?")
        return "".join(char if char == "Ñ" else "".join(
            part for part in unicodedata.normalize("NFD", char)
            if not unicodedata.combining(part)) for char in value)

    def size(self, value: str) -> tuple[int, int]:
        count = len(self.normalized(value))
        return max(1, (count * 6 - 1) * self.scale), 7 * self.scale

    def render(self, value, antialias, color):
        value = self.normalized(value)
        key = value, tuple(color)
        if key not in self.cache:
            result = self.pg.Surface(self.size(value), self.pg.SRCALPHA)
            for index, char in enumerate(value):
                for row, bits in enumerate(self.GLYPHS.get(char, self.GLYPHS["?"]).split("/")):
                    for column, bit in enumerate(bits):
                        if bit == "1":
                            self.pg.draw.rect(result, color, (
                                (index * 6 + column) * self.scale, row * self.scale,
                                self.scale, self.scale))
            if len(self.cache) >= 256:
                self.cache.clear()
            self.cache[key] = result
        return self.cache[key]


class PygameWindow:
    """Dos mapas de 8x8 sobre fondo negro. La FPGA decide cada resultado."""

    SIZE = (960, 640)
    CELL = 42
    OWN_ORIGIN = (88, 150)
    RIVAL_ORIGIN = (536, 150)
    BLACK = (0, 0, 0)
    BLUE = (0, 62, 210)
    GRID = (225, 225, 235)
    SHIP = (170, 170, 184)
    HIT = (235, 30, 30)
    MISS = (25, 210, 200)
    WHITE = (245, 245, 245)
    MUTED = (170, 170, 180)
    YELLOW = (255, 225, 40)
    GREEN = (65, 225, 125)

    def __init__(self, port: str | None = None) -> None:
        import pygame
        self.pg = pygame
        # Solo vídeo y fuentes: esta interfaz no requiere dispositivos de audio.
        pygame.display.init()
        pygame.font.init()
        self.screen = pygame.display.set_mode(self.SIZE, pygame.RESIZABLE)
        pygame.display.set_caption("Batalla Naval - Jugador 2")
        self.surface = pygame.Surface(self.SIZE)
        self.clock = pygame.time.Clock()
        self.font_title = PixelFont(pygame, 4)
        self.font_label = PixelFont(pygame, 3)
        self.font = PixelFont(pygame, 2)
        self.font_small = self.font
        self.state = BattleState()
        self.transport = None
        self.connected = False
        self.running = True
        self.row = self.column = 0
        self.orientation = "H"
        self.port_text = port or "COM3"
        self.port_dialog = port is None
        self.dialog_error = ""
        self.ports = []
        self.message = "Conecta la FPGA y activa nueva partida."
        self.message_color = self.WHITE
        self.refresh_ports()
        if port:
            self.connect()
        else:
            pygame.key.start_text_input()

    def refresh_ports(self) -> None:
        try:
            self.ports = available_ports()
        except RuntimeError:
            self.dialog_error = "Instala pyserial: py -3.13 -m pip install pyserial"

    def connect(self) -> None:
        if self.transport is not None:
            self.dialog_error = "Espera a que se cierre la conexión anterior."
            return
        port = self.port_text.strip()
        if not port:
            self.dialog_error = "Escribe el puerto de tu FPGA."
            return
        self.dialog_error = ""
        self.state = BattleState()
        self.row = self.column = 0
        self.orientation = "H"
        self.transport = SerialWorker(port)
        self.port_dialog = False
        self.pg.key.stop_text_input()
        self.notice(f"Conectando a {port}…", self.YELLOW)

    def show_port_dialog(self) -> None:
        if self.transport is not None:
            self.notice("Ya hay una conexión abierta. Cierra la ventana para cambiar el puerto.", self.YELLOW)
            return
        self.port_dialog = True
        self.dialog_error = ""
        self.refresh_ports()
        self.pg.key.start_text_input()

    def notice(self, text: str, color=None) -> None:
        self.message, self.message_color = text, color or self.WHITE

    def poll_serial(self) -> None:
        transport = self.transport
        if transport is None:
            return
        for _ in range(100):
            try:
                kind, value = transport.events.get_nowait()
            except queue.Empty:
                break
            if kind == "CONNECTED":
                self.connected = True
                self.notice("Conectado. Activa nueva partida en la FPGA; esperando NEW.", self.YELLOW)
            elif kind == "FRAME":
                self.receive_frame(value)
            elif kind == "WARNING":
                self.notice("UART: " + value, self.HIT)
            elif kind == "ERROR":
                self.connected = False
                self.notice("Error UART: " + value + " · C para reconectar.", self.HIT)
            elif kind == "CLOSED":
                self.connected = False
                self.transport = None
                break

    def receive_frame(self, line: str) -> None:
        try:
            notice = self.state.apply(line)
            kind, args = parse_frame(line)
        except ProtocolError as exc:
            self.notice("UART: " + str(exc), self.HIT)
            return
        color = self.WHITE
        if kind == "NEW":
            self.row = self.column = 0
            self.orientation = "H"
            notice, color = "Nueva partida. Coloca tus barcos de 4, 3 y 2 casillas.", self.GREEN
        elif kind == "PLACE_OK":
            notice, color = f"Barco de {SHIP_LENGTHS[args[0]]} casillas confirmado.", self.GREEN
        elif kind == "PLACE_REJECT":
            reason = {"OVERLAP": "Se traslapa con otro barco.",
                      "OUT_OF_BOUNDS": "El barco se sale del mapa.",
                      "INVALID": "La posición no es válida."}[args[1]]
            notice, color = "Posición rechazada. " + reason, self.HIT
        elif kind in {"SHOT", "INCOMING"}:
            row, column, result, ship = args
            player = "Tu disparo" if kind == "SHOT" else "Disparo del enemigo"
            text = {"HIT": "Impacto", "MISS": "Fallo", "SUNK": "Barco hundido"}[result]
            notice = f"{player} ({row}, {column}): {text}."
            color = self.MISS if result == "MISS" else self.HIT
        elif kind == "SHOT_REJECT":
            reason = {"REPEAT": "Ya disparaste a esa casilla.",
                      "NOT_TURN": "Espera tu turno.", "INVALID": "Disparo inválido."}[args[2]]
            notice, color = "Disparo rechazado. " + reason, self.HIT
        elif kind == "END":
            notice = self.statistics_text()
            color = self.WHITE
        elif kind == "ERROR":
            color = self.HIT
        # TURN actualiza el indicador superior y mantiene visible el último resultado.
        if kind != "TURN":
            self.notice(notice, color)

    def wanted(self):
        return self.state.wanted_prompt() if self.connected else None

    def constrain_selection(self) -> None:
        """Mantiene el barco completo dentro del mapa durante la selección."""
        max_row = max_column = BOARD_SIZE - 1
        wanted = self.wanted()
        if wanted and wanted[0] == "PLACE":
            length = SHIP_LENGTHS[self.state.next_ship]
            if self.orientation == "V":
                max_row = BOARD_SIZE - length
            else:
                max_column = BOARD_SIZE - length
        self.row = max(0, min(max_row, self.row))
        self.column = max(0, min(max_column, self.column))

    def submit(self) -> None:
        wanted = self.wanted()
        if wanted is None or self.transport is None:
            return
        self.constrain_selection()
        try:
            frame = (self.state.placement_command(f"{self.row},{self.column},{self.orientation}")
                     if wanted[0] == "PLACE" else
                     self.state.shot_command(f"{self.row},{self.column}"))
        except ValueError as exc:
            self.notice(str(exc), self.HIT)
            return
        self.transport.commands.put(frame)
        self.notice("Esperando confirmación de la FPGA…", self.YELLOW)

    def logical_position(self, position):
        width, height = self.screen.get_size()
        scale = min(width / self.SIZE[0], height / self.SIZE[1])
        offset_x = (width - self.SIZE[0] * scale) / 2
        offset_y = (height - self.SIZE[1] * scale) / 2
        return (position[0] - offset_x) / scale, (position[1] - offset_y) / scale

    def select(self, position) -> None:
        wanted = self.wanted()
        if wanted is None:
            return
        x, y = self.logical_position(position)
        origin = self.OWN_ORIGIN if wanted[0] == "PLACE" else self.RIVAL_ORIGIN
        column, row = int((x - origin[0]) // self.CELL), int((y - origin[1]) // self.CELL)
        if 0 <= row < BOARD_SIZE and 0 <= column < BOARD_SIZE:
            self.row, self.column = row, column
            self.constrain_selection()

    def handle_event(self, event) -> None:
        pg = self.pg
        if event.type == pg.QUIT:
            self.running = False
            return
        if event.type == pg.VIDEORESIZE:
            self.screen = pg.display.set_mode((max(320, event.w), max(240, event.h)), pg.RESIZABLE)
            return
        if self.port_dialog:
            if event.type == pg.TEXTINPUT:
                # Acepta COM de Windows y rutas /dev de Linux/macOS.
                self.port_text = (self.port_text + event.text)[:100]
            elif event.type == pg.KEYDOWN:
                if event.key == pg.K_BACKSPACE:
                    self.port_text = self.port_text[:-1]
                elif event.key in (pg.K_RETURN, pg.K_KP_ENTER):
                    self.connect()
                elif event.key == pg.K_F5:
                    self.refresh_ports()
                elif event.key == pg.K_ESCAPE:
                    self.running = False
                elif event.key == pg.K_a and event.mod & pg.KMOD_CTRL:
                    self.port_text = ""
            elif event.type == pg.MOUSEBUTTONDOWN and event.button == 1:
                x, y = self.logical_position(event.pos)
                if pg.Rect(370, 322, 220, 44).collidepoint(x, y):
                    self.connect()
            return
        if event.type == pg.MOUSEBUTTONDOWN and event.button == 1:
            self.select(event.pos)
        if event.type != pg.KEYDOWN:
            return
        if event.key == pg.K_ESCAPE:
            self.running = False
        elif event.key == pg.K_c:
            self.show_port_dialog()
        wanted = self.wanted()
        if wanted is None:
            return
        moves = {pg.K_UP: (-1, 0), pg.K_DOWN: (1, 0), pg.K_LEFT: (0, -1), pg.K_RIGHT: (0, 1)}
        if event.key in moves:
            dr, dc = moves[event.key]
            self.row += dr
            self.column += dc
            self.constrain_selection()
        elif event.key == pg.K_r and wanted[0] == "PLACE":
            self.orientation = "V" if self.orientation == "H" else "H"
            self.constrain_selection()
        elif event.key in (pg.K_RETURN, pg.K_KP_ENTER):
            self.submit()

    def text(self, value, position, color=None, font=None, centered=False):
        image = (font or self.font).render(value, True, color or self.WHITE)
        rect = image.get_rect(center=position) if centered else image.get_rect(topleft=position)
        self.surface.blit(image, rect)

    def wrapped_message(self, text, y, width=900, color=None):
        # Hasta dos líneas para que los errores no salgan por el borde de la ventana.
        words = text.split()
        lines, line = [], ""
        for word in words:
            candidate = (line + " " + word).strip()
            if line and self.font_small.size(candidate)[0] > width:
                lines.append(line)
                line = word
            else:
                line = candidate
        if line:
            lines.append(line)
        for index, line in enumerate(lines[:2]):
            self.text(line, (480, y + index * 21), color=color, font=self.font_small, centered=True)

    def status(self):
        state = self.state
        if not self.connected:
            return "Sin conexión" if self.transport is None else "Conectando…", self.MUTED
        if state.phase == "WAITING":
            return "Esperando nueva partida de la FPGA", self.YELLOW
        if state.phase == "PLACING":
            if state.pending_place:
                return "Esperando confirmación del barco", self.YELLOW
            if state.next_ship < len(SHIP_LENGTHS):
                return f"Coloca tu barco de {SHIP_LENGTHS[state.next_ship]} casillas", self.WHITE
            return "Tu flota está lista. Esperando al enemigo", self.WHITE
        if state.phase == "BATTLE":
            if state.pending_shot:
                return "Esperando resultado del disparo", self.YELLOW
            if state.turn == "P2":
                return "Tu turno", self.GREEN
            return ("Turno del enemigo · Jugador 1" if state.turn == "P1" else "Esperando turno"), self.WHITE
        won = state.summary is not None and state.summary[0] == "P2"
        return ("VICTORIA · Fin del juego", self.GREEN) if won else ("DERROTA · Fin del juego", self.HIT)

    def statistics_text(self) -> str:
        # END conserva el protocolo original (los dos últimos datos son hundidos).
        # Los impactos se obtienen de las casillas confirmadas por la FPGA.
        impacts1 = sum(cell == "X" for row in self.state.own for cell in row)
        impacts2 = sum(cell == "X" for row in self.state.rival for cell in row)
        if self.state.summary is not None:
            _, shots1, shots2, _, _ = self.state.summary
        else:
            shots1 = sum(cell in {"X", "o"} for row in self.state.own for cell in row)
            shots2 = sum(cell in {"X", "o"} for row in self.state.rival for cell in row)
        return f"Disparos J1/J2: {shots1:02d}/{shots2:02d}   Impactos: {impacts1:02d}/{impacts2:02d}"

    def draw_legend(self) -> None:
        for label, x, color in (("Barco", 256, self.SHIP), ("Impacto", 464, self.HIT),
                                ("Fallo", 640, self.MISS), ("Agua", 800, (75, 180, 255))):
            self.text(label, (x, 511), color=color, centered=True)

    def cell_rect(self, origin, row, column):
        return self.pg.Rect(origin[0] + column * self.CELL, origin[1] + row * self.CELL, self.CELL, self.CELL)

    def draw_board(self, board, origin, own: bool) -> None:
        pg = self.pg
        wanted = self.wanted()
        for row in range(BOARD_SIZE):
            for column in range(BOARD_SIZE):
                color = {".": self.BLUE, "B": self.SHIP, "X": self.HIT, "o": self.MISS}[board[row][column]]
                pg.draw.rect(self.surface, color, self.cell_rect(origin, row, column))
        preview = None
        if own:
            if self.state.pending_place is not None:
                preview = self.state.pending_place
            elif wanted and wanted[0] == "PLACE":
                preview = (self.state.next_ship, self.row, self.column, self.orientation)
        if preview is not None:
            ship, row, column, orientation = preview
            for offset in range(SHIP_LENGTHS[ship]):
                r = row + (offset if orientation == "V" else 0)
                c = column + (offset if orientation == "H" else 0)
                if 0 <= r < BOARD_SIZE and 0 <= c < BOARD_SIZE:
                    # Solo vista previa: la matriz conserva '.' hasta PLACE,ship,OK.
                    pg.draw.rect(self.surface, (100, 112, 145), self.cell_rect(origin, r, c))
        # La cuadrícula se limita estrictamente al rectángulo de 8x8.
        side = BOARD_SIZE * self.CELL
        for index in range(BOARD_SIZE + 1):
            pg.draw.line(self.surface, self.GRID,
                         (origin[0] + index * self.CELL, origin[1]),
                         (origin[0] + index * self.CELL, origin[1] + side), 2)
            pg.draw.line(self.surface, self.GRID,
                         (origin[0], origin[1] + index * self.CELL),
                         (origin[0] + side, origin[1] + index * self.CELL), 2)
        selection = None
        if wanted and own == (wanted[0] == "PLACE"):
            selection = self.row, self.column
        elif not own and self.state.pending_shot is not None:
            selection = self.state.pending_shot
        if selection is not None and (pg.time.get_ticks() // 450) % 2 == 0:
            row, column = selection
            pg.draw.rect(self.surface, self.YELLOW, self.cell_rect(origin, row, column).inflate(-4, -4), 3)

    def draw(self) -> None:
        pg = self.pg
        self.surface.fill(self.BLACK)
        self.text("Jugador 2", (480, 36), font=self.font_title, centered=True)
        status, color = self.status()
        self.text(status, (480, 87), color=color, centered=True)
        self.text("NUESTRO MAPA", (256, 128), font=self.font_label, centered=True)
        self.text("MAPA ENEMIGO", (704, 128), font=self.font_label, centered=True)
        self.draw_board(self.state.own, self.OWN_ORIGIN, True)
        self.draw_board(self.state.rival, self.RIVAL_ORIGIN, False)
        wanted = self.wanted()
        if wanted:
            orientation = "Horizontal" if self.orientation == "H" else "Vertical"
            action = " · " + orientation if wanted[0] == "PLACE" else ""
            self.text(f"Fila {self.row} · Columna {self.column}{action}", (480, 511), color=self.YELLOW, centered=True)
        else:
            self.draw_legend()
        self.wrapped_message(self.message, 547, color=self.message_color)
        self.text("R: rotar   ·   Enter: Confirmar   ·   Esc: Salir",
                  (480, 600), color=self.MUTED, font=self.font_small, centered=True)
        connection = f"{self.port_text} · 115200 · 8N1" if self.connected else "C: conectar"
        self.text(connection, (480, 627), color=self.MUTED, font=self.font_small, centered=True)
        if self.port_dialog:
            cover = pg.Surface(self.SIZE, pg.SRCALPHA)
            cover.fill((0, 0, 0, 215))
            self.surface.blit(cover, (0, 0))
            pg.draw.rect(self.surface, (15, 15, 15), (190, 187, 580, 256))
            pg.draw.rect(self.surface, self.MUTED, (190, 187, 580, 256), 1)
            self.text("Conectar con la FPGA", (480, 219), font=self.font_label, centered=True)
            self.text("Puerto serial (por ejemplo COM3)", (480, 251), centered=True)
            pg.draw.rect(self.surface, self.WHITE, (300, 272, 360, 36), 1)
            shown = self.port_text[-30:] + ("|" if (pg.time.get_ticks() // 500) % 2 == 0 else "")
            self.text(shown, (310, 278))
            pg.draw.rect(self.surface, (0, 60, 145), (370, 322, 220, 44))
            self.text("Conectar / Enter", (480, 344), centered=True)
            ports = "Disponibles: " + ", ".join(self.ports) if self.ports else "F5: actualizar puertos · Ctrl+A: borrar"
            self.wrapped_message(ports, 385, width=540, color=self.MUTED)
            if self.dialog_error:
                self.wrapped_message(self.dialog_error, 417, width=540, color=self.HIT)
        # Escalado uniforme: negro alrededor y el clic conserva fila/columna.
        width, height = self.screen.get_size()
        scale = min(width / self.SIZE[0], height / self.SIZE[1])
        size = max(1, int(self.SIZE[0] * scale)), max(1, int(self.SIZE[1] * scale))
        self.screen.fill(self.BLACK)
        image = self.surface if size == self.SIZE else pg.transform.scale(self.surface, size)
        self.screen.blit(image, ((width - size[0]) // 2, (height - size[1]) // 2))
        pg.display.flip()

    def close(self) -> None:
        self.running = False
        if self.transport is not None:
            self.transport.stop.set()
            self.transport.thread.join(timeout=2.5)
        self.pg.quit()

    def run(self) -> None:
        try:
            while self.running:
                # Procesa primero las respuestas UART para no enviar una acción obsoleta.
                self.poll_serial()
                for event in self.pg.event.get():
                    self.handle_event(event)
                self.draw()
                self.clock.tick(60)
        finally:
            self.close()


def main() -> None:
    import os
    os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")
    parser = argparse.ArgumentParser(description="Batalla Naval: Pygame del Jugador 2")
    parser.add_argument("--port", help="Puerto serial, por ejemplo COM3")
    parser.add_argument("--terminal", action="store_true", help="Usa la terminal original")
    args = parser.parse_args()
    if args.terminal:
        try:
            port = args.port or choose_port()
            if not port:
                raise RuntimeError("Debes indicar un puerto serial")
            run(port)
        except KeyboardInterrupt:
            print("\nAplicación cerrada.")
        except (RuntimeError, OSError) as exc:
            parser.exit(1, f"Error: {exc}\n")
        return
    try:
        import pygame
    except ImportError:
        parser.exit(1, "Instala Pygame con: py -3.13 -m pip install pygame pyserial\n")
    try:
        PygameWindow(args.port).run()
    except pygame.error as exc:
        parser.exit(1, f"No se pudo abrir la ventana Pygame: {exc}\n")
    except KeyboardInterrupt:
        print("\nAplicación cerrada.")


if __name__ == "__main__":
    main()
