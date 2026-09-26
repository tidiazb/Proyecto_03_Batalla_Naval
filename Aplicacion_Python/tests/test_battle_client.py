import sys
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python"))
from battle_client import (BattleState, LineFramer, ProtocolError,
                           open_serial, parse_frame, parse_placement, parse_shot)


class TestFraming(unittest.TestCase):
    def test_partial_lines_and_crlf(self):
        framer = LineFramer()
        self.assertEqual(framer.feed(b"NEW\r\nTURN,P"), (["NEW"], []))
        self.assertEqual(framer.feed(b"2\n"), (["TURN,P2"], []))

    def test_bad_byte_and_long_frame_recover(self):
        framer = LineFramer(max_length=8)
        lines, errors = framer.feed(b"\xff\n" + b"A" * 20 + b"\nNEW\n")
        self.assertEqual(lines, ["NEW"])
        self.assertEqual(len(errors), 2)


class TestInputs(unittest.TestCase):
    def test_serial_configuration(self):
        fake = SimpleNamespace(EIGHTBITS=8, PARITY_NONE="N", STOPBITS_ONE=1,
                               Serial=Mock(return_value="connected"))
        with patch.dict(sys.modules, {"serial": fake}):
            self.assertEqual(open_serial("COM7"), "connected")
        fake.Serial.assert_called_once_with(
            port="COM7", baudrate=115200, bytesize=8, parity="N",
            stopbits=1, timeout=0.05, write_timeout=2,
        )

    def test_coordinates_and_orientation(self):
        self.assertEqual(parse_placement(" 2, 3, v "), (2, 3, "V"))
        self.assertEqual(parse_shot("7,0"), (7, 0))
        for invalid in ("8,0", "2,9,H", "2,3,D", "2;3;H", "", "-1,0"):
            with self.assertRaises(ValueError, msg=invalid):
                parse_placement(invalid)
        with self.assertRaises(ValueError):
            parse_shot("8,0")

    def test_invalid_uart_frame(self):
        for invalid in ("TURN,P3", "SHOT,8,0,HIT,-", "PLACE,5,OK",
                        "INCOMING,0,0,BOAT,-", "SECRET,0,0", "END,P1,-1,2,3,4"):
            with self.assertRaises(ProtocolError, msg=invalid):
                parse_frame(invalid)


class TestGamePresentation(unittest.TestCase):
    def test_full_game_and_new_game(self):
        state = BattleState()
        self.assertIsNone(state.wanted_prompt())
        state.apply("NEW")
        self.assertEqual(state.wanted_prompt(), ("PLACE", 0))

        self.assertEqual(state.placement_command("0,0,H"), "PLACE,0,0,0,H")
        self.assertIsNone(state.wanted_prompt())  # Esperar a la FPGA.
        state.apply("PLACE,0,REJECT,OVERLAP")
        self.assertEqual(state.own[0][0], ".")
        self.assertEqual(state.wanted_prompt(), ("PLACE", 0))
        state.placement_command("0,0,H")
        state.apply("PLACE,0,OK")
        self.assertEqual(state.own[0][:4], ["B"] * 4)
        self.assertEqual(state.wanted_prompt(), ("PLACE", 1))

        state.placement_command("2,2,V")
        state.apply("PLACE,1,OK")
        self.assertEqual([state.own[r][2] for r in (2, 3, 4)], ["B"] * 3)
        state.placement_command("7,6,H")  # La FPGA decide si esto es válido.
        state.apply("PLACE,2,REJECT,OUT_OF_BOUNDS")
        state.placement_command("6,5,H")
        state.apply("PLACE,2,OK")
        self.assertEqual(state.own[6][5:7], ["B", "B"])
        self.assertIsNone(state.wanted_prompt())

        state.apply("BATTLE")
        state.apply("TURN,P1")
        self.assertIsNone(state.wanted_prompt())
        state.apply("INCOMING,0,0,HIT,-")
        self.assertEqual(state.own[0][0], "X")
        state.apply("INCOMING,7,7,MISS,-")
        self.assertEqual(state.own[7][7], "o")

        state.apply("TURN,P2")
        self.assertEqual(state.shot_command("1,2"), "FIRE,1,2")
        state.apply("SHOT_REJECT,1,2,REPEAT")
        self.assertEqual(state.wanted_prompt(), ("FIRE", 0))
        state.shot_command("1,3")
        state.apply("SHOT,1,3,SUNK,2")
        self.assertEqual(state.rival[1][3], "X")
        self.assertEqual(state.rival[0][0], ".")  # No se revelan barcos rivales.

        state.apply("END,P2,15,13,2,3")
        self.assertEqual(state.summary, ("P2", 15, 13, 2, 3))
        self.assertIsNone(state.wanted_prompt())
        state.apply("NEW")
        self.assertEqual(state.own[0][0], ".")
        self.assertEqual(state.rival[1][3], ".")
        self.assertEqual(state.wanted_prompt(), ("PLACE", 0))

    def test_invalid_frames_do_not_change_board(self):
        state = BattleState()
        state.apply("NEW")
        with self.assertRaises(ProtocolError):
            state.apply("INCOMING,9,2,HIT,-")
        with self.assertRaises(ProtocolError):
            state.apply("PLACE,0,OK")
        self.assertEqual(state.own[0][0], ".")
        self.assertEqual(state.next_ship, 0)
        with self.assertRaises(ValueError):
            state.placement_command("9,0,H")
        self.assertIsNone(state.pending_place)

    def test_fpga_error_allows_retry(self):
        state = BattleState()
        state.apply("NEW")
        state.placement_command("1,1,H")
        self.assertIsNone(state.wanted_prompt())
        state.apply("ERROR,BAD_FRAME")
        self.assertEqual(state.wanted_prompt(), ("PLACE", 0))

        state.apply("BATTLE")
        state.apply("TURN,P2")
        state.shot_command("0,0")
        state.apply("SHOT_REJECT,0,0,NOT_TURN")
        self.assertEqual(state.turn, "P1")
        self.assertIsNone(state.wanted_prompt())


if __name__ == "__main__":
    unittest.main()
