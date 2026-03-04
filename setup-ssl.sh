#!/bin/bash

# Matrix Server SSL Setup Script
echo "Matrix Server SSL Setup"

# Load configuration
if [ ! -f "config.env" ]; then
    echo "ERROR: config.env not found!"
    exit 1
fi

source config.env

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "ERROR: DOMAIN and EMAIL must be set in config.env"
    exit 1
fi

echo "Domain: $DOMAIN"
echo "Email: $EMAIL"

# Install certbot if not present
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    sudo apt update
    sudo apt install -y certbot
fi

# Stop nginx if running
sudo systemctl stop nginx 2>/dev/null || true

# Get SSL certificates
echo "Getting SSL certificates..."
sudo certbot certonly \
    --standalone \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    -d "$DOMAIN"

# Create ssl directory
mkdir -p ssl/

# Copy certificates to local ssl directory
echo "Copying certificates to local ssl directory..."
if sudo test -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem"; then
    sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ssl/
    sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ssl/
    
    # Change ownership to current user
    sudo chown $USER:$USER ssl/*
    
    echo "✅ SSL certificates copied to ssl/ directory"
    
    # Verify certificates
    ls -la ssl/
else
    echo "ERROR: Certificate files not found!"
    exit 1
fi

# Setup certificate renewal
echo "Setting up automatic certificate renewal..."
sudo crontab -l 2>/dev/null | grep -q "certbot renew" || {
    (sudo crontab -l 2>/dev/null; echo "0 12 * * * certbot renew --quiet --deploy-hook 'cp /etc/letsencrypt/live/$DOMAIN/*.pem /home/$USER/synapse-server/ssl/ && chown $USER:$USER /home/$USER/synapse-server/ssl/*'") | sudo crontab -
}

echo "SSL setup completed successfully!"
echo "Certificates are in: $(pwd)/ssl/"
