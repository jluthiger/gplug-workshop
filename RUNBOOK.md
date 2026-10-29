# Runbook – Einrichten vor Ort

Ziel: in **45 min** vom eigenen Notebook und gPlug zu einem laufenden Agenten und dem Starter auf dem
Gerät. Danach beginnt die Übung (`EXERCISES.md`). Jeder Schritt nennt, was du sehen solltest.
Weicht etwas ab: Hand hoch, Helfer kommen. Begriffe: [`LEGENDE.md`](LEGENDE.md).

| Schritt | Was | Zeit |
|---|---|---|
| 1 | Workshop-Ordner herunterladen | 5 min |
| 2 | Zugangsdaten für das Sprachmodell | – |
| 3 | Docker-Image laden, Agent testen | 10 min |
| 4 | gPlug ins Workshop-WLAN | 10 min |
| 5 | Firmware prüfen, Zeitzone | 5–10 min |
| 6 | Starter aufs Gerät | 5 min |

Schritte 4–5 laufen parallel zu 1–3: das Gerät braucht Minuten zum Neustart, nutze die Zeit.

## Was du brauchst

- Mitgebracht: gPlug, Notebook mit Netzteil, USB-Datenkabel (nicht nur Ladekabel), Texteditor,
  [Docker Desktop](https://docs.docker.com/get-started/get-docker/) läuft (Test:
  `docker run --rm hello-world`). Docker Desktop fehlt: Download ca. 1 GB, Installation 10 min,
  gleich als Erstes starten. Besser zu Hause erledigen.
- Vom Tisch: Zettel mit Workshop-WLAN (Name, Passwort).
- Terminal: macOS *Terminal*, Linux beliebig, Windows **Ubuntu in WSL** (unten). Alle Befehle im
  Workshop-Ordner.

Windows einmalig, vor Docker Desktop (Windows ohne Ubuntu, nur PowerShell:
[`WINDOWS_POWERSHELL.md`](WINDOWS_POWERSHELL.md)):
1. PowerShell **als Administrator** (Rechtsklick auf Start → *Terminal (Administrator)*):
   `wsl --install -d Ubuntu`, dann Notebook neu starten. Meldet Windows, die Virtualisierung sei
   deaktiviert: im BIOS/UEFI *Intel VT-x* bzw. *AMD-V/SVM* einschalten.
2. Ubuntu öffnen (Startmenü → *Ubuntu*), Linux-Namen und -Passwort festlegen.
3. Docker Desktop installieren, dann *Settings* → *Resources* → *WSL integration* → *Ubuntu*
   einschalten → *Apply & restart*. Test in Ubuntu: `docker run --rm hello-world`.

Notebook zuerst ins Workshop-WLAN, Schritte 1–3 brauchen Internet.

## 1. Workshop-Ordner herunterladen

```sh
cd ~
curl -L -o ki-workshop.zip https://github.com/gplug-ch/ki-workshop/archive/refs/heads/main.zip
unzip -q ki-workshop.zip && mv ki-workshop-main ki-workshop && rm ki-workshop.zip
cd ki-workshop
```

Ubuntu meldet `unzip: command not found`: `sudo apt install -y unzip`. Wer git kennt, klont
stattdessen: `git clone https://github.com/gplug-ch/ki-workshop.git`, dann `cd ki-workshop`.

Erwartet: `ls` zeigt u.a. `RUNBOOK.md`, `EXERCISES.md`, `app`, `docker-run.sh`.

## 2. Zugangsdaten für das Sprachmodell

Nichts zu tun: der Workshop-Zugang zu Infomaniak steckt im Docker-Image. Er gilt nur am
Workshop-Tag. Eigener Zugang (Infomaniak oder Claude): `SETUP_OPENCODE.md`, Schritt 3 bzw.
Abschnitt *Alternative: Claude-Modelle von Anthropic*.

## 3. Docker-Image laden, Agent testen

1. Shell im Container öffnen. Beim ersten Mal lädt das Skript das fertige Image von GitHub
   (ca. 300 MB, 1–2 min):
   ```sh
   ./docker-run.sh bash
   opencode --version              # erwartet: opencode v2.0.32
   ```
2. Nur wer geklont hat: im Container Namen für Commits setzen, sonst überspringen (Stände sichert
   ihr in der Übung als Kopie von `app/spot.be`):
   ```sh
   git config user.name "Vorname Name"
   git config user.email "du@example.ch"
   ```
   Danach `exit`.
3. Agent starten: `./docker-run.sh`

   Erwartet: opencode-Oberfläche, unten das Modell `Qwen3.5 122B-A10B (Infomaniak AI (Schweiz))`.
