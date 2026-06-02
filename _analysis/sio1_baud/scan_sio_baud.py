from __future__ import annotations

import csv
import json
import struct
import sys
from pathlib import Path

SIO1_REGS = {
    0x1F801050: "data",
    0x1F801054: "stat",
    0x1F801058: "mode",
    0x1F80105A: "ctrl",
    0x1F80105E: "baud",
}

MUL = {0: 0, 1: 1, 2: 16, 3: 64}


def sign16(v: int) -> int:
    return v - 0x10000 if v & 0x8000 else v


def phys(addr: int) -> int:
    return addr & 0x1FFFFFFF


def reg_name(r: int) -> str:
    names = [
        "r0",
        "at",
        "v0",
        "v1",
        "a0",
        "a1",
        "a2",
        "a3",
        "t0",
        "t1",
        "t2",
        "t3",
        "t4",
        "t5",
        "t6",
        "t7",
        "s0",
        "s1",
        "s2",
        "s3",
        "s4",
        "s5",
        "s6",
        "s7",
        "t8",
        "t9",
        "k0",
        "k1",
        "gp",
        "sp",
        "fp",
        "ra",
    ]
    return names[r]


def exe_mapping(data: bytes) -> tuple[int | None, int]:
    if data.startswith(b"PS-X EXE") and len(data) >= 0x800:
        return struct.unpack_from("<I", data, 0x18)[0], 0x800
    return None, 0


def read_const_load(data: bytes, load_addr: int | None, file_base: int, addr: int, op: int) -> int | None:
    if load_addr is None:
        return None
    off = file_base + (addr - load_addr)
    if off < file_base or off >= len(data):
        return None
    if op == 0x23 and off + 4 <= len(data):  # lw
        return struct.unpack_from("<I", data, off)[0]
    if op in (0x21, 0x25) and off + 2 <= len(data):  # lh/lhu
        value = struct.unpack_from("<H", data, off)[0]
        return value | 0xFFFF0000 if op == 0x21 and value & 0x8000 else value
    if op in (0x20, 0x24) and off < len(data):  # lb/lbu
        value = data[off]
        return value | 0xFFFFFF00 if op == 0x20 and value & 0x80 else value
    return None


def infer_stores(data: bytes) -> list[dict]:
    load_addr, file_base = exe_mapping(data)
    const: list[int | None] = [None] * 32
    const[0] = 0
    mem_const: dict[tuple[int, int], int] = {}
    stores: list[dict] = []

    for off in range(0, len(data) - 3, 4):
        (word,) = struct.unpack_from("<I", data, off)
        op = word >> 26
        rs = (word >> 21) & 31
        rt = (word >> 16) & 31
        imm = word & 0xFFFF
        funct = word & 0x3F
        rd = (word >> 11) & 31

        if op in (0x28, 0x29, 0x2B):
            base = const[rs]
            addr = None if base is None else phys((base + sign16(imm)) & 0xFFFFFFFF)
            width = {0x28: 1, 0x29: 2, 0x2B: 4}[op]
            if addr in SIO1_REGS:
                stores.append(
                    {
                        "file_offset": off,
                        "op": {0x28: "sb", 0x29: "sh", 0x2B: "sw"}[op],
                        "reg": SIO1_REGS[addr],
                        "addr": addr,
                        "source_reg": reg_name(rt),
                        "value": const[rt],
                    }
                )
            elif addr is not None and const[rt] is not None:
                mask = {1: 0xFF, 2: 0xFFFF, 4: 0xFFFFFFFF}[width]
                mem_const[(addr, width)] = const[rt] & mask

        if op == 0x0F:  # lui
            const[rt] = (imm << 16) & 0xFFFFFFFF
        elif op == 0x0D:  # ori
            const[rt] = None if const[rs] is None else (const[rs] | imm) & 0xFFFFFFFF
        elif op in (0x08, 0x09):  # addi/addiu
            const[rt] = None if const[rs] is None else (const[rs] + sign16(imm)) & 0xFFFFFFFF
        elif op == 0x0C:  # andi
            const[rt] = None if const[rs] is None else const[rs] & imm
        elif op == 0x0E:  # xori
            const[rt] = None if const[rs] is None else (const[rs] ^ imm) & 0xFFFFFFFF
        elif op == 0 and funct in (0x21, 0x25):  # addu/or
            a, b = const[rs], const[(word >> 16) & 31]
            if a is None or b is None:
                const[rd] = None
            elif funct == 0x21:
                const[rd] = (a + b) & 0xFFFFFFFF
            else:
                const[rd] = (a | b) & 0xFFFFFFFF
        elif op in (0x20, 0x21, 0x23, 0x24, 0x25):  # loads
            base = const[rs]
            if base is None:
                const[rt] = None
            else:
                addr = (base + sign16(imm)) & 0xFFFFFFFF
                paddr = phys(addr)
                width = 4 if op == 0x23 else 2 if op in (0x21, 0x25) else 1
                if (paddr, width) in mem_const:
                    value = mem_const[(paddr, width)]
                    if op == 0x21 and value & 0x8000:
                        value |= 0xFFFF0000
                    elif op == 0x20 and value & 0x80:
                        value |= 0xFFFFFF00
                    const[rt] = value & 0xFFFFFFFF
                else:
                    const[rt] = read_const_load(data, load_addr, file_base, addr, op)
        elif op == 0 and funct not in (0x00,):
            if rd:
                const[rd] = None

        const[0] = 0

    return stores


