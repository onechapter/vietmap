# Generate Vector Tiles from GeoJSON using Tippecanoe (PowerShell)

Write-Host "=== Phase 3: Generate Vector Tiles ===" -ForegroundColor Cyan
Write-Host ""

# Check if tippecanoe is installed
$tippecanoeCmd = Get-Command tippecanoe -ErrorAction SilentlyContinue
if (-not $tippecanoeCmd) {
    Write-Host "❌ ERROR: tippecanoe not found!" -ForegroundColor Red
    Write-Host "Please install tippecanoe:" -ForegroundColor Yellow
    Write-Host "  Windows: choco install tippecanoe" -ForegroundColor Yellow
    Write-Host "  Or download from: https://github.com/felt/tippecanoe/releases" -ForegroundColor Yellow
    exit 1
}

# Check if tile-join is installed
$tileJoinCmd = Get-Command tile-join -ErrorAction SilentlyContinue
if (-not $tileJoinCmd) {
    Write-Host "❌ ERROR: tile-join not found!" -ForegroundColor Red
    Write-Host "tile-join should come with tippecanoe installation" -ForegroundColor Yellow
    exit 1
}

# Create tiles directory
if (-not (Test-Path "tiles")) {
    New-Item -ItemType Directory -Path "tiles" | Out-Null
}

# 1. Danger Zone (polygon - heavy, needs optimization)
Write-Host "1. Generating danger_zone.mbtiles..." -ForegroundColor Green
& tippecanoe `
  -o tiles/danger_zone.mbtiles `
  --layer=danger_zone `
  --no-feature-limit `
  --no-tile-size-limit `
  --drop-densest-as-needed `
  --extend-zooms-if-still-dropping `
  --coalesce-smallest-as-needed `
  --force `
  data_sources/final/danger_zone.geojson

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ danger_zone.mbtiles created" -ForegroundColor Green
} else {
    Write-Host "  ❌ Failed to create danger_zone.mbtiles" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 2. Railway (light)
Write-Host "2. Generating railway.mbtiles..." -ForegroundColor Green
& tippecanoe `
  -o tiles/railway.mbtiles `
  --layer=railway `
  --force `
  data_sources/final/railway.geojson

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ railway.mbtiles created" -ForegroundColor Green
} else {
    Write-Host "  ❌ Failed to create railway.mbtiles" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 3. Cameras (may be empty)
Write-Host "3. Generating cameras.mbtiles..." -ForegroundColor Green
& tippecanoe `
  -o tiles/cameras.mbtiles `
  --layer=cameras `
  --force `
  data_sources/final/cameras.geojson

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ cameras.mbtiles created" -ForegroundColor Green
} else {
    Write-Host "  ❌ Failed to create cameras.mbtiles" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 4. Speed Limit (may be empty)
Write-Host "4. Generating speed_limit.mbtiles..." -ForegroundColor Green
& tippecanoe `
  -o tiles/speed_limit.mbtiles `
  --layer=speed_limit `
  --force `
  data_sources/final/speed_limit.geojson

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ speed_limit.mbtiles created" -ForegroundColor Green
} else {
    Write-Host "  ❌ Failed to create speed_limit.mbtiles" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 5. Merge all tiles
Write-Host "5. Merging all tiles into vietmap.mbtiles..." -ForegroundColor Green
& tile-join `
  -o vietmap.mbtiles `
  tiles/danger_zone.mbtiles `
  tiles/railway.mbtiles `
  tiles/cameras.mbtiles `
  tiles/speed_limit.mbtiles `
  --force

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ vietmap.mbtiles created" -ForegroundColor Green
} else {
    Write-Host "  ❌ Failed to merge tiles" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "=== Complete ===" -ForegroundColor Cyan
Write-Host "Output: vietmap.mbtiles" -ForegroundColor Green

