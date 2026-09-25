# Cottage tiles

Source: tools/art/cottage-repaired-source.png

The exporter assembles the repaired artwork into a 48x48 cottage using
nearest-neighbor sampling, then splits it into nine 16x16 RGBA PNGs named
tile_ROW_COLUMN.png. The roof occupies the first row of tiles.

The opaque white and light gray checkerboard background connected to the canvas
edges is converted to actual PNG alpha transparency before splitting. Enclosed
highlights and the cottage's colored pixels are preserved. Rebuilding applies
the same background cleanup to both cottage.png and its tiles.

Rebuild: powershell -File tools/build_cottage_tiles.ps1
