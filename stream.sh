#!/bin/bash

# Configuración de variables
YOUTUBE_KEY="${YOUTUBE_KEY:-your-youtube-code}"
SERVER_PORT="${PORT:-8080}"
VIDEO_DIR="/app"

# Instalar dependencias necesarias
apt-get update && apt-get install -y ffmpeg nginx

# Configurar nginx para servir archivos de video
mkdir -p /var/www/html
cat > /etc/nginx/sites-available/default << EOF
server {
    listen $SERVER_PORT default_server;
    listen [::]:$SERVER_PORT default_server;
    
    root /var/www/html;
    
    location / {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Iniciar nginx
service nginx start

# Crear playlist con videos aleatorios
create_playlist() {
    # Limpiar directorio web
    rm -f /var/www/html/*.mp4
    
    # Obtener lista de videos y mezclarlos aleatoriamente
    VIDEOS=($(ls $VIDEO_DIR/*.mp4 2>/dev/null | shuf))
    
    if [ ${#VIDEOS[@]} -eq 0 ]; then
        echo "Error: No se encontraron videos en $VIDEO_DIR"
        exit 1
    fi
    
    echo "Videos encontrados: ${#VIDEOS[@]}"
    
    # Crear archivo de lista para FFmpeg
    rm -f /tmp/playlist.txt
    for video in "${VIDEOS[@]}"; do
        echo "file '$video'" >> /tmp/playlist.txt
    done
}

# Función para transmitir a YouTube
stream_to_youtube() {
    while true; do
        echo "Creando nueva playlist aleatoria..."
        create_playlist
        
        echo "Iniciando transmisión a YouTube..."
        
        # Configuración OPTIMIZADA para bajo consumo de CPU
        ffmpeg -f concat -safe 0 -stream_loop -1 \
            -re -i /tmp/playlist.txt \
            -c:v libx264 \
            -preset ultrafast \
            -tune zerolatency \
            -crf 35 \
            -maxrate 1000k \
            -bufsize 4000k \
            -g 60 \
            -keyint_min 60 \
            -sc_threshold 0 \
            -profile:v baseline \
            -level 3.0 \
            -pix_fmt yuv420p \
            -c:a aac \
            -b:a 128k \
            -ar 44100 \
            -ac 2 \
            -threads 2 \
            -f flv "rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY"
        
        echo "Stream finalizado, reiniciando con nueva playlist..."
        sleep 2
    done
}

# Iniciar transmisión
stream_to_youtube

