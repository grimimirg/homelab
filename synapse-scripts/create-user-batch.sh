#!/bin/bash

# Batch User Creation Script
echo "=== Matrix Batch User Creation ==="
echo ""

# Check if Matrix server is running
if ! docker-compose ps synapse | grep -q "Up"; then
    echo "ERROR: Synapse container is not running!"
    exit 1
fi

# Create users.txt example if not exists
if [ ! -f "users.txt" ]; then
    echo "Creating example users.txt file..."
    cat > users.txt << EOF
# Matrix Users File
# Format: username:password:admin(true/false)
# Example:
andrea:my_secure_password:true
mario:another_password:false
luigi:super_password:false
EOF
    echo "Created users.txt with examples"
    echo "Edit users.txt and run this script again"
    exit 0
fi

source config.env

echo "Reading users from users.txt..."
echo ""

while IFS=':' read -r username password is_admin || [ -n "$username" ]; do
    # Skip comments and empty lines
    if [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]]; then
        continue
    fi
    
    # Set admin flag
    if [[ "$is_admin" == "true" ]]; then
        admin_flag="--admin"
        admin_text="ADMIN"
    else
        admin_flag=""
        admin_text="Regular"
    fi
    
    echo "Creating: @$username:$DOMAIN ($admin_text)"
    
    # Create user
    docker-compose exec -T synapse register_new_matrix_user \
        -c /data/homeserver.yaml \
        -u "$username" \
        -p "$password" \
        $admin_flag \
        http://localhost:8008
    
    if [ $? -eq 0 ]; then
        echo "@$username:$DOMAIN created successfully"
    else
        echo "Failed to create @$username:$DOMAIN"
    fi
    echo ""
    
done < users.txt

echo "Batch user creation completed!"
