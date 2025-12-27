# This file restores nginx-proxy configuration from a backup location

# Define DOCKER_FOLDER if not already set (e.g., for direct execution)
source ../scripts/ensure-DOCKER_FOLDER.sh

# Go to backup folder
cd ../backup/nginx-pm

# Ensure target directories exist before copying
mkdir -p "${DOCKER_FOLDER}/nginx-pm/data"
mkdir -p "${DOCKER_FOLDER}/nginx-pm/letsencrypt"

# Copy old config to current directory
sudo cp -r ./data/. ${DOCKER_FOLDER}/nginx-pm/data/.
sudo cp -r ./letsencrypt/. ${DOCKER_FOLDER}/nginx-pm/letsencrypt/

# Ensure the current user is the owner of the files
sudo chown -R $USER:$USER ${DOCKER_FOLDER}/nginx-pm

# replace any DNS names in the config files
# Define the target directory
TARGET_DIR="${DOCKER_FOLDER}/nginx-pm/data/nginx/proxy_host"
# 1. Ask if the user wants to change the DNS name
read -p "Do you want to change the DNS name in proxy hosts? (y/n): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    source ../scripts/ensure-sqlite-drivers.sh
    # 2. Ask for old and new DNS names
    read -p "Enter the OLD DNS name (e.g., my1.duckdns.org): " old_dns
    read -p "Enter the NEW DNS name (e.g., my2.duckdns.org): " new_dns

    if [[ -z "$old_dns" || -z "$new_dns" ]]; then
        echo "Error: DNS names cannot be empty."
        exit 1
    fi

    echo "Searching for occurrences of '$old_dns' in $TARGET_DIR..."

    # 3. Replace the DNS name block in all files under the directory
    # We use a different delimiter (|) in sed in case the DNS names contain slashes (unlikely but safe)
    # We use -i to edit files in-place
    
    # First, let's show what will be changed (Dry Run)
    echo "--- Preview of changes ---"
    grep -r "$old_dns" "$TARGET_DIR" | sed "s/$old_dns/$new_dns/g" | head -n 5
    echo "--------------------------"

    read -p "Proceed with the replacement in all files? (y/n): " final_confirm
    
    if [[ $final_confirm =~ ^[Yy]$ ]]; then
        # Find all files in the directory and apply sed
        find "$TARGET_DIR" -type f -exec sed -i "s/$old_dns/$new_dns/g" {} +
        echo "Success: Replacement complete."
        sudo sqlite3 "${DOCKER_FOLDER}/nginx-pm/data/database.sqlite" "UPDATE proxy_host SET domain_names = REPLACE(domain_names, '$old_dns', '$new_dns');"
        echo "Database updated."
    else
        echo "Operation cancelled."
    fi
else
    echo "No changes made."
fi

# Replace any IP addresses to the old server that has been moved to this new machine
# Define the target directory
TARGET_DIR="${DOCKER_FOLDER}/nginx-pm/data/nginx/proxy_host"

# 1. Ask if the user wants to change the Server IP
read -p "Do you want to change a backend server IP address? (y/n): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    source ../scripts/ensure-sqlite-drivers.sh
    # 2. Ask for old and new IP addresses
    read -p "Enter the OLD IP (e.g., 192.168.68.117): " old_ip
    read -p "Enter the NEW IP (e.g., 192.168.68.120): " new_ip

    # Basic validation to ensure inputs aren't empty
    if [[ -z "$old_ip" || -z "$new_ip" ]]; then
        echo "Error: IP addresses cannot be empty."
        exit 1
    fi

    echo "Scanning files in $TARGET_DIR..."

    # Check if the old IP actually exists in the files first
    grep_check=$(grep -r "$old_ip" "$TARGET_DIR")

    if [ -z "$grep_check" ]; then
        echo "Could not find any files containing the IP: $old_ip"
        exit 1
    fi

    # 3. Show a preview of the change
    echo "--- Preview of change ---"
    echo "From: set \$server \"$old_ip\";"
    echo "To:   set \$server \"$new_ip\";"
    echo "-------------------------"

    read -p "Proceed with replacement in all matching files? (y/n): " final_confirm

    if [[ $final_confirm =~ ^[Yy]$ ]]; then
        # Use sed to replace the IP. 
        # We escape the dots in the IP for the search pattern so they are treated literally.
        old_ip_escaped=$(echo $old_ip | sed 's/\./\\./g')
        
        find "$TARGET_DIR" -type f -exec sed -i "s/$old_ip_escaped/$new_ip/g" {} +
        
        echo "Success: All occurrences of $old_ip have been updated to $new_ip."

        # Run the SQL update (Replace the IPs with yours)
        # This updates the 'forward_host' column in the 'proxy_host' table
        sudo sqlite3 ${DOCKER_FOLDER}/nginx-pm/data/database.sqlite "UPDATE proxy_host SET forward_host = '$new_ip' WHERE forward_host = '$old_ip';"
        echo "Database updated."
    else
        echo "Operation cancelled."
    fi
else
    echo "No changes made."
fi

echo "Note: Remember to restart Nginx Proxy Manager to apply changes."

# Go back to previous folder
cd -
