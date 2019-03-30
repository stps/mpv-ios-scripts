# mpv iOS build scripts

These are build scripts for building [libmpv](https://github.com/mpv-player/mpv), and its dependencies:

* FFmpeg
* libass
* freetype
* harfbuzz
* fribidi
* uchardet

Currently used to help build [Outplayer](http://get.outplayer.app) on iOS.

## Configuration

Tested with:

* macOS 10.14.4
* Xcode 10.2

## Usage

1. Run `./download.sh` to download and unarchive the projects' source
2. Run `./build.sh -e ENVIRONMENT`, where environment is one of:

`development`: builds arm64 and x86_64 fat static libaries, and builds mpv with debug symbols and no optimization.

`distribution`: builds only arm64 static libraries, adds bitcode, and adds `-Os` to optimize for size and speed.

## References

These scripts build upon [ybma-xbzheng/mpv-build-mac-iOS](https://github.com/ybma-xbzheng/mpv-build-mac-iOS) and [mpv-player/mpv-build](https://github.com/mpv-player/mpv-build)