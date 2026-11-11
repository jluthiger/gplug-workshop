# Runbook – Einrichten vor Ort

Ziel: in **40 min** vom eigenen Notebook und gPlug zu einem laufenden Agenten und dem Starter auf dem
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

Erst Notebook (Schritte 1–3), dann gPlug (4–5) mit Helfern, zuletzt Starter (6).

## Was du brauchst

- Mitgebracht: gPlug, Notebook mit Netzteil, USB-Datenkabel (nicht nur Ladekabel), Texteditor,
  [Docker Desktop](https://docs.docker.com/get-started/get-docker/) läuft. Docker Desktop fehlt:
  Download ca. 1 GB, Installation 10 min, gleich als Erstes starten. Besser zu Hause erledigen.
- Vom Tisch: Zettel mit Workshop-WLAN (Name, Passwort).
- Terminal: macOS *Terminal*, Linux beliebig, Windows **Ubuntu in WSL** (unten). Alle Befehle im
  Workshop-Ordner. Code-Blöcke lassen sich unverändert kopieren und ausführen; Werte fragen sie
  selbst ab.

Test, ob Docker läuft:

```sh
docker run --rm hello-world
```

Windows einmalig, vor Docker Desktop (Windows ohne Ubuntu, nur PowerShell:
[`WINDOWS_POWERSHELL.md`](WINDOWS_POWERSHELL.md)):
1. PowerShell **als Administrator** öffnen (Rechtsklick auf Start → *Terminal (Administrator)*),
   danach Notebook neu starten. Meldet Windows, die Virtualisierung sei deaktiviert: im BIOS/UEFI
   *Intel VT-x* bzw. *AMD-V/SVM* einschalten.
   ```powershell
   wsl --install -d Ubuntu
   ```
2. Ubuntu öffnen (Startmenü → *Ubuntu*), Linux-Namen und -Passwort festlegen.
3. Docker Desktop installieren, dann *Settings* → *Resources* → *WSL integration* → *Ubuntu*
   einschalten → *Apply & restart*. Danach den Docker-Test oben in Ubuntu ausführen.

Notebook zuerst ins Workshop-WLAN, Schritte 1–3 brauchen Internet.

## 1. Workshop-Ordner herunterladen

```sh
cd ~
curl -L -o ki-workshop.zip https://github.com/gplug-ch/ki-workshop/archive/refs/heads/main.zip
unzip -q ki-workshop.zip && mv ki-workshop-main ki-workshop && rm ki-workshop.zip
cd ki-workshop
```

Ubuntu meldet `unzip: command not found`: installieren, dann den Block oben wiederholen.

```sh
sudo apt install -y unzip
```

Wer git kennt, klont stattdessen:

```sh
cd ~
git clone https://github.com/gplug-ch/ki-workshop.git
cd ki-workshop
```

Prüfen, erwartet u.a. `RUNBOOK.md`, `EXERCISES.md`, `app`, `docker-run.sh`:

```sh
ls
```

## 2. Zugangsdaten für das Sprachmodell

Nichts zu tun: der Workshop-Zugang zu Infomaniak steckt im Docker-Image. Er gilt nur am
Workshop-Tag. Eigener Zugang (Infomaniak oder Claude): `SETUP_OPENCODE.md`, Schritt 3 bzw.
Abschnitt *Alternative: Claude-Modelle von Anthropic*.

## 3. Docker-Image laden, Agent testen

1. Image laden und opencode prüfen. Beim ersten Mal lädt das Skript das fertige Image von GitHub
   (ca. 300 MB, 1–2 min). Erwartet: `opencode v2.0.32`.
   ```sh
   ./docker-run.sh opencode --version
   ```
2. Nur wer geklont hat: Namen für Commits setzen, die Zeile fragt Name und E-Mail ab. Sonst
   überspringen (Stände sichert ihr in der Übung als Kopie von `app/spot.be`):
   ```sh
   ./docker-run.sh bash -c 'read -rp "Name: " n; read -rp "E-Mail: " e; git config user.name "$n"; git config user.email "$e"'
   ```
3. Agent starten:
   ```sh
   ./docker-run.sh
   ```
   Erwartet: opencode-Oberfläche, unten das Modell `Qwen3.5 122B-A10B (Infomaniak AI (Schweiz))`.
4. Erste Frage eintippen:
   ```
   Lies app/spot.be. Erkläre in 5 Sätzen, was die App tut.
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
2. *Werkzeuge* (*Tools*) → *Konsole* (*Console*). Nicht im Terminal: diese beiden Zeilen einzeln in
   die Konsole eingeben, jede mit Enter.
   ```
   Timezone 99
   ```
   ```
   Time
   ```
   Erwartet: `Time` zeigt die aktuelle Uhrzeit (Sommer-/Winterzeit korrekt).

Die WebUI-Seite offen lassen, du brauchst sie in der Übung.

## 6. Starter aufs Gerät

1. IP eintragen. Die Zeile fragt die IP aus Schritt 4 ab (nur die IP eingeben, z.B. `192.168.1.50`):
   ```sh
   printf 'gPlug-IP: '; read -r ip; echo "$ip" > .gplug
   ```
2. In der WebUI *Werkzeuge* → *Dateisystem verwalten* (*Manage File system*): gibt es schon eine
   `autoexec.be`?
   - **Nein**:
     ```sh
     ./upload.sh app/spot.be app/autoexec.be
     ```
   - **Ja**: nicht überschreiben. In der WebUI bearbeiten, Zeile `load("spot")` ergänzen,
     speichern, dann nur:
     ```sh
     ./upload.sh app/spot.be
     ```

   Erwartet: `OK  /spot.be (… Byte)`, `OK  BrRestart`, `OK  heap_free … kB`.
3. Prüfen. Log, erwartet `SPOT: v… geladen`, keine Fehlermeldung mit `BRY:`
   (`BRY: Berry initialized` und `BRY: Successfully loaded …` sind normal):
   ```sh
   ./log.sh
   ```
   Status, erwartet JSON mit `"Sim":true`:
   ```sh
   ./brcmd.sh 'tasmota.cmd("SpotStatus")'
   ```
4. WebUI neu laden (Cmd+R / F5).

   Erwartet: drei Kopfzeilen (Spotpreis jetzt, Einspeisung heute, Vergütung heute) und ein Chart
   mit der cyan Preislinie über einen Tag. Maus über das Chart: Zeit und Preis erscheinen.

## Fertig?

| Prüfung | Erwartet |
|---|---|
| `./docker-run.sh` | opencode mit Modell Qwen3.5, antwortet |
| `./log.sh` | `SPOT: v… geladen`, keine `BRY:`-Fehlermeldung |
| `./brcmd.sh 'tasmota.cmd("SpotStatus")'` | `"Sim":true`, Heap über 100 kB |
| WebUI | Preislinie, Cursor zeigt Werte |

Alles grün: weiter mit [`EXERCISES.md`, Abschnitt *Vorbereitung*](https://github.com/gplug-ch/ki-workshop/blob/main/EXERCISES.md#vorbereitung-5-min) (`HeapFree` notieren).

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
- Weiterarbeiten mit KI: [`SETUP_OPENCODE.md`](SETUP_OPENCODE.md); ohne KI, mit Editor und Upload
  von Hand: [`SETUP_OHNE_KI.md`](SETUP_OHNE_KI.md).

Weiter zur [Übung (55 min)](https://github.com/gplug-ch/ki-workshop/tree/main#%C3%BCbung-55-min).
