#!/bin/bash
# Generate Vector Tiles from GeoJSON using Tippecanoe

set -e

echo "=== Phase 3: Generate Vector Tiles ==="
echo ""

# Create tiles directory
mkdir -p tiles

# 1. Danger Zone (polygon - heavy, needs optimization)
echo "1. Generating danger_zone.mbtiles..."
tippecanoe \
  -o tiles/danger_zone.mbtiles \
  --layer=danger_zone \
  --no-feature-limit \
  --no-tile-size-limit \
  --drop-densest-as-needed \
  --extend-zooms-if-still-dropping \
  --coalesce-smallest-as-needed \
  --force \
  data_sources/final/danger_zone.geojson

echo "  ✅ danger_zone.mbtiles created"
echo ""

# 2. Railway (light)
echo "2. Generating railway.mbtiles..."
tippecanoe \
  -o tiles/railway.mbtiles \
  --layer=railway \
  --force \
  data_sources/final/railway.geojson

echo "  ✅ railway.mbtiles created"
echo ""

# 3. Cameras (may be empty)
echo "3. Generating cameras.mbtiles..."
tippecanoe \
  -o tiles/cameras.mbtiles \
  --layer=cameras \
  --force \
  data_sources/final/cameras.geojson

echo "  ✅ cameras.mbtiles created"
echo ""

# 4. Speed Limit (may be empty)
echo "4. Generating speed_limit.mbtiles..."
tippecanoe \
  -o tiles/speed_limit.mbtiles \
  --layer=speed_limit \
  --force \
  data_sources/final/speed_limit.geojson

echo "  ✅ speed_limit.mbtiles created"
echo ""

# 5. Merge all tiles
echo "5. Merging all tiles into vietmap.mbtiles..."
tile-join \
  -o vietmap.mbtiles \
  tiles/danger_zone.mbtiles \
  tiles/railway.mbtiles \
  tiles/cameras.mbtiles \
  tiles/speed_limit.mbtiles \
  --force

echo "  ✅ vietmap.mbtiles created"
echo ""

echo "=== Complete ==="
echo "Output: vietmap.mbtiles"

