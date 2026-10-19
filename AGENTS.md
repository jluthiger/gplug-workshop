# AGENTS.md – Regeln für den Coding-Agenten

Projekt: Berry-App `app/spot.be` für den gPlug (Tasmota 15.3.0+, ESP32-C3). Holt BKW-Einspeisepreise,
misst ¼-h-Energie, zeigt Chart in der Tasmota-WebUI. Am Workshop baust du **eine kleine Ergänzung**
an dieser Referenz-App, nicht eine neue App.

## 1. Zuerst lesen

Vor der ersten Änderung lesen, nicht raten:

- `INTENT.md` – Anforderungen, Randbedingungen, Entscheide.
- `TASMOTA_BERRY_API.md` – die Tasmota-Berry-API. **Nur** Funktionen verwenden, die dort, in
  `app/spot.be` oder in der Berry-Sprachreferenz
  (<https://tasmota.github.io/docs/_media/BERRY_LANGUAGE_REFERENCE.txt>) stehen. Fehlt etwas: sagen,
  nicht erfinden.
- `app/spot.be` – bestehender Code. Ergänzungen an den Kommentaren `# ERWEITERUNGSPUNKT` einhängen.

## 2. Dateien

| Datei | Zweck | Aufs Gerät? |
|---|---|---|
| `app/spot.be` | die App | ja |
| `app/autoexec.be` | lädt `spot` beim Start und bei `BrRestart` | ja, nur bei Bedarf |
| `app/desktop_harness.be`, `app/persist.be`, `app/path.be` | Desktop-Test, Stubs | **nie** |
| `reference/` | gPlug-Scripts und `read_sensors`-Beispiele (Zähler-Pfad) | nein |

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
./brcmd.sh 'load("spot")'                     # App neu laden ohne Upload (idempotent)
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
- Flash schonen: nicht öfter als nötig in Dateien schreiben (CSV einmal pro Tag bzw. Stunde).
- Jeder Callback-Body in `try ... except .. as e, m ... end`, Fehler mit `log("SPOT: ...", 2)`.
- Neue Commands mit `tasmota.add_cmd`, Crons mit fester Id, damit `load("spot")` nichts doppelt
  registriert.
- Stil von `spot.be` übernehmen: deutsche Kommentare, kurze Methoden, keine Tricks.

## 7. Git

Funktionierende Stände in kleinen Commits sichern, wenn der Mensch zustimmt. Nie `.gplug`, API-Keys
oder `bkw.json` committen.
