
#!/bin/bash

YOUTUBE_KEY="${YOUTUBE_KEY}"
VIDEO_DIR="/app"
MAX_RETRIES=5
RETRY_DELAY=10

echo "=========================================="
echo "Iniciando YouTube Streamer 24/7"
echo "=========================================="

if [ -z "$YOUTUBE_KEY" ]; then
  echo "ERROR: falta YOUTUBE_KEY"
  exit 1
fi

# Función para transmitir con reintentos
stream_video() {
  local video="$1"
  local retries=0
  
  while [ $retries -lt $MAX_RETRIES ]; do
    echo "▶ Transmitiendo: $(basename "$video") [intento $((retries+1))/$MAX_RETRIES]"
    
    ffmpeg -hide_banner -loglevel error \
      -re \
      -i "$video" \
      -c:v copy \
      -c:a copy \
      -f flv \
      -flvflags no_duration_filesize \
      -rtmp_buffer 10000 \
      -reconnect 1 \
      -reconnect_streamed 1 \
      -reconnect_delay_max 10 \
      "rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY"
    
    EXIT_CODE=$?
    
    # Códigos de salida normales
    if [ $EXIT_CODE -eq 0 ] || [ $EXIT_CODE -eq 255 ]; then
      echo "✓ Video completado: $(basename "$video")"
      return 0
    fi
    
    # Error de conexión - reintentar
    echo "⚠ Error de transmisión (código: $EXIT_CODE)"
    retries=$((retries+1))
    
    if [ $retries -lt $MAX_RETRIES ]; then
      echo "→ Reintentando en ${RETRY_DELAY}s..."
      sleep $RETRY_DELAY
    fi
  done
  
  echo "✗ No se pudo transmitir $(basename "$video") después de $MAX_RETRIES intentos"
  return 1
}

# Loop principal
while true
do
  echo ""
  echo "=========================================="
  echo "Buscando videos en $VIDEO_DIR..."
  
  mapfile -t VIDEOS < <(find "$VIDEO_DIR" -type f -iname "*.mp4" | shuf)
  TOTAL=${#VIDEOS[@]}
  
  if [ "$TOTAL" -eq 0 ]; then
    echo "⚠ No hay videos en $VIDEO_DIR"
    sleep 15
    continue
  fi
  
  echo "✓ Videos encontrados: $TOTAL"
  echo "=========================================="
  
  for VIDEO in "${VIDEOS[@]}"
  do
    if [ ! -f "$VIDEO" ]; then
      echo "⚠ Archivo no encontrado: $(basename "$VIDEO")"
      continue
    fi
    
    stream_video "$VIDEO"
    
    # Pausa entre videos para estabilidad
    sleep 3
  done
  
  echo ""
  echo "Playlist completada - reiniciando ciclo..."
  sleep 5
done
