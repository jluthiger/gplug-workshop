# Workshop-Vorbereitung DIY Tasmota/Berry App — 12.11.2026

Checkliste für eine reibungslose Durchführung. Ergänzt `INTENT.md` (App) und `TASMOTA_BERRY_API.md` (Agent-Kontext).
Rahmen: Do 17:00, ca. 3 h, 20 + 4 Teilnehmende, BYOD (eigener gPlug, eigenes Notebook mit USB), Barzahlung vor Ort.

## 1. Zeitplan (3 h netto)

Hauptthema: **Arbeiten mit einem Coding-Agenten** auf einem Embedded-Gerät. Die Berry-App ist das Übungsobjekt.

| # | Zeit | Block | Ziel |
|---|---|---|---|
| 1 | 0:00–0:15 | Einlass, Zahlung, WLAN-Zettel verteilen | alle online |
| 2a | 0:15–0:45 | Notebook: Repo von GitHub (ZIP), Docker-Image laden (`./docker-run.sh`, Key eingebaut), erste Agent-Antwort | Agent antwortet |
| 2b | 0:15–0:45 | parallel, mit Helfern: gPlug ins Venue-WLAN, Firmware ≥ 15.3.0 per Datei-Upload durch Helfer, `Timezone 99` | `Information` zeigt ≥ 15.3.0, `Time` stimmt |
| 2c | 0:45–1:00 | Referenz-App hochladen (`upload.sh`) | `SpotPrices` liefert JSON auf jedem Gerät |
| 3 | 1:00–1:10 | Demo Referenz-App: Datenfluss, Grafik (3 Tage, Simulator-Zeitraffer), CSV, Konsole | Verständnis Übungsobjekt |
| 4 | 1:10–1:35 | **KI-Einführung**: Kontext zeigen (INTENT, Cheat-Sheet, AGENTS.md), Live-Demo guter vs. schlechter Prompt, Demo „Agent halluziniert API → Kontext fixt es“, Agent testet selbst auf Gerät via `brcmd.sh` | Arbeitszyklus verstanden |
| 5 | 1:35–2:35 | **Übung mit Agent**: eine Ergänzung (Vorlage in §1a) | Ergänzung läuft auf eigenem Gerät |
| 6 | 2:35–2:50 | Zeigen: 3–4 Teilnehmende präsentieren Prompt-Verlauf + Ergebnis; was ging schief, was half | Reflexion Methode |
| 7 | 2:50–3:00 | Abschluss, gPlug zurück ins Heim-WLAN, Links, Feedback | — |

Puffer ist knapp; Block 2 ist der kritische. **Keine Vorab-Mail** (entschieden 22.10., Hermann): Teilnehmende machen vor dem Kurs nichts ausser den Voraussetzungen in §2. Firmware-Upgrade, Zeitzone und Agent-Setup laufen vor Ort; 2a und 2b parallel, Helfer übernehmen die Geräte.

## 1a. KI-Didaktik

**Lernziele** (was Teilnehmende nach dem Abend können):

1. Einem Agenten den richtigen **Kontext** geben: Intent, API-Cheat-Sheet, bestehender Code, Gerätegrenzen (RAM, 50-ms-Regel). Verstehen, dass der Agent ohne Kontext plausibel klingende, falsche API erfindet.
2. Eine Aufgabe **klein und prüfbar** formulieren: Erweiterungspunkt nennen, erwartetes Resultat nennen, Testkriterium nennen.
3. Den **Zyklus** schliessen: Code hochladen → `BrRestart` → Konsole lesen → Fehlermeldung wörtlich an den Agenten → nächste Iteration. Den Agenten den Zyklus selbst fahren lassen (`upload.sh`, `brcmd.sh`, `log.sh`), aber Resultat selbst prüfen.
4. **Grenzen** erkennen: wann der Agent rät, wann er Doku braucht, wann der Mensch entscheiden muss (Speicher, Flash-Wear, Datenformat).

**Übungsvorlagen** (je mit Prompt-Vorlage, erwartetem Ergebnis, Prüfschritt):

