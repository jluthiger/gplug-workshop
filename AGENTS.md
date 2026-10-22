# AGENTS.md – Regeln für den Coding-Agenten

Projekt: Berry-App `app/spot.be` für den gPlug (Tasmota 15.3.0+, ESP32-C3). Holt BKW-Einspeisepreise,
misst ¼-h-Energie, zeigt Chart in der Tasmota-WebUI. Am Workshop erweitert ihr den Starter in
**kleinen Schritten** (`EXERCISES.md`) zur Referenz-App, keine neue App.

**Nur im Projektordner arbeiten.** Dateien und Ordner ausserhalb des Projekt-Wurzelordners (der Ordner
mit dieser `AGENTS.md`) weder lesen noch schreiben, auch nicht über Shell-Befehle: keine absoluten
Pfade ausserhalb, kein `..` aus dem Projekt hinaus, kein `~`, keine Umgebungs- oder Konfigurationsdateien
des Notebooks. Temporäre Dateien im Projektordner anlegen. Braucht eine Aufgabe etwas von ausserhalb:
anhalten und den Menschen fragen.

## 1. Zuerst lesen

Vor der ersten Änderung lesen, nicht raten:

- `INTENT.md` – Anforderungen, Randbedingungen, Entscheide.
- `TASMOTA_BERRY_API.md` – die Tasmota-Berry-API. **Nur** Funktionen verwenden, die dort, in
  `app/spot.be` oder in der Berry-Sprachreferenz
  (<https://tasmota.github.io/docs/_media/BERRY_LANGUAGE_REFERENCE.txt>) stehen. Fehlt etwas: sagen,
  nicht erfinden.
- `app/spot.be` – bestehender Code. Ergänzungen an den Kommentaren `# ERWEITERUNGSPUNKT` einhängen.
- `EXERCISES.md` – Aufgabe, Vorgaben und Prüfschritte der Übung.

## 2. Dateien

| Datei | Zweck | Aufs Gerät? |
|---|---|---|
| `app/spot.be` | die App | ja |
| `app/autoexec.be` | lädt `spot` beim Start und bei `BrRestart` | ja, nur bei Bedarf |
| `app/desktop_harness.be`, `app/persist.be`, `app/path.be` | Desktop-Test, Stubs | **nie** |
| `reference/` | `read_sensors`-Beispiele (Zähler-Pfad) | nein |
| `app/steps/spot_N.be` | fertiger Stand nach Schritt N; nicht ändern, nur der Mensch kopiert einen davon nach `app/spot.be` | nein (nur als `app/spot.be`) |
| `tools/make_steps.py` | Vorbereitung der Kursleitung; nie mit `--write` aufrufen (überschreibt `app/spot.be`) | nein |

## 3. Werkzeuge (Gerät)

Gerät steht in `.gplug` (eine Zeile, IP) oder in `$GPLUG`. Mit dem Gerät **nur** über diese Skripte
reden, kein direktes `curl` aufs Gerät.

| Skript | Wirkung |
|---|---|
| `./upload.sh app/spot.be` | hochladen, Grösse prüfen, `BrRestart` (lädt App neu) |
| `./upload.sh --no-restart <datei>` | nur hochladen |
| `./brcmd.sh '<berry>'` | Berry-Ausdruck ausführen, Resultat als JSON, z.B. `./brcmd.sh 'tasmota.cmd("SpotStatus")'` |
| `./log.sh [n]` | letzte n Konsolenzeilen (Standard 40, ohne SENSOR/STATE-Telemetrie), `-a` = alles |

Nützliche Prüfungen:

```sh
./brcmd.sh 'tasmota.cmd("SpotStatus")'        # Zustand, Preise, Heap
./brcmd.sh 'tasmota.cmd("SpotPrices")'        # nächste 10 h
./brcmd.sh 'tasmota.gc()'                      # erst aufräumen, dann:
./brcmd.sh 'tasmota.memory("heap_free")'      # freier Heap in kB, soll > 100 bleiben
./brcmd.sh 'load("spot")'                     # App neu laden ohne Upload (erster Reload +20 kB, danach stabil)
```

## 4. Arbeitszyklus

1. Plan in 3–5 Sätzen nennen: Erweiterungspunkt, Datenquelle, erwartetes Resultat, Prüfschritt.
2. Kleine Änderung in `app/spot.be`.
3. Optional Desktop-Test: `cd app && berry desktop_harness.be` (braucht `app/bkw.json`, einmal holen mit
   `curl -s -o app/bkw.json https://api.bkw.ch/api/dyntariffs/v1/Tariffs/energyreturn`). Muss mit
   `HARNESS OK` enden.
4. `./upload.sh app/spot.be`, danach **immer** `./log.sh` lesen. Zeilen mit `BRY:` oder `SPOT:` und
   jede Fehlermeldung wörtlich auswerten.
5. Mit `./brcmd.sh` prüfen, ob das erwartete Resultat da ist. Heap prüfen.
6. Ergebnis kurz melden: was geändert, was geprüft, was offen. Der Mensch prüft selbst in der WebUI.

Schlägt ein Schritt zweimal gleich fehl: anhalten, Fehlermeldung zeigen, Mensch fragen.

## 5. Verboten auf dem Gerät

Nie ausführen, auch nicht über `tasmota.cmd(...)`: `Reset`, `Restart`, `BrRestart` (aus Berry heraus
stürzt das Gerät ab; Neustart der App nur via `./upload.sh` oder `load("spot")`), `Upgrade`, `OtaUrl`,
`Backlog`, WLAN- und Passwort-Kommandos (`Ssid`, `Password`, `WebPassword`, `Wifi…`), `Module`,
`Template`, `Gpio…`, `SetOption…`, `Script` (das gPlug-Script liest den Zähler), Dateien löschen
oder umbenennen ausser eigenen CSV-Testdateien. `brcmd.sh` sperrt die meisten davon; trotzdem selbst
einhalten. Unklar, ob ein Kommando harmlos ist: Mensch fragen.

## 6. Code-Regeln (Berry auf Tasmota)

- Berry blockiert Tasmota: kein Callback länger als 50 ms, kein Warten in Schleifen, lange Arbeit mit
  `tasmota.set_timer` aufteilen.
- `tasmota.web_send` nur in `web_sensor()`, `webserver.on` nur in `web_add_handler()`.
- Strict Mode: keine undeklarierten Globals lesen; Klassen-Member mit `var` deklarieren.
- RAM ist knapp (~120 kB frei): keine grossen Strings oder Listen aufbauen, HTML/SVG stückweise
  senden, BKW-Antwort nie mit `json.load` parsen.
- Heap im Blick behalten: nach jedem Upload meldet `upload.sh` `heap_free`; unter 100 kB startet es
  das Gerät selbst neu (jeder `BrRestart` kostet ~1 kB, nur ein Neustart gibt das zurück). Fällt der
  Heap nach einer Änderung dauerhaft (gleiche Aktion mehrmals, `tasmota.gc()` davor), ist die
  Änderung schuld: Ursache suchen, nicht weiterbauen.
- Dateien nie mit `f.read(n)` blockweise lesen (leckt in Tasmota 15.3 ~1.5 × n Byte pro Durchlauf):
  `f.readbytes(n).asstring()` oder `f.readline()` verwenden, siehe `parse_file` in `spot.be`.
- Flash schonen: nicht öfter als nötig in Dateien schreiben (CSV einmal pro Tag bzw. Stunde).
- Jeder Callback-Body in `try ... except .. as e, m ... end`, Fehler mit `log("SPOT: ...", 2)`.
- Neue Commands mit `tasmota.add_cmd`, Crons mit fester Id, damit `load("spot")` nichts doppelt
  registriert.
- Chart: neue Kurven nur über `chart_curves()` + `send_polyline` bzw. `send_bars` (Abschnitt
  `F3  Chart`), keine eigene Zeichenschleife, kein `<script>` und keine Checkboxen im Sensorbereich
  (Tasmota ersetzt ihn per AJAX, Scripts darin laufen nicht).
- Achsen: erlaubt sind Preis rechts (Rp./kWh), **eine** Achse links für kWh (Schritt 1) und im
  Vergütungs-Chart eine Achse links für CHF (Schritt 4). Jede weitere Achse nur nach Rückfrage.
- Stil von `spot.be` übernehmen: deutsche Kommentare, kurze Methoden, keine Tricks.

## 7. Git

Funktionierende Stände in kleinen Commits sichern, wenn der Mensch zustimmt. Nie `.gplug`, API-Keys
oder `bkw.json` committen.
