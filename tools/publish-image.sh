#!/bin/sh
# publish-image.sh – Workshop-Image bauen und auf ghcr.io veröffentlichen (nur Kursleitung).
#   tools/publish-image.sh base       Basis-Image ohne Secrets (einmalig, bleibt)
#   tools/publish-image.sh workshop   Basis + Infomaniak-Zugang aus INFOMANIAK_* der Shell (Workshop-Tag)
# Voraussetzungen: gh auth refresh -s write:packages,delete:packages
#                  gh auth token | docker login ghcr.io -u <github-user> --password-stdin
#                  docker buildx create --use   (einmalig, für amd64 + arm64)
# Package nach dem ersten Push in GitHub auf "public" stellen (Org-Packages sind privat).
set -eu
cd "$(dirname "$0")/.."
IMAGE=ghcr.io/gplug-ch/ki-workshop
PLATFORMS=linux/amd64,linux/arm64

case "${1:-}" in
  base)
    docker buildx build --platform "$PLATFORMS" --push -t "$IMAGE:base" .
    ;;
  workshop)
    [ -n "${INFOMANIAK_PRODUCT_ID:-}" ] && [ -n "${INFOMANIAK_API_KEY:-}" ] \
      || { echo "INFOMANIAK_PRODUCT_ID und INFOMANIAK_API_KEY in der Shell setzen" >&2; exit 1; }
    docker buildx build --platform "$PLATFORMS" --push -t "$IMAGE:workshop" \
      --build-arg INFOMANIAK_PRODUCT_ID --build-arg INFOMANIAK_API_KEY \
      -f Dockerfile.workshop .
    echo "Nach dem Workshop: tools/delete-image.sh und Token im Infomaniak-Manager widerrufen."
    ;;
  *)
    echo "Aufruf: $0 base|workshop" >&2; exit 2
    ;;
esac
