#!/bin/bash
# VERSIÓN CPU MUY BAJO (25-35%) - CON VIDEOS RANDOM

YOUTUBE_KEY="${YOUTUBE_KEY:-your-youtube-code}"
SERVER_PORT="${PORT:-8080}"
VIDEO_DIR="/app"

apt-get update && apt-get install -y ffmpeg nginx

mkdir -p /var/www/html
cat > /etc/nginx/sites-available/default << EOF
server {
    listen $SERVER_PORT default_server;
    listen [::]:$SERVER_PORT default_server;
    root /var/www/html;
    location / {
        add_header 'Access-Control-Allow-Origin' '*';
        try_files \$uri \$uri/ =404;
    }
}
EOF

service nginx start

create_playlist() {
    # Videos mezclados aleatoriamente
    VIDEOS=($(ls $VIDEO_DIR/*.mp4 2>/dev/null | shuf))
    
    if [ ${#VIDEOS[@]} -eq 0 ]; then
        echo "Error: No se encontraron videos"
        exit 1
    fi
    
    echo "=========================================="
    echo "Videos totales: ${#VIDEOS[@]}"
    echo "Orden aleatorio:"
    for video in "${VIDEOS[@]}"; do
        echo "  → $(basename $video)"
    done
    echo "=========================================="
    
    rm -f /tmp/playlist.txt
    for video in "${VIDEOS[@]}"; do
        echo "file '$video'" >> /tmp/playlist.txt
    done
}

stream_to_youtube() {
    while true; do
        create_playlist
        
        echo "Streaming en 720p @ 20fps (CPU bajo)..."
        
        # CONFIGURACIÓN ULTRA LIGERA PERO FUNCIONAL
        ffmpeg -f concat -safe 0 -stream_loop -1 \
            -re -i /tmp/playlist.txt \
            -c:v libx264 \
            -preset ultrafast \
            -crf 30 \
            -s 1280x720 \
            -r 20 \
            -maxrate 1000k \
            -bufsize 2000k \
            -g 60 \
            -c:a aac \
            -b:a 64k \
            -ar 44100 \
            -f flv "rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY"
        
        echo "Reiniciando en 5 segundos..."
        sleep 5
    done
}

stream_to_youtube


