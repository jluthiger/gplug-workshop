#!/bin/sh
# upload.sh – Dateien aufs gPlug laden, Grösse prüfen, danach BrRestart.
#   ./upload.sh app/spot.be [weitere Dateien...]
#   ./upload.sh --no-restart app/spot.be
# Gerät: Umgebungsvariable GPLUG oder Datei .gplug (IP oder Hostname, eine Zeile).
set -eu

dev="${GPLUG:-}"
[ -z "$dev" ] && [ -f "$(dirname "$0")/.gplug" ] && dev=$(tr -d ' \r\n' < "$(dirname "$0")/.gplug")
[ -z "$dev" ] && { echo "FEHLER: Gerät unbekannt. 'export GPLUG=<ip>' oder IP in .gplug eintragen." >&2; exit 2; }
H="http://$dev"

restart=1
if [ "${1:-}" = "--no-restart" ]; then restart=0; shift; fi
[ $# -eq 0 ] && { echo "Aufruf: $0 [--no-restart] <datei> [...]" >&2; exit 2; }

for f in "$@"; do
  [ -f "$f" ] || { echo "FEHLER: $f nicht gefunden" >&2; exit 1; }
  case "$(basename "$f")" in
    persist.be|path.be|desktop_harness.be)
      echo "FEHLER: $f ist ein Desktop-Stub und gehört nicht aufs Gerät" >&2; exit 1 ;;
  esac
done

# Upload-Modus Datei (nach jedem Neustart nötig, sonst wird der Upload als Firmware behandelt)
curl -s -m 10 -o /dev/null "$H/ufsd" || { echo "FEHLER: $H nicht erreichbar" >&2; exit 1; }

for f in "$@"; do
  name=$(basename "$f")
  code=$(curl -s -m 30 -o /dev/null -w '%{http_code}' -F "ufsu=@$f" "$H/ufsu")
  [ "$code" = "200" ] || { echo "FEHLER: Upload $name HTTP $code" >&2; exit 1; }
  want=$(wc -c < "$f" | tr -d ' ')
  got=$(curl -s -m 10 -G "$H/cm" \
    --data-urlencode "cmnd=Br var f=open(\"/$name\") var n=f.size() f.close() return n" \
    | sed -n 's/.*"Br":"\([0-9]*\)".*/\1/p')
  [ "$got" = "$want" ] || { echo "FEHLER: $name auf Gerät $got Byte, lokal $want Byte" >&2; exit 1; }
  echo "OK  /$name ($want Byte)"
done

if [ $restart -eq 1 ]; then
  curl -s -m 15 -o /dev/null "$H/cm?cmnd=BrRestart"
  echo "OK  BrRestart – jetzt ./log.sh lesen"
fi