- **Übung: vom Starter zur Referenz-App in 4 Schritten** (entschieden 22.10., Details in `EXERCISES.md`). Starter im Docker-Container zeigt nur die Preislinie (1 Tag, ¼ h); Ziel ist `docs/zielbild.jpg`. Schritte: 1 Energie-Balken mit kWh-Achse, 2 Negativpreis orange + Schattierung, 3 3 Tage mit Stundenwerten, 4 Vergütungs-Chart mit Σ. 1–2 Pflicht, 3–4 für Schnelle; Checkpoints `app/steps/spot_N.be` zum Aufholen. Probelauf 19.10. der alten Übung A (Qwen3.5-122B, 30 min, 14 Uploads, dritte Achse/Checkboxen/doppelte Schleife) bleibt Demo-Material für Block 4.
- **Bonus** (wer fertig ist): Stunden-CSV mit Aufbewahrung; Schwellwert an Shelly/MQTT.

**Demo-Material** (vorbereiten, nicht improvisieren):

- Transkript/Commits der Referenz-App-Entwicklung mit dem Agenten: 3 Momente zeigen — ein guter Prompt, ein Fehlversuch mit Halluzination, die Korrektur durch Kontext.
- Zwei Prompts für dieselbe Aufgabe nebeneinander: „mach eine Grafik“ vs. strukturierter Prompt (Erweiterungspunkt, Datenquelle, Format, Test). Live ausführen, Ergebnis vergleichen.
- Agent-Werkzeuge im Sandbox-Repo, damit der Agent das Gerät selbst bedienen kann:
  - `upload.sh <file>` — Datei auf gPlug laden (`/ufsu`) und `BrRestart`
  - `brcmd.sh "<berry>"` — Berry-Ausdruck auf dem Gerät ausführen (`/cm?cmnd=Br%20...`), Resultat zurück
  - `log.sh` — letzte Konsolenzeilen holen
  - `AGENTS.md` beschreibt die drei Skripte und verbietet dem Agenten Reboot/Reset-Kommandos.

## 2. Kursvoraussetzungen und Setup vor Ort

Entschieden 22.10. (Hermann): **keine Vorbereitungsarbeiten** durch Teilnehmende, keine Mail vorab.
Ausschreibung nennt nur:

- Eigenen gPlug mitbringen.
- Notebook mit USB-Port und Datenkabel mitbringen.
- Software installiert: Docker, Texteditor oder beliebige Entwicklungsumgebung.
- Optional: eigener Claude-Code-Zugang.

Vor Ort (Block 2, Anleitung in `RUNBOOK.md`, Repo öffentlich auf GitHub `gplug-ch/ki-workshop`, kein USB-Stick (entschieden 22.10.)):

- [ ] Workshop-Repo holen (ZIP, wer git kennt: `git clone https://github.com/gplug-ch/ki-workshop.git`). Kein Key eintragen: steckt im Image (eigener Claude-Zugang: `SETUP_OPENCODE.md`).
- [ ] `./docker-run.sh` bzw. `.\docker-run.ps1` lädt das Image beim ersten Start von ghcr.io (~300 MB). Test: `opencode --version` (v2.0.x), erste Frage an den Agenten.
- [ ] gPlug ins Venue-WLAN (WLAN-Zettel), danach Firmware prüfen: unter 15.3.0 → Helfer spielen die **gPlug-Firmware** per Datei-Upload ein (Datei auf Helfer-Notebooks). Nicht *Update über Webserver*: die OtaUrl zeigt auf die Standard-Firmware `tasmota32c3.bin`, die vermutlich keinen Scripter hat (gPlug-Script/Zähler) – prüfen.
- [ ] In der Tasmota-Konsole `Timezone 99` eingeben (ab Werk `+01:00`). Prüfen: `Time` zeigt die aktuelle Uhrzeit.
- [ ] Gerät nicht erreichbar oder Upgrade misslingt: Flash-Station (esptool) oder Reserve-gPlug.
- [ ] Hinweis: Anleitung zurück ins Heim-WLAN liegt bei.

Entfallen gegenüber der früheren Hausaufgaben-Mail: `Status 10` mitbringen (kein Meter vor Ort, Simulator), USB-Treiber/Chrome (nur Flash-Station braucht sie, wird gestellt), Shelly mitbringen (nur noch erwähnen, falls jemand fragt).

## 2a. Testgerät

Zwei Geräte bei Jürg:

