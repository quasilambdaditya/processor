"""
=================================================================================================
Make .coe for Split and Unified Modes
=================================================================================================
"""

import sys
from pathlib import Path

DEPTH = 1024
HALF_DEPTH = DEPTH // 2


def read_hex_words(path: Path):
    words = []
    for lineno, line in enumerate(path.read_text().splitlines(), start=1):
        line = line.strip()
        if not line:
            continue
        if line.startswith("0x") or line.startswith("0X"):
            line = line[2:]
        if len(line) != 8:
            raise ValueError(f"{path.name}: line {lineno}: expected 8 hex digits, got '{line}'")
        try:
            int(line, 16)
        except ValueError:
            raise ValueError(f"{path.name}: line {lineno}: invalid hex number '{line}'")
        words.append(line.upper())
    return words


def write_coe(words, out_path: Path):
    header = "memory_initialization_radix=16;\n" \
             "memory_initialization_vector=\n"
    lines = []
    for i, word in enumerate(words):
        end = ";" if i == len(words) - 1 else ","
        lines.append(word + end)
    out_path.write_text(header + "\n".join(lines) + "\n")


def make_coe_dual(programA: Path, programB: Path, out_path: Path):
    wordsA = read_hex_words(programA)
    wordsB = read_hex_words(programB)

    if len(wordsA) > HALF_DEPTH:
        raise ValueError(f"Program A too large ({len(wordsA)} > {HALF_DEPTH})")
    if len(wordsB) > HALF_DEPTH:
        raise ValueError(f"Program B too large ({len(wordsB)} > {HALF_DEPTH})")

    padA = ["00000000"] * (HALF_DEPTH - len(wordsA))
    padB = ["00000000"] * (HALF_DEPTH - len(wordsB))
    memory = wordsA + padA + wordsB + padB

    write_coe(memory, out_path)


def make_coe_single(program: Path, out_path: Path):
    words = read_hex_words(program)
    write_coe(words, out_path)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    mode = int(sys.argv[1])
    if mode == 1:
        if len(sys.argv) != 4:
            print("Usage: python make_coe.py 1 input.hex output.coe")
            sys.exit(1)
        make_coe_single(Path(sys.argv[2]), Path(sys.argv[3]))
    elif mode == 0:
        if len(sys.argv) != 5:
            print("Usage: python make_coe.py 0 programA.hex programB.hex output.coe")
            sys.exit(1)
        make_coe_dual(Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[4]))
    else:
        print("Mode must be 0 or 1.")
        sys.exit(1)


if __name__ == "__main__":
    main()
