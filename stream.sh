

#!/bin/bash

# Configuración de variables
VIDEO_FILE="${VIDEO_FILE:-rickroll.mp4}"
YOUTUBE_KEY="${YOUTUBE_KEY:-your-youtube-code}"
SERVER_PORT="${PORT:-8080}"

# Instalar dependencias necesarias
apt-get update && apt-get install -y ffmpeg nginx

# Configurar nginx
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

# Loop con videos aleatorios
while true; do
    # Obtener lista de videos
    VIDEOS=(/app/*.mp4)
    
    if [ ${#VIDEOS[@]} -eq 0 ]; then
        echo "Error: No hay videos en /app/"
        exit 1
    fi
    
    # Seleccionar video aleatorio
    VIDEO=${VIDEOS[$RANDOM % ${#VIDEOS[@]}]}
    echo "========================================="
    echo "Videos totales: ${#VIDEOS[@]}"
    echo "Reproduciendo: $(basename $VIDEO)"
    echo "========================================="
    
    # Copiar a nginx
    cp "$VIDEO" /var/www/html/video.mp4
    
    # Transmitir (configuración simplificada y optimizada)
    ffmpeg -stream_loop 5 \
        -re -i "http://localhost:$SERVER_PORT/video.mp4" \
        -c:v libx264 \
        -preset superfast \
        -maxrate 1500k \
        -bufsize 3000k \
        -g 50 \
        -c:a aac \
        -b:a 128k \
        -ar 44100 \
        -f flv "rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY"
    
    echo "Video terminado. Siguiente en 2 segundos..."
    sleep 2
done
