#!/bin/bash

YOUTUBE_KEY="${YOUTUBE_KEY}"
VIDEO_DIR="/app"

echo "Iniciando streamer..."

if [ -z "$YOUTUBE_KEY" ]; then
  echo "ERROR: falta YOUTUBE_KEY"
  exit 1
fi

while true
do

  echo "Buscando videos..."

  mapfile -t VIDEOS < <(find "$VIDEO_DIR" -type f -iname "*.mp4" | shuf)

  TOTAL=${#VIDEOS[@]}

  if [ "$TOTAL" -eq 0 ]; then
    echo "No hay videos"
    sleep 5
    continue
  fi

  echo "Videos encontrados: $TOTAL"

  for VIDEO in "${VIDEOS[@]}"
  do

    echo "Transmitiendo: $(basename "$VIDEO")"

    ffmpeg \
    -re \
    -i "$VIDEO" \
    -c:v copy \
    -c:a copy \
    -f flv \
    -flvflags no_duration_filesize \
    "rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY"

    echo "Video terminado"

    sleep 1

  done

done
