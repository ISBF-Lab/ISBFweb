# Avatar frame analysis fixtures

These synthetic 288 × 288 PNGs exercise decoded transparency and conservative circle suggestions.

| File | Content |
| --- | --- |
| `closed-ring.png` | RGBA ring, centered at (144, 152), with inner radius 120 and outer radius 136 |
| `open-ring.png` | Right half of the same ring |
| `irregular-ring.png` | Elliptical ring, centered at (144, 144), with inner radii 125 × 90 and outer radii 140 × 105 |
| `transparent-blank.png` | Fully transparent RGBA canvas |
| `opaque-rgba.png` | Fully opaque RGBA canvas |
| `opaque-palette.png` | Opaque palette pixels with an unused transparent palette entry |
| `transparent-palette.png` | The closed ring with transparent palette pixels |

Pixel inclusion uses pixel centers (x + 0.5, y + 0.5). Ring pixels are RGB (70, 120, 220); transparent RGBA pixels are all zero. Palette files use index 0 for the opaque ring color and index 1 for transparency, with a `tRNS` alpha table of [255, 0]. The opaque palette fixture uses only index 0.

The expected circle suggestion moves the ring upward by roughly 3.33% of the avatar diameter. Open, irregular, and blank images remain valid transparent uploads but have no automatic suggestion.
