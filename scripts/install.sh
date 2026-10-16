#!/bin/bash

set -e

ENV_PATH="$HOME/.Jenv"
INSTALL_DIR="$HOME/.local/share/applications"
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

# Step 1: Create virtual environment if not found
if [ ! -d "$ENV_PATH" ]; then
    echo "🔧 No virtual environment found at $ENV_PATH. Creating one..."
    python3 -m venv "$ENV_PATH"
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
    pip install jupyter -q
    echo "✅ Jupyter installed successfully."
else
    Jupyter_Path=$(which jupyter)
    echo "✅ Jupyter already installed at '$Jupyter_Path'."
fi
complete_stage "Requirements installed"

# Step 4: Install launcher script and desktop entry
echo "📂 Installing launcher script and desktop entry..."
mkdir -p ~/.local/bin/
cp "$SCRIPT_DIR/scripts/open_ipynb.sh" ~/.local/bin/
chmod +x ~/.local/bin/open_ipynb.sh

cp "$SCRIPT_DIR/desktop/jupyter-ipynb.desktop" "$INSTALL_DIR/"
update-desktop-database "$INSTALL_DIR"

cp "$SCRIPT_DIR/desktop/ipynb.xml" ~/.local/share/mime/packages
update-mime-database ~/.local/share/mime/
xdg-mime default jupyter-ipynb.desktop application/x-ipynb+json

complete_stage "Launcher files copied"
echo "🚀 Installed launcher to $INSTALL_DIR and script to ~/.local/bin/"

echo "🎉 All set! You can now open .ipynb files from your file manager!"
