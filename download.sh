#!/bin/sh -e

# Change to preferred versions
MPV_VERSION="0.30.0"
FFMPEG_VERSION="4.2.1"
LIBASS_VERSION="0.14.0"
FREETYPE_VERSION="2.10.0"
HARFBUZZ_VERSION="2.6.4"
FRIBIDI_VERSION="1.0.8"
UCHARDET_VERSION="0.0.6"

MPV_URL="https://github.com/mpv-player/mpv/archive/v$MPV_VERSION.tar.gz"
FFMPEG_URL="http://www.ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2"
LIBASS_URL="https://github.com/libass/libass/releases/download/$LIBASS_VERSION/libass-$LIBASS_VERSION.tar.gz"
FREETYPE_URL="https://sourceforge.net/projects/freetype/files/freetype2/$FREETYPE_VERSION/freetype-$FREETYPE_VERSION.tar.bz2"
HARFBUZZ_URL="https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-$HARFBUZZ_VERSION.tar.xz"
FRIBIDI_URL="https://github.com/fribidi/fribidi/releases/download/v$FRIBIDI_VERSION/fribidi-$FRIBIDI_VERSION.tar.bz2"
UCHARDET_URL="https://www.freedesktop.org/software/uchardet/releases/uchardet-$UCHARDET_VERSION.tar.xz"

rm -rf src
mkdir -p src downloads
for URL in $UCHARDET_URL $FREETYPE_URL $HARFBUZZ_URL $FRIBIDI_URL $LIBASS_URL $FFMPEG_URL $MPV_URL; do
	TARNAME=${URL##*/}
    if [ ! -f "downloads/$TARNAME" ]; then
	    curl -f -L -- $URL > downloads/$TARNAME
    fi
    echo "$TARNAME"
    tar xvf downloads/$TARNAME -C src
done

echo "\033[1;32mDownloaded: \033[0m\n mpv: $MPV_VERSION \
                            \n FFmpeg: $FFMPEG_VERSION \
                            \n libass: $LIBASS_VERSION \
                            \n freetype: $FREETYPE_VERSION \
                            \n harfbuzz: $HARFBUZZ_VERSION \
                            \n fribidi: $FRIBIDI_VERSION \
                            \n uchardet: $UCHARDET_VERSION "