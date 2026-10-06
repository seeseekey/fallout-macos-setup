#!/bin/bash

set -euo pipefail

# Fullscreen is the default; --windowed selects windowed mode.
windowed=0
for argument in "$@"; do
  case "$argument" in
    --windowed) windowed=1 ;;
    --help|-h)
      echo "Usage: $(basename "$0") [--windowed]"
      echo "Default: fullscreen at 1920 x 1080 with 2x scaling."
      echo "--windowed: windowed mode with the same resolution and scaling."
      exit 0
      ;;
    *)
      echo "Unknown option: $argument (see --help)" >&2
      exit 1
      ;;
  esac
done

# Resolve installer paths relative to this script, regardless of the caller's directory.
cd "$(dirname "$0")"

if ! command -v brew >/dev/null; then
  echo "Homebrew was not found. Please install Homebrew first: https://brew.sh" >&2
  exit 1
fi

if ! command -v innoextract >/dev/null; then
  echo "Installing innoextract using Homebrew..."
  brew install innoextract
fi

for file in "setup_fallout_2_1.02_gog_v1_(77792).exe" "setup_fallout_2_1.02_gog_v1_(77792)-1.bin"; do
  if [[ ! -f "$file" ]]; then
    echo "File not found next to the script: $file" >&2
    exit 1
  fi
done

# Download the macOS app from the latest official release.
# Keep an existing DMG intact if the download fails.
download_file="$(mktemp "./fallout2-ce-macos.dmg.download.XXXXXX")"
trap 'rm -f "$download_file"' EXIT
curl --fail --location --retry 3 --connect-timeout 15 \
  --output "$download_file" \
  "https://github.com/alexbatalov/fallout2-ce/releases/latest/download/fallout2-ce-macos.dmg"
mv "$download_file" "fallout2-ce-macos.dmg"
trap - EXIT

# Create the Fallout 2 installation directory.
mkdir -p "/Applications/Fallout 2"

# Extract game archives, the official patch, loose data, and music.
innoextract "setup_fallout_2_1.02_gog_v1_(77792).exe" \
  -I master.dat \
  -I critter.dat \
  -I patch000.dat \
  -I data \
  -I sound \
  -d "/Applications/Fallout 2"

# Stop before launching if the extraction did not provide the game archives.
[[ -s "/Applications/Fallout 2/master.dat" ]]
[[ -s "/Applications/Fallout 2/critter.dat" ]]
[[ -s "/Applications/Fallout 2/patch000.dat" ]]
[[ -d "/Applications/Fallout 2/data" ]]
[[ -d "/Applications/Fallout 2/sound/music" ]]

# The installer puts empty writable directories under app/data.
if [[ -d "/Applications/Fallout 2/app/data" ]]; then
  ditto "/Applications/Fallout 2/app/data" "/Applications/Fallout 2/data"
fi
mkdir -p "/Applications/Fallout 2/data/savegame"

# Community Edition expects uppercase music filenames.
for music_file in "/Applications/Fallout 2/sound/music/"*.acm; do
  [[ -f "$music_file" ]] || continue
  music_name="$(basename "$music_file" | tr '[:lower:]' '[:upper:]')"
  mv "$music_file" "/Applications/Fallout 2/sound/music/$music_name"
done

# Create the Fallout 2 configuration file.
cat > "/Applications/Fallout 2/fallout2.cfg" <<'EOF'
[system]
master_dat=master.dat
critter_dat=critter.dat
master_patches=data
critter_patches=data

[sound]
music_path1=sound/music/
music_path2=sound/music/
EOF

# Start Fallout 2 in the selected mode at 1920 x 1080 with 2x scaling.
cat > "/Applications/Fallout 2/f2_res.ini" <<EOF
[MAIN]
SCR_WIDTH=1920
SCR_HEIGHT=1080
WINDOWED=$windowed
SCALE_2X=1
EOF

# Mount the Fallout 2 Community Edition disk image.
diskutil image attach "fallout2-ce-macos.dmg"

# Also unmount the image if copying fails.
trap 'diskutil unmount "/Volumes/Fallout II Community Edition" >/dev/null || true' EXIT

# Copy Fallout 2 Community Edition into the installation directory.
ditto \
  "/Volumes/Fallout II Community Edition/Fallout II Community Edition.app" \
  "/Applications/Fallout 2/Fallout II Community Edition.app"

# Unmount the disk image.
diskutil unmount "/Volumes/Fallout II Community Edition"
trap - EXIT

# Avoid AppTranslocation so the app can find the adjacent game data.
xattr -dr com.apple.quarantine "/Applications/Fallout 2/Fallout II Community Edition.app"

# Launch Fallout 2 Community Edition.
open "/Applications/Fallout 2/Fallout II Community Edition.app"
