#!/bin/bash

if [[ ${UID} -ne 0 ]]; then
    echo "Please Run with sudo or root"
    exit 1
fi

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

create_user() {
    local username=$1
    local workspace="/home/$username/workspace"

    # Create User
    echo "Creating user $username"
    useradd -m -s /bin/bash "$username" || {
        echo "Error: Failed to create user $username" >&2
        exit 1
    }

    while true; do
        read -s -p "Enter password for $username: " password
        echo
        read -s -p "Re-enter password for $username: " password_confirm
        if [ "$password" == "$password_confirm" ]; then
            echo "$username:$password" | chpasswd
            break
        else
            echo "Passwords do not match. Please try again."
        fi
    done

    # Set password expiration (30 days)
    sudo chage -M 30 "$username"
    
    # Force password change on first login
    sudo chage -d 0 "$username"

    echo "Creating workspace directory: $workspace"
    mkdir -p "$workspace" || {
        echo "Error: Failed to create workspace directory" >&2
        exit 1
    }

    chown $username:$username  "$workspace"
    chmod 700 "$workspace"

    echo "----------------------------------------"
    echo -e "Created user ${GREEN}$username${NC}"
    echo -e "Workspace: ${GREEN}$workspace${NC} (permissions: 700)"
    echo -e "${RED}Password expires in 30 days, change required on first login${NC}"
    echo "----------------------------------------"
}

enforce_password_policy() {
    echo "Configuring password policies..."
    sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 30/' /etc/login.defs
    sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs
    sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs

    # Configure PAM settings for password complexity
    echo "Updating PAM password complexity settings"
    sudo apt-get install -y libpam-pwquality  # Ensure the module is installed
    echo "password requisite pam_pwquality.so retry=3 minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1" | sudo tee -a /etc/security/pwquality.conf
}

list_users() {
    echo "All System Users (Ordered by UID Descending)"
    echo "-------------------------------------------"
    printf "| %-20s | %-10s | %-30s |\n" "Username" "UID" "Home Directory"
    echo "|----------------------|------------|--------------------------------|"
    
    # Read from /etc/passwd, sort by UID (field 3) in reverse order
    sort -t: -k3 -nr /etc/passwd | while IFS=: read -r username _ uid _ _ home _; do
        printf "| %-20s | %-10s | %-30s |\n" "$username" "$uid" "$home"
    done
    echo "|----------------------|------------|--------------------------------|"
}

echo "User Management Script"
echo "---------------------"
echo "1. List existing users"
echo "2. Create new users"
echo "---------------------"
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1)
        echo "Existing users:"
        list_users
        ;;
    2)
        read -p "Enter username: " username
        create_user "$username"
        enforce_password_policy
        ;;
    *)
        echo "Invalid choice. Please enter 1 or 2."
        ;;
esac


