#!/bin/sh
# build_tapp.sh – Referenz-App (app/steps/spot_4.be) als Tasmota-App in dist/ packen.
#   tools/build_tapp.sh [ausgabe-ordner]     (Standard: dist)
# Ergebnis:
#   spot.tapp      Smart Meter ("sim": false)
#   spot-sim.tapp  Simulator ohne Smart Meter ("sim": true, wie im Quelltext)
# Tasmota liest nur unkomprimierte Archive, deshalb zip -0. Fester Dateiname ohne Version:
# ein Update überschreibt die alte Datei auf dem Gerät, sonst liefen zwei Fassungen parallel.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
out=${1:-dist}
case "$out" in /*) ;; *) out="$root/$out" ;; esac
src="$root/app/steps/spot_4.be"
sim_on='"sim": true,'
sim_off='"sim": false,'

[ "$(grep -c "$sim_on" "$src")" = 1 ] || { echo "FEHLER: $sim_on nicht genau einmal in $src" >&2; exit 1; }

tmp=$(mktemp -d "$root/.tapp.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$out"

pack() {  # pack <name> <spot.be>
  rm -f "$out/$1"
  cp "$root/LICENSE" "$root/VERSION" "$tmp/"
  cat > "$tmp/autoexec.be" <<'BE'
# autoexec.be im .tapp – Tasmota führt sie beim Start aus.
# tasmota.wd = Pfad des Archivs, z.B. "/spot.tapp#".
load(tasmota.wd + "spot.be")
BE
  cp "$2" "$tmp/spot.be"
  (cd "$tmp" && zip -q -0 -X -D "$out/$1" autoexec.be spot.be VERSION LICENSE)
  [ "$(unzip -Zv "$out/$1" | grep -c 'compression method: *none (stored)')" = 4 ] \
    || { echo "FEHLER: $1 enthält komprimierte Dateien" >&2; exit 1; }
  echo "OK  $out/$1 ($(wc -c < "$out/$1" | tr -d ' ') Byte)"
}

sed "s/$sim_on/$sim_off/" "$src" > "$tmp/spot_meter.be"
grep -q "$sim_off" "$tmp/spot_meter.be" || { echo "FEHLER: sim nicht umgestellt" >&2; exit 1; }
pack spot.tapp "$tmp/spot_meter.be"
pack spot-sim.tapp "$src"
