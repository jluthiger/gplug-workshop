#!/bin/sh
# docker-run.sh – Workshop-Sandbox holen (beim ersten Mal) und opencode darin starten.
#   ./docker-run.sh            opencode im Container
#   ./docker-run.sh bash       Shell im Container (zum Prüfen)
#   ./docker-run.sh --build    Image lokal aus dem Dockerfile bauen statt von ghcr.io laden
# Sichtbar ist nur dieser Ordner (/work). Infomaniak-Zugang steckt im Workshop-Image;
# INFOMANIAK_PRODUCT_ID / INFOMANIAK_API_KEY aus der eigenen Shell haben Vorrang (eigener Zugang).
set -eu
cd "$(dirname "$0")"
IMAGE=ghcr.io/gplug-ch/ki-workshop:workshop

if [ "${1:-}" = "--build" ]; then
  shift
  docker build -t "$IMAGE" .
elif ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  docker pull "$IMAGE" \
    || { echo "Image nicht ladbar (Workshop vorbei?): ./docker-run.sh --build baut es lokal" >&2; exit 1; }
fi

# Eigene Werte nur durchreichen, wenn gesetzt: leeres -e würde die Werte aus dem Image löschen
env_args=""
[ -n "${INFOMANIAK_PRODUCT_ID:-}" ] && env_args="$env_args -e INFOMANIAK_PRODUCT_ID"
[ -n "${INFOMANIAK_API_KEY:-}" ] && env_args="$env_args -e INFOMANIAK_API_KEY"
[ -n "${GPLUG:-}" ] && env_args="$env_args -e GPLUG"

# Linux: mit eigener UID laufen, damit Dateien im Ordner dir gehören (Docker Desktop macht das selbst)
user=""
[ "$(uname -s)" = "Linux" ] && user="--user $(id -u):$(id -g)"

# shellcheck disable=SC2086
exec docker run -it --rm $user $env_args \
  -v "$PWD":/work -w /work \
  -v gplug-workshop-data:/home/agent/.local/share/opencode \
  "$IMAGE" "$@"