def load_manifest(folder: Path) -> dict[str, str]:
    rows: dict[str, str] = {}
    manifest = folder / "manifest.tsv"
    if not manifest.exists():
        return rows
    with manifest.open("r", encoding="utf-8", newline="") as f:
        for row in csv.DictReader((line for line in f if not line.startswith("#")), delimiter="\t"):
            if row.get("extracted"):
                rows[row["extracted"]] = row["path"]
    return rows


def summarize(folder: Path) -> dict:
    manifest = load_manifest(folder)
    all_stores: list[dict] = []
    for path in sorted(folder.glob("*.bin")):
        try:
            data = path.read_bytes()
        except OSError:
            continue
        for store in infer_stores(data):
            store["file"] = manifest.get(path.name, path.name)
            store["dump"] = path.name
            all_stores.append(store)

    mode_values = sorted({s["value"] for s in all_stores if s["reg"] == "mode" and s["value"] is not None})
    baud_values = sorted({s["value"] for s in all_stores if s["reg"] == "baud" and s["value"] is not None})
    ctrl_values = sorted({s["value"] for s in all_stores if s["reg"] == "ctrl" and s["value"] is not None})

    nearby = []
    for m in [s for s in all_stores if s["reg"] == "mode" and s["value"] is not None]:
        for b in [s for s in all_stores if s["reg"] == "baud" and s["value"] is not None and s["dump"] == m["dump"]]:
            if abs(b["file_offset"] - m["file_offset"]) <= 256:
                low = m["value"] & 3
                mul = MUL.get(low, 0)
                nominal = b["value"] * mul if mul else 0
                nearby.append(
                    {
                        "file": m["file"],
                        "mode": m["value"],
                        "baud": b["value"],
                        "mode_low": low,
                        "mul": mul,
                        "nominal_period": nominal,
                        "fixed2x_period": nominal * 2 if nominal else 0,
                        "mode_off": m["file_offset"],
                        "baud_off": b["file_offset"],
                    }
                )

    return {
        "folder": str(folder),
        "store_count": len(all_stores),
        "mode_values": mode_values,
        "baud_values": baud_values,
        "ctrl_values": ctrl_values,
        "nearby_mode_baud": nearby,
        "stores": all_stores,
    }


def main() -> int:
    folders = [Path(arg) for arg in sys.argv[1:]]
    result = [summarize(folder) for folder in folders]
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
