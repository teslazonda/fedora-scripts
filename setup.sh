#!/usr/bin/env bash

set -euo pipefail

echo "==> Updating system packages..."
sudo dnf upgrade -y

echo "==> Installing development tools and dependencies..."
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y \
    curl \
    git \
    wget \
    zsh \
    vim-enhanced \
    openssl-devel \
    pkgconf-pkg-config \
    rust \
    cargo \
    rustfmt || true

echo "==> Setting Zsh as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
fi

echo "==> Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "==> Installing zsh-syntax-highlighting plugin..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

echo "==> Enabling plugin in .zshrc..."
ZSHRC="$HOME/.zshrc"

# Ensure plugins line exists, then append plugin if missing
if grep -q "^plugins=" "$ZSHRC"; then
    if ! grep -q "zsh-syntax-highlighting" "$ZSHRC"; then
        sed -i 's/^plugins=(\(.*\))/plugins=(\1 zsh-syntax-highlighting)/' "$ZSHRC"
    fi
else
    echo "plugins=(zsh-syntax-highlighting)" >> "$ZSHRC"
fi

echo "==> Installing VS Code..."
if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo tee /etc/yum.repos.d/vscode.repo > /dev/null <<EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
fi

sudo dnf check-update || true
sudo dnf install -y code

echo "==> Configuring Vim..."
VIMRC="$HOME/.vimrc"

if ! grep -q "inoremap jk <Esc>" "$VIMRC" 2>/dev/null; then
    cat <<'EOF' >> "$VIMRC"

" Use 'jk' to exit insert mode
inoremap jk <Esc>
EOF
fi

echo "==> Installation complete!"
echo "NOTE: Restart your terminal or run 'exec zsh' to apply changes."
