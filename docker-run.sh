#!/bin/sh
# docker-run.sh – Workshop-Sandbox bauen (beim ersten Mal) und opencode darin starten.
#   ./docker-run.sh            opencode im Container
#   ./docker-run.sh bash       Shell im Container (zum Prüfen)
#   ./docker-run.sh --build    Image neu bauen
# Sichtbar ist nur dieser Ordner (/work). Infomaniak-Werte aus der eigenen Shell.
set -eu
cd "$(dirname "$0")"
IMAGE=gplug-workshop

if [ "${1:-}" = "--build" ] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  docker build -t "$IMAGE" .
  [ "${1:-}" = "--build" ] && shift
fi

[ -n "${INFOMANIAK_PRODUCT_ID:-}" ] && [ -n "${INFOMANIAK_API_KEY:-}" ] \
  || echo "WARNUNG: INFOMANIAK_PRODUCT_ID oder INFOMANIAK_API_KEY nicht gesetzt (SETUP_OPENCODE.md Schritt 3)" >&2

# Linux: mit eigener UID laufen, damit Dateien im Ordner dir gehören (Docker Desktop macht das selbst)
user=""
[ "$(uname -s)" = "Linux" ] && user="--user $(id -u):$(id -g)"

# shellcheck disable=SC2086
exec docker run -it --rm $user \
  -v "$PWD":/work -w /work \
  -v gplug-workshop-data:/home/agent/.local/share/opencode \
  -e INFOMANIAK_PRODUCT_ID -e INFOMANIAK_API_KEY -e GPLUG \
  "$IMAGE" "$@"
