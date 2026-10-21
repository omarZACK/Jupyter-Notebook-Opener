#!/bin/bash

set -euo pipefail

NOTEBOOK="$1"
FULL_PATH=$(readlink -f -- "$NOTEBOOK")

ENV_PATH="$HOME/.Jenv"
JUPYTER_BIN="$ENV_PATH/bin/jupyter"
LOG_FILE="${TMPDIR:-/tmp}/jupyter-notebook-opener-$UID.log"

# Activate the environment
echo "📦 Activating virtual environment at $ENV_PATH"
if [ ! -x "$JUPYTER_BIN" ]; then
    echo "❌ Jupyter is not installed in $ENV_PATH. Run the installer first." >&2
    exit 1
fi
source "$ENV_PATH/bin/activate"

get_server_info() {
    # Get the first running server line
    "$JUPYTER_BIN" notebook list | grep -v "Currently running servers" | head -1 || true
}

# Try to get running server info
SERVER_LINE=$(get_server_info)

if [ -z "$SERVER_LINE" ]; then
    echo "No running Jupyter notebook server found. Starting a new one in home directory..."

    # Start Jupyter notebook server in background, no browser, no token, root dir $HOME
    nohup "$JUPYTER_BIN" notebook --allow-root --no-browser \
        --ServerApp.token='' --ServerApp.password='' \
        --notebook-dir="$HOME" > "$LOG_FILE" 2>&1 &

    # Wait for server to start by checking logs for URL
    echo "Waiting for Jupyter server to start..."
    for _ in {1..30}; do
        if grep -Eq 'http://(localhost|127\.0\.0\.1):[0-9]+' "$LOG_FILE"; then
            break
        fi
        sleep 1
    done

    if ! grep -Eq 'http://(localhost|127\.0\.0\.1):[0-9]+' "$LOG_FILE"; then
        echo "❌ Jupyter server did not start. Check $LOG_FILE for details." >&2
        exit 1
    fi

    # Extract server line from logs
    SERVER_LINE=$(grep -E 'http://(localhost|127\.0\.0\.1):[0-9]+' "$LOG_FILE" | head -1)

    # Give it a bit more time to be ready
    sleep 2
fi

# Extract base URL (without trailing slash)
BASE_URL=$(echo "$SERVER_LINE" | sed -nE 's#.*(http://(localhost|127\.0\.0\.1):[0-9]+).*#\1#p' | head -1)

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

xdg-open "$NOTEBOOK_URL" >/dev/null 2>&1 &
