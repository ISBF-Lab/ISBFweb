import struct
from pathlib import Path

directory = Path(__file__).resolve().parents[1] / "public/images"
for source in directory.glob("*.png"):
    if source.stem.endswith("-static"):
        continue
    data = source.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    output = bytearray(data[:8])
    offset = 8
    while offset < len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        kind = data[offset + 4 : offset + 8]
        chunk = data[offset : offset + length + 12]
        if kind not in (b"acTL", b"fcTL", b"fdAT"):
            output.extend(chunk)
        offset += length + 12
    source.with_name(source.stem + "-static.png").write_bytes(output)
