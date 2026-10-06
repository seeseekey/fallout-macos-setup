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

for file in "setup_fallout_1.2_(27130).exe" "setup_fallout_1.2_(27130)-1.bin"; do
  if [[ ! -f "$file" ]]; then
    echo "File not found next to the script: $file" >&2
    exit 1
  fi
done

# Download the macOS app from the latest official release.
# Keep an existing DMG intact if the download fails.
download_file="$(mktemp "./fallout-ce-macos.dmg.download.XXXXXX")"
trap 'rm -f "$download_file"' EXIT
curl --fail --location --retry 3 --connect-timeout 15 \
  --output "$download_file" \
  "https://github.com/alexbatalov/fallout1-ce/releases/latest/download/fallout-ce-macos.dmg"
mv "$download_file" "fallout-ce-macos.dmg"
trap - EXIT

# Create the Fallout installation directory.
mkdir -p "/Applications/Fallout"

# Extract the required Fallout game data from the GOG installer.
innoextract "setup_fallout_1.2_(27130).exe" \
  -I MASTER.DAT \
  -I CRITTER.DAT \
  -I DATA \
  -d "/Applications/Fallout"

# Stop before launching if the extraction did not provide the game archives.
[[ -s "/Applications/Fallout/MASTER.DAT" ]]
[[ -s "/Applications/Fallout/CRITTER.DAT" ]]
[[ -d "/Applications/Fallout/DATA" ]]

# Create the Fallout configuration file.
cat > "/Applications/Fallout/fallout.cfg" <<'EOF'
[system]
master_dat=MASTER.DAT
critter_dat=CRITTER.DAT
master_patches=DATA
critter_patches=DATA

[sound]
music_path1=DATA/SOUND/MUSIC/
music_path2=DATA/SOUND/MUSIC/
EOF

# Start Fallout in the selected mode at 1920 x 1080 with 2x scaling.
cat > "/Applications/Fallout/f1_res.ini" <<EOF
[MAIN]
SCR_WIDTH=1920
SCR_HEIGHT=1080
WINDOWED=$windowed
SCALE_2X=1
EOF

# Mount the Fallout Community Edition disk image.
diskutil image attach "fallout-ce-macos.dmg"

# Also unmount the image if copying fails.
trap 'diskutil unmount "/Volumes/Fallout Community Edition" >/dev/null || true' EXIT

# Copy Fallout Community Edition into the Fallout installation directory.
ditto \
  "/Volumes/Fallout Community Edition/Fallout Community Edition.app" \
  "/Applications/Fallout/Fallout Community Edition.app"

# Unmount the disk image.
diskutil unmount "/Volumes/Fallout Community Edition"
trap - EXIT

# Avoid AppTranslocation: it otherwise starts this downloaded app in a temporary
# directory, where the adjacent MASTER.DAT and CRITTER.DAT cannot be found.
xattr -dr com.apple.quarantine "/Applications/Fallout/Fallout Community Edition.app"

# Launch Fallout Community Edition.
open "/Applications/Fallout/Fallout Community Edition.app"
