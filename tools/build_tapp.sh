#!/bin/sh
# build_tapp.sh – Referenz-App (app/steps/spot_4.be) als Tasmota-App in dist/ packen.
#   tools/build_tapp.sh [ausgabe-ordner]     (Standard: dist)
# Ergebnis:
#   spot.tapp      Smart Meter ("sim": false), Simulator-Methoden entfernt (~2 kB Berry-Heap weniger)
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

sed "s/$sim_on/$sim_off/" "$src" > "$tmp/spot_sed.be"
grep -q "$sim_off" "$tmp/spot_sed.be" || { echo "FEHLER: sim nicht umgestellt" >&2; exit 1; }

# spot.tapp ohne Simulator: Methoden sim_* (ausser sim_lapse) samt Kommentar darüber entfernen.
# Alle Aufrufe stehen hinter cfg["sim"] bzw. sim_lapse() und laufen mit "sim": false nie;
# Berry löst self.sim_x() erst zur Laufzeit auf, fehlende Methoden stören das Laden nicht.
python3 -I - "$tmp/spot_sed.be" "$tmp/spot_meter.be" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
lines = open(src, encoding="utf-8").read().split("\n")
out, removed, i = [], [], 0
while i < len(lines):
    m = re.match(r"  def (sim_\w+)\(", lines[i])
    if m and m.group(1) != "sim_lapse":
        while out and out[-1].startswith("  #"):      # Kommentar direkt über der Methode
            out.pop()
        j = i + 1
        while j < len(lines) and lines[j] != "  end":
            j += 1
        if j == len(lines):
            sys.exit("FEHLER: Ende von %s nicht gefunden" % m.group(1))
        removed.append(m.group(1))
        i = j + 1
        if i < len(lines) and lines[i] == "" and out and out[-1] == "":
            i += 1                                     # doppelte Leerzeile vermeiden
        continue
    out.append(lines[i])
    i += 1
s = "\n".join(out)
want = {"sim_fill_prices", "sim_base", "sim_price", "sim_kw", "sim_counter", "sim_backfill", "sim_advance"}
if set(removed) != want:
    sys.exit("FEHLER: entfernt %s, erwartet %s" % (sorted(removed), sorted(want)))
guard = re.compile(r'cfg\["sim"\]|sim_lapse\(\)')
for name in removed:                                   # Aufruf nur hinter sim-Prüfung (gleiche oder Zeile davor)
    for n, line in enumerate(out, 1):
        if "self." + name + "(" in line and not guard.search(line) and not (n > 1 and guard.search(out[n - 2])):
            sys.exit("FEHLER: Zeile %d ruft %s ohne sim-Prüfung auf: %s" % (n, name, line.strip()))
open(dst, "w", encoding="utf-8").write(s)
print("OK  Simulator entfernt: %s (%d -> %d Byte)" % (", ".join(removed), len(open(src, encoding="utf-8").read().encode()), len(s.encode())))
PY
pack spot.tapp "$tmp/spot_meter.be"
pack spot-sim.tapp "$src"