- **Ohne Meter**: `http://192.168.0.201` (LAN, kein WebPassword): Tasmota 15.3.0, ESP32-C3, gPlug-Script 6.9.26 — exakt der Zustand der Teilnehmergeräte am Workshop. Simulator-Pfad, UI, Command, Preisabruf.
- **Am Meter**: `http://gplugk.local` = `192.168.0.130`: Tasmota **15.5.0**, ESP32-C3, gPlugK-Script 6.9.26 (Kamstrup DLMS Push). Realpfad `z.Eo` (live, z.B. 42'872.724 kWh am 18.10.), 3-Tage-Soak-Test der Zählererfassung und CSV. Zweite Tasmota-Version im Test → deckt 15.3.0 und 15.5.0 ab.

Beide Script-Varianten (L+G und Kamstrup, gplug.ch) liefern dieselben JSON-Schlüssel unter `z` — der Default-Pfad `["z","Eo"]` gilt gerätetypübergreifend.

Reihenfolge: jede Änderung zuerst auf dem Gerät ohne Meter, dann auf dem Gerät am Meter.

Testgerät .201 steht seit 18.10. auf `Timezone 99` (vorher fest `+01:00`, Uhr 1 h nach). `Br load("spot")` ist idempotent (alte Instanz wird abgemeldet); nach verwaisten Instanzen (Heap < 110 kB, doppelter UI-Block) `Restart 1` und einmal laden.

Arbeitszyklus von diesem Rechner aus (Basis für `upload.sh` / `brcmd.sh` / `log.sh`):

```sh
curl -s http://192.168.0.201/ufsd -o /dev/null              # Dateimanager-Seite öffnen: schaltet Upload auf Datei-Modus
curl -F 'ufsu=@spot.be' http://192.168.0.201/ufsu          # Datei hochladen
curl 'http://192.168.0.201/cm?cmnd=BrRestart'               # Berry-VM neu starten (läuft autoexec.be)
curl 'http://192.168.0.201/cm?cmnd=Br%20load("spot")'       # Datei laden
curl 'http://192.168.0.201/cm?cmnd=Br%20tasmota.memory("heap_free")'
curl 'http://192.168.0.201/?m=1'                            # Sensor-HTML wie im WebUI
```

Hinweise:
- `BrRestart` lädt nur `autoexec.be`; Dateien, die nicht dort stehen, müssen danach explizit geladen werden.
- Ohne vorherigen Aufruf von `/ufsd` (nach jedem Reboot) behandelt Tasmota den Upload als Firmware und meldet „Upload fehlgeschlagen – Nicht genug Speicherplatz“. `upload.sh` muss den Aufruf immer voranstellen.
- Upload-Größe prüfen: `Br open("/spot.be").size()` muss der lokalen Dateigröße entsprechen.

## 3. Zu klären (vor Design-Freeze, bis Ende Oktober)

- [x] Stock-Firmware auf Webshop-gPlugs: Berry, UFS, SML aktiv (geklärt 18.10.).
- [x] Mindestversion Tasmota **15.3.0** (festgelegt 18.10.). Referenz-App darauf testen.
- [ ] Firmware-Datei für das gPlug-Build ≥ 15.3.0 beschaffen und Upgrade per Datei-Upload auf einem Gerät mit älterer Version testen (Dauer messen, Einstellungen/Script bleiben erhalten?). Anleitung mit Screenshots (`Information`, `Firmware Upgrade`) für `RUNBOOK.md`.
- [ ] **Vor dem Öffentlich-Schalten von `gplug-ch/ki-workshop`**: Verlauf enthält den echten Zählerschlüssel (`reference/gplugk_script.txt`, viele Commits ab `d9dded0`). Entweder Verlauf bereinigen (Rewrite + Force-Push) oder Repo neu mit einem einzigen Commit des aktuellen Stands anlegen; Schlüssel am Zähler ersetzen lassen. Danach Verlauf erneut scannen.
- [ ] Prüfen, ob die Standard-Firmware `tasmota32c3.bin` (OtaUrl der gPlugs) Scripter enthält; sonst gPlug-Firmware-Datei von gplug.ch für die Helfer beschaffen.
- [x] BKW-API: Folgetags-Serie ab 16:33–17:03 lokal (gemessen So 18.10.), danach nur noch Folgetag abrufbar.
- [ ] BKW-API: Messung an einem Werktag wiederholen (Abrufe 15:00–18:00 lokal, alle 15 min).
- [x] Venue-WLAN (Glue): ≥ 50 Clients, kein Captive Portal, keine Client-Isolation, HTTPS 443 frei — von Hermann bestätigt (22.10.). Trotzdem Test vor Ort am Workshop-Tag beim Aufbau (Notebook erreicht gPlug, `api.bkw.ch`, LLM-Provider).
- [ ] Hermanns Antworten (Meeting 21.10., `261021-meeting-hermann/notes.md`) in `INTENT.md` §6 und F1/F2/F3 übertragen.
- [x] Hauptfokus „Arbeiten mit Coding-Agent“, Berry-App als Übungsobjekt: bestätigt (21.10.).
- [x] Zielbild Referenz-App: `docs/zielbild.jpg` (3 Tage, Stundenwerte, Energie + Preis, Vergütung CHF/h mit Σ), entschieden 22.10.
- [ ] Infomaniak-LLM: ein Feature der Referenz-App damit bauen lassen, Qualität bewerten, Fallback-Provider festlegen.
- [ ] opencode.ai: Permission-Konfiguration prüfen (Shell-Kommandos auf `upload.sh`/`brcmd.sh`/`log.sh` begrenzbar? Schreibzugriff nur im Repo?), Infomaniak als OpenAI-kompatibler Provider konfigurierbar? Windows-Install getestet?
- [ ] Aufwand/Offerte (20 h) gegen neuen Scope abgleichen: grössere Grafik, Simulator-Zeitraffer, Fake-Vortage. Hermann informieren, falls es nicht reicht.

## 4. Deliverables (fertig, getestet, bis Ende Oktober)

| # | Datei | Inhalt | Test |
|---|---|---|---|
| 1 | `app/spot.be` | Referenz-App Kern (F1, F2, F5), Tages-CSV — **v0.2 vorhanden**, Desktop-Harness grün, auf 192.168.0.201 live getestet (18.10.). **Grafik neu** nach Zielbild `docs/zielbild.jpg` (22.10.): 3 Tage, Stundenwerte, oben Einspeisung kWh (orange bei Preis < 0) + Preislinie + negativer Bereich schattiert + „jetzt“, unten Vergütung CHF/h + Σ — offen | ≥ 3 Tage auf gplugk (Meter) — offen; Rendering ohne Heap-Einbruch > 5 kB |
| 2 | Simulator | in `spot.be` integriert (`sim: true`): Zähler-Tageskurve, Backfill des laufenden Tages, Preis-Fallback aus Folgetag — vorhanden. **Neu (22.10.)**: Zeitraffer (Takt 5/15/60 min, jeder Takt = eine ¼ h), zusätzlich Leistung `Po` (kW), 2 Vortage mit Fake-Preisen (inkl. negativ) und Fake-Energie auffüllen, als „(Sim)“ markiert — offen | Grafik füllt sich am Abend sichtbar |
| 3 | `autoexec.be` | `load("spot")`, Kommentar | vorhanden (`app/autoexec.be`), auf .201 installiert 18.10., BrRestart lädt App, 1 UI-Block, Fetch OK |
| 4 | `bkw.json` auf dem Gerät | gecachte API-Antwort, `SpotFetch file` **vorhanden** in `spot.be` | am Workshop-Tag morgens frische Antwort speichern und mit ausliefern |
| 1a | `app/desktop_harness.be` + `persist.be`/`path.be` | spot.be ohne Gerät durchspielen (Tag simulieren, CSV, Commands, HTML) | läuft: `berry desktop_harness.be` |
| 5 | `reference/read_sensors_sample.json` | `read_sensors()`-Ausgabe — **vorhanden**, von Gerät 192.168.0.201 gezogen (18.10.). gPlug-Scripts 22.10. entfernt (Lizenz unklar, `gplugk_script.txt` enthielt Zählerschlüssel, steht noch im Git-Verlauf: Schlüssel ersetzen lassen, Verlauf bereinigen nur nach Freigabe) | Zähler-Pfad `["z","Eo"]` daraus abgeleitet |
| 6 | `TASMOTA_BERRY_API.md` | Agent-Kontext | Agent baut Übung ohne Halluzination |
| 7 | `AGENTS.md` | Regeln für opencode.ai: Dateien, Upload-Befehl, Tests, „nie `tasmota.web_send` ausserhalb `web_sensor`“ usw. | Trockenlauf mit Agent |
| 8 | `upload.sh`, `brcmd.sh`, `log.sh` (+ `.ps1`) | Agent-Werkzeuge: Upload + `BrRestart`, Berry-Ausdruck via `/cm?cmnd=Br`, Konsole lesen | Agent löst Schritt 1 allein, Mensch prüft nur |
| 9 | `RUNBOOK.md` | Teilnehmer-Schritte **ab Null vor Ort** (Repo klonen, Image bauen, API-Key, WLAN, Firmware-Upload durch Helfer, `Timezone 99`, App hochladen) mit erwarteter Ausgabe pro Schritt (Screenshots) — **Entwurf 22.10.** (Menünamen vom Gerät .202 übernommen, deutsche WebUI). Offen: Verhalten ohne bekanntes WLAN (AP-Name, `192.168.4.1`, Dauer bis AP) an einem gPlug prüfen; Firmware-Upload durch Helfer: Dateiname auf Stick, bleiben WLAN/Script erhalten (§3); Screenshots | von einer unbeteiligten Person durchgespielt, Block 2 in ≤ 45 min |
| 10 | Agent-Setup | Standard: Docker-Image (`Dockerfile`, `docker-run.sh`/`.ps1`, opencode 2.0.32 + berry + git, nur Repo gemountet). Fallback: opencode 2.0 nativ + `opencode.json` (Infomaniak-Provider, Berechtigungen auf Repo + Skripte) — Image vorhanden, auf macOS getestet 19.10. Image kommt fertig von `ghcr.io/gplug-ch/ki-workshop:workshop` mit eingebautem Key (23.10., siehe Ablauf unten); `docker-run.sh`/`.ps1` laden nur, wenn das Image fehlt, `--build` baut lokal | `docker pull` + erste Agent-Antwort auf Mac, Win, Linux < 10 min |
| 11 | `EXERCISES.md` | 4 Schritte Starter → Referenz-App mit Prompt-Vorlage, Ergebnis, Prüfschritt — geschrieben 22.10.; Bonus CSV/Shelly | Alle 4 Schritte mit Infomaniak-LLM durchspielen, Zeit pro Schritt messen (Ziel: 1–2 in 35 min) |
| 12 | Demo-Transkript | 3 Ausschnitte aus Referenz-App-Entwicklung (guter Prompt, Halluzination, Korrektur) | auf Beamer lesbar |
| 13 | `AGENTS.md`-Ergänzung | Werkzeuge beschreiben, verbotene Kommandos (`Reset`, `Restart`, `Upgrade`), Regel „nach jedem Upload `log.sh` lesen“ | Agent hält sich daran im Trockenlauf |
| 14 | ~~USB-Sticks~~ entfallen (22.10.): Repo öffentlich auf GitHub, Image wird gebaut. Bleibt: gPlug-Firmware ≥ 15.3.0 auf Helfer-Notebooks, frische `bkw.json` vom Workshop-Morgen als Offline-Fallback | Helfer-Notebooks geprüft |
| 15 | Starter + Checkpoints | `app/spot.be` = Starter (nur Preislinie), `app/steps/spot_1.be` … `spot_4.be` (= Referenz-App v0.3); rückwärts aus der Referenz-App abgeleitet, nur F3 verschieden; Generator `tools/make_steps.py` (ohne Option nur prüfen, `--write` schreibt neu und überschreibt `app/spot.be` – nur Vorbereitung) — **vorhanden 22.10.** | alle 5 Stände Harness `HARNESS OK` (22.10.); auf .202: Referenz Heap 109–112 kB mit offener WebUI, Starter 115–119 kB; Checkpoints 1–3 auf Gerät ok (22.10., Heap 106–119 kB, Grafik geprüft); `upload.sh` misst Heap jetzt 12 s nach Restart (vorher während TLS-Fetch → Fehl-Neustarts) |

## 5. Sandbox-Entscheid

Gehostet entfällt: der Agent muss das gPlug im Venue-WLAN erreichen (`upload.sh`, `brcmd.sh`, `log.sh`) — aus der Cloud geht das nicht. **Der Agent läuft lokal auf dem Notebook.** Optionen:

- **A** Docker lokal: eigenes opencode-Image, nur Repo gemountet, gPlug über Standard-Netz erreichbar. Echte Isolation vom Notebook. Risiko: Docker-Desktop-Installation auf 20 BYOD-Notebooks (Windows/WSL, Mac Intel/ARM).
- **D** opencode.ai nativ installiert (ein Binary, Install-Script), Arbeitsverzeichnis = Workshop-Repo, Agent-Berechtigungen über opencode-Konfiguration auf dieses Verzeichnis und die drei Skripte begrenzt. Keine Container-Isolation, aber kein Docker-Setup. Infomaniak-API-Key via Config-Datei im Repo-Ordner.

**Entscheid (19.10.2026): A als Standard, D als Fallback.**

- Grund: Nur der Container setzt die Regel «kein Zugriff ausserhalb des Workshop-Ordners» technisch durch. Nativ begrenzen `opencode.json` und `AGENTS.md` nur die opencode-eigenen Werkzeuge; ein bestätigter Shell-Befehl sieht das ganze Notebook.
- Umsetzung: `Dockerfile` (Debian slim, opencode **2.0.32** gepinnt, `berry` 1.1.0 für den Desktop-Test, `git`, `curl`), `docker-run.sh` / `docker-run.ps1` (baut beim ersten Start, mountet nur das Repo als `/work`, reicht `INFOMANIAK_*` und `GPLUG` durch, Volume `gplug-workshop-data` für Sitzungen, unter Linux mit eigener UID). `.dockerignore` hält Repo und Secrets aus dem Build-Kontext.
- `--network host` ist nicht nötig: der Standard-Bridge-Modus erreicht gPlug (IP) und Internet, auch unter Docker Desktop. `.local`-Namen lösen im Container nicht auf → IP in `.gplug`.
- Getestet 19.10. auf macOS (Apple Silicon, Docker 29.8): Skripte gegen 192.168.0.201, Desktop-Harness `HARNESS OK`, opencode erreicht Infomaniak. Offen: Windows (Docker Desktop + WSL 2, `docker-run.ps1`), Linux, Mac Intel, interaktive TUI-Sitzung mit echtem Key.
- opencode-Version: Das Script `opencode.ai/install` installiert 1.x (Agent-Wechsel `Tab`); Workshop nutzt 2.0 (`Shift+Tab`), nativ via `opencode.ai/v2/install`.
- Keine Vorab-Mail (22.10.): Docker installiert ist Kursvoraussetzung, Repo vor Ort von GitHub, Image wird mit `./docker-run.sh` geladen. Test-Kommando im Runbook (`opencode --version`, erste Frage an Agent).
- Fertiges Image mit eingebautem Key (entschieden 23.10.): `ghcr.io/gplug-ch/ki-workshop:base` (ohne Secrets, bleibt) und `:workshop` (`Dockerfile.workshop`, `ENV INFOMANIAK_*`, nur am Workshop-Tag). Öffentlich, damit kein `docker login` nötig ist → Key ist für jeden sichtbar, der das Image findet (`docker history`). Risiko begrenzt durch: Token-Ablauf = Workshop-Tag + 1, Ausgabenlimite im Infomaniak-Manager, Image danach löschen. Ablauf Kursleitung:
  - [ ] einmalig: `gh auth refresh -s write:packages,delete:packages`, `gh auth token | docker login ghcr.io -u <github-user> --password-stdin`, `docker buildx create --use`.
  - [ ] jetzt: `tools/publish-image.sh base`; Package auf GitHub auf *public* stellen (Org-Packages sind privat); Repo `gplug-ch/ki-workshop` public; Pull-Test auf Windows (`docker pull ghcr.io/gplug-ch/ki-workshop:base`).
  - [ ] Vortag: Infomaniak-Manager: Ausgabenlimite setzen, Token mit Scope `ai-tools` und Ablauf Workshop-Tag + 1 erstellen.
  - [ ] Workshop-Morgen: `INFOMANIAK_PRODUCT_ID=… INFOMANIAK_API_KEY=… tools/publish-image.sh workshop`; Test `./docker-run.sh` (lokales Image vorher mit `docker rmi` entfernen).
  - [ ] danach: `tools/delete-image.sh`, Token im Manager widerrufen.

Zu prüfen für D (Fallback): Verhalten auf Windows ohne Docker — Geräte-Skripte sind `sh`, laufen dort nur in WSL.

## 5a. Heap-Befund (19.10.)

Testgerät nach einer Agent-Sitzung mit 14 Upload-Zyklen bei 64 kB Heap (statt ~130), Preisabruf lieferte nur 39 von 96 Werten, einmal `MEMORY ALLOCATION FAILED`. Gemessen, je nach `tasmota.gc()`:

| Aktion | Heap-Verlust | Erholt durch |
|---|---|---|
| `BrRestart` (jeder `upload.sh`-Lauf) | ~1 kB, ausserhalb Berry | nur `Restart 1` |
| `load("spot")` ohne Restart, erstes Mal | ~20 kB (zweite Klassen-Kopie), danach ~0 | `BrRestart` |
| Abruf alt (`get_string`) | 0 kB, aber unter ~70 kB still abgeschnitten, unter ~50 kB Reboot | — |
| Abruf neu (`write_file` + `f.read(2048)`) | **~3 kB pro Abruf, Berry-Leck in `f.read(n)`** | nur Reboot |
| Abruf neu (`write_file` + `f.readbytes(2048)`) | 0 kB | — |
| HTTPS klein, Datei-Upload | 0 kB | — |

Massnahmen: `parse_file` liest mit `readbytes`; `upload.sh` prüft nach `BrRestart` den Heap und startet unter 100 kB (`MIN_HEAP`, bis 19.10. 80 kB) das Gerät neu; Cheat-Sheet und `AGENTS.md` nennen beide Fallen. Lehrinhalt für Block 4: Agent-Sitzung zeigt, wie 14 Iterationen das Gerät leise aushungern.

## 6. Vor Ort

- [ ] 4 Reserve-gPlugs mit Firmware + Referenz-App (für defekte/alte Geräte).
- [ ] 2 Ersatz-USB-Kabel (Daten, nicht nur Laden), 1 Notebook mit esptool, Chrome und USB-Treibern (CH340/CP210x) als Flash-Station.
- [ ] WLAN-Zettel pro Tisch (nur WLAN, Key steckt im Image), Beamer, Verlängerungskabel.
- [ ] Helfer-Notebooks gemäss Deliverable 14 (gPlug-Firmware, `bkw.json`).
- [ ] 1 Helfer pro 6 Teilnehmende für Block 2 (Firmware-Upgrade und `Timezone 99` übernehmen Helfer, parallel zum Agent-Setup).

## 7. Risiken (Rangfolge)

1. Firmware/Partition passt nicht oder Upgrade dauert → Block 2 platzt. Ohne Vorab-Mail kommen alle Geräte im Ab-Werk-Zustand. Mitigation: Upgrade per Datei-Upload vorab getestet (§3), Helfer übernehmen Geräte parallel zum Agent-Setup, Flash-Station, Reserve-Geräte.
2. Venue-WLAN blockiert oder überlastet. Mitigation: Test beim Aufbau, Hotspot-Fallback, Offline-JSON. Ohne Stick lädt jedes Notebook das Image-Material (Debian-Pakete, Berry, opencode; geschätzt einige 100 MB × 20) über das Venue-WLAN – Bandbreite beim Aufbau testen; Fallback: Image auf ghcr.io veröffentlichen oder Reserve-Stick mit `docker save`-Tar.
3. Agent-Setup (opencode/Docker) frisst Zeit. Mitigation: Build-Dauer vorab auf Mac/Win/Linux messen, Option D als Fallback, Helfer prüfen in Block 1 beim Einlass, ob Docker läuft.
4. Agent halluziniert Tasmota-API. Mitigation: Cheat-Sheet + `AGENTS.md` im Kontext — und als Demo bewusst zeigen, das ist Lehrinhalt.
5. Zu viel Scope live. Mitigation: nur eine Übung, Referenz-App fertig.
8. Grösserer Scope der Referenz-App (22.10.) sprengt Budget oder Liefertermin Ende Oktober. Mitigation: Aufwand früh schätzen (§3), Hermann rechtzeitig informieren; 3-Tage-Grafik vor Simulator-Zeitraffer priorisieren. Starter + 4 Checkpoints verfünffachen den Testaufwand der Grafik.
6. Infomaniak-LLM zu schwach für Berry → Übung scheitert, Teilnehmende schliessen „KI taugt nicht“. Mitigation: Übungen vorab mit genau diesem Modell durchspielen (Deliverable 11), Fallback-Modell konfiguriert.
7. Agent führt destruktives Kommando auf Gerät aus (`Reset 1`, falsches `Upgrade`). Mitigation: `brcmd.sh` filtert Kommandoliste, `AGENTS.md` verbietet, Reserve-Geräte.
