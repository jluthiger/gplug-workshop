#!/bin/sh
# sync_participant.sh – Stand dieses Repos ins Teilnehmer-Repo (gplug-ch/ki-workshop) übertragen.
#   tools/sync_participant.sh ../workshop-261112
# Kopiert alle committeten Dateien ausser den internen (INTERN), löscht dort Dateien, die es hier
# nicht mehr gibt, und entfernt im README den Block <!-- kursleitung -->. Committet nicht:
# Ergebnis mit git diff im Ziel prüfen, dann dort committen und pushen.
set -eu

INTERN='^(WORKSHOP_PREP\.md|REPLY_HERMANN\.md|261021-meeting-hermann/|mock/|ui-drafts/|tools/sync_participant\.sh)'

src=$(cd "$(dirname "$0")/.." && pwd)
[ $# -eq 1 ] || { echo "Aufruf: $0 <ziel-repo>" >&2; exit 2; }
dst=$(cd "$1" && pwd)
[ "$src" != "$dst" ] || { echo "FEHLER: Ziel = Quelle" >&2; exit 1; }
git -C "$dst" remote get-url origin | grep -q 'ki-workshop' \
  || { echo "FEHLER: $dst ist nicht das Teilnehmer-Repo (origin ohne ki-workshop)" >&2; exit 1; }
[ -z "$(git -C "$src" status --porcelain)" ] || { echo "FEHLER: Quelle hat uncommittete Änderungen" >&2; exit 1; }
[ -z "$(git -C "$dst" status --porcelain)" ] || { echo "FEHLER: Ziel hat uncommittete Änderungen" >&2; exit 1; }

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
git -C "$src" ls-files | grep -Ev "$INTERN" > "$T/keep"

# Dateien, die es in der Quelle nicht (mehr) gibt, im Ziel löschen
git -C "$dst" ls-files | sort > "$T/old"
sort "$T/keep" > "$T/new"
comm -23 "$T/old" "$T/new" | while read -r f; do git -C "$dst" rm -q -- "$f"; echo "DEL $f"; done

rsync -a --files-from="$T/keep" "$src/" "$dst/"
sed -i.bak '/<!-- kursleitung -->/,/<!-- \/kursleitung -->/d' "$dst/README.md" && rm "$dst/README.md.bak"

# Verweise auf interne Dateien, die im Ziel ins Leere zeigen
if grep -rnE 'WORKSHOP_PREP|REPLY_HERMANN|261021-meeting|ui-drafts|mock/' --exclude-dir=.git --exclude='*.pdf' \
     --exclude=.gitignore "$dst"; then
  echo "HINWEIS: obige Zeilen verweisen auf interne Dateien"
fi
git -C "$dst" add -A
git -C "$dst" status --short
