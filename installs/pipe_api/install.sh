#!/bin/bash

# Install prereqs
sudo apt install -y unzip nginx certbot python3-certbot-nginx aspnetcore-runtime-6.0

# Create app folder
sudo mkdir /pipe_app

# Configure firewall
sudo ufw allow 'Nginx Full'
yes | sudo ufw enable

# Move to app directory and unzip
sudo mv /home/pipey/pipes.zip /pipe_app/ 
sudo unzip /pipe_app/pipes.zip -d /pipe_app
sudo rm /pipe_app/pipes.zip

# Setup config file
sudo mv /pipe_app/appsettings.Development.json /pipe_app/appsettings.Production.json

# Start nginx
sudo service nginx start

# Replace nginx config
cat > /home/pipey/default <<'EOL'
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
sudo mv /home/pipey/default /etc/nginx/sites-available/default

# Reload nginx config
sudo nginx -s reload

# Run app as a service
cat > /home/pipey/pipeapp.service <<'EOL'
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
User=pipey
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
EOL
sudo mv /home/pipey/pipeapp.service /etc/systemd/system/pipeapp.service

sudo systemctl enable pipeapp.service
sudo systemctl start pipeapp.service
sudo systemctl status pipeapp.service

# Set up Certbot for SSL
sudo certbot --nginx -d api.iddeal.dev
