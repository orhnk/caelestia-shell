#!/usr/bin/env python3
"""Read a PNG image from stdin, print the first pixel as #rrggbb.

Used by the ColourPicker fallback (slurp + grim) when hyprpicker is missing.
Only stdlib: works for 8-bit non-interlaced RGB/RGBA PNGs, which is what
`grim -g 'x,y 1x1'` produces. For a 1x1 image the first pixel's raw bytes are
correct regardless of the scanline filter type.
"""

import struct
import sys
import zlib


def main() -> int:
    data = sys.stdin.buffer.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        return 1

    pos = 8
    color_type = None
    idat = bytearray()
    while pos + 8 <= len(data):
        (length,) = struct.unpack(">I", data[pos : pos + 4])
        chunk = data[pos + 4 : pos + 8]
        if chunk == b"IHDR":
            _w, _h, _depth, color_type = struct.unpack(">IIBB", data[pos + 8 : pos + 18])
        elif chunk == b"IDAT":
            idat += data[pos + 8 : pos + 8 + length]
        elif chunk == b"IEND":
            break
        pos += 12 + length

    if color_type not in (2, 6) or not idat:
        return 1

    try:
        raw = zlib.decompress(bytes(idat))
    except zlib.error:
        return 1

    if len(raw) < 4:
        return 1

    r, g, b = raw[1], raw[2], raw[3]
    sys.stdout.write("#%02x%02x%02x\n" % (r, g, b))
    return 0


if __name__ == "__main__":
    sys.exit(main())
