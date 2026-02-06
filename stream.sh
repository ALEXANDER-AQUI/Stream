#!/bin/bash

YOUTUBE_KEY="${YOUTUBE_KEY}"

cd /app

echo "Buscando videos..."

find /app -type f -iname "*.mp4" > videos.txt

TOTAL=$(wc -l < videos.txt)

if [ "$TOTAL" -eq 0 ]; then
  echo "No hay videos"
  exit 1
fi

echo "Videos encontrados: $TOTAL"

while true
do

  shuf videos.txt > playlist.txt

  echo "Transmitiendo con calidad optimizada..."

  ffmpeg \
  -re \
  -f concat \
  -safe 0 \
  -i playlist.txt \
  -c:v copy \
  -c:a copy \
  -f flv \
  -flvflags no_duration_filesize \
  -bufsize 6000k \
  -rtmp_buffer 1000 \
  "rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY"

  sleep 2

done

