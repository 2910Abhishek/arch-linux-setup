#!/bin/bash

# Exit on any error, but handle specific cases
set -e

# Warn if running as root, but don’t exit
if [ "$EUID" -eq 0 ]; then
    echo "Warning: Running as root is not recommended, but proceeding anyway."
fi

# Default PostgreSQL password (override with environment variable)
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-"secure_default_password"}

# Function to handle errors and exit gracefully
handle_error() {
    echo "Error: $1"
    exit 1
}

# Update the system (requires root)
echo "Updating system..."
sudo pacman -Syu --noconfirm || handle_error "Failed to update system"

# Install base development tools and dependencies (requires root)
echo "Installing base tools and dependencies..."
sudo pacman -S --noconfirm base-devel git wget curl unzip || handle_error "Failed to install base tools"

# Install yay (AUR helper) as the current user
echo "Installing yay (AUR helper)..."
if ! command -v yay &> /dev/null; then
    # Clean up /tmp/yay if it exists
    [ -d /tmp/yay ] && rm -rf /tmp/yay
    git clone https://aur.archlinux.org/yay.git /tmp/yay || handle_error "Failed to clone yay repository"
    cd /tmp/yay
    makepkg -si --noconfirm || handle_error "Failed to build and install yay"
    cd -
    rm -rf /tmp/yay
else
    echo "yay is already installed, skipping..."
fi

# Install X11 and a basic desktop environment (XFCE) (requires root)
echo "Installing XFCE desktop environment..."
sudo pacman -S --noconfirm xfce4 xfce4-goodies xorg lightdm lightdm-gtk-greeter || handle_error "Failed to install XFCE"
sudo systemctl enable lightdm || handle_error "Failed to enable lightdm"

# Install Google Chrome (AUR package)
echo "Installing Google Chrome..."
yay -S --noconfirm google-chrome || handle_error "Failed to install Google Chrome"

# Install Visual Studio Code (AUR package)
echo "Installing Visual Studio Code..."
yay -S --noconfirm visual-studio-code-bin || handle_error "Failed to install VS Code"

# Install Cursor (AUR package)
echo "Installing Cursor..."
yay -S --noconfirm cursor || handle_error "Failed to install Cursor"

# Install Postman (AUR package)
echo "Installing Postman..."
yay -S --noconfirm postman-bin || handle_error "Failed to install Postman"

# Install MongoDB and MongoDB Compass (AUR packages)
echo "Installing MongoDB and MongoDB Compass..."
yay -S --noconfirm mongodb-bin mongodb-compass || handle_error "Failed to install MongoDB and Compass"
sudo systemctl enable --now mongod || handle_error "Failed to start MongoDB"

# Install NVM (Node Version Manager) as the current user
echo "Installing NVM..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || handle_error "Failed to install NVM"
fi
# Load NVM into the current shell session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# Install the latest LTS version of Node.js
nvm install --lts || handle_error "Failed to install Node.js LTS"
nvm use --lts || handle_error "Failed to use Node.js LTS"

# Install PostgreSQL (requires root)
echo "Installing PostgreSQL..."
sudo pacman -S --noconfirm postgresql || handle_error "Failed to install PostgreSQL"

# Initialize PostgreSQL database (requires root)
echo "Initializing PostgreSQL database..."
if [ ! -d /var/lib/postgres/data ] || [ -z "$(ls -A /var/lib/postgres/data)" ]; then
    sudo mkdir -p /var/lib/postgres/data
    sudo chown postgres:postgres /var/lib/postgres/data
    sudo -u postgres initdb -D /var/lib/postgres/data || handle_error "Failed to initialize PostgreSQL"
fi

# Start and enable PostgreSQL service (requires root)
echo "Starting and enabling PostgreSQL service..."
sudo systemctl enable --now postgresql || handle_error "Failed to start PostgreSQL"

# Set up PostgreSQL default user (postgres) with a password (requires root)
echo "Setting up PostgreSQL user with password: $POSTGRES_PASSWORD"
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASSWORD';" || handle_error "Failed to set PostgreSQL password"

# Install additional useful tools (requires root)
echo "Installing additional utilities..."
sudo pacman -S --noconfirm vim nano terminator firefox || handle_error "Failed to install additional utilities"

# Final message
echo "Setup complete!"
echo " - Desktop environment: XFCE (start with 'startx' or reboot)"
echo " - PostgreSQL user: postgres, Password: $POSTGRES_PASSWORD"
echo " - MongoDB is running (systemctl status mongod to verify)"
echo "Rebooting in 5 seconds... (Ctrl+C to cancel)"
sleep 5
sudo reboot || echo "Reboot failed, please reboot manually"
