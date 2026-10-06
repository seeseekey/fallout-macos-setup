# Fallout Community Edition installers for macOS

These Bash scripts install Fallout 1 and Fallout 2 Community Edition using
the original game data from GOG offline installers. They download the latest
official macOS Community Edition release and launch the game after installation.

## Requirements

- macOS with the `diskutil image attach` command available.
- [Homebrew](https://brew.sh) installed and available in your terminal's `PATH`.
- Your own copies of the games and their GOG offline backup installers.
- An internet connection for the Community Edition download and, if needed,
  the installation of `innoextract`.
- Write access to the script directory and the game's installation directory
  under `/Applications`.

The scripts automatically run `brew install innoextract` if `innoextract`
is missing. If Homebrew cannot be found, they print an installation link and stop.
They do not install Homebrew or download the commercial game installers.

## Prepare the installer files

Place each game's EXE and BIN next to its installation script:

```text
Fallout/
├── install-fallout-1.sh
├── install-fallout-2.sh
├── setup_fallout_1.2_(27130).exe
├── setup_fallout_1.2_(27130)-1.bin
├── setup_fallout_2_1.02_gog_v1_(77792).exe
└── setup_fallout_2_1.02_gog_v1_(77792)-1.bin
```

You only need the installer files for the game you want to install. Keep the
EXE and its matching BIN together. The scripts currently use the exact filenames
shown above; other installer versions may require changes to the filename checks,
extraction commands, and data paths.

You do not need to download the DMGs manually. Each script downloads its DMG
into the script directory on every run. An existing DMG is replaced only after
the download succeeds.

## Install and launch

Open Terminal and change to the directory containing the scripts. For example,
if you saved them in `~/Fallout`:

```sh
cd ~/Fallout
chmod +x install-fallout-1.sh install-fallout-2.sh
```

Install Fallout 1:

```sh
./install-fallout-1.sh
```

Install Fallout 2:

```sh
./install-fallout-2.sh
```

Both scripts default to **1920 × 1080 fullscreen with 2x scaling**. To install
with windowed mode instead, use:

```sh
./install-fallout-1.sh --windowed
./install-fallout-2.sh --windowed
```

The windowed option uses the same resolution and scaling as fullscreen.
You can run a script from any working directory by providing its path;
installer files are always located relative to the script itself.

Display usage information without installing anything:

```sh
./install-fallout-1.sh --help
./install-fallout-2.sh --help
```

| Option | Effect |
| --- | --- |
| No option | Write `WINDOWED=0` to the resolution configuration. |
| `--windowed` | Write `WINDOWED=1` to the resolution configuration. |
| `--help`, `-h` | Print usage information and exit. |

Unknown options cause the script to stop before installation.

## Installation locations

| Game | Installation directory | App | Configuration files |
| --- | --- | --- | --- |
| Fallout 1 | `/Applications/Fallout` | `Fallout Community Edition.app` | `fallout.cfg`, `f1_res.ini` |
| Fallout 2 | `/Applications/Fallout 2` | `Fallout II Community Edition.app` | `fallout2.cfg`, `f2_res.ini` |

The scripts extract the required game archives and loose data, write the data
and music paths, copy the Community Edition app from its DMG, and unmount the
image. Fallout 2 also includes `patch000.dat` and renames music files to uppercase.

After copying the app, each script removes its `com.apple.quarantine` attribute
to prevent macOS AppTranslocation from starting it in a temporary directory
without access to the adjacent game data.

To launch an installed game later, open its app in Finder or run:

```sh
open "/Applications/Fallout/Fallout Community Edition.app"
open "/Applications/Fallout 2/Fallout II Community Edition.app"
```

## Change resolution or display mode

Edit the game's `f1_res.ini` or `f2_res.ini`. Both scripts initially write:

```ini
[MAIN]
SCR_WIDTH=1920
SCR_HEIGHT=1080
WINDOWED=0
SCALE_2X=1
```

- `SCR_WIDTH` and `SCR_HEIGHT` select the output resolution.
- `WINDOWED=0` selects fullscreen; `WINDOWED=1` selects windowed mode.
- `SCALE_2X=1` doubles the size of the game image and interface.
  Use `SCALE_2X=0` to disable this scaling.

Restart the game after changing these settings. To make different settings the
installation defaults, edit the resolution configuration block in each script.

## Running the scripts again

Every run downloads the latest Community Edition DMG, extracts the game data
again, copies the app, rewrites both configuration files, and launches the game.
The scripts install into the existing game directory and do not create backups.
Close the game first and back up any custom configuration or modified game files
that you want to keep. A rerun overwrites manual changes to the configuration files.

To change only the display mode of an existing installation, edit the resolution
configuration directly instead of running the installer again.

## Troubleshooting

### Homebrew was not found

Install Homebrew from [brew.sh](https://brew.sh) and follow its instructions for
adding it to your terminal's `PATH`. Check that `brew --version` works before
running the script again.

### File not found next to the script

Check that both installer parts use the exact filenames listed above and are in
the same directory as the script. A GOG Galaxy installer is not a substitute for
the offline backup installer.

### Could not find the master datafile

Launch the app inside the game's installation directory. The DAT files and
configuration must be alongside the app, with filenames matching the paths in
the configuration. The scripts already remove the app's quarantine attribute
to address AppTranslocation.

### Download or disk image mounting failed

Check your internet connection and the project's release page. If the expected
Community Edition volume is already mounted, eject it in Finder before rerunning
the script. If `diskutil image attach` is unavailable on your macOS version, the
mounting commands need to be adapted for that version.

## Projects and licenses

- [Fallout 1 Community Edition](https://github.com/alexbatalov/fallout1-ce)
- [Fallout 1 releases](https://github.com/alexbatalov/fallout1-ce/releases)
- [Fallout 2 Community Edition](https://github.com/alexbatalov/fallout2-ce)
- [Fallout 2 releases](https://github.com/alexbatalov/fallout2-ce/releases)
- [innoextract](https://constexpr.org/innoextract/)

The installation scripts and this documentation are provided under the
[MIT License](LICENSE). The license does not cover the original Fallout game
assets or the Community Edition engines; those retain their respective licenses.
