#!/bin/sh -e

LIBRARIES="libuchardet libfreetype libharfbuzz libass"
# LGPL licensed projects should be built as dynamic framework bundles
FRAMEWORKS="libfribidi ffmpeg libmpv"

export PKG_CONFIG_PATH
export LDFLAGS
export CFLAGS
export CXXFLAGS
export COMMON_OPTIONS
export ENVIRONMENT
export ARCH

while getopts "e:" OPTION; do
case $OPTION in
		e )
			ENVIRONMENT=$(echo "$OPTARG" | awk '{print tolower($0)}')
			;;
		? )
			echo "Invalid option"
			exit 1
			;;
	esac
done

export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"
DEPLOYMENT_TARGET="11.0"

if [[ "$ENVIRONMENT" = "distribution" ]]; then
    ARCHS="arm64"
elif [[ "$ENVIRONMENT" = "development" ]]; then
    ARCHS="x86_64 arm64"
elif [[ "$ENVIRONMENT" = "" ]]; then
    echo "An environment option is required (-e development or -e distribution)"
    exit 1
else
    echo "Unhandled environment option"
    exit 1
fi

ROOT="$(pwd)"
SCRIPTS="$ROOT/scripts"
DYLIB="$ROOT/dylib"
SCRATCH="$ROOT/scratch"
LIB="$ROOT/lib"
export SRC="$ROOT/src"
mkdir -p $LIB $DYLIB

for ARCH in $ARCHS; do
    if [[ $ARCH = "arm64" ]]; then
        HOSTFLAG="aarch64"
		export SDKPATH="$(xcodebuild -sdk iphoneos -version Path)"
		ACFLAGS="-arch $ARCH -isysroot $SDKPATH -mios-version-min=$DEPLOYMENT_TARGET"
		ALDFLAGS="-arch $ARCH -isysroot $SDKPATH -Wl,-ios_version_min,$DEPLOYMENT_TARGET -lbz2"
	elif [[ $ARCH = "x86_64" ]]; then
        HOSTFLAG="x86_64"
		export SDKPATH="$(xcodebuild -sdk iphonesimulator -version Path)"
		ACFLAGS="-arch $ARCH -isysroot $SDKPATH -mios-simulator-version-min=$DEPLOYMENT_TARGET"
		ALDFLAGS="-arch $ARCH -isysroot $SDKPATH -Wl,-ios_simulator_version_min,$DEPLOYMENT_TARGET -lbz2"
	else
        echo "Unhandled architecture option"
        exit 1
    fi

    if [[ "$ENVIRONMENT" = "development" ]]; then
        CFLAGS="$ACFLAGS"
        LDFLAGS="$ALDFLAGS"
    else
        CFLAGS="$ACFLAGS -fembed-bitcode -Os"
        LDFLAGS="$ALDFLAGS -fembed-bitcode -Os"
    fi
    CXXFLAGS="$CFLAGS"

    mkdir -p $SCRATCH

    PKG_CONFIG_PATH="$SCRATCH/$ARCH/lib/pkgconfig"
    COMMON_OPTIONS="--prefix=$SCRATCH/$ARCH --exec-prefix=$SCRATCH/$ARCH --build=x86_64-apple-darwin14 --enable-static \
                    --disable-shared --disable-dependency-tracking --with-pic --host=$HOSTFLAG"
    
    for LIBRARY in $LIBRARIES; do
        case $LIBRARY in
            "libfreetype" )
				mkdir -p $SCRATCH/$ARCH/freetype && cd $_ && $SCRIPTS/freetype-build
				;;
            "libharfbuzz" )
				mkdir -p $SCRATCH/$ARCH/harfbuzz && cd $_ && $SCRIPTS/harfbuzz-build
				;;
            "libass" )
				mkdir -p $SCRATCH/$ARCH/libass && cd $_ && $SCRIPTS/libass-build
				;;
            "libuchardet" )
				mkdir -p $SCRATCH/$ARCH/uchardet && cd $_ && $SCRIPTS/uchardet-build
				;;
        esac
    done

    for FRAMEWORK in $FRAMEWORKS; do
        case $FRAMEWORK in
            "libfribidi" )
				mkdir -p $SCRATCH/$ARCH/fribidi && cd $_ && $SCRIPTS/fribidi-build
				;;
            "ffmpeg" )
				mkdir -p $SCRATCH/$ARCH/ffmpeg && cd $_ && $SCRIPTS/ffmpeg-build
				;;
            "libmpv" )
                if [[ "$ENVIRONMENT" = "development" ]]; then
                    CFLAGS="$ACFLAGS -g2 -Og"
                    LDFLAGS="$ALDFLAGS -g2 -Og"
                fi
				mkdir -p $SCRATCH/$ARCH/mpv && $SCRIPTS/mpv-build && cp $SRC/mpv*/build/libmpv.a "$SCRATCH/$ARCH/mpv"
				;;
        esac
    done
