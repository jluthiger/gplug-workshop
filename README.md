# gPlug Spotpreis-App (Tasmota Berry)

Berry-App für den [gPlug](https://gplug.ch) (Tasmota, ESP32-C3): holt einmal täglich die
dynamischen BKW-Einspeisetarife, misst viertelstündlich die eingespeiste Energie am
Smart Meter und zeigt Preis, Energie und Vergütung als Chart in der Tasmota-WebUI.

Referenz-App und Unterlagen für den DIY-Workshop **«Arbeiten mit einem Coding-Agenten
auf einem Embedded-Gerät»** (12. November 2026, Glue, Bern). Die App wurde selbst mit
einem Coding-Agenten entwickelt; der Prozess ist Teil des Workshops.

## Funktionen (v0.2)

- **Preise**: BKW-API `dyntariffs/v1/Tariffs/energyreturn`, 96 Viertelstundenwerte pro Tag,
  stündlich geprüft, nur bei Bedarf abgerufen. ~21 kB JSON wird sofort nach dem Parsen freigegeben.
- **Zähler**: Export-Zählerstand aus dem gPlug-Script (`z.Eo`), alle 15 min, Delta auf 0.01 kWh.
  Ohne Smart Meter läuft ein Simulator (`sim: true`).
- **WebUI**: Kopfzeilen (Preis jetzt, Einspeisung heute, Vergütung heute) + SVG-Chart des
  laufenden Tages, oberhalb des Tasmota-Hauptmenüs.
- **CSV**: eine Zeile pro Tag in `spot_YYYY-MM.csv` (`Datum;Energie_kWh;Verguetung_CHF`),
  maximal zwei Monatsdateien.
- **Commands**: `SpotPrices` (nächste 10 h als JSON), `SpotPrices 15`, `SpotStatus`,
  `SpotFetch`, `SpotFetch file`, `SpotTick`.
- **Telemetrie**: `"Spot":{"Price","EnergyToday","RevenueToday"}` im Tele-JSON.

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

Alternativ über die Tasmota-WebUI: *Consoles → Manage File system → Upload*, dann in der
Konsole `BrRestart`.

Konfiguration am Anfang von `app/spot.be` (`spot_cfg`): `sim`, `meter_path`, `days`,
`csv_dir`, `csv_hourly`.

## Entwicklung

- `app/spot.be` – die App. Kommentare `# ERWEITERUNGSPUNKT` markieren die Übungen.
- `app/desktop_harness.be` – simuliert einen Tag auf dem PC (Berry-Interpreter nötig,
  `brew install berry` oder aus den Tasmota-Quellen). Braucht eine gespeicherte BKW-Antwort
  `bkw.json` im Arbeitsverzeichnis. Ausgabe endet mit `HARNESS OK`.
- `app/persist.be`, `app/path.be` – Stubs nur für den Harness, nie aufs Gerät laden.
- `mock/` – UI-Mock mit synthetischen Daten, `ui-drafts/` – die drei UI-Entwürfe.
- `reference/` – gPlug-Scripts (L+G E450, Kamstrup) und `read_sensors`-Samples.
- `TASMOTA_BERRY_API.md` – Spickzettel der verwendeten Tasmota-Berry-API, als Kontext für
  den Coding-Agenten gedacht.

Neuladen auf dem Gerät ohne Neustart: `Br load("spot")` (idempotent, alte Instanz wird
abgemeldet).

## Workshop-Unterlagen

- `INTENT.md` – Anforderungen F1–F6, BKW-API-Fakten, Entscheide, offene Fragen, Abkürzungen.
- `WORKSHOP_PREP.md` – Zeitplan, KI-Didaktik, Hausaufgaben, Deliverables, Risiken.
- `REPLY_HERMANN.md` – Antwort auf das RFC des Veranstalters.
- `SETUP_OPENCODE.md` – Setup opencode + Infomaniak-LLM (Schritt für Schritt), Konfiguration in `opencode.json`.

## Lizenz

MIT, siehe `LICENSE`.
