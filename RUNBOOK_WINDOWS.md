# Runbook Windows – Einrichten vor Ort

Ziel: in **40 min** vom eigenen Notebook und gPlug zu einem laufenden Agenten und dem Starter auf dem
Gerät. Danach beginnt die Übung (`EXERCISES.md`). Jeder Schritt nennt, was du sehen solltest.
Weicht etwas ab: Hand hoch, Helfer kommen. Begriffe: [`LEGENDE.md`](LEGENDE.md).
Anderes System: [macOS](RUNBOOK_MACOS.md), [Linux](RUNBOOK_LINUX.md).

| Schritt | Was | Zeit |
|---|---|---|
| 1 | Workshop-Ordner herunterladen | 5 min |
| 2 | Zugangsdaten für das Sprachmodell | – |
| 3 | Docker-Image laden, Agent testen | 10 min |
| 4 | gPlug ins Workshop-WLAN | 10 min |
| 5 | Firmware prüfen, Zeitzone | 5–10 min |
| 6 | Hello World von Hand (Übung Schritt 0) | 10 min |
| 7 | Starter aufs Gerät | 5 min |

Erst Notebook (Schritte 1–3), dann gPlug (4–5) mit Helfern, dann Hello World (6), zuletzt Starter (7).
Schritt 1 ist offen, 2–7 sind zugeklappt: Anleitung aufklappen (▸), wenn du dort bist; erledigte zuklappen.

## Was du brauchst

