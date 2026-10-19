#!/bin/sh
# log.sh – letzte Zeilen der Tasmota-Konsole holen.
#   ./log.sh        letzte 40 Zeilen, ohne periodische SENSOR/STATE-Telemetrie
#   ./log.sh 100    letzte 100 Zeilen
#   ./log.sh -a     alles, ungefiltert
# Gerät: Umgebungsvariable GPLUG oder Datei .gplug (IP oder Hostname, eine Zeile).
set -eu

dev="${GPLUG:-}"
[ -z "$dev" ] && [ -f "$(dirname "$0")/.gplug" ] && dev=$(tr -d ' \r\n' < "$(dirname "$0")/.gplug")
[ -z "$dev" ] && { echo "FEHLER: Gerät unbekannt. 'export GPLUG=<ip>' oder IP in .gplug eintragen." >&2; exit 2; }

n=40 all=0
case "${1:-}" in
  -a) all=1 ;;
  '') ;;
  *)  n=$1 ;;
esac

# /cs?c2=0 liefert "<index>}1<reset>}1<zeilen...>}1" (Web-Konsole von Tasmota)
raw=$(curl -s -m 10 "http://$dev/cs?c2=0") || { echo "FEHLER: http://$dev nicht erreichbar" >&2; exit 1; }
lines=$(printf '%s\n' "$raw" | sed -e '1s/^[0-9]*}1[0-9]*}1//' -e '$s/}1$//')

if [ $all -eq 1 ]; then
  printf '%s\n' "$lines"
else
  printf '%s\n' "$lines" | grep -Ev 'RSL: (SENSOR|STATE) = ' | tail -n "$n"
fi
