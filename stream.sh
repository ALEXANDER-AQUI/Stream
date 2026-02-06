#!/bin/bash

YOUTUBE_KEY="${YOUTUBE_KEY}"
VIDEO_DIR="/app"

echo "Iniciando sistema de streaming..."

# Verificar que exista la clave
if [ -z "$YOUTUBE_KEY" ]; then
  echo "ERROR: Falta YOUTUBE_KEY"
  exit 1
fi

while true
do

  echo "Buscando videos en $VIDEO_DIR..."

  # crear playlist random correctamente
  find "$VIDEO_DIR" -type f -iname "*.mp4" | shuf | sed "s/.*/file '&'/" > /tmp/playlist.txt

  TOTAL=$(wc -l < /tmp/playlist.txt)

  if [ "$TOTAL" -eq 0 ]; then
    echo "No se encontraron videos"
    sleep 5
    continue
  fi

  echo "Videos encontrados: $TOTAL"
  echo "Iniciando transmisión..."

  # modo ultra bajo CPU (SIN recodificar)
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

  echo "Reiniciando lista random..."

  sleep 2

done
