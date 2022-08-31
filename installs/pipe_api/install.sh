#!/bin/bash

# Install updates and prereqs
sudo apt update
yes | sudo apt upgrade
sudo apt install -y unzip nginx certbot python3-certbot-nginx aspnetcore-runtime-6.0

# Create app folder
sudo mkdir /pipe_app

# Configure firewall
sudo ufw allow 'Nginx Full'
sudo ufw enable

# Move to app directory and unzip
sudo mv /home/pipey/pipes.zip /pipe_app/ 
sudo unzip /pipe_app/pipes.zip -d /pipe_app
sudo rm /pipe_app/pipes.zip

# Setup config file
sudo mv /pipe_app/appsettings.Development.json /pipe_app/appsettings.Production.json

# Start nginx
sudo service nginx start

# Replace nginx config
sudo rm /etc/nginx/sites-available/default
sudo cat > /etc/nginx/sites-available/default <<EOL
server {
    listen        80;
    server_name   api.iddeal.dev;
    location / {
        proxy_pass         http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection keep-alive;
        proxy_set_header   Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}

server {
    listen   80 default_server;
    # listen [::]:80 default_server deferred;
    return   444;
}
EOL

# Reload nginx config
sudo nginx -s reload

# Run app as a service
sudo cat > /etc/systemd/system/pipeapp.service <<EOL
[Unit]
Description=Pipes API app

[Service]
WorkingDirectory=/pipe_app
ExecStart=/usr/bin/dotnet /pipe_app/Pipes.Web.dll
Restart=always
# Restart service after 10 seconds if the dotnet service crashes:
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=dotnet-pipesapi
User=pipes
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl enable pipeapp.service
sudo systemctl start pipeapp.service
sudo systemctl status pipeapp.service

# Set up Certbot for SSL
sudo certbot --nginx -d api.iddeal.dev