- Mitgebracht: gPlug, Notebook mit Netzteil, USB-Datenkabel (nicht nur Ladekabel), Texteditor,
  [Docker Desktop](https://docs.docker.com/get-started/get-docker/) läuft. Docker Desktop fehlt:
  Download ca. 1 GB, Installation 10 min, gleich als Erstes starten. Besser zu Hause erledigen.
- Vom Tisch: Zettel mit Workshop-WLAN (Name, Passwort).
- Terminal: eine der beiden Varianten unten. Alle Befehle im Workshop-Ordner. Code-Blöcke lassen
  sich unverändert kopieren und ausführen; Werte fragen sie selbst ab. Einfügen im Terminal und in
  opencode: **Ctrl+V** oder Rechtsklick.

Zwei Varianten. Einmal wählen und dabei bleiben:

| | Variante | Für wen |
|---|---|---|
| **A** | **Ubuntu in WSL** (empfohlen) | alle; die Befehle der Unterlagen gelten unverändert |
| **B** | PowerShell | wer kein Ubuntu installieren kann oder will; Geräte-Skripte laufen in der Container-Shell |

In jedem Schritt steht zuerst Variante A. Weicht Variante B ab, folgt ein zugeklappter Block **PowerShell
(Variante B)**; ohne solchen Block gilt der Schritt für beide. Variante A: diese Blöcke überspringen.

### Variante A: Ubuntu in WSL (empfohlen)

Einmalig, vor Docker Desktop:

1. PowerShell **als Administrator** öffnen (Rechtsklick auf Start → *Terminal (Administrator)*),
   danach Notebook neu starten. Meldet Windows, die Virtualisierung sei deaktiviert: im BIOS/UEFI
   *Intel VT-x* bzw. *AMD-V/SVM* einschalten.
   ```powershell
   wsl --install -d Ubuntu
   ```
2. Ubuntu öffnen (Startmenü → *Ubuntu*), Linux-Namen und -Passwort festlegen.
3. Docker Desktop installieren, dann *Settings* → *Resources* → *WSL integration* → *Ubuntu*
   einschalten → *Apply & restart*.

Alle Befehle ab hier im **Ubuntu**-Fenster.

### Variante B: PowerShell

<details>
<summary><b>PowerShell (Variante B)</b> (aufklappen)</summary>

Docker Desktop installieren (mit WSL 2, Standard des Installers). Alle Befehle ab hier in der
normalen **PowerShell** (Startmenü → *Terminal* oder *PowerShell*), nicht als Administrator.

</details>

### Docker testen (beide Varianten)

```sh
docker run --rm hello-world
```

Notebook zuerst ins Workshop-WLAN, Schritte 1–3 brauchen Internet.

## 1. Workshop-Ordner herunterladen

<details open>
<summary><b>Schritt 1 – Anleitung</b> (zuklappen, wenn erledigt)</summary>

```sh
cd ~
curl -L -o ki-workshop.zip https://github.com/gplug-ch/ki-workshop/archive/refs/heads/main.zip
unzip -q ki-workshop.zip && mv ki-workshop-main ki-workshop && rm ki-workshop.zip
cd ki-workshop
```

Meldet Ubuntu `unzip: command not found`: installieren, dann den Block oben wiederholen.

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

<details>
<summary><b>PowerShell (Variante B)</b> (aufklappen)</summary>

```powershell
cd $HOME
Invoke-WebRequest https://github.com/gplug-ch/ki-workshop/archive/refs/heads/main.zip -OutFile ki-workshop.zip
Expand-Archive ki-workshop.zip -DestinationPath . ; Rename-Item ki-workshop-main ki-workshop ; Remove-Item ki-workshop.zip
cd ki-workshop
```

Mit git: dieselben drei Zeilen wie oben (`cd ~`, `git clone …`, `cd ki-workshop`). Prüfen mit `ls`.

</details>

</details>

## 2. Zugangsdaten für das Sprachmodell

<details>
<summary><b>Schritt 2 – Anleitung</b> (aufklappen)</summary>

Nichts zu tun: der Workshop-Zugang zu Infomaniak steckt im Docker-Image. Er gilt nur am
Workshop-Tag. Eigener Zugang (Infomaniak oder Claude): `SETUP_OPENCODE.md`, Schritt 3 bzw.
Abschnitt *Alternative: Claude-Modelle von Anthropic*.

</details>

## 3. Docker-Image laden, Agent testen

<details>
<summary><b>Schritt 3 – Anleitung</b> (aufklappen)</summary>

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

   Prompts aus `EXERCISES.md` kopieren und mit **Ctrl+V** oder Rechtsklick in opencode einfügen.

<details>
<summary><b>PowerShell (Variante B)</b> (aufklappen)</summary>

Statt `./docker-run.sh` überall `.\docker-run.ps1`:

```powershell
.\docker-run.ps1 opencode --version    # Punkt 1
.\docker-run.ps1                       # Punkt 3: opencode starten
```

Punkt 2 (nur wer geklont hat) in der Container-Shell: `.\docker-run.ps1 bash` öffnen, dort die
beiden Zeilen mit eigenem Namen und eigener E-Mail eingeben, dann `exit`.

```sh
git config user.name "Vorname Name"
git config user.email "name@example.org"
```

Meldet PowerShell `UnauthorizedAccess` bzw. „Ausführung von Skripts ist deaktiviert“: im selben
Fenster freigeben (gilt nur für dieses Fenster), dann erneut starten:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

</details>

</details>

## 4. gPlug ins Workshop-WLAN

<details>
<summary><b>Schritt 4 – Anleitung</b> (aufklappen)</summary>

Das Gerät kennt nur dein Heim-WLAN und findet es hier nicht.

1. gPlug per USB-Kabel am Notebook oder Netzteil einstecken, 1–2 min warten.
2. Mit Notebook oder Handy das WLAN des gPlug suchen (Name beginnt mit `gPlug` oder `tasmota`),
   verbinden. Öffnet sich keine Seite: im Browser `http://192.168.4.1`.
3. Workshop-WLAN wählen, Passwort vom Zettel, *Speichern*. Die Seite zeigt die **neue IP-Adresse**
   des gPlug: notieren.
4. Notebook zurück ins Workshop-WLAN, im Browser `http://<gplug-ip>` öffnen.

   Erwartet: Tasmota-Startseite des gPlug.

Kein gPlug-WLAN sichtbar nach 3 min: Helfer rufen.

</details>

## 5. Firmware prüfen, Zeitzone

<details>
<summary><b>Schritt 5 – Anleitung</b> (aufklappen)</summary>

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

</details>

## 6. Hello World von Hand

<details>
<summary><b>Schritt 6 – Anleitung</b> (aufklappen)</summary>

Eine Mini-App mit dem Texteditor ändern und nur über die WebUI hochladen und starten, ohne Skripte
und ohne Agent. Anleitung: [`EXERCISES.md`, *Schritt 0 – Hello World von Hand*](EXERCISES.md#schritt-0--hello-world-von-hand-alle-10-min).

Erwartet: Zeile **Hallo gPlug** (bzw. dein Text) mit «läuft seit N s» in der WebUI. Der nächste
Schritt entfernt sie wieder.

</details>

## 7. Starter aufs Gerät

<details>
<summary><b>Schritt 7 – Anleitung</b> (aufklappen)</summary>

<details>
<summary><b>PowerShell (Variante B)</b> (aufklappen)</summary>

`upload.sh`, `log.sh`, `brcmd.sh` und die Zeile für `.gplug` laufen
nicht in PowerShell. Zuerst die Container-Shell öffnen und offen lassen, dort die Befehle der
Punkte 1–3 unverändert eingeben. Für die Übung ein zweites PowerShell-Fenster für den Agenten
(`.\docker-run.ps1`) öffnen; der Agent führt die Skripte selbst im Container aus.

```powershell
.\docker-run.ps1 bash
```

</details>

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
4. WebUI neu laden (F5).

   Erwartet: drei Kopfzeilen (Spotpreis jetzt, Einspeisung heute, Vergütung heute) und ein Chart
   mit der cyan Preislinie über einen Tag. Maus über das Chart: Zeit und Preis erscheinen. Die
   Zeile «Hallo gPlug» aus Schritt 6 ist weg.

</details>

## Fertig?

| Prüfung | Erwartet |
|---|---|
| `./docker-run.sh` (Variante B: `.\docker-run.ps1`) | opencode mit Modell Qwen3.5, antwortet |
| `./log.sh` | `SPOT: v… geladen`, keine `BRY:`-Fehlermeldung |
| `./brcmd.sh 'tasmota.cmd("SpotStatus")'` | `"Sim":true`, Heap über 100 kB |
| WebUI | Preislinie, Cursor zeigt Werte |

Alles grün: weiter mit [`EXERCISES.md`, Abschnitt *Vorbereitung*](https://github.com/gplug-ch/ki-workshop/blob/main/EXERCISES.md#vorbereitung-5-min) (`HeapFree` notieren).

## Häufige Probleme

| Symptom | Lösung |
|---|---|
| `docker: command not found` / `Cannot connect to the Docker daemon` | Docker Desktop starten (Variante A: *WSL integration* für Ubuntu an), neues Terminal, Schritt 3 wiederholen |
| PowerShell: `UnauthorizedAccess` / „Ausführung von Skripts ist deaktiviert“ | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`, Schritt 3 |
| PowerShell: `./upload.sh` wird nicht erkannt | Skripte nur in der Container-Shell `.\docker-run.ps1 bash`, Schritt 7 |
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
- Variante B: Image lokal bauen mit `.\docker-run.ps1 --build`.

### Eigener Zugang in PowerShell (Variante B)

<details>
<summary><b>PowerShell (Variante B)</b> (aufklappen)</summary>

Ersetzt in [`SETUP_OPENCODE.md`](SETUP_OPENCODE.md) den Schritt 3 (Variablen setzen). Variante A
folgt dort den Befehlen für Ubuntu.

Nur im aktuellen Fenster:

```powershell
$env:INFOMANIAK_PRODUCT_ID = "123456"
$env:INFOMANIAK_API_KEY    = "xxxxxxxxxxxxxxxx"

curl.exe -s "https://api.infomaniak.com/2/ai/$env:INFOMANIAK_PRODUCT_ID/openai/v1/models" `
  -H "Authorization: Bearer $env:INFOMANIAK_API_KEY"
```

Dauerhaft für den eigenen Benutzer, danach **alle** Terminal-Fenster schliessen und neu öffnen:

```powershell
[Environment]::SetEnvironmentVariable("INFOMANIAK_PRODUCT_ID", "123456", "User")
[Environment]::SetEnvironmentVariable("INFOMANIAK_API_KEY", "xxxxxxxxxxxxxxxx", "User")
```

Prüfen (zeigt den Token nicht an), erwartet `ID=123456 KEY=True`:

```powershell
"ID=$env:INFOMANIAK_PRODUCT_ID KEY=$([bool]$env:INFOMANIAK_API_KEY)"
```

Windows-Variablen sind in Ubuntu/WSL nicht sichtbar, dort `~/.bashrc` verwenden.

</details>

Weiter zur [Übung (65 min)](https://github.com/gplug-ch/ki-workshop/tree/main#%C3%BCbung-65-min).
