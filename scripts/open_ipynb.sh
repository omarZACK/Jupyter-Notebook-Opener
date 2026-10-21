#!/bin/bash

set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <notebook.ipynb>" >&2
    exit 1
fi

NOTEBOOK="$1"
FULL_PATH=$(readlink -f -- "$NOTEBOOK")

ENV_PATH="$HOME/.Jenv"
JUPYTER_BIN="$ENV_PATH/bin/jupyter"
LOG_FILE="${TMPDIR:-/tmp}/jupyter-notebook-opener-$UID.log"

# Jupyter only serves files below its server root. A single shared server
# rooted at "/" covers every disk, so exactly one server is maintained for
# all notebooks; servers with narrower roots get restarted into this setup.
SERVER_ROOT="/"

echo "📦 Activating virtual environment at $ENV_PATH"
if [ ! -x "$JUPYTER_BIN" ]; then
    echo "❌ Jupyter is not installed in $ENV_PATH. Run the installer first." >&2
    exit 1
fi
source "$ENV_PATH/bin/activate"

find_shared_server_url() {
    "$JUPYTER_BIN" notebook list | while IFS= read -r line; do
        case "$line" in *" :: "*) ;; *) continue ;; esac
        server_url=${line%%" :: "*}
        server_root=${line##*" :: "}
        resolved_root=$(realpath -- "$server_root" 2>/dev/null) || continue
        resolved_target=$(realpath -- "$SERVER_ROOT" 2>/dev/null) || continue
        if [ "$resolved_root" = "$resolved_target" ]; then
            echo "$server_url"
            return 0
        fi
    done
}

server_url=$(find_shared_server_url || true)

if [ -z "$server_url" ]; then
    if "$JUPYTER_BIN" notebook list | grep -q " :: "; then
        echo "🔁 Restarting a Jupyter server rooted elsewhere as a shared one..."
        pkill -f "$ENV_PATH/bin/jupyter" 2>/dev/null || true
        sleep 1
    fi

    echo "🚀 Starting one shared Jupyter server rooted at $SERVER_ROOT..."
    nohup "$JUPYTER_BIN" notebook --allow-root --no-browser \
        --ServerApp.root_dir="$SERVER_ROOT" \
        --ContentsManager.allow_hidden=True > "$LOG_FILE" 2>&1 &

    echo "⏳ Waiting for Jupyter server to start..."
    for _ in {1..30}; do
        # grep exits 1 when the URL is not yet in the log; that must not
        # abort the script while the server is still starting up
        server_url=$(grep -Eo 'http://(localhost|127\.0\.0\.1):[0-9]+[^ ]*\?token=[a-zA-Z0-9]+' "$LOG_FILE" | head -1 || true)
        [ -n "$server_url" ] && break
        sleep 1
    done

    if [ -z "$server_url" ]; then
        echo "❌ Jupyter server did not start. Check $LOG_FILE for details." >&2
        exit 1
    fi

    sleep 2
else
    echo "🔁 Reusing running shared Jupyter server rooted at $SERVER_ROOT"
fi

# The logged/listed URL may carry an extra path (e.g. /tree) before the
# token query; only scheme, host and port are needed as the base URL.
BASE_URL=$(sed -nE 's#^(http://(localhost|127\.0\.0\.1):[0-9]+).*$#\1#p' <<< "$server_url")

TOKEN=""
case "$server_url" in
    *\?token=*) TOKEN=${server_url#*\?token=} ;;
esac

REL_PATH=$(realpath --relative-to="$SERVER_ROOT" "$FULL_PATH")

urlencode() {
    local LANG=C
    local length="${#1}"
    for (( i=0; i<length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_/-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
}

ENCODED_REL_PATH=$(urlencode "$REL_PATH")

NOTEBOOK_URL="${BASE_URL}/notebooks/${ENCODED_REL_PATH}"
if [ -n "$TOKEN" ]; then
    NOTEBOOK_URL="${NOTEBOOK_URL}?token=${TOKEN}"
fi

echo "Opening notebook URL: $NOTEBOOK_URL"

xdg-open "$NOTEBOOK_URL" >/dev/null 2>&1 &
