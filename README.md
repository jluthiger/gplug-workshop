# gPlug Spotpreis-App (Tasmota Berry)

![Vom Starter (links, nur Preislinie) zur Referenz-App (rechts) in 4 Schritten](docs/stufen.png)

*Vom Starter (links, nur Spotpreis) zur Referenz-App (rechts): Einspeisung, Negativpreise, 3 Tage,
Vergütung. Am Workshop baust du diese Schritte mit dem Coding-Agenten.*

Berry-App für den [gPlug](https://gplug.ch) (Tasmota, ESP32-C3): holt einmal täglich die
dynamischen BKW-Einspeisetarife, misst viertelstündlich die eingespeiste Energie am
Smart Meter und zeigt Preis, Energie und Vergütung als Chart in der Tasmota-WebUI.

Referenz-App und Unterlagen für den DIY-Workshop **«Arbeiten mit einem Coding-Agenten
auf einem Embedded-Gerät»** (12. November 2026, Glue, Bern). Die App wurde selbst mit
einem Coding-Agenten entwickelt; der Prozess ist Teil des Workshops.

## Teilnahme am Workshop

Keine Vorbereitung nötig. Mitbringen: eigener gPlug ([gplug.ch](https://gplug.ch)), Notebook
(macOS, Linux, Windows) mit Netzteil, USB-Datenkabel; installiert: Docker Desktop und ein
Texteditor. Unbekannte Begriffe: [`LEGENDE.md`](LEGENDE.md).

### Vor Ort: Einrichten (mit Anleitung und Helfern)

Schritt für Schritt mit erwarteter Ausgabe: [`RUNBOOK.md`](RUNBOOK.md). Kurzfassung:

1. Workshop-Ordner als ZIP holen (oder `git clone https://github.com/gplug-ch/ki-workshop.git`).
   `./docker-run.sh` (Windows: `.\docker-run.ps1`) lädt beim ersten Mal das fertige Image von
   `ghcr.io/gplug-ch/ki-workshop` (Infomaniak-Zugang für den Workshop-Tag eingebaut) und startet
   opencode. Nach dem Workshop oder mit eigenem Zugang: [`SETUP_OPENCODE.md`](SETUP_OPENCODE.md).
2. gPlug ins Workshop-WLAN, IP notieren, `http://<gplug-ip>` öffnen. *Tasmota Version* unter
   15.3.0: Helfer spielen die gPlug-Firmware ein. In der Konsole `Timezone 99`.
3. IP eintragen und Starter laden:
   ```sh
   echo <gplug-ip> > .gplug
   ./upload.sh app/spot.be app/autoexec.be   # Windows: zuerst .\docker-run.ps1 bash
   ./log.sh                                  # erwartet: SPOT: v0.3 geladen, keine BRY:-Zeile
   ./brcmd.sh 'tasmota.cmd("SpotStatus")'    # erwartet: "Sim":true
   ```
   Existiert auf dem Gerät schon eine `autoexec.be`: nicht überschreiben, dort `load("spot")`
   ergänzen und nur `app/spot.be` hochladen. Die WebUI zeigt jetzt die Preislinie (Simulator,
   kein Smart Meter nötig).

### Übung: vom Starter zur Referenz-App (60 min)

Ablauf, Prompts und Prüfschritte in [`EXERCISES.md`](EXERCISES.md) ([PDF, A4](docs/EXERCISES.pdf)):

1. Energie-Balken mit kWh-Achse — **Pflicht**
2. Negativpreis: Balken orange, Bereich unter 0 schattiert — **Pflicht**
3. 3 Tage mit Stundenwerten — für Schnelle
4. Vergütungs-Chart mit Σ — für Schnelle

Wer hängen bleibt, kopiert den Checkpoint des vorigen Schritts (`app/steps/spot_N.be`) nach
`app/spot.be`. Zum Schluss Abschlussrunde (Checkliste in `EXERCISES.md`).

**Erfolgreich**, wenn Schritt 2 in der WebUI sichtbar ist, `./log.sh` `SPOT: v0.3 geladen` ohne
`BRY:` zeigt, `HeapFree` über 100 kB liegt und der Stand gesichert ist.

### Nach dem Workshop

- API-Key widerrufen bzw. Ausgabenlimite prüfen.
- gPlug zurück ins Heim-WLAN.
- Am Smart Meter: in `app/spot.be` `"sim": false` setzen und `./upload.sh app/spot.be`.

## Funktionen (v0.3, Referenz-App)

- **Preise**: BKW-API `dyntariffs/v1/Tariffs/energyreturn`, 96 Viertelstundenwerte pro Tag,
  stündlich geprüft, nur bei Bedarf abgerufen. ~21 kB JSON wird sofort nach dem Parsen freigegeben.
- **Zähler**: Export-Zählerstand aus dem gPlug-Script (`z.Eo`), alle 15 min, Delta auf 0.01 kWh.
  Ohne Smart Meter läuft ein Simulator (`sim: true`) mit Leistung `Po`, Zeitraffer (`sim_tick`
  5/15/60 min) und gefüllten Vortagen; der heutige Tag bekommt ein Mittagstief mit Negativpreisen.
- **WebUI**: Kopfzeilen (Preis jetzt, Einspeisung heute, Vergütung heute) + SVG-Chart über 3 Tage
  mit Stundenwerten (Einspeisung, Spotpreis, Vergütung), Cursor mit Werten, oberhalb des
  Tasmota-Hauptmenüs. Der Starter (`app/spot.be`) zeigt nur die Preislinie eines Tages.
- **CSV**: eine Zeile pro Tag in `spot_YYYY-MM.csv` (`Datum;Energie_kWh;Verguetung_CHF`),
  maximal zwei Monatsdateien.
- **Commands**: `SpotPrices` (nächste 10 h als JSON), `SpotPrices 15`, `SpotStatus`,
  `SpotFetch`, `SpotFetch file`, `SpotTick`.
- **Telemetrie**: `"Spot":{"Price","EnergyToday","RevenueToday"}` im Tele-JSON, im Sim-Modus
  zusätzlich `"Po"`.

Speicher: 4 Tage × 100 Slots × 2 Byte je für Preis und Energie, ca. 1.6 kB RAM. Freier Heap
mit geladener App ~120 kB.

## Installation auf dem gPlug

Voraussetzungen: Tasmota ≥ 15.3.0 mit Berry, UFS und SML (gPlug ab Webshop), `Timezone 99`
(Sommerzeit; ab Werk steht `+01:00`).

```sh
H=http://<gplug-ip>
curl -s -o /dev/null $H/ufsd                 # einmal nach jedem Neustart: Upload-Modus Datei
curl -F 'ufsu=@app/spot.be'     $H/ufsu
curl -F 'ufsu=@app/autoexec.be' $H/ufsu
curl "$H/cm?cmnd=BrRestart"                  # lädt autoexec.be -> load("spot")
curl "$H/cm?cmnd=SpotStatus"
```

Alternativ über die Tasmota-WebUI: *Werkzeuge → Dateisystem verwalten* (*Tools → Manage File system*), dann in der
Konsole `BrRestart`.

Konfiguration am Anfang von `app/spot.be` (`spot_cfg`): `sim`, `meter_path`, `days`,
`csv_dir`, `csv_hourly`.

## Entwicklung

- `app/spot.be` – der Starter. Kommentare `# ERWEITERUNGSPUNKT` markieren die Übungsschritte; neue
  Chart-Kurven über `chart_curves()` und `send_polyline` / `send_bars` (Abschnitt `F3  Chart`).
- `app/steps/spot_1.be` … `spot_4.be` – Checkpoints nach jedem Schritt; `spot_4.be` = Referenz-App.
- `tools/make_steps.py` – erzeugt Starter und Checkpoints 1–3 aus `spot_4.be` (ohne Option nur
  prüfen, `--write` schreibt). Nach Änderungen alle Stände mit dem Harness prüfen.
- `docs/build-pdf.sh` – `EXERCISES.md` als A4-PDF (`docs/EXERCISES.pdf`, braucht pandoc und Chrome).
- `app/desktop_harness.be` – simuliert einen Tag auf dem PC (Berry-Interpreter nötig,
  `brew install berry` oder aus den Tasmota-Quellen). Braucht eine gespeicherte BKW-Antwort
  `bkw.json` im Arbeitsverzeichnis. Ausgabe endet mit `HARNESS OK`.
- `app/persist.be`, `app/path.be` – Stubs nur für den Harness, nie aufs Gerät laden.
- `reference/` – `read_sensors`-Samples (gPlug L+G E450, Kamstrup). Die gPlug-Scripts selbst (gplug.ch) liegen nicht im Repo.
- `AGENTS.md` – Regeln für den Coding-Agenten, lädt opencode automatisch.
- `upload.sh`, `brcmd.sh`, `log.sh` – Gerät bedienen (Upload + `BrRestart`, Berry-Ausdruck,
  Konsole). Geräte-IP in `.gplug` oder `$GPLUG`.
- `Dockerfile`, `docker-run.sh`, `docker-run.ps1` – Sandbox: opencode 2.0, `berry`, `git` im
  Container, sichtbar nur dieser Ordner (Standard-Setup, siehe `SETUP_OPENCODE.md`).
  `Dockerfile.workshop`, `tools/publish-image.sh`, `tools/delete-image.sh` – Kursleitung:
  Image mit Workshop-Zugang auf ghcr.io veröffentlichen und danach löschen, Anleitung in
  [`DOCKER_ADMIN.md`](DOCKER_ADMIN.md).
- `TASMOTA_BERRY_API.md` – Spickzettel der verwendeten Tasmota-Berry-API, als Kontext für
  den Coding-Agenten gedacht.

Neuladen auf dem Gerät ohne Neustart: `Br load("spot")` (idempotent, alte Instanz wird
abgemeldet).

## Workshop-Unterlagen

- `EXERCISES.md` – Übungen mit Prompt-Vorlagen, erwartetem Resultat, Prüfschritten und Stolpersteinen.
- `INTENT.md` – Anforderungen F1–F6, BKW-API-Fakten, Entscheide, offene Fragen, Abkürzungen.
- `LEGENDE.md` – Begriffe und Abkürzungen für Teilnehmende.
- `THIRD_PARTY.md` – fremde Inhalte, Lizenzen, Entscheide dazu.
- `RUNBOOK.md` – Einrichten vor Ort, Schritt für Schritt.
- `SETUP_OPENCODE.md` – Setup opencode + Infomaniak-LLM (Schritt für Schritt), Konfiguration in `opencode.json`.

<!-- kursleitung -->
### Nur Kursleitung (nicht im Teilnehmer-Repo)

- `WORKSHOP_PREP.md` – Zeitplan, KI-Didaktik, Setup vor Ort, Deliverables, Risiken.
- `REPLY_HERMANN.md` – Antwort auf das RFC des Veranstalters; `261021-meeting-hermann/` – Meeting 21.10.
- `mock/` – UI-Mock mit synthetischen Daten, `ui-drafts/` – die drei UI-Entwürfe.
- `tools/sync_participant.sh` – überträgt den Stand ins Teilnehmer-Repo `gplug-ch/ki-workshop`.
<!-- /kursleitung -->

## Lizenz

MIT, siehe `LICENSE`; Fremdes: `THIRD_PARTY.md`.
