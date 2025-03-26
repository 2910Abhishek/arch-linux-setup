#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Get the username of the user who invoked sudo
REAL_USER=${SUDO_USER:-$(whoami)}
HOME_DIR=$(eval echo ~$REAL_USER)

# Function to print colored output
print_status() {
    echo -e "\e[1;34m==> $1\e[0m"
}

# Store password at the beginning
print_status "Please enter your password once for all operations:"
read -s PASSWORD
echo

# Function to check if command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "\e[1;32m==> Success: $1\e[0m"
    else
        echo -e "\e[1;31m==> Error: $1\e[0m"
        exit 1
    fi
}

# Function to check if an AUR package is installed
is_aur_package_installed() {
    yay -Qi "$1" >/dev/null 2>&1
}

# Install yay if not already installed
print_status "Checking/Installing yay AUR helper"
if ! command -v yay &> /dev/null; then
    cd /tmp
    rm -rf yay  # Clean up any existing yay directory
    sudo -u $REAL_USER git clone https://aur.archlinux.org/yay.git
    cd yay
    sudo -u $REAL_USER makepkg -si --noconfirm
    cd ..
    rm -rf yay
    check_status "yay installation"
else
    echo "yay is already installed, skipping..."
fi

# Add system update
print_status "Updating system packages"
pacman -Syu --noconfirm
check_status "System update"

# Install AUR packages as non-root user
print_status "Installing AUR packages"
AUR_PACKAGES=(
    "postman-bin"
    "mongodb-compass"
    "mongodb-bin"
    "google-chrome"
    "spotify"
    "nvm"
    "visual-studio-code-bin"
)

for package in "${AUR_PACKAGES[@]}"; do
    if ! is_aur_package_installed "$package"; then
        echo "Installing $package..."
        echo "$PASSWORD" | sudo -u $REAL_USER yay -S --noconfirm "$package"
    else
        echo "$package is already installed, skipping..."
    fi
done
check_status "AUR packages installation"

# Configure NVM if installed
print_status "Checking/Configuring NVM"
if ! grep -q "NVM_DIR" "$HOME_DIR/.bashrc"; then
    sudo -u $REAL_USER bash -c "cat >> $HOME_DIR/.bashrc << 'EOL'
# NVM configuration
export NVM_DIR=\"\$HOME/.nvm\"
[ -s \"/usr/share/nvm/init-nvm.sh\" ] && \\. \"/usr/share/nvm/init-nvm.sh\"
EOL"
    check_status "NVM configuration"
else
    echo "NVM already configured, skipping..."
fi

print_status "Installation completed successfully!"
echo "Please note: Some changes might require a logout or system restart to take effect."
echo "Script was run as root/sudo by user: $REAL_USER"

# Add restart prompt
read -p "Would you like to restart the system now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Restarting system in 5 seconds..."
    sleep 5
    reboot
else
    echo "Please remember to restart your system later for all changes to take effect."
fi
