#!/usr/bin/env python3
"""Port base16 schemes from ifraaH (github.com/orhnk/ifraaH) to Caelestia CLI format.

ifraaH themes are plain base16 (base00-base0F + name/variant metadata in YAML).
Caelestia expects much wider palettes (``<scheme>/<flavour>/<mode>.txt`` files
with space-separated ``key hex`` lines covering Material3 roles, terminal
colours and app-template aliases). This script converts every ifraaH theme into
that layout:

    schemes/<scheme>/default/dark.txt   (or light.txt)

Because plain base16 only defines 16 colours, every other role is *derived*
from base16 with a fixed, documented mapping (see ``derive_aliases``). The
mapping is intentionally mode-independent except where noted, so dark and
light themes stay readable without hand-tuning 347 palettes.

The shell itself synthesises the same fallbacks at runtime for minimal
base16-only ``scheme.json`` files (see ``services/Colours.qml``), so these
aliases are belt-and-braces for the CLI app templates
(``caelestia scheme set`` applies gtk/fuzzel/btop/... templates which reference
keys such as ``$primary``/``$surface``).

Usage:
    scripts/port-ifraah-schemes.py --src ~/src/ifraaH/themes --out schemes
"""

import argparse
import os
import re
import sys
from pathlib import Path

BASE_KEYS = [f"base{i:02X}" for i in range(16)]

HEX_RE = re.compile(r"^#?([0-9a-fA-F]{6})$")


def parse_theme(path: Path) -> tuple[str, str, dict[str, str]]:
    """Parse an ifraaH YAML theme without requiring PyYAML.

    Returns (stem, variant, palette) where palette maps baseXX -> bare hex.
    """
    stem = path.stem
    variant: str | None = None
    palette: dict[str, str] = {}
    in_palette = False
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if re.match(r"^variant\s*:", line):
            variant = line.split(":", 1)[1].strip().strip("'\"")
            continue
        if re.match(r"^palette\s*:", line):
            in_palette = True
            continue
        if in_palette:
            m = re.match(r"^(base[0-9A-F]{2})\s*:\s*[\"']?(#?[0-9a-fA-F]{6})[\"']?", line)
            if m:
                palette[m.group(1)] = m.group(2).lstrip("#").lower()
            elif re.match(r"^[a-zA-Z]", line) and not line.startswith(" "):
                in_palette = False
    if variant not in ("dark", "light"):
        raise ValueError(f"{path}: missing or invalid variant: {variant!r}")
    missing = [k for k in BASE_KEYS if k not in palette]
    if missing:
        raise ValueError(f"{path}: missing palette keys: {missing}")
    for k, v in palette.items():
        if not HEX_RE.match(v):
            raise ValueError(f"{path}: invalid hex for {k}: {v!r}")
        palette[k] = v.lower()
    return stem, variant, palette


