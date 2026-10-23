#!/bin/sh
# delete-image.sh – Workshop-Image mit eingebautem Infomaniak-Zugang von ghcr.io löschen (nur Kursleitung).
# Löscht das ganze Package ghcr.io/gplug-ch/ki-workshop (alle Tags, auch :base; Multi-Arch-Teile
# hängen als untagged Versionen daran). Danach baut docker-run.sh das Image wieder lokal (--build).
# Braucht: gh auth refresh -s delete:packages
set -eu
PACKAGE=/orgs/gplug-ch/packages/container/ki-workshop

printf 'Package %s komplett löschen? [j/N] ' "$PACKAGE"
read -r answer
[ "$answer" = "j" ] || { echo "abgebrochen"; exit 1; }

gh api -X DELETE "$PACKAGE"
echo "gelöscht. Jetzt Token im Infomaniak-Manager widerrufen:"
echo "  https://manager.infomaniak.com/v3/ng/profile/user/token/list"
