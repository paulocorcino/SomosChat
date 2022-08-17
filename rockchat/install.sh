#!/bin/bash

read -p "Insert URL your RocketChat: " url

if [[ -n "$url" ]]
then
    echo "Install RC on $url"
else
    echo "URL is required"
    exit 1
fi

sudo apt-get -y update
apt install snapd nginx -y
sudo snap install rocketchat-server

rm /etc/nginx/sites-enabled/default

cat >/etc/nginx/sites-enabled/default <<EOL

upstream rocket_backend {
  server 127.0.0.1:3000;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
	root /var/www/html;

	server_name _;

    access_log /var/log/nginx/rocketchat-access.log;
    error_log /var/log/nginx/rocketchat-error.log;

    location / {
        proxy_pass http://rocket_backend/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forward-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forward-Proto http;
        proxy_set_header X-Nginx-Proxy true;

        proxy_redirect off;
    }
}
EOL

sudo systemctl restart nginx
sudo systemctl enable nginx
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d $url -m paulo.corcino@somos.chat --agree-tos 
sudo systemctl restart nginx
