#!/bin/bash

YOUTUBE_KEY="${YOUTUBE_KEY}"
VIDEO_DIR="/app"

echo "Iniciando YouTube Streamer (modo estable)"

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
    sleep 10
    continue
  fi
  
  echo "Videos encontrados: $TOTAL"
  
  for VIDEO in "${VIDEOS[@]}"
  do
    echo "Transmitiendo: $(basename "$VIDEO")"
    
    ffmpeg -hide_banner -loglevel warning \
      -re \
      -i "$VIDEO" \
      -c:v libx264 \
      -preset veryfast \
      -tune zerolatency \
      -b:v 2500k \
      -maxrate 2500k \
      -bufsize 5000k \
      -pix_fmt yuv420p \
      -g 50 \
      -c:a aac \
      -b:a 128k \
      -ar 44100 \
      -f flv \
      -flvflags no_duration_filesize \
      -rtmp_buffer 10000 \
      "rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY"
    
    if [ $? -eq 0 ] || [ $? -eq 255 ]; then
      echo "✓ OK"
    else
      echo "⚠ Error - esperando 10s..."
      sleep 10
    fi
    
    sleep 3
  done
done