done

# todo: clean up duplicated parts here
if [[ "$ENVIRONMENT" = "development" ]]; then
    for LIBRARY in $LIBRARIES; do
        lipo -create $SCRATCH/arm64/lib/$LIBRARY.a $SCRATCH/x86_64/lib/$LIBRARY.a -o $LIB/$LIBRARY.a
    done

    # Device
    SDKPATH="$(xcodebuild -sdk iphoneos -version Path)"

    export FRIBIDI_SCRATCH="$SCRATCH/arm64/fribidi"
    # Duplicate symbols workaround
    rm -f $FRIBIDI_SCRATCH/bin/fribidi-benchmark.o $FRIBIDI_SCRATCH/bin/fribidi-bidi-types.o $FRIBIDI_SCRATCH/bin/fribidi-caprtl2utf8.o
    g++ -dynamiclib -install_name @rpath/libfribidi.framework/libfribidi -arch arm64 -isysroot $SDKPATH -mios-version-min=$DEPLOYMENT_TARGET -g2 -Og $(find $FRIBIDI_SCRATCH -name "*.o") -o $SCRATCH/arm64/lib/libfribidi

    export FFMPEG_SCRATCH="$SCRATCH/arm64/ffmpeg"
    # Duplicate symbols workaround
    rm -f $FFMPEG_SCRATCH/libavfilter/log2_tab.o $FFMPEG_SCRATCH/libavdevice/reverse.o $FFMPEG_SCRATCH/libavformat/log2_tab.o $FFMPEG_SCRATCH/libswscale/log2_tab.o $FFMPEG_SCRATCH/libavcodec/reverse.o $FFMPEG_SCRATCH/libavformat/golomb_tab.o $FFMPEG_SCRATCH/libavcodec/log2_tab.o $FFMPEG_SCRATCH/libswresample/log2_tab.o
    g++ -dynamiclib -install_name @rpath/libffmpeg.framework/libffmpeg -arch arm64 -isysroot $SDKPATH -mios-version-min=$DEPLOYMENT_TARGET -g2 -Og -framework videotoolbox -framework avfoundation -framework corevideo -framework corefoundation -framework audiotoolbox -framework coremedia -framework foundation -lz -lbz2 -liconv $(find $FFMPEG_SCRATCH -name "*.o") -o $SCRATCH/arm64/lib/libffmpeg

    export MPV_SCRATCH="$SCRATCH/arm64/mpv"
    g++ -dynamiclib -install_name @rpath/libmpv.framework/libmpv -arch arm64 -all_load -isysroot $SDKPATH -mios-version-min=$DEPLOYMENT_TARGET -g2 -Og $SCRATCH/arm64/lib/libass.a $SCRATCH/arm64/lib/libfreetype.a $SCRATCH/arm64/lib/libharfbuzz.a $SCRATCH/arm64/lib/libuchardet.a $SCRATCH/arm64/lib/libffmpeg $SCRATCH/arm64/lib/libfribidi -framework foundation -framework audiotoolbox -framework coretext -framework avfoundation -framework corevideo -framework opengles -lz -lbz2 -liconv $MPV_SCRATCH/libmpv.a -o $SCRATCH/arm64/lib/libmpv

    # Simulator
    export SDKPATH="$(xcodebuild -sdk iphonesimulator -version Path)"

    export FRIBIDI_SCRATCH="$SCRATCH/x86_64/fribidi"
    # Duplicate symbols workaround
    rm -f $FRIBIDI_SCRATCH/bin/fribidi-benchmark.o $FRIBIDI_SCRATCH/bin/fribidi-bidi-types.o $FRIBIDI_SCRATCH/bin/fribidi-caprtl2utf8.o
    g++ -dynamiclib -install_name @rpath/libfribidi.framework/libfribidi -arch x86_64 -isysroot $SDKPATH -mios-version-min=$DEPLOYMENT_TARGET -g2 -Og $(find $FRIBIDI_SCRATCH -name "*.o") -o $SCRATCH/x86_64/lib/libfribidi

    export FFMPEG_SCRATCH="$SCRATCH/x86_64/ffmpeg"
    # Duplicate symbols workaround
    rm -f $FFMPEG_SCRATCH/libavfilter/log2_tab.o $FFMPEG_SCRATCH/libavdevice/reverse.o $FFMPEG_SCRATCH/libavformat/log2_tab.o $FFMPEG_SCRATCH/libswscale/log2_tab.o $FFMPEG_SCRATCH/libavcodec/reverse.o $FFMPEG_SCRATCH/libavformat/golomb_tab.o $FFMPEG_SCRATCH/libavcodec/log2_tab.o $FFMPEG_SCRATCH/libswresample/log2_tab.o
    g++ -dynamiclib -install_name @rpath/libffmpeg.framework/libffmpeg -arch x86_64 -isysroot $SDKPATH -mios-version-min=$DEPLOYMENT_TARGET -g2 -Og -framework videotoolbox -framework avfoundation -framework corevideo -framework corefoundation -framework audiotoolbox -framework coremedia -framework foundation -lz -lbz2 -liconv $(find $FFMPEG_SCRATCH -name "*.o") -o $SCRATCH/x86_64/lib/libffmpeg

    export MPV_SCRATCH="$SCRATCH/x86_64/mpv"
    g++ -dynamiclib -install_name @rpath/libmpv.framework/libmpv -arch x86_64 -all_load -isysroot $SDKPATH -mios-version-min=$DEPLOYMENT_TARGET -g2 -Og $SCRATCH/x86_64/lib/libass.a $SCRATCH/x86_64/lib/libfreetype.a $SCRATCH/x86_64/lib/libharfbuzz.a $SCRATCH/x86_64/lib/libuchardet.a $SCRATCH/x86_64/lib/libffmpeg $SCRATCH/x86_64/lib/libfribidi -framework foundation -framework audiotoolbox -framework coretext -framework avfoundation -framework corevideo -framework opengles -lz -lbz2 -liconv $MPV_SCRATCH/libmpv.a -o $SCRATCH/x86_64/lib/libmpv

    lipo -create $SCRATCH/arm64/lib/libfribidi $SCRATCH/x86_64/lib/libfribidi -o $DYLIB/libfribidi
    lipo -create $SCRATCH/arm64/lib/libffmpeg $SCRATCH/x86_64/lib/libffmpeg -o $DYLIB/libffmpeg
    lipo -create $SCRATCH/arm64/lib/libmpv $SCRATCH/x86_64/lib/libmpv -o $DYLIB/libmpv
