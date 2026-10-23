# gPlug Spotpreis-App (Tasmota Berry)

![Vom Starter (links, nur Preislinie) zur Referenz-App (rechts) in 4 Schritten](docs/stufen.png)

*Vom Starter (links, nur Spotpreis) zur Referenz-App (rechts): Einspeisung, Negativpreise, 3 Tage,
Vergütung. Am Workshop baust du diese Schritte mit dem Coding-Agenten.*

Unterlagen für den DIY-Workshop **«Arbeiten mit einem Coding-Agenten auf einem Embedded-Gerät»**
(12. November 2026, Glue, Bern). Die Berry-App für den [gPlug](https://gplug.ch) holt die
dynamischen BKW-Einspeisetarife, misst die eingespeiste Energie und zeigt beides als Chart in der
Tasmota-WebUI.

## Mitbringen

Eigener gPlug ([gplug.ch](https://gplug.ch)), Notebook (macOS, Linux, Windows) mit Netzteil,
USB-Datenkabel. Installiert: [Docker Desktop](https://docs.docker.com/get-started/get-docker/)
und ein Texteditor. Sonst keine Vorbereitung nötig.

## Vor Ort einrichten

Schritt für Schritt mit erwarteter Ausgabe: [`RUNBOOK.md`](RUNBOOK.md). Kurzfassung:

1. Workshop-Ordner als ZIP holen, `./docker-run.sh` (Windows: `.\docker-run.ps1`) starten. Lädt
   beim ersten Mal das fertige Image und startet den Agenten opencode. Zugang zum Sprachmodell
   ist eingebaut.
2. gPlug ins Workshop-WLAN, `http://<gplug-ip>` öffnen. Helfer prüfen Firmware und Zeitzone.
3. IP eintragen und Starter laden:
   ```sh
   echo <gplug-ip> > .gplug
   ./upload.sh app/spot.be app/autoexec.be   # Windows: zuerst .\docker-run.ps1 bash
   ./log.sh                                  # erwartet: SPOT: v0.3 geladen, keine BRY:-Zeile
   ```
   Die WebUI zeigt jetzt die Preislinie (Simulator, kein Smart Meter nötig).

## Übung (60 min)

Ablauf, Prompts und Prüfschritte: [`EXERCISES.md`](EXERCISES.md) ([PDF, A4](docs/EXERCISES.pdf)).

1. Energie-Balken mit kWh-Achse — **Pflicht**
2. Negativpreis: Balken orange, Bereich unter 0 schattiert — **Pflicht**
3. 3 Tage mit Stundenwerten — für Schnelle
4. Vergütungs-Chart mit Σ — für Schnelle

Hängen geblieben: Checkpoint des vorigen Schritts `app/steps/spot_N.be` nach `app/spot.be`
kopieren.

## Nach dem Workshop

- gPlug zurück ins Heim-WLAN.
- Am Smart Meter: in `app/spot.be` `"sim": false` setzen und `./upload.sh app/spot.be`.
- Weiterarbeiten mit eigenem Zugang zum Sprachmodell: [`SETUP_OPENCODE.md`](SETUP_OPENCODE.md),
  Image lokal bauen mit `./docker-run.sh --build`.

## Wichtige Dateien

- `app/spot.be` – die App, an der du arbeitest. `app/steps/` – Checkpoints nach jedem Schritt.
- `upload.sh`, `brcmd.sh`, `log.sh` – Gerät bedienen (hochladen, Berry-Befehl, Konsole).
- `AGENTS.md` – Regeln für den Coding-Agenten (liest opencode automatisch).
- `LEGENDE.md` – Begriffe und Abkürzungen.

<!-- kursleitung -->
## Nur Kursleitung (nicht im Teilnehmer-Repo)

### Funktionen (v0.3, Referenz-App)

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

### Installation ohne Skripte

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

Alternativ über die Tasmota-WebUI: *Werkzeuge → Dateisystem verwalten*, dann in der Konsole
`BrRestart`. Existiert auf dem Gerät schon eine `autoexec.be`: dort `load("spot")` ergänzen.
Konfiguration am Anfang von `app/spot.be` (`spot_cfg`): `sim`, `meter_path`, `days`,
`csv_dir`, `csv_hourly`.

### Entwicklung

- `app/spot.be` – Starter, `# ERWEITERUNGSPUNKT` markiert die Übungsschritte; neue Chart-Kurven
  über `chart_curves()` und `send_polyline` / `send_bars` (Abschnitt `F3  Chart`).
- `app/steps/spot_1.be` … `spot_4.be` – Checkpoints; `spot_4.be` = Referenz-App.
- `tools/make_steps.py` – erzeugt Starter und Checkpoints 1–3 aus `spot_4.be` (ohne Option nur
  prüfen, `--write` schreibt). Nach Änderungen alle Stände mit dem Harness prüfen.
- `app/desktop_harness.be` – simuliert einen Tag auf dem PC (`berry`, braucht `bkw.json`), endet
  mit `HARNESS OK`. `app/persist.be`, `app/path.be` – Stubs nur dafür.
- `reference/` – `read_sensors`-Samples (gPlug L+G E450, Kamstrup).
- `docs/build-pdf.sh` – `EXERCISES.md` als A4-PDF (pandoc + Chrome).
- `Dockerfile`, `docker-run.sh`, `docker-run.ps1` – Sandbox (opencode 2.0, `berry`, `git`, nur
  dieser Ordner sichtbar).
- `TASMOTA_BERRY_API.md`, `INTENT.md` – Kontext für den Agenten: API-Spickzettel, Anforderungen.
- `THIRD_PARTY.md` – fremde Inhalte und Lizenzen.

Neuladen ohne Neustart: `Br load("spot")` (idempotent).

### Interne Unterlagen

- `WORKSHOP_PREP.md` – Zeitplan, KI-Didaktik, Setup vor Ort, Deliverables, Risiken.
- `DOCKER_ADMIN.md`, `Dockerfile.workshop`, `tools/publish-image.sh`, `tools/delete-image.sh` –
  Workshop-Image mit Key auf ghcr.io veröffentlichen und danach löschen.
- `REPLY_HERMANN.md` – Antwort auf das RFC des Veranstalters; `261021-meeting-hermann/` – Meeting 21.10.
- `mock/` – UI-Mock mit synthetischen Daten, `ui-drafts/` – die drei UI-Entwürfe.
- `tools/sync_participant.sh` – überträgt den Stand ins Teilnehmer-Repo `gplug-ch/ki-workshop`.
<!-- /kursleitung -->

## Lizenz

MIT, siehe `LICENSE`; Fremdes: `THIRD_PARTY.md`.
