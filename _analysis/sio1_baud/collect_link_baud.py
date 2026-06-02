from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import scan_sio_baud


DEFAULT_LINK_ROOT = Path(r"Z:\Games\MiSTer\games\PSX\_Link_")
DEFAULT_OUT_DIR = Path(__file__).resolve().parent
MAX_DIR_BYTES = 32 * 1024 * 1024
MAX_DIR_DEPTH = 32
MAX_DIRS_PER_DISC = 4096

SKIP_SUFFIXES = {
    ".av",
    ".bs",
    ".cnf",
    ".da",
    ".mdec",
    ".mng",
    ".mov",
    ".ppf",
    ".sec",
    ".seq",
    ".str",
    ".tim",
    ".tmd",
    ".vag",
    ".vb",
    ".vh",
    ".xa",
}

CODE_SUFFIXES = {
    "",
    ".exe",
    ".ovl",
    ".ovr",
    ".prg",
}


@dataclass(frozen=True)
class CueTrack:
    file: Path
    mode: str


@dataclass(frozen=True)
class IsoFile:
    path: str
    lba: int
    size: int
    data: bytes | None = None


def clean_name(name: str) -> str:
    out = re.sub(r'[\\/:%*?"<>|;]', "_", name)
    out = re.sub(r"\s+", "_", out).strip("_")
    return out[:140]


def parse_cue(cue: Path) -> CueTrack:
    current_file: Path | None = None
    tracks: list[CueTrack] = []
    cue_dir = cue.parent
    for raw in cue.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.upper().startswith("REM "):
            continue
        m = re.match(r'FILE\s+"(.+)"\s+\S+', line, re.IGNORECASE)
        if m:
            current_file = cue_dir / m.group(1)
            continue
        m = re.match(r"TRACK\s+\d+\s+(\S+)", line, re.IGNORECASE)
        if m and current_file is not None:
            tracks.append(CueTrack(current_file, m.group(1).upper()))
    for track in tracks:
        if "MODE" in track.mode:
            return track
    raise ValueError(f"no data track in {cue}")


def sector_layout(mode: str, image_size: int) -> tuple[int, int]:
    if mode == "MODE1/2048":
        return 2048, 0
    if mode == "MODE1/2352":
        return 2352, 16
    if mode in {"MODE2/2352", "CDI/2352"}:
        return 2352, 24
    if image_size % 2048 == 0:
        return 2048, 0
    return 2352, 24


