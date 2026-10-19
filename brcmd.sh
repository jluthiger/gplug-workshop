#!/bin/sh
# brcmd.sh – Berry-Ausdruck auf dem gPlug ausführen, Resultat als JSON zurück.
#   ./brcmd.sh 'tasmota.memory("heap_free")'
#   ./brcmd.sh 'tasmota.cmd("SpotStatus")'
# Gerät: Umgebungsvariable GPLUG oder Datei .gplug (IP oder Hostname, eine Zeile).
# Die Sperrliste ist eine Leitplanke gegen Versehen, kein Sicherheitsmechanismus.
set -eu

dev="${GPLUG:-}"
[ -z "$dev" ] && [ -f "$(dirname "$0")/.gplug" ] && dev=$(tr -d ' \r\n' < "$(dirname "$0")/.gplug")
[ -z "$dev" ] && { echo "FEHLER: Gerät unbekannt. 'export GPLUG=<ip>' oder IP in .gplug eintragen." >&2; exit 2; }
[ $# -eq 0 ] && { echo "Aufruf: $0 '<berry-ausdruck>'" >&2; exit 2; }
expr="$*"

# Gesperrt: Neustart/Reset, Firmware, WLAN/Passwörter, Pins/Modul, gPlug-Script, Backlog, Dateien löschen.
# Auch BrRestart: aus Berry heraus aufgerufen stürzt das Gerät ab (getestet 19.10., Tasmota 15.3.0).
check=$(printf '%s' "$expr" | tr 'A-Z' 'a-z')
if printf '%s' "$check" | grep -Eq '(^|[^a-z0-9_])(reset|restart|brrestart|upgrade|otaurl|ssid[0-9]*|password[0-9]*|webpassword|wifi[a-z]*|module|template|gpio[a-z0-9]*|script|backlog|ufsdelete|ufsrename|setoption[0-9]*)([^a-z0-9_]|$)'; then
  echo "GESPERRT: Ausdruck enthält ein verbotenes Kommando (siehe AGENTS.md). Mensch fragen." >&2
  exit 3
fi

curl -s -m 15 -G "http://$dev/cm" --data-urlencode "cmnd=Br $expr" \
  || { echo "FEHLER: http://$dev nicht erreichbar" >&2; exit 1; }
echo
