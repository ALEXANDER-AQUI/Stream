#!/bin/bash
# VERSIÓN OPTIMIZADA PARA 100 GB/MES (34+ DÍAS 24/7)
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
        
        echo "Streaming en 480p @ 15fps (optimizado 100GB/mes)..."
        
        # CONFIGURACIÓN OPTIMIZADA PARA 100 GB/MES
        ffmpeg -f concat -safe 0 -stream_loop -1 \
            -re -i /tmp/playlist.txt \
            -c:v libx264 \
            -preset veryfast \
            -tune zerolatency \
            -crf 28 \
            -s 854x480 \
            -r 15 \
            -threads 1 \
            -maxrate 240k \
            -bufsize 480k \
            -g 45 \
            -keyint_min 45 \
            -pix_fmt yuv420p \
            -c:a aac \
            -b:a 32k \
            -ar 22050 \
            -ac 1 \
            -f flv "rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY"
        
        echo "Reiniciando en 5 segundos..."
        sleep 5
    done
}

stream_to_youtube
