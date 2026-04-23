#!/bin/bash

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "Certificates generation"
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo ""

# Load configuration
if [ ! -f ".env" ]; then
    echo "ERROR: .env not found!"
    exit 1
fi

source .env

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "ERROR: DOMAIN and EMAIL must be set in .env"
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
echo "Getting SSL certificates for all subdomains..."
sudo certbot certonly \
    --standalone \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    -d "$DOMAIN" \
    -d "auth.$DOMAIN" \
    -d "git.$DOMAIN" \
    -d "n8n.$DOMAIN" \
    -d "music.$DOMAIN" \
    -d "docs.$DOMAIN" \
    -d "synapse.$DOMAIN"

# Create ssl directory
mkdir -p ssl/

# Copy certificates to local ssl directory
echo "Copying certificates to local ssl directory..."
if sudo test -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem"; then
    sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ssl/
    sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ssl/
    
    # Change ownership to current user
    sudo chown $USER:$USER ssl/*
    
    echo "SSL certificates copied to ssl/ directory"
    
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

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "SSL setup completed successfully!"
echo "Certificates are in: $(pwd)/ssl/"
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo ""