def derive_aliases(p: dict[str, str]) -> dict[str, str]:
    """Derive the Caelestia/compat palette from plain base16.

    Canonical base16 roles:
      base00 default bg, base01 lighter bg, base02 selection bg,
      base03 comments, base04 dark fg, base05 default fg,
      base06 light fg, base07 light bg,
      base08 red, base09 orange, base0A yellow, base0B green,
      base0C cyan, base0D blue, base0E magenta, base0F brown.
    """
    b = p
    return {
        # --- surfaces (bg ramp 00 -> 01 -> 02, fg 05, dim 04/03) ---
        "background": b["base00"],
        "surface": b["base00"],
        "surfaceDim": b["base00"],
        "surfaceContainerLowest": b["base00"],
        "surfaceContainerLow": b["base01"],
        "surfaceContainer": b["base01"],
        "surfaceContainerHigh": b["base02"],
        "surfaceContainerHighest": b["base02"],
        "surfaceBright": b["base01"],
        "surfaceVariant": b["base02"],
        "onBackground": b["base05"],
        "onSurface": b["base05"],
        "onSurfaceVariant": b["base04"],
        "inverseSurface": b["base05"],
        "inverseOnSurface": b["base00"],
        "outline": b["base04"],
        "outlineVariant": b["base02"],
        "shadow": "000000",
        "scrim": "000000",
        # --- accents: blue primary, cyan secondary, magenta tertiary ---
        "surfaceTint": b["base0D"],
        "primary": b["base0D"],
        "onPrimary": b["base00"],
        "primaryContainer": b["base0D"],
        "onPrimaryContainer": b["base00"],
        "inversePrimary": b["base0D"],
        "secondary": b["base0C"],
        "onSecondary": b["base00"],
        "secondaryContainer": b["base0C"],
        "onSecondaryContainer": b["base00"],
        "tertiary": b["base0E"],
        "onTertiary": b["base00"],
        "tertiaryContainer": b["base0E"],
        "onTertiaryContainer": b["base00"],
        "primary_paletteKeyColor": b["base0D"],
        "secondary_paletteKeyColor": b["base0C"],
        "tertiary_paletteKeyColor": b["base0E"],
        "neutral_paletteKeyColor": b["base05"],
        "neutral_variant_paletteKeyColor": b["base04"],
        "primaryFixed": b["base0D"],
        "primaryFixedDim": b["base0D"],
        "onPrimaryFixed": b["base00"],
        "onPrimaryFixedVariant": b["base03"],
        "secondaryFixed": b["base0C"],
        "secondaryFixedDim": b["base0C"],
        "onSecondaryFixed": b["base00"],
        "onSecondaryFixedVariant": b["base03"],
        "tertiaryFixed": b["base0E"],
        "tertiaryFixedDim": b["base0E"],
        "onTertiaryFixed": b["base00"],
        "onTertiaryFixedVariant": b["base03"],
        # --- semantic ---
        "error": b["base08"],
        "onError": b["base00"],
        "errorContainer": b["base08"],
        "onErrorContainer": b["base00"],
        "success": b["base0B"],
        "onSuccess": b["base00"],
        "successContainer": b["base0B"],
        "onSuccessContainer": b["base00"],
        # --- terminal (standard base16 mapping) ---
        "term0": b["base00"],
        "term1": b["base08"],
        "term2": b["base0B"],
        "term3": b["base0A"],
        "term4": b["base0D"],
        "term5": b["base0E"],
        "term6": b["base0C"],
        "term7": b["base05"],
        "term8": b["base03"],
        "term9": b["base08"],
        "term10": b["base0B"],
        "term11": b["base0A"],
        "term12": b["base0D"],
        "term13": b["base0E"],
        "term14": b["base0C"],
        "term15": b["base07"],
        # --- links (kde-ish roles used by CLI templates) ---
        "klink": b["base0D"],
        "klinkSelection": b["base0D"],
        "kvisited": b["base0E"],
        "kvisitedSelection": b["base0E"],
        "knegative": b["base08"],
        "knegativeSelection": b["base08"],
        "kneutral": b["base09"],
        "kneutralSelection": b["base09"],
        "kpositive": b["base0B"],
        "kpositiveSelection": b["base0B"],
        # --- catppuccin-style aliases used by CLI templates ---
        "rosewater": b["base06"],
        "flamingo": b["base0F"],
        "pink": b["base0E"],
        "mauve": b["base0E"],
        "red": b["base08"],
        "maroon": b["base08"],
        "peach": b["base09"],
        "yellow": b["base0A"],
        "green": b["base0B"],
        "teal": b["base0C"],
        "sky": b["base0C"],
        "sapphire": b["base0D"],
        "blue": b["base0D"],
        "lavender": b["base0E"],
        "text": b["base05"],
        "subtext1": b["base04"],
        "subtext0": b["base03"],
        "overlay2": b["base03"],
        "overlay1": b["base02"],
        "overlay0": b["base01"],
        "surface2": b["base02"],
        "surface1": b["base01"],
        "surface0": b["base00"],
        "base": b["base00"],
        "mantle": b["base00"],
        "crust": b["base00"],
    }


