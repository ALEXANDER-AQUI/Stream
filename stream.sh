#!/bin/bash

YOUTUBE_KEY="${YOUTUBE_KEY}"
VIDEO_DIR="/app"

echo "Iniciando sistema optimizado..."

create_playlist() {

    ls $VIDEO_DIR/*.mp4 2>/dev/null | shuf | sed "s/.*/file '&'/" > /tmp/playlist.txt

    TOTAL=$(wc -l < /tmp/playlist.txt)

    if [ "$TOTAL" -eq 0 ]; then
        echo "No hay videos"
        exit 1
    fi

    echo "Videos encontrados: $TOTAL"
}

while true
do

    create_playlist

    echo "Transmitiendo con CPU ultra bajo..."

    ffmpeg \
    -re \
    -f concat \
    -safe 0 \
    -protocol_whitelist file,pipe \
    -i /tmp/playlist.txt \
    -c:v copy \
    -c:a copy \
    -f flv \
    -flvflags no_duration_filesize \
    -fflags +genpts \
    -avoid_negative_ts make_zero \
    "rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY"

    sleep 2

done


