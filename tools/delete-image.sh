#!/bin/sh
# delete-image.sh – Tag :workshop (Image mit Infomaniak-Zugang) von ghcr.io löschen (nur Kursleitung).
# Löscht die Index-Version mit dem Tag und ihre untagged Teil-Manifeste (amd64, arm64, Attestationen).
# :base und das Package bleiben, die Sichtbarkeit "public" damit auch.
# Braucht: gh auth refresh -s delete:packages, docker login ghcr.io (für docker manifest inspect)
set -eu
IMAGE=ghcr.io/gplug-ch/ki-workshop
API=/orgs/gplug-ch/packages/container/ki-workshop/versions
TAG=${1:-workshop}

versions=$(gh api --paginate "$API" --jq '.[] | "\(.id) \(.name)"')
index=$(echo "$versions" | while read -r id digest; do
  gh api "$API/$id" --jq "select(.metadata.container.tags | index(\"$TAG\")) | \"$id $digest\""
done)
[ -n "$index" ] || { echo "Tag :$TAG nicht gefunden, nichts zu tun"; exit 0; }
index_id=${index%% *}; index_digest=${index#* }

children=$(docker manifest inspect "$IMAGE@$index_digest" \
  | python3 -c 'import sys,json; print("\n".join(m["digest"] for m in json.load(sys.stdin).get("manifests", [])))')

echo "Lösche :$TAG = $index_digest"
echo "$children" | sed 's/^/  + /'
printf 'Weiter? [j/N] '
read -r answer
[ "$answer" = "j" ] || { echo "abgebrochen"; exit 1; }

for digest in $children; do
  id=$(echo "$versions" | awk -v d="$digest" '$2 == d { print $1 }')
  [ -n "$id" ] && gh api -X DELETE "$API/$id" && echo "gelöscht $digest"
done
gh api -X DELETE "$API/$index_id" && echo "gelöscht :$TAG"

echo "Jetzt Token im Infomaniak-Manager widerrufen:"
echo "  https://manager.infomaniak.com/v3/ng/profile/user/token/list"
