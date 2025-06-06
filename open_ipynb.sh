#!/bin/bash
NOTEBOOK="$1"
FULL_PATH=$(readlink -f "$NOTEBOOK")

ENV_PATH="$HOME/.Jenv"

# Activate the environment
echo "📦 Activating virtual environment at $ENV_PATH"
source "$ENV_PATH/bin/activate"

get_server_info() {
    # Get the first running server line
    jupyter notebook list | grep -v "Currently running servers" | head -1
}

# Try to get running server info
SERVER_LINE=$(get_server_info)

if [ -z "$SERVER_LINE" ]; then
    echo "No running Jupyter notebook server found. Starting a new one in home directory..."

    # Start Jupyter notebook server in background, no browser, no token, root dir $HOME
    nohup jupyter notebook --no-browser --NotebookApp.token='' --NotebookApp.password='' --notebook-dir="$HOME" > /tmp/jupyter.log 2>&1 &

    # Wait for server to start by checking logs for URL
    echo "Waiting for Jupyter server to start..."
    while ! grep -q 'http://localhost:[0-9]\+' /tmp/jupyter.log; do
        sleep 1
    done

    # Extract server line from logs
    SERVER_LINE=$(grep 'http://localhost:' /tmp/jupyter.log | head -1)

    # Give it a bit more time to be ready
    sleep 2
fi

# Extract base URL (without trailing slash)
BASE_URL=$(echo "$SERVER_LINE" | grep -oP 'http://localhost:\d+' | head -1)

# Extract root directory after ':: '
ROOT_DIR=$(echo "$SERVER_LINE" | sed -n 's/.*:: \(.*\)/\1/p')

# If root dir empty (e.g. when started manually), fallback to $HOME
if [ -z "$ROOT_DIR" ]; then
    ROOT_DIR="$HOME"
fi

# Compute relative path from root directory
REL_PATH=$(realpath --relative-to="$ROOT_DIR" "$FULL_PATH")

# URL encode function
urlencode() {
    local LANG=C
    local length="${#1}"
    for (( i=0; i<length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
}

ENCODED_REL_PATH=$(urlencode "$REL_PATH")

# Build URL with /notebooks/ path to open notebook directly
NOTEBOOK_URL="${BASE_URL}/notebooks/${ENCODED_REL_PATH}"

echo "Opening notebook URL: $NOTEBOOK_URL"

xdg-open "$NOTEBOOK_URL" &

wait