# Output order: base16 first, then grouped aliases (readable, deterministic).
ORDER = BASE_KEYS + [
    "term0", "term1", "term2", "term3", "term4", "term5", "term6", "term7",
    "term8", "term9", "term10", "term11", "term12", "term13", "term14", "term15",
    "background", "surface", "surfaceDim", "surfaceBright",
    "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer",
    "surfaceContainerHigh", "surfaceContainerHighest",
    "surfaceVariant", "onBackground", "onSurface", "onSurfaceVariant",
    "inverseSurface", "inverseOnSurface", "outline", "outlineVariant",
    "shadow", "scrim", "surfaceTint",
    "primary", "onPrimary", "primaryContainer", "onPrimaryContainer", "inversePrimary",
    "secondary", "onSecondary", "secondaryContainer", "onSecondaryContainer",
    "tertiary", "onTertiary", "tertiaryContainer", "onTertiaryContainer",
    "primary_paletteKeyColor", "secondary_paletteKeyColor", "tertiary_paletteKeyColor",
    "neutral_paletteKeyColor", "neutral_variant_paletteKeyColor",
    "primaryFixed", "primaryFixedDim", "onPrimaryFixed", "onPrimaryFixedVariant",
    "secondaryFixed", "secondaryFixedDim", "onSecondaryFixed", "onSecondaryFixedVariant",
    "tertiaryFixed", "tertiaryFixedDim", "onTertiaryFixed", "onTertiaryFixedVariant",
    "error", "onError", "errorContainer", "onErrorContainer",
    "success", "onSuccess", "successContainer", "onSuccessContainer",
    "klink", "klinkSelection", "kvisited", "kvisitedSelection",
    "knegative", "knegativeSelection", "kneutral", "kneutralSelection",
    "kpositive", "kpositiveSelection",
    "rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach",
    "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender",
    "text", "subtext1", "subtext0", "overlay2", "overlay1", "overlay0",
    "surface2", "surface1", "surface0", "base", "mantle", "crust",
]


def plan_layout(themes: list[tuple[str, str, dict]]) -> dict[tuple[str, str, str], dict]:
    """Map (scheme, flavour, mode) -> palette.

    One scheme per ifraaH file stem, flavour ``default``, mode from the YAML
    variant -- except when a ``<base>-dark``/``<base>-light`` file pairs with
    an opposite-variant ``<base>`` file, in which case both modes live under
    the ``<base>`` scheme (e.g. ``atelier-cave`` gets dark+light).
    """
    by_stem = {stem: variant for stem, variant, _ in themes}
    layout: dict[tuple[str, str, str], dict] = {}
    for stem, variant, palette in themes:
        base = stem[: -(len(variant) + 1)] if stem.endswith("-" + variant) else None
        if base is not None and by_stem.get(base) not in (None, variant):
            key = (base, "default", variant)
        else:
            key = (stem, "default", variant)
        if key in layout:
            raise ValueError(f"collision for {key}: {stem}")
        layout[key] = palette
    return layout


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--src", required=True, help="ifraaH themes dir (YAML files)")
    ap.add_argument("--out", required=True, help="output schemes dir")
    args = ap.parse_args()

    src = Path(args.src)
    out = Path(args.out)
    files = sorted(src.glob("*.yaml"))
    if not files:
        print(f"no yaml themes in {src}", file=sys.stderr)
        return 1

    themes = [parse_theme(f) for f in files]
    layout = plan_layout(themes)

    for (scheme, flavour, mode), palette in sorted(layout.items()):
        dest = out / scheme / flavour / f"{mode}.txt"
        dest.parent.mkdir(parents=True, exist_ok=True)
        full = dict(palette)
        full.update(derive_aliases(palette))
        extra = sorted(set(full) - set(ORDER))
        with dest.open("w") as f:
            for key in ORDER + extra:
                f.write(f"{key} {full[key]}\n")

    n_schemes = len({s for s, _, _ in layout})
    n_dark = sum(1 for _, _, m in layout if m == "dark")
    n_light = sum(1 for _, _, m in layout if m == "light")
    print(f"ported {len(files)} ifraaH themes -> {n_schemes} schemes "
          f"({len(layout)} files: {n_dark} dark, {n_light} light) in {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