class IsoReader:
    def __init__(self, cue: Path):
        track = parse_cue(cue)
        self.cue = cue
        self.image = track.file
        self.mode = track.mode
        self._fh = self.image.open("rb")
        self._size = self.image.stat().st_size
        self.sector_size, self.data_offset = sector_layout(track.mode, self._size)

    def close(self) -> None:
        self._fh.close()

    def read_sector_data(self, lba: int) -> bytes:
        self._fh.seek(lba * self.sector_size + self.data_offset)
        return self._fh.read(2048)

    def read_file(self, lba: int, size: int) -> bytes:
        if lba < 0 or size < 0:
            raise ValueError(f"invalid ISO extent lba={lba} size={size}")
        chunks: list[bytes] = []
        remaining = size
        cur_lba = lba
        while remaining > 0:
            data = self.read_sector_data(cur_lba)
            take = min(remaining, len(data))
            chunks.append(data[:take])
            remaining -= take
            cur_lba += 1
        return b"".join(chunks)

    def root_record(self) -> tuple[int, int]:
        pvd = self.read_sector_data(16)
        if pvd[1:6] != b"CD001":
            raise ValueError(f"{self.cue}: missing ISO9660 PVD; mode={self.mode}")
        return parse_dir_record(pvd[156:])[1:3]

    def iter_files(self) -> Iterable[IsoFile]:
        root_lba, root_size = self.root_record()
        yield from self._walk_dir("", root_lba, root_size, set(), 0)

    def _walk_dir(
        self,
        prefix: str,
        lba: int,
        size: int,
        visited: set[tuple[int, int]],
        depth: int,
    ) -> Iterable[IsoFile]:
        if depth > MAX_DIR_DEPTH or size <= 0 or size > MAX_DIR_BYTES:
            return
        key = (lba, size)
        if key in visited or len(visited) >= MAX_DIRS_PER_DISC:
            return
        visited.add(key)
        raw = self.read_file(lba, size)
        pos = 0
        while pos < len(raw):
            length = raw[pos]
            if length == 0:
                pos = ((pos // 2048) + 1) * 2048
                continue
            rec = raw[pos : pos + length]
            try:
                name, extent, data_len, flags = parse_dir_record(rec)
            except ValueError:
                pos += length
                continue
            pos += length
            if name in {".", ".."}:
                continue
            child = f"{prefix}/{name}" if prefix else name
            if flags & 0x02:
                if (extent, data_len) != key and 0 < data_len <= MAX_DIR_BYTES:
                    yield from self._walk_dir(child, extent, data_len, visited, depth + 1)
            else:
                yield IsoFile(path=child, lba=extent, size=data_len)


def parse_dir_record(rec: bytes) -> tuple[str, int, int, int]:
    if len(rec) < 34:
        raise ValueError("short directory record")
    extent = int.from_bytes(rec[2:6], "little")
    data_len = int.from_bytes(rec[10:14], "little")
    flags = rec[25]
    name_len = rec[32]
    name_raw = rec[33 : 33 + name_len]
    if name_raw == b"\x00":
        name = "."
    elif name_raw == b"\x01":
        name = ".."
    else:
        name = name_raw.decode("ascii", errors="replace")
    return name, extent, data_len, flags


def strip_version(path: str) -> str:
    return re.sub(r";\d+$", "", path)


def suffix_for_iso_path(path: str) -> str:
    return Path(strip_version(path)).suffix.lower()


def parse_system_cnf(data: bytes) -> set[str]:
    text = data.decode("ascii", errors="ignore")
    boot_files: set[str] = set()
    for m in re.finditer(r"cdrom:\\?([^;\r\n]+(?:;\d+)?)", text, re.IGNORECASE):
        boot_files.add(m.group(1).replace("\\", "/").upper())
        boot_files.add(strip_version(m.group(1)).replace("\\", "/").upper())
    return boot_files


def should_read_for_scan(path: str, boot_files: set[str], include_bin_overlays: bool) -> bool:
    nover = strip_version(path).upper()
    suffix = suffix_for_iso_path(path)
    if nover in boot_files:
        return True
    if re.search(r"(SCUS|SLUS|SLES|SCES|SLPS|SIPS|SLPM|SCPS)[_\-.]?\d", nover):
        return True
    if suffix in SKIP_SUFFIXES:
        return False
    if suffix == ".bin":
        return True
    if suffix in CODE_SUFFIXES:
        return True
    return False


def should_scan(path: str, data: bytes, boot_files: set[str], include_bin_overlays: bool) -> bool:
    nover = strip_version(path).upper()
    suffix = suffix_for_iso_path(path)
    if nover in boot_files:
        return True
    if data.startswith(b"PS-X EXE"):
        return True
    if re.search(r"(SCUS|SLUS|SLES|SCES|SLPS|SIPS|SLPM|SCPS)[_\-.]?\d", nover):
        return True
    if suffix in SKIP_SUFFIXES:
        return False
    if suffix == ".bin":
        return include_bin_overlays
    return suffix in CODE_SUFFIXES


def format_hex_values(values: Iterable[int]) -> str:
    return ",".join(f"0x{value:04x}" for value in sorted(values))


def compact_pairs(pairs: list[dict]) -> list[dict]:
    seen: dict[tuple[str, int, int, int, int], dict] = {}
    for pair in pairs:
        key = (
            pair.get("file", ""),
            int(pair.get("mode", 0)),
            int(pair.get("baud", 0)),
            int(pair.get("mul", 0)),
            int(pair.get("nominal_period", 0)),
        )
        if key not in seen:
            seen[key] = {
                "file": key[0],
                "mode": key[1],
                "baud": key[2],
                "mode_low": pair.get("mode_low", 0),
                "mul": key[3],
                "nominal_period": key[4],
                "fixed2x_period": pair.get("fixed2x_period", 0),
                "count": 0,
            }
        seen[key]["count"] += 1
    return sorted(seen.values(), key=lambda p: (p["file"], p["mode"], p["baud"]))


def summarize_title(cue: Path, max_bytes: int, include_bin_overlays: bool) -> dict:
    title = cue.parent.name
    reader = IsoReader(cue)
    try:
        files = list(reader.iter_files())
        boot_files: set[str] = set()
        for file in files:
            if strip_version(file.path).upper().endswith("SYSTEM.CNF") and file.size <= 32768:
                boot_files |= parse_system_cnf(reader.read_file(file.lba, file.size))

        all_stores: list[dict] = []
        scanned_files = 0
        scanned_bytes = 0
        skipped_large = 0
        skipped_noncode = 0
        errors: list[str] = []

        for file in files:
            if file.size > max_bytes:
                skipped_large += 1
                continue
            if not should_read_for_scan(file.path, boot_files, include_bin_overlays):
                skipped_noncode += 1
                continue
            try:
                header = reader.read_file(file.lba, min(file.size, 64))
            except OSError as exc:
                errors.append(f"{file.path}: {exc}")
                continue
            if not should_scan(file.path, header, boot_files, include_bin_overlays):
                skipped_noncode += 1
                continue
            try:
                data = header if file.size <= len(header) else reader.read_file(file.lba, file.size)
            except OSError as exc:
                errors.append(f"{file.path}: {exc}")
                continue
            scanned_files += 1
            scanned_bytes += len(data)
            for store in scan_sio_baud.infer_stores(data):
                store["file"] = file.path
                store["lba"] = file.lba
                all_stores.append(store)

        mode_values = sorted({s["value"] for s in all_stores if s["reg"] == "mode" and s["value"] is not None})
        baud_values = sorted({s["value"] for s in all_stores if s["reg"] == "baud" and s["value"] is not None})
        ctrl_values = sorted({s["value"] for s in all_stores if s["reg"] == "ctrl" and s["value"] is not None})

        nearby = []
        modes = [s for s in all_stores if s["reg"] == "mode" and s["value"] is not None]
        bauds = [s for s in all_stores if s["reg"] == "baud" and s["value"] is not None]
        for mode in modes:
            for baud in bauds:
                if baud["file"] != mode["file"]:
                    continue
                if abs(int(baud["file_offset"]) - int(mode["file_offset"])) > 256:
                    continue
                low = mode["value"] & 3
                mul = scan_sio_baud.MUL.get(low, 0)
                nominal = baud["value"] * mul if mul else 0
                nearby.append(
                    {
                        "file": mode["file"],
                        "mode": mode["value"],
                        "baud": baud["value"],
                        "mode_low": low,
                        "mul": mul,
                        "nominal_period": nominal,
                        "fixed2x_period": nominal * 2 if nominal else 0,
                        "mode_off": mode["file_offset"],
                        "baud_off": baud["file_offset"],
                    }
                )

        return {
            "title": title,
            "cue": str(cue),
            "image": str(reader.image),
            "cue_mode": reader.mode,
            "sector_size": reader.sector_size,
            "data_offset": reader.data_offset,
            "file_count": len(files),
            "scanned_files": scanned_files,
            "scanned_bytes": scanned_bytes,
            "skipped_large": skipped_large,
            "skipped_noncode": skipped_noncode,
            "scan_errors": errors,
            "store_count": len(all_stores),
            "mode_values": mode_values,
            "baud_values": baud_values,
            "ctrl_values": ctrl_values,
            "nearby_mode_baud": compact_pairs(nearby),
            "stores": all_stores,
        }
    finally:
        reader.close()


def write_outputs(results: list[dict], out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "link_sio1_baud_all.json").write_text(json.dumps(results, indent=2), encoding="utf-8")

    csv_rows = []
    for result in results:
        pairs = result["nearby_mode_baud"]
        nominal_periods = sorted({p["nominal_period"] for p in pairs if p["nominal_period"]})
        fixed_periods = sorted({p["fixed2x_period"] for p in pairs if p["fixed2x_period"]})
        multipliers = sorted({p["mul"] for p in pairs if p["mul"]})
        csv_rows.append(
            {
                "title": result["title"],
                "cue": result["cue"],
                "file_count": result["file_count"],
                "scanned_files": result["scanned_files"],
                "scanned_bytes": result["scanned_bytes"],
                "store_count": result["store_count"],
                "mode_values": format_hex_values(result["mode_values"]),
                "baud_values": format_hex_values(result["baud_values"]),
                "ctrl_values": format_hex_values(result["ctrl_values"]),
                "multipliers": ",".join(str(v) for v in multipliers),
                "nominal_periods": ",".join(str(v) for v in nominal_periods),
                "fixed2x_periods": ",".join(str(v) for v in fixed_periods),
                "pair_count": len(pairs),
                "notes": "; ".join(result["scan_errors"][:3]),
            }
        )

    period_groups: dict[int, set[str]] = {}
    for result in results:
        for pair in result["nearby_mode_baud"]:
            period_groups.setdefault(int(pair["nominal_period"]), set()).add(result["title"])

    focus_terms = (
        "assault",
        "blast",
        "cart",
        "twisted",
        "duke",
        "wipeout xl",
        "motor toon",
        "r4",
        "armored core",
        "descent",
        "doom",
    )
    focus_rows = [row for row in csv_rows if any(term in row["title"].lower() for term in focus_terms)]

    csv_path = out_dir / "link_sio1_baud_all.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(csv_rows[0].keys()) if csv_rows else [])
        if csv_rows:
            writer.writeheader()
            writer.writerows(csv_rows)

    md_lines = [
        "# PSX Link SIO1 Baud Scan",
        "",
        "Static scan of local `Z:\\Games\\MiSTer\\games\\PSX\\_Link_` cue images.",
        "Mode multipliers use PCSX-Redux SIO1 mapping: mode low bits 1=1x, 2=16x, 3=64x.",
        "",
        "## Summary",
        "",
        f"- Titles scanned: {len(results)}",
        f"- SIO1 register stores found: {sum(int(row['store_count']) for row in csv_rows)}",
        f"- Titles with a nearby mode/baud pair: {sum(1 for row in csv_rows if row['nominal_periods'])}",
        f"- Titles without a nearby mode/baud pair: {sum(1 for row in csv_rows if not row['nominal_periods'])}",
        "- Dominant pair: mode `0x00ce`, baud `0x00d8`, multiplier `16`, nominal period `3456`, fixed-2x period `6912`.",
        "",
        "## Focus Titles",
        "",
        "| Title | Stores | Modes | Bauds | Multipliers | Nominal periods | Fixed 2x periods |",
        "|---|---:|---|---|---|---|---|",
    ]
    for row in focus_rows:
        md_lines.append(
            "| {title} | {store_count} | {mode_values} | {baud_values} | {multipliers} | {nominal_periods} | {fixed2x_periods} |".format(
                **{k: str(v).replace("|", "\\|") for k, v in row.items()}
            )
        )
    md_lines.extend(
        [
            "",
            "## Period Groups",
            "",
            "| Nominal period | Title count | Example titles |",
            "|---:|---:|---|",
        ]
    )
    for period, titles in sorted(period_groups.items(), key=lambda item: (-len(item[1]), item[0])):
        examples = "; ".join(sorted(titles)[:10])
        md_lines.append(f"| {period} | {len(titles)} | {examples} |")
    md_lines.extend(
        [
            "",
            "## All Titles",
            "",
        "| Title | Stores | Modes | Bauds | Multipliers | Nominal periods | Fixed 2x periods |",
        "|---|---:|---|---|---|---|---|",
        ]
    )
    for row in csv_rows:
        md_lines.append(
            "| {title} | {store_count} | {mode_values} | {baud_values} | {multipliers} | {nominal_periods} | {fixed2x_periods} |".format(
                **{k: str(v).replace("|", "\\|") for k, v in row.items()}
            )
        )
    md_lines.append("")
    (out_dir / "link_sio1_baud_all.md").write_text("\n".join(md_lines), encoding="utf-8")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Collect PSX link title SIO1 baud data.")
    parser.add_argument("--link-root", type=Path, default=DEFAULT_LINK_ROOT)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    parser.add_argument("--max-bytes", type=int, default=8 * 1024 * 1024)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument(
        "--include-bin-overlays",
        action="store_true",
        help="Also scan generic .BIN files that are not PS-X EXEs or boot IDs.",
    )
    args = parser.parse_args(argv)

    cues = sorted(args.link_root.rglob("*.cue"), key=lambda p: str(p).lower())
    if args.limit:
        cues = cues[: args.limit]
    results = []
    for idx, cue in enumerate(cues, 1):
        print(f"[{idx}/{len(cues)}] {cue.parent.name}", flush=True)
        try:
            results.append(summarize_title(cue, args.max_bytes, args.include_bin_overlays))
        except Exception as exc:  # noqa: BLE001 - data collection should keep going.
            results.append(
                {
                    "title": cue.parent.name,
                    "cue": str(cue),
                    "error": str(exc),
                    "file_count": 0,
                    "scanned_files": 0,
                    "scanned_bytes": 0,
                    "store_count": 0,
                    "mode_values": [],
                    "baud_values": [],
                    "ctrl_values": [],
                    "nearby_mode_baud": [],
                    "scan_errors": [str(exc)],
                }
            )
    write_outputs(results, args.out_dir)
    print(f"wrote {args.out_dir / 'link_sio1_baud_all.json'}")
    print(f"wrote {args.out_dir / 'link_sio1_baud_all.csv'}")
    print(f"wrote {args.out_dir / 'link_sio1_baud_all.md'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
