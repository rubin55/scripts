#!/usr/bin/env python3
"""Extract advance widths from a TrueType font and list them per width."""

import argparse
import sys
from collections import defaultdict
from fontTools.ttLib import TTFont


def to_ranges(codepoints):
    pts = sorted(set(codepoints))
    if not pts:
        return ""
    start = end = pts[0]
    parts = []
    for cp in pts[1:]:
        if cp == end + 1:
            end = cp
        else:
            parts.append((start, end))
            start = end = cp
    parts.append((start, end))
    return ", ".join(
        f"0x{s:04x}" if s == e else f"0x{s:04x}-0x{e:04x}"
        for s, e in parts
    )


def main():
    parser = argparse.ArgumentParser(description="List advance widths from a TrueType font.")
    parser.add_argument("-f", "--font", metavar="FILE", help="path to TTF font file")
    args = parser.parse_args()
    if not args.font:
        parser.print_help()
        sys.exit(0)

    font = TTFont(args.font)

    cmap = font.getBestCmap()
    if cmap is None:
        sys.exit(f"no Unicode cmap found in {args.font}")
    hmtx = font["hmtx"].metrics

    char_to_width = {}
    for codepoint, glyph_name in cmap.items():
        if glyph_name in hmtx:
            advance, _ = hmtx[glyph_name]
            char_to_width[codepoint] = advance

    width_to_chars = defaultdict(list)
    for codepoint, width in char_to_width.items():
        width_to_chars[width].append(codepoint)

    for width in sorted(width_to_chars):
        print(f"width {width}: {to_ranges(width_to_chars[width])}")

    font.close()


if __name__ == "__main__":
    main()
