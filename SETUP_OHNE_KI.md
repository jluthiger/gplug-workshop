# Setup: Berry-Apps ohne KI entwickeln

Für die Arbeit nach dem Workshop: die App `app/spot.be` (oder eine eigene) mit einem Texteditor
ändern und von Hand auf den gPlug laden. Kein Sprachmodell, kein Zugang nötig. Zeitbedarf ca. 5 min.

Befehle für Linux, macOS und Ubuntu in WSL. Windows mit PowerShell:
[`WINDOWS_POWERSHELL.md`](WINDOWS_POWERSHELL.md) (Skripte in der Container-Shell
`.\docker-run.ps1 bash`).

## 1. Was du brauchst

- gPlug im Heim-WLAN, WebUI erreichbar (`http://<gplug-ip>`).
- Texteditor, z.B. VS Code.
- Für Weg A: Terminal mit `sh` und `curl` (auf macOS und Linux vorhanden). Für Weg B nur den Browser.

## 2. Weg A: mit den Workshop-Skripten (empfohlen)

Dieselben Skripte wie am Workshop, nur rufst du sie selbst auf.

1. IP eintragen (einmal, nach WLAN-Wechsel neu):
   ```sh
   printf 'gPlug-IP: '; read -r ip; echo "$ip" > .gplug
   ```
2. `app/spot.be` im Editor ändern, speichern.
3. Hochladen. Das Skript prüft die Grösse auf dem Gerät, lädt die App neu (`BrRestart`) und startet
   den gPlug selbst neu, wenn der Heap unter 100 kB fällt:
   ```sh
   ./upload.sh app/spot.be
   ```
   Erwartet: `OK  /spot.be (… Byte)`, `OK  BrRestart`, `OK  heap_free … kB`.
4. Konsole lesen. Erwartet `SPOT: … geladen`, keine Zeile mit `BRY:`:
   ```sh
   ./log.sh
   ```
5. Prüfen und WebUI neu laden (Cmd+R / F5):
   ```sh
   ./brcmd.sh 'tasmota.cmd("SpotStatus")'
   ```

## 3. Weg B: nur mit dem Browser

Menünamen wie auf dem gPlug (deutsch), in Klammern englisch.

1. *Werkzeuge* (*Tools*) → *Dateisystem verwalten* (*Manage File system*).
2. Datei wählen (`app/spot.be`) und hochladen. Kleine Änderungen gehen auch direkt dort: Datei
   bearbeiten, speichern.
3. *Werkzeuge* → *Konsole* (*Console*), App neu laden:
   ```
   BrRestart
   ```
   Konsole lesen: `SPOT: … geladen`, keine Zeile mit `BRY:`.
4. Heap prüfen, soll über 100 kB liegen. Jeder `BrRestart` kostet ~1 kB, erst ein Neustart gibt ihn
   zurück:
   ```
   Br tasmota.gc() return tasmota.memory("heap_free")
   ```
   Unter 100 kB: `Restart 1` (gPlug startet neu, ca. 20 s).

## 4. Optional: auf dem Notebook testen

Fehler früh finden, ohne Upload. `berry` steckt im Docker-Image; ohne Sprachmodell-Zugang meldet
`docker-run.sh` nur einen `HINWEIS`, die Shell läuft trotzdem.

```sh
curl -s -o app/bkw.json https://api.bkw.ch/api/dyntariffs/v1/Tariffs/energyreturn   # einmal
./docker-run.sh bash
cd app && berry desktop_harness.be
```

Erwartet: letzte Zeile `HARNESS OK`.

## 5. Regeln für Berry auf dem gPlug

Gelten mit und ohne KI. Ausführlich in [`AGENTS.md`](AGENTS.md) §6, die API in
[`TASMOTA_BERRY_API.md`](TASMOTA_BERRY_API.md).

- Kein Callback länger als 50 ms; lange Arbeit mit `tasmota.set_timer` aufteilen.
- RAM knapp (~120 kB frei): keine grossen Strings oder Listen, HTML stückweise senden.
- Jeder Callback-Body in `try ... except .. as e, m ... end`.
- Neue Instanzvariablen mit `var` deklarieren (strict mode).
- Flash schonen: Dateien selten schreiben.
- Ergänzungen an den Kommentaren `# ERWEITERUNGSPUNKT` in `app/spot.be` einhängen.
- Funktionierende Stände sichern: `cp app/spot.be spot_v1.be` oder `git commit`.

## Fehlerbehebung

| Symptom | Ursache / Lösung |
|---|---|
| `BRY:`-Zeile mit Zeilennummer | Syntax- oder Laufzeitfehler, Zeile in `app/spot.be` ansehen |
| `FEHLER: http://… nicht erreichbar` | IP in `.gplug` falsch oder Notebook nicht im selben WLAN |
| Upload meldet `Nicht genug Speicherplatz` | `./upload.sh` erneut; in Weg B die Seite *Dateisystem verwalten* neu öffnen |
| Cursor im Chart zeigt nichts | WebUI-Seite neu laden |
| Verirrt | Checkpoint `app/steps/spot_N.be` nach `app/spot.be` kopieren, hochladen |

## Quellen

- Berry-Sprachreferenz: <https://tasmota.github.io/docs/_media/BERRY_LANGUAGE_REFERENCE.txt>
- Tasmota Berry: <https://tasmota.github.io/docs/Berry/>
