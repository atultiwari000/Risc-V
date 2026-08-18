#!/usr/bin/env python3
"""Two-pass MIPS assembler for the educational subset:
    addi, add, sub, and, or, slt, lw, sw, beq, bne, j
Registers: $zero,$at,$v0-1,$a0-3,$t0-9,$s0-7,$k0-1,$gp,$sp,$fp,$ra
Output: readmemh-compatible hex (one word per line, uppercase, no 0x)."""

import argparse
import re
import sys

REG = {
    "zero": 0, "at": 1, "v0": 2, "v1": 3,
    "a0": 4, "a1": 5, "a2": 6, "a3": 7,
    "t0": 8, "t1": 9, "t2": 10, "t3": 11, "t4": 12,
    "t5": 13, "t6": 14, "t7": 15,
    "s0": 16, "s1": 17, "s2": 18, "s3": 19, "s4": 20,
    "s5": 21, "s6": 22, "s7": 23,
    "t8": 24, "t9": 25,
    "k0": 26, "k1": 27, "gp": 28, "sp": 29, "fp": 30, "ra": 31,
}

RTYPE = {"add": (0x20, 0x00), "sub": (0x22, 0x00), "and": (0x24, 0x00),
         "or": (0x25, 0x00), "slt": (0x2A, 0x00)}

OPCODE = {"addi": 0x08, "lw": 0x23, "sw": 0x2B, "beq": 0x04, "bne": 0x05}


def reg(x):
    name = x.lstrip("$").lower()
    if name not in REG:
        raise ValueError(f"unknown register ${name}")
    return REG[name]


def imm(x):
    x = x.strip().lower()
    if x.startswith("0x"):
        return int(x, 16)
    return int(x, 0)


def tokenize(line):
    line = re.split(r"[#;]", line)[0]
    line = line.strip()
    if line.startswith("//"):
        line = ""
    parts = re.split(r"[,\s()]+", line)
    return [p for p in parts if p]


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src", help="assembly input file")
    ap.add_argument("-o", dest="out", default="program.hex",
                    help="output hex file (default: program.hex)")
    ap.add_argument("--zero-fill", type=int, default=0,
                    help="pad output with zeros to this many words")
    args = ap.parse_args()

    lines = []
    with open(args.src) as f:
        for ln, raw in enumerate(f, 1):
            toks = tokenize(raw)
            if not toks:
                continue
            lines.append((ln, toks))

    labels = {}
    instrs = []

    # pass 1: gather labels, instruction list, word addresses
    pc = 0
    for ln, toks in lines:
        if toks[0].endswith(":"):
            label = toks[0][:-1]
            if label in labels:
                raise ValueError(f"{args.src}:{ln} duplicate label '{label}'")
            labels[label] = pc
            toks = toks[1:]
        if not toks:
            continue
        op = toks[0]
        if op not in RTYPE and op not in OPCODE and op != "j":
            raise ValueError(f"{args.src}:{ln} unknown instruction '{op}'")
        instrs.append((ln, pc, toks))
        pc += 4

    # pass 2: encode
    words = []
    for ln, pc, toks in instrs:
        op = toks[0]
        if op in RTYPE:
            fn, _ = RTYPE[op]
            if len(toks) != 4:
                raise ValueError(f"{args.src}:{ln} {op} needs 4 operands")
            rd, rs, rt = reg(toks[1]), reg(toks[2]), reg(toks[3])
            words.append((pc, (0 << 26) | (rs << 21) | (rt << 16)
                          | (rd << 11) | (0 << 6) | fn))
        elif op == "addi" or op == "lw" or op == "sw":
            if len(toks) != 4:
                raise ValueError(f"{args.src}:{ln} {op} needs 4 operands")
            if op == "addi":
                rt, rs = reg(toks[1]), reg(toks[2])
                off = imm(toks[3])
            else:
                rt, off, rs = reg(toks[1]), 0, reg(toks[3])
                if toks[2] in labels:
                    off = labels[toks[2]]
                else:
                    off = imm(toks[2])
            if not (-(1 << 15) <= off < (1 << 15)):
                raise ValueError(f"{args.src}:{ln} immediate out of range")
            words.append((pc, (OPCODE[op] << 26) | (rs << 21) | (rt << 16)
                          | (off & 0xFFFF)))
        elif op == "beq" or op == "bne":
            if len(toks) != 4:
                raise ValueError(f"{args.src}:{ln} {op} needs 4 operands")
            rs, rt = reg(toks[1]), reg(toks[2])
            tgt = toks[3].strip()
            if tgt in labels:
                off = (labels[tgt] - pc - 4) >> 2
            else:
                off = imm(tgt)
            if not (-(1 << 15) <= off < (1 << 15)):
                raise ValueError(f"{args.src}:{ln} branch offset out of range")
            words.append((pc, (OPCODE[op] << 26) | (rs << 21) | (rt << 16)
                          | (off & 0xFFFF)))
        elif op == "j":
            if len(toks) != 2:
                raise ValueError(f"{args.src}:{ln} j needs 1 operand")
            tgt = toks[1].strip()
            if tgt in labels:
                target = labels[tgt]
            else:
                target = imm(tgt)
                if target % 4 != 0:
                    raise ValueError(f"{args.src}:{ln} jump target not word aligned")
            words.append((pc, (2 << 26) | ((target >> 2) & 0x3FFFFFF)))
        else:
            raise ValueError(f"{args.src}:{ln} unknown instruction '{op}'")

    n = args.zero_fill
    if n <= 0:
        n = (max((w for w, _ in words), default=-4) + 4) // 4

    buf = []
    for i in range(n):
        code = dict(words).get(i * 4, 0)
        buf.append(f"{code:08X}")

    with open(args.out, "w") as f:
        f.write("\n".join(buf) + "\n")

    for w, c in words:
        print(f"{w//4:02X}  {c:08X}")


if __name__ == "__main__":
    sys.exit(main())