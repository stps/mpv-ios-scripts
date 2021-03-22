# mpv iOS build scripts

This is a macOS shell script for cross-compiling [libmpv](https://github.com/mpv-player/mpv) for iOS (arm64 and x86_64). Includes build scripts for:

* mpv
* FFmpeg
* libass
* freetype
* harfbuzz
* fribidi
* uchardet

## Usage

1. Run `./download.sh` to download and unarchive the projects' source
2. Run `./build.sh -e ENVIRONMENT`, where environment is one of:

`development`: builds arm64 and x86_64 fat static libaries, and builds mpv with debug symbols and no optimization.

`distribution`: builds only arm64 static libraries, adds bitcode, and adds `-Os` to optimize for size and speed.

## References

These scripts build upon [ybma-xbzheng/mpv-build-mac-iOS](https://github.com/ybma-xbzheng/mpv-build-mac-iOS) and [mpv-player/mpv-build](https://github.com/mpv-player/mpv-build)