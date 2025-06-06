#!/bin/bash

ENV_PATH="$HOME/.Jenv"
INSTALL_DIR="$HOME/.local/share/applications"
SCRIPT_DIR="$(pwd)"

# Function to show a text progress bar
progress_bar() {
    local duration=$1
    local bar="============================================================"
    local bar_length=${#bar}
    local i=0

    while [ "$i" -le "$duration" ]; do
        sleep 0.1
        percent=$(( (100 * i) / duration ))
        bar_index=$(( (bar_length * i) / duration ))
        printf "\r[%.*s%*s] %d%%" "$bar_index" "$bar" $((bar_length - bar_index)) "" "$percent"
        ((i++))
    done
    echo ""
}

# Step 1: Create virtual environment if not found
if [ ! -d "$ENV_PATH" ]; then
    echo "🔧 No virtual environment found at $ENV_PATH. Creating one..."
    python3 -m venv "$ENV_PATH" &
    pid=$!
    progress_bar 30 &
    wait $pid
    echo "✅ Virtual environment created."
else
    echo "✅ Virtual environment already exists at $ENV_PATH."
fi

# Step 2: Activate the environment
echo "📦 Activating virtual environment at $ENV_PATH"
# shellcheck disable=SC1090
source "$ENV_PATH/bin/activate"

# Step 3: Install Jupyter if missing
if ! command -v jupyter &>/dev/null; then
    echo "🔍 Jupyter not found. Installing via pip..."
    pip install jupyter --quit &
    pid=$!
    progress_bar 50 &
    wait $pid
    echo "✅ Jupyter installed successfully."
else
    Jupyter_Path=$(which jupyter)
    echo "✅ Jupyter already installed at '$Jupyter_Path'."
fi

# Step 4: Install launcher script and desktop entry
echo "📂 Installing launcher script and desktop entry..."
cp "$SCRIPT_DIR/open_ipynb.sh" ~/.local/bin/
chmod +x ~/.local/bin/open_ipynb.sh

cp "$SCRIPT_DIR/jupyter-ipynb.desktop" "$INSTALL_DIR/"
update-desktop-database "$INSTALL_DIR"

cp "$SCRIPT_DIR/ipynb.xml" ~/.local/share/mime/packages
update-mime-database ~/.local/share/mime/
xdg-mime default jupyter-ipynb.desktop application/x-ipynb+json

echo "🚀 Installed launcher to $INSTALL_DIR and script to ~/.local/bin/"

echo "🎉 All set! You can now open .ipynb files from your file manager!"
