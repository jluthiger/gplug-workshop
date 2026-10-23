# Runbook – Einrichten vor Ort

Ziel: in **45 min** vom eigenen Notebook und gPlug zu einem laufenden Agenten und dem Starter auf dem
Gerät. Danach beginnt die Übung (`EXERCISES.md`). Jeder Schritt nennt, was du sehen solltest.
Weicht etwas ab: Hand hoch, Helfer kommen. Begriffe: [`LEGENDE.md`](LEGENDE.md).

| Schritt | Was | Zeit |
|---|---|---|
| 1 | Workshop-Ordner herunterladen | 5 min |
| 2 | Zugangsdaten für das Sprachmodell | 5 min |
| 3 | Docker-Image laden, Agent testen | 10 min |
| 4 | gPlug ins Workshop-WLAN | 10 min |
| 5 | Firmware prüfen, Zeitzone | 5–10 min |
| 6 | Starter aufs Gerät | 5 min |

Schritte 4–5 laufen parallel zu 1–3: das Gerät braucht Minuten zum Neustart, nutze die Zeit.

## Was du brauchst

- Mitgebracht: gPlug, Notebook mit Netzteil, USB-Datenkabel (nicht nur Ladekabel), Docker Desktop
  läuft (Test: `docker run --rm hello-world`), Texteditor.
- Docker Desktop fehlt: <https://docs.docker.com/get-started/get-docker/> (macOS: Apple- oder
  Intel-Chip wählen; Windows: Installer verlangt WSL 2 und einen Neustart). Download ca. 1 GB,
  Installation 10 min: gleich als Erstes starten, danach Docker Desktop öffnen und warten, bis es
  *Running* meldet. Besser schon zu Hause erledigen.
- Windows: WSL 2 vor Docker Desktop installieren. PowerShell **als Administrator** öffnen
  (Rechtsklick auf Start → *Terminal (Administrator)*), dann:
  ```powershell
  wsl --install --no-distribution
  ```
  Notebook neu starten. Test in normaler PowerShell: `wsl --status` meldet Standardversion 2.
  Ist WSL schon installiert, bringt `wsl --update` es auf den aktuellen Stand. Meldet Windows, die
  Virtualisierung sei deaktiviert: im BIOS/UEFI *Intel VT-x* bzw. *AMD-V/SVM* einschalten.
- Vom Tisch: Zettel mit Workshop-WLAN (Name, Passwort).

Notebook zuerst ins Workshop-WLAN, Schritte 1–3 brauchen Internet.

Terminal: macOS *Terminal*, Linux beliebig, Windows *PowerShell*. Alle Befehle im Workshop-Ordner.

Windows-Alternative zu PowerShell: Ubuntu in WSL. Dann gelten überall die Befehle für
macOS / Linux (`export`, `./docker-run.sh`), PowerShell-Sperren fallen weg.
1. Ubuntu installieren (PowerShell): `wsl --install -d Ubuntu`. Beim ersten Start Linux-Namen und
   -Passwort festlegen.
2. Docker Desktop → *Settings* → *Resources* → *WSL integration* → *Ubuntu* einschalten →
   *Apply & restart*.
3. Ubuntu öffnen (Startmenü → *Ubuntu*), Test: `docker run --rm hello-world`.
4. Workshop-Ordner (Schritt 1) unter Windows herunterladen, dann ins Linux-Home kopieren, dort
   laufen Dateizugriffe viel schneller als über `/mnt/c`:
   ```sh
   cp -r /mnt/c/Users/<name>/ki-workshop ~/
   cd ~/ki-workshop
   chmod +x *.sh                  # nötig, falls ./docker-run.sh "Permission denied" meldet
   ```

## 1. Workshop-Ordner herunterladen

ZIP herunterladen: <https://github.com/gplug-ch/ki-workshop/archive/refs/heads/main.zip>.
Entpacken (Doppelklick), der Ordner heisst `ki-workshop-main`: in `ki-workshop` umbenennen und ins
Home-Verzeichnis verschieben (macOS `/Users/<name>`, Windows `C:\Users\<name>`). Dann im Terminal:
```sh
cd ~/ki-workshop                  # Windows: cd $HOME\ki-workshop
```

Lieber alles im Terminal? macOS / Linux:
```sh
cd ~
curl -L -o ki-workshop.zip https://github.com/gplug-ch/ki-workshop/archive/refs/heads/main.zip
unzip -q ki-workshop.zip && mv ki-workshop-main ki-workshop && rm ki-workshop.zip
cd ki-workshop
```
Windows (PowerShell):
```powershell
cd $HOME
Invoke-WebRequest https://github.com/gplug-ch/ki-workshop/archive/refs/heads/main.zip -OutFile ki-workshop.zip
Expand-Archive ki-workshop.zip -DestinationPath . ; Rename-Item ki-workshop-main ki-workshop ; Remove-Item ki-workshop.zip
cd ki-workshop
```

Wer git kennt, klont stattdessen: `git clone https://github.com/gplug-ch/ki-workshop.git` im
Home-Verzeichnis, dann `cd ki-workshop`.

Erwartet: `ls` zeigt u.a. `RUNBOOK.md`, `EXERCISES.md`, `app`, `docker-run.sh`.

## 2. Zugangsdaten für das Sprachmodell

Nichts zu tun: der Workshop-Zugang zu Infomaniak steckt im Docker-Image. Er gilt nur am
Workshop-Tag und wird danach gesperrt. Eigener Zugang (Infomaniak oder Claude) statt Workshop-Key:
`SETUP_OPENCODE.md`, Schritt 3 bzw. Abschnitt *Alternative: Claude-Modelle von Anthropic*.

## 3. Docker-Image laden, Agent testen

1. Shell im Container öffnen. Beim ersten Mal lädt das Skript das fertige Docker-Image von
   GitHub (ca. 300 MB, 1–2 min), danach startet es sofort:
   ```sh
   ./docker-run.sh bash            # Windows: .\docker-run.ps1 bash
   opencode --version              # erwartet: opencode v2.0.32
   ```
   Windows meldet `UnauthorizedAccess` bzw. „Ausführung von Skripts ist deaktiviert“: PowerShell
   blockiert das Skript. Im selben Fenster freigeben (gilt nur für dieses Fenster) und neu starten:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\docker-run.ps1 bash
   ```
2. Nur wer git kennt und geklont hat: im Container Namen für Commits setzen (gilt nur für diesen
   Ordner). Alle anderen überspringen, git braucht es im Workshop nicht; funktionierende Stände
   sichert ihr in der Übung als Kopie von `app/spot.be`.
   ```sh
   git config user.name "Vorname Name"
   git config user.email "du@example.ch"
   ```
   Danach `exit`.
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
   - **Tiefer**: Helfer rufen, nicht selbst aktualisieren. Der gPlug braucht seine eigene Firmware
     von gplug.ch (mit gPlug-Script für den Zähler); die Standard-Firmware von Tasmota
     (*Update über Webserver*) passt nicht. Die Helfer spielen sie über *Firmwareupdate* →
     *Updatedatei hochladen* ein (ca. 2 min, Gerät startet neu).
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

Alles grün: weiter mit `EXERCISES.md`, Abschnitt *Vorbereitung* (`HeapFree` notieren).

## Häufige Probleme

| Symptom | Lösung |
|---|---|
| `docker: command not found` / `Cannot connect to the Docker daemon` | Docker Desktop starten, neues Terminal, Schritt 2 wiederholen |
| Image-Bau bricht ab (Download-Fehler) | `./docker-run.sh --build` erneut; WLAN prüfen; Helfer rufen |
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
