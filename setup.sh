#!/bin/bash

# Exit on any error
set -e

# Check if script is run as root (we'll switch to user for AUR builds)
if [ "$EUID" -eq 0 ]; then
    echo "This script should not be run as root directly. Use 'sudo' from a regular user."
    exit 1
fi

# Default PostgreSQL password (override with environment variable)
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-"secure_default_password"}

# Update the system (requires root)
echo "Updating system..."
sudo pacman -Syu --noconfirm

# Install base development tools and dependencies (requires root)
echo "Installing base tools and dependencies..."
sudo pacman -S --noconfirm base-devel git wget curl unzip

# Install yay (AUR helper) as the current user
echo "Installing yay (AUR helper)..."
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
fi

# Install X11 and a basic desktop environment (XFCE) (requires root)
echo "Installing XFCE desktop environment..."
sudo pacman -S --noconfirm xfce4 xfce4-goodies xorg lightdm lightdm-gtk-greeter
sudo systemctl enable lightdm

# Install Google Chrome (AUR package)
echo "Installing Google Chrome..."
yay -S --noconfirm google-chrome

# Install Visual Studio Code (AUR package)
echo "Installing Visual Studio Code..."
yay -S --noconfirm visual-studio-code-bin

# Install Cursor (AUR package)
echo "Installing Cursor..."
yay -S --noconfirm cursor

# Install Postman (AUR package)
echo "Installing Postman..."
yay -S --noconfirm postman-bin

# Install MongoDB and MongoDB Compass (AUR packages)
echo "Installing MongoDB and MongoDB Compass..."
yay -S --noconfirm mongodb-bin mongodb-compass
sudo systemctl enable --now mongod

# Install NVM (Node Version Manager) as the current user
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
# Load NVM into the current shell session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# Install the latest LTS version of Node.js
nvm install --lts
nvm use --lts

# Install PostgreSQL (requires root)
echo "Installing PostgreSQL..."
sudo pacman -S --noconfirm postgresql

# Initialize PostgreSQL database (requires root)
echo "Initializing PostgreSQL database..."
sudo mkdir -p /var/lib/postgres/data
sudo chown postgres:postgres /var/lib/postgres/data
sudo -u postgres initdb -D /var/lib/postgres/data

# Start and enable PostgreSQL service (requires root)
echo "Starting and enabling PostgreSQL service..."
sudo systemctl enable --now postgresql

# Set up PostgreSQL default user (postgres) with a password (requires root)
echo "Setting up PostgreSQL user with password: $POSTGRES_PASSWORD"
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASSWORD';"

# Install additional useful tools (requires root)
echo "Installing additional utilities..."
sudo pacman -S --noconfirm vim nano terminator firefox

# Final message
echo "Setup complete!"
echo " - Desktop environment: XFCE (start with 'startx' or reboot)"
echo " - PostgreSQL user: postgres, Password: $POSTGRES_PASSWORD"
echo " - MongoDB is running (systemctl status mongod to verify)"
echo "Rebooting in 5 seconds... (Ctrl+C to cancel)"
sleep 5
sudo reboot
