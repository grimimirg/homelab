#!/bin/bash

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "Authelia SSO Setup"
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo ""

if [ ! -f ".env" ]; then
    echo "ERROR: .env file not found!"
    exit 1
fi

source .env

echo "This script will configure Authelia with the default admin user."
echo ""
echo "Default credentials:"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "You can change the password after first login via Authelia UI."
echo ""

read -p "Do you want to continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "The admin user is already configured in the templates."
echo "Password hash for 'admin' is pre-generated."
echo ""
echo "✓ Admin user: admin"
echo "✓ Password: admin"
echo "✓ Email: ${EMAIL}"
echo ""
echo "After deployment, you can:"
echo "  1. Access https://auth.${DOMAIN}"
echo "  2. Login with admin:admin"
echo "  3. Change password in settings"
echo ""
echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "  Setup Complete!"
echo ""
echo "Next steps:"
echo "  1. Run: ./scaffold.sh"
echo "  2. Run: ./build.sh"
echo "  3. Access: https://auth.${DOMAIN}"
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo ""