4. Erste Frage eintippen:
   ```
   Lies INTENT.md. Erkläre in 5 Sätzen, was app/spot.be tut.
   ```
   Erwartet: Der Agent liest Dateien (Werkzeug-Aufrufe sichtbar) und antwortet sinnvoll.
   Beenden mit `/exit`.

## 4. gPlug ins Workshop-WLAN

Das Gerät kennt nur dein Heim-WLAN und findet es hier nicht.

1. gPlug per USB-Kabel am Notebook oder Netzteil einstecken, 1–2 min warten.
2. Mit Notebook oder Handy das WLAN des gPlug suchen (Name beginnt mit `gPlug` oder `tasmota`),
   verbinden. Öffnet sich keine Seite: im Browser `http://192.168.4.1`.
3. Workshop-WLAN wählen, Passwort vom Zettel, *Speichern*. Die Seite zeigt die **neue IP-Adresse**
   des gPlug: notieren.
4. Notebook zurück ins Workshop-WLAN, im Browser `http://<gplug-ip>` öffnen.

   Erwartet: Tasmota-Startseite des gPlug.

Kein gPlug-WLAN sichtbar nach 3 min: Helfer rufen.

## 5. Firmware prüfen, Zeitzone

Menünamen wie auf dem gPlug (deutsch), in Klammern englisch.

1. *Informationen* (*Information*), Zeile *Tasmota Version* (*Program Version*):
   - **15.3.0 oder höher**: weiter mit 2.
   - **Tiefer**: Helfer rufen, nicht selbst aktualisieren. Der gPlug braucht seine eigene Firmware
     von gplug.ch (mit Zähler-Script), die Standard-Firmware von Tasmota passt nicht.
2. *Werkzeuge* (*Tools*) → *Konsole* (*Console*), eingeben:
   ```
   Timezone 99
   Time
   ```
   Erwartet: `Time` zeigt die aktuelle Uhrzeit (Sommer-/Winterzeit korrekt).

Die WebUI-Seite offen lassen, du brauchst sie in der Übung.

## 6. Starter aufs Gerät

1. IP eintragen (nur die IP, eine Zeile):
   ```sh
   echo 192.168.x.y > .gplug
   ```
2. In der WebUI *Werkzeuge* → *Dateisystem verwalten* (*Manage File system*): gibt es schon eine
   `autoexec.be`?
   - **Nein**: `./upload.sh app/spot.be app/autoexec.be`
   - **Ja**: nicht überschreiben. In der WebUI bearbeiten, Zeile `load("spot")` ergänzen,
     speichern, dann nur `./upload.sh app/spot.be`.

   Erwartet: `OK  /spot.be (… Byte)`, `OK  BrRestart`, `OK  heap_free … kB`.
3. Prüfen:
   ```sh
   ./log.sh                                   # erwartet: SPOT: v0.3 geladen, keine Zeile mit BRY:
   ./brcmd.sh 'tasmota.cmd("SpotStatus")'     # erwartet: JSON mit "Sim":true
   ```
4. WebUI neu laden (Cmd+R / F5).

   Erwartet: drei Kopfzeilen (Spotpreis jetzt, Einspeisung heute, Vergütung heute) und ein Chart
   mit der cyan Preislinie über einen Tag. Maus über das Chart: Zeit und Preis erscheinen.

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
| `docker: command not found` / `Cannot connect to the Docker daemon` | Docker Desktop starten (Windows: WSL integration für Ubuntu an), neues Terminal, Schritt 3 wiederholen |
| Image-Download bricht ab | `./docker-run.sh bash` erneut; WLAN prüfen; Helfer rufen |
| `Permission denied` bei `./upload.sh` | `chmod +x *.sh` |
| `WARNUNG: INFOMANIAK_PRODUCT_ID … nicht gesetzt` / `method_not_found` | Helfer rufen (Workshop-Image fehlt?) |
| `FEHLER: http://… nicht erreichbar` | IP in `.gplug` falsch, oder Notebook nicht im Workshop-WLAN |
| Upload meldet `Nicht genug Speicherplatz` | `./upload.sh` erneut ausführen |
| `!! heap_free … < 100 kB: Gerät wird neu gestartet` | normal, das Skript wartet selbst (ca. 20 s) |
| Chart fehlt, Uhrzeit falsch | `Timezone 99` vergessen, Schritt 5.2 |
| Weitere Agent-Fehler | `SETUP_OPENCODE.md`, Abschnitt *Fehlerbehebung* |

## Nach dem Workshop

- gPlug zurück ins Heim-WLAN: zu Hause einstecken, er öffnet wieder sein eigenes WLAN; Schritt 4
  mit dem Heim-WLAN wiederholen.
- Am Smart Meter echte Werte statt Simulator: in `app/spot.be` `"sim": false`, `./upload.sh app/spot.be`.
