#!/bin/bash

set -e

ENV_PATH="$HOME/.Jenv"
INSTALL_DIR="$HOME/.local/share/applications"
BIN_DIR="$HOME/.local/bin"
MIME_DIR="$HOME/.local/share/mime"
CONFIG_DIR="$HOME/.config"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

TOTAL_STAGES=4
CURRENT_STAGE=0

# Update the progress bar after each installation stage completes.
complete_stage() {
    CURRENT_STAGE=$((CURRENT_STAGE + 1))
    local percent=$((CURRENT_STAGE * 100 / TOTAL_STAGES))
    local filled=$((CURRENT_STAGE * 40 / TOTAL_STAGES))
    local empty=$((40 - filled))
    local filled_bar
    local empty_bar

    printf -v filled_bar '%*s' "$filled" ''
    printf -v empty_bar '%*s' "$empty" ''
    filled_bar=${filled_bar// /=}

    printf "\r[%s%s] %3d%% - %s\n" \
        "$filled_bar" "$empty_bar" "$percent" "$1"
}

print_python_setup_help() {
    local distro="your distribution"

    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        distro="${ID:-$distro}"
    fi

    echo "❌ Python virtual-environment support is unavailable."
    echo "Install Python 3 and its venv package for $distro, then run this script again."
    case "$distro" in
        debian|ubuntu|linuxmint|pop)
            echo "Example: sudo apt install python3 python3-venv"
            ;;
        fedora|rhel|centos|rocky|almalinux)
            echo "Example: sudo dnf install python3"
            ;;
        arch|manjaro)
            echo "Example: sudo pacman -S python"
            ;;
        opensuse*|sles)
            echo "Example: sudo zypper install python311"
            ;;
        gentoo)
            echo "Example: sudo emerge dev-lang/python"
            ;;
    esac
}

# Step 1: Create virtual environment if not found
if [ ! -d "$ENV_PATH" ]; then
    echo "🔧 No virtual environment found at $ENV_PATH. Creating one..."
    if ! command -v python3 >/dev/null 2>&1; then
        print_python_setup_help
        exit 1
    fi
    if ! python3 -m venv "$ENV_PATH"; then
        rm -rf "$ENV_PATH"
        print_python_setup_help
        exit 1
    fi
    echo "✅ Virtual environment created."
else
    echo "✅ Virtual environment already exists at $ENV_PATH."
fi
complete_stage "Virtual environment ready"

# Step 2: Activate the environment
echo "📦 Activating virtual environment at $ENV_PATH"
# shellcheck disable=SC1090
source "$ENV_PATH/bin/activate"
complete_stage "Virtual environment activated"

# Step 3: Install Jupyter if missing
if ! command -v jupyter &>/dev/null; then
    echo "🔍 Jupyter not found. Installing via pip..."
    python -m pip install jupyter -q
    echo "✅ Jupyter installed successfully."
else
    Jupyter_Path=$(command -v jupyter)
    echo "✅ Jupyter already installed at '$Jupyter_Path'."
fi
complete_stage "Requirements installed"

# Step 4: Install launcher script and desktop entry
echo "📂 Installing launcher script and desktop entry..."
mkdir -p "$BIN_DIR" "$INSTALL_DIR" "$MIME_DIR/packages" "$CONFIG_DIR"
cp "$SCRIPT_DIR/scripts/open_ipynb.sh" "$BIN_DIR/"
chmod +x "$BIN_DIR/open_ipynb.sh"

sed "s|^Exec=.*|Exec=$BIN_DIR/open_ipynb.sh %F|" \
    "$SCRIPT_DIR/desktop/jupyter-ipynb.desktop" \
    > "$INSTALL_DIR/jupyter-ipynb.desktop"

cp "$SCRIPT_DIR/desktop/ipynb.xml" "$MIME_DIR/packages/"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$INSTALL_DIR"
else
    echo "⚠️ update-desktop-database is unavailable; desktop menus may refresh after logout."
fi

if command -v update-mime-database >/dev/null 2>&1; then
    update-mime-database "$MIME_DIR"
else
    echo "⚠️ update-mime-database is unavailable; MIME associations may refresh after logout."
fi

if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default jupyter-ipynb.desktop application/x-ipynb+json
else
    echo "⚠️ xdg-mime is unavailable; set the default .ipynb application manually."
fi

complete_stage "Launcher files copied"
echo "🚀 Installed launcher to $INSTALL_DIR and script to $BIN_DIR/"

echo "🎉 All set! You can now open .ipynb files from your file manager!"