else
    for LIBRARY in $LIBRARIES; do
        cp $SCRATCH/arm64/lib/$LIBRARY.a $LIB/$LIBRARY.a
    done

    # Device
    SDKPATH="$(xcodebuild -sdk iphoneos -version Path)"
    export FRIBIDI_SCRATCH="$SCRATCH/arm64/fribidi"
    # Duplicate symbols workaround
    rm -f $FRIBIDI_SCRATCH/bin/fribidi-benchmark.o $FRIBIDI_SCRATCH/bin/fribidi-bidi-types.o $FRIBIDI_SCRATCH/bin/fribidi-caprtl2utf8.o
    g++ -dynamiclib -install_name @rpath/libfribidi.framework/libfribidi -arch arm64 -isysroot $SDKPATH -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode -Os $(find $FRIBIDI_SCRATCH -name "*.o") -o $DYLIB/libfribidi

    export FFMPEG_SCRATCH="$SCRATCH/arm64/ffmpeg"
    # Duplicate symbols workaround
    rm -f $FFMPEG_SCRATCH/libavfilter/log2_tab.o $FFMPEG_SCRATCH/libavdevice/reverse.o $FFMPEG_SCRATCH/libavformat/log2_tab.o $FFMPEG_SCRATCH/libswscale/log2_tab.o $FFMPEG_SCRATCH/libavcodec/reverse.o $FFMPEG_SCRATCH/libavformat/golomb_tab.o $FFMPEG_SCRATCH/libavcodec/log2_tab.o $FFMPEG_SCRATCH/libswresample/log2_tab.o
    g++ -dynamiclib -install_name @rpath/libffmpeg.framework/libffmpeg -arch arm64 -isysroot $SDKPATH -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode -Os -framework videotoolbox -framework avfoundation -framework corevideo -framework corefoundation -framework audiotoolbox -framework coremedia -framework foundation -lz -lbz2 -liconv $(find $FFMPEG_SCRATCH -name "*.o") -o $DYLIB/libffmpeg

    export MPV_SCRATCH="$SCRATCH/arm64/mpv*"
    g++ -dynamiclib -install_name @rpath/libmpv.framework/libmpv -arch arm64 -all_load -isysroot $SDKPATH -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode -Os $LIB/libass.a $LIB/libfreetype.a $LIB/libharfbuzz.a $LIB/libuchardet.a $DYLIB/libffmpeg $DYLIB/libfribidi -framework foundation -framework audiotoolbox -framework coretext -framework avfoundation -framework corevideo -framework opengles -lz -lbz2 -liconv $MPV_SCRATCH/libmpv.a -o $DYLIB/libmpv
fi