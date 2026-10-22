# Runbook – Einrichten vor Ort

Ziel: in **45 min** vom eigenen Notebook und gPlug zu einem laufenden Agenten und dem Starter auf dem
Gerät. Danach beginnt die Übung (`EXERCISES.md`). Jeder Schritt nennt, was du sehen solltest.
Weicht etwas ab: Hand hoch, Helfer kommen. Begriffe: [`LEGENDE.md`](LEGENDE.md).

| Schritt | Was | Zeit |
|---|---|---|
| 1 | Ordner und Docker-Image vom USB-Stick | 10 min |
| 2 | Zugangsdaten für das Sprachmodell | 5 min |
| 3 | Agent testen | 5 min |
| 4 | gPlug ins Workshop-WLAN | 10 min |
| 5 | Firmware prüfen, Zeitzone | 5–10 min |
| 6 | Starter aufs Gerät | 5 min |

Schritte 4–5 laufen parallel zu 1–3: das Gerät braucht Minuten zum Neustart, nutze die Zeit.

## Was du brauchst

- Mitgebracht: gPlug, Notebook mit Netzteil, USB-Datenkabel (nicht nur Ladekabel), Docker Desktop
  läuft (Test: `docker run --rm hello-world`), Texteditor.
- Vom Tisch: USB-Stick, Zettel mit Workshop-WLAN (Name, Passwort), Product-ID und API-Key.

Terminal: macOS *Terminal*, Linux beliebig, Windows *PowerShell*. Alle Befehle im Workshop-Ordner.

## 1. Ordner und Docker-Image vom USB-Stick

1. Ordner `workshop` vom Stick in dein Home-Verzeichnis kopieren (ganzer Ordner, inkl. versteckter
   Ordner `.git`). Nicht vom Stick aus arbeiten.
2. Terminal öffnen, in den Ordner wechseln:
   ```sh
   cd ~/workshop                   # Windows: cd $HOME\workshop
   ```
3. Prozessor-Typ abfragen und passendes Image laden:
   ```sh
   docker version --format '{{.Server.Arch}}'     # amd64 oder arm64
   docker load -i /Volumes/<STICK>/gplug-workshop-arm64.tar
   ```
   Pfad zum Stick: macOS `/Volumes/<Name>`, Windows z.B. `E:\gplug-workshop-amd64.tar`, Linux
   meist `/media/<user>/<Name>`. Apple-Chip (M1…M4) = `arm64`, die meisten Windows-Notebooks = `amd64`.

   Erwartet (nach ca. 1 min): `Loaded image: gplug-workshop:latest`

## 2. Zugangsdaten für das Sprachmodell

Werte vom Zettel einsetzen. Sie gelten nur in diesem Terminal-Fenster: alle weiteren Befehle hier
ausführen, Fenster offen lassen.

macOS / Linux:
```sh
export INFOMANIAK_PRODUCT_ID=123456
export INFOMANIAK_API_KEY=xxxxxxxxxxxxxxxx
echo "ID=$INFOMANIAK_PRODUCT_ID KEY=${INFOMANIAK_API_KEY:+gesetzt}"
```
Windows (PowerShell):
```powershell
$env:INFOMANIAK_PRODUCT_ID = "123456"
$env:INFOMANIAK_API_KEY    = "xxxxxxxxxxxxxxxx"
"ID=$env:INFOMANIAK_PRODUCT_ID KEY=$([bool]$env:INFOMANIAK_API_KEY)"
```
Erwartet: `ID=123456 KEY=gesetzt` (Windows `KEY=True`).

Der Key gehört dem Workshop und wird danach gesperrt: nicht weitergeben, nicht in Dateien
speichern. Eigener Claude-Zugang statt Infomaniak: `SETUP_OPENCODE.md`, Abschnitt *Alternative:
Claude-Modelle von Anthropic*.

## 3. Agent testen

1. Shell im Container öffnen und Werkzeuge prüfen:
   ```sh
   ./docker-run.sh bash            # Windows: .\docker-run.ps1 bash
   opencode --version              # erwartet: opencode v2.0.32
   ```
2. Im Container git deinen Namen geben (für die Commits in der Übung, gilt nur für diesen Ordner):
   ```sh
   git config user.name "Vorname Name"
   git config user.email "du@example.ch"
   git log -1 --oneline            # erwartet: eine Zeile mit dem letzten Stand
   exit
   ```
3. Agent starten:
   ```sh
   ./docker-run.sh                 # Windows: .\docker-run.ps1
   ```
   Erwartet: opencode-Oberfläche, unten das Modell `Qwen3.5 122B-A10B (Infomaniak AI (Schweiz))`.
4. Erste Frage eintippen:
   ```
   Lies INTENT.md. Erkläre in 5 Sätzen, was app/spot.be tut.
   ```
   Erwartet: Der Agent liest Dateien (Werkzeug-Aufrufe sichtbar) und antwortet sinnvoll.
   Beenden mit `/exit`.

`WARNUNG: INFOMANIAK_PRODUCT_ID … nicht gesetzt` oder `method_not_found`: Schritt 2 im selben
Fenster wiederholen.

## 4. gPlug ins Workshop-WLAN

Das Gerät kennt nur dein Heim-WLAN und findet es hier nicht.

1. gPlug per USB-Kabel am Notebook oder Netzteil einstecken. 1–2 min warten.
2. Mit Notebook oder Handy das WLAN des gPlug suchen (Name beginnt mit `gPlug` oder `tasmota`),
   verbinden. Öffnet sich keine Seite: im Browser `http://192.168.4.1`.
3. Workshop-WLAN wählen, Passwort vom Zettel eingeben, *Speichern*. Die Seite zeigt die **neue
   IP-Adresse** des gPlug: notieren.
4. Notebook zurück ins Workshop-WLAN. Im Browser `http://<gplug-ip>` öffnen.

   Erwartet: Tasmota-Startseite des gPlug.

Kein gPlug-WLAN sichtbar nach 3 min: Helfer rufen (Flash-Station oder Reserve-gPlug).

## 5. Firmware prüfen, Zeitzone

Menünamen wie auf dem gPlug (deutsche Oberfläche), in Klammern die englischen.

1. In der WebUI *Informationen* (*Information*): Zeile *Tasmota Version* (*Program Version*).
   - **15.3.0 oder höher**: weiter mit 2.
   - **Tiefer**: *Firmwareupdate* (*Firmware Upgrade*) → *Updatedatei hochladen* (*Upgrade by file
     upload*) → Datei aus dem Ordner `firmware/` des Sticks wählen (die `.bin`-Datei, nicht
     `.factory.bin`) → *Starten* (*Start upgrade*). Gerät startet neu (ca. 1–2 min). Danach
     *Informationen* erneut prüfen.
2. *Werkzeuge* (*Tools*) → *Konsole* (*Console*), eingeben:
   ```
   Timezone 99
   Time
   ```
   Erwartet: `Time` zeigt die aktuelle Uhrzeit (Sommer-/Winterzeit korrekt).

Die WebUI-Seite des gPlug offen lassen, du brauchst sie in der Übung.

## 6. Starter aufs Gerät

Windows: diese Befehle in der Container-Shell (`.\docker-run.ps1 bash`), dort laufen die Skripte.

1. IP eintragen (nur die IP, eine Zeile):
   ```sh
   echo 192.168.x.y > .gplug
   ```
2. In der WebUI *Werkzeuge* → *Dateisystem verwalten* (*Manage File system*): gibt es schon eine
   `autoexec.be`?
   - **Nein**: beide Dateien hochladen:
     ```sh
     ./upload.sh app/spot.be app/autoexec.be
     ```
   - **Ja**: nicht überschreiben. Datei in der WebUI bearbeiten, Zeile `load("spot")` ergänzen,
     speichern, dann nur `./upload.sh app/spot.be`.

   Erwartet: `OK  /spot.be (… Byte)`, `OK  BrRestart`, `OK  heap_free … kB`.
3. Prüfen:
   ```sh
   ./log.sh                                   # erwartet: SPOT: v0.3 geladen, keine Zeile mit BRY:
   ./brcmd.sh 'tasmota.cmd("SpotStatus")'     # erwartet: JSON mit "Sim":true
   ```
4. WebUI neu laden (Cmd+R / F5).

   Erwartet: drei Kopfzeilen (Spotpreis jetzt, Einspeisung heute, Vergütung heute) und ein Chart
   mit der cyan Preislinie über einen Tag. Mit der Maus über das Chart: Zeit und Preis erscheinen.

## Fertig?

| Prüfung | Erwartet |
|---|---|
| `./docker-run.sh` | opencode mit Modell Qwen3.5, antwortet |
| `./log.sh` | `SPOT: v0.3 geladen`, keine `BRY:`-Zeile |
| `./brcmd.sh 'tasmota.cmd("SpotStatus")'` | `"Sim":true`, Heap über 100 kB |
| WebUI | Preislinie, Cursor zeigt Werte |
| `git log -1` im Container | funktioniert, Name gesetzt |

Alles grün: weiter mit `EXERCISES.md`, Abschnitt *Vorbereitung* (`HeapFree` notieren).

## Häufige Probleme

| Symptom | Lösung |
|---|---|
| `docker: command not found` / `Cannot connect to the Docker daemon` | Docker Desktop starten, neues Terminal, Schritt 2 wiederholen |
| `docker-run.sh` baut ein Image (lange Ausgabe, Download) | Abbrechen (Ctrl+C), Schritt 1.3 nachholen; im Workshop-WLAN nicht bauen |
| `./upload.sh: Permission denied` | `sh upload.sh app/spot.be` bzw. im Container ausführen |
| `FEHLER: http://… nicht erreichbar` | IP in `.gplug` falsch, oder Notebook nicht im Workshop-WLAN |
| Upload meldet `Nicht genug Speicherplatz` | Gerät neu gestartet, Upload-Modus fehlt: `./upload.sh` erneut ausführen |
| `!! heap_free … < 100 kB: Gerät wird neu gestartet` | normal, das Skript wartet selbst (ca. 20 s) |
| Chart fehlt, Uhrzeit falsch | `Timezone 99` vergessen, Schritt 5.2 |
| Weitere Agent-Fehler | `SETUP_OPENCODE.md`, Abschnitt *Fehlerbehebung* |

## Nach dem Workshop

- gPlug zurück ins Heim-WLAN: zu Hause einstecken, er findet das Workshop-WLAN nicht und öffnet
  wieder sein eigenes WLAN; Schritt 4 mit dem Heim-WLAN wiederholen.
- Workshop-Key aus dem Terminal entfernen: Fenster schliessen genügt (nichts gespeichert).
- Am Smart Meter echte Werte statt Simulator: in `app/spot.be` `"sim": false`, `./upload.sh app/spot.be`.
