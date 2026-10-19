# Workshop-Vorbereitung DIY Tasmota/Berry App — 12.11.2026

Checkliste für eine reibungslose Durchführung. Ergänzt `INTENT.md` (App) und `TASMOTA_BERRY_API.md` (Agent-Kontext).
Rahmen: Do 17:00, ca. 3 h, 20 + 4 Teilnehmende, BYOD (eigener gPlug, eigenes Notebook mit USB), Barzahlung vor Ort.

## 1. Zeitplan (3 h netto)

Hauptthema: **Arbeiten mit einem Coding-Agenten** auf einem Embedded-Gerät. Die Berry-App ist das Übungsobjekt.

| # | Zeit | Block | Ziel |
|---|---|---|---|
| 1 | 0:00–0:15 | Einlass, Zahlung, WLAN-Zettel | alle online |
| 2 | 0:15–0:40 | gPlug ins Venue-WLAN, Firmware-Check, Referenz-App hochladen | `SpotPrices` liefert JSON auf jedem Gerät |
| 3 | 0:40–0:55 | Demo Referenz-App: Datenfluss, Grafik, CSV, Konsole | Verständnis Übungsobjekt |
| 4 | 0:55–1:25 | **KI-Einführung**: Sandbox starten, Kontext zeigen (INTENT, Cheat-Sheet, AGENTS.md), Live-Demo guter vs. schlechter Prompt, Demo „Agent halluziniert API → Kontext fixt es“, Agent testet selbst auf Gerät via `brcmd.sh` | Arbeitszyklus verstanden |
| 5 | 1:25–2:30 | **Übung mit Agent**: eine Ergänzung (Übung A oder B, Vorlage in §1a) | Ergänzung läuft auf eigenem Gerät |
| 6 | 2:30–2:50 | Zeigen: 3–4 Teilnehmende präsentieren Prompt-Verlauf + Ergebnis; was ging schief, was half | Reflexion Methode |
| 7 | 2:50–3:00 | Abschluss, gPlug zurück ins Heim-WLAN, Links, Feedback | — |

Puffer ist knapp; Block 2 ist der kritische. Alles, was sich vorab erledigen lässt, kommt in die Hausaufgaben-Mail.

## 1a. KI-Didaktik

**Lernziele** (was Teilnehmende nach dem Abend können):

1. Einem Agenten den richtigen **Kontext** geben: Intent, API-Cheat-Sheet, bestehender Code, Gerätegrenzen (RAM, 50-ms-Regel). Verstehen, dass der Agent ohne Kontext plausibel klingende, falsche API erfindet.
2. Eine Aufgabe **klein und prüfbar** formulieren: Erweiterungspunkt nennen, erwartetes Resultat nennen, Testkriterium nennen.
3. Den **Zyklus** schliessen: Code hochladen → `BrRestart` → Konsole lesen → Fehlermeldung wörtlich an den Agenten → nächste Iteration. Den Agenten den Zyklus selbst fahren lassen (`upload.sh`, `brcmd.sh`, `log.sh`), aber Resultat selbst prüfen.
4. **Grenzen** erkennen: wann der Agent rät, wann er Doku braucht, wann der Mensch entscheiden muss (Speicher, Flash-Wear, Datenformat).

**Übungsvorlagen** (je mit Prompt-Vorlage, erwartetem Ergebnis, Prüfschritt):

- **Übung A — Grafik** (festgelegt 19.10.): dritte Kurve Energie mit eigener Skala, keine dritte Achse. Vorlage, Prompts, Prüfschritte und Stolpersteine in `EXERCISES.md`. Probelauf 19.10. (Qwen3.5-122B): 30 min, 14 Uploads, dritte Achse/Checkboxen/doppelte Schleife → Chart-Code refaktoriert (`send_polyline`, `chart_curves()`, Ausgabe byte-identisch); Ziel ≤ 4 Uploads. 3-Tage-Seite bleibt Reserve für Schnelle.
- **Übung B — CSV**: Stunden-Datei + Aufbewahrung zwei Monate. Prüfschritt: Dateimanager zeigt Dateien, `Br`-Konsole kann Tageswechsel simulieren. Lehrt: Testbarkeit einfordern (Agent soll Funktion mit Datum-Parameter bauen).
- **Übung C — Shelly/MQTT** (für Schnelle): Schwellwert-Schaltung. Lehrt: Agent Drittsystem-API geben (Shelly-Doku-Auszug), sonst rät er.

**Demo-Material** (vorbereiten, nicht improvisieren):

- Transkript/Commits der Referenz-App-Entwicklung mit dem Agenten: 3 Momente zeigen — ein guter Prompt, ein Fehlversuch mit Halluzination, die Korrektur durch Kontext.
- Zwei Prompts für dieselbe Aufgabe nebeneinander: „mach eine Grafik“ vs. strukturierter Prompt (Erweiterungspunkt, Datenquelle, Format, Test). Live ausführen, Ergebnis vergleichen.
- Agent-Werkzeuge im Sandbox-Repo, damit der Agent das Gerät selbst bedienen kann:
  - `upload.sh <file>` — Datei auf gPlug laden (`/ufsu`) und `BrRestart`
  - `brcmd.sh "<berry>"` — Berry-Ausdruck auf dem Gerät ausführen (`/cm?cmnd=Br%20...`), Resultat zurück
  - `log.sh` — letzte Konsolenzeilen holen
  - `AGENTS.md` beschreibt die drei Skripte und verbietet dem Agenten Reboot/Reset-Kommandos.

## 2. Hausaufgaben-Mail (≥ 10 Tage vor Workshop)

- [ ] gPlug auf **Tasmota ≥ 15.3.0** aktualisieren (OTA-Link + Screenshot). Prüfen in `Information`-Seite.
- [ ] In der Tasmota-Konsole `Timezone 99` eingeben (Sommerzeit; ab Werk steht `+01:00`). Prüfen: `Time` zeigt die aktuelle Uhrzeit.
- [ ] USB-Treiber installieren (CH340/CP210x, je nach gPlug-Chip) — nur Recovery-Fall.
- [ ] Chrome oder Edge installieren (Tasmota Web Installer braucht WebSerial).
- [ ] Docker Desktop installieren und `./docker-run.sh` (Windows: `.\docker-run.ps1`) einmal starten, baut das Image (Standard, siehe §5) **oder**, falls Docker nicht geht, opencode 2.0 direkt installieren (`curl -fsSL https://opencode.ai/v2/install | bash`). Test-Kommando mitliefern: `opencode --version` (v2.0.x) und eine erste Frage an den Agenten im Workshop-Repo.
- [ ] Workshop-Repo (ZIP oder git clone) in eigenen Ordner entpacken; Infomaniak-API-Key gemäss Anleitung eintragen.
- [ ] Heim-SM-Konfiguration notieren: Ausgabe von `Status 10` als Text mitbringen (für eigenen Zähler-Pfad).
- [ ] Optional: Shelly oder anderes HTTP-schaltbares Gerät mitbringen.
- [ ] Hinweis: gPlug wird am Workshop ins Venue-WLAN umkonfiguriert, Anleitung zurück ins Heim-WLAN liegt bei.

## 2a. Testgerät

Zwei Geräte bei Jürg:

- **Ohne Meter**: `http://192.168.0.201` (LAN, kein WebPassword): Tasmota 15.3.0, ESP32-C3, gPlug-Script 6.9.26 — exakt der Zustand der Teilnehmergeräte am Workshop. Simulator-Pfad, UI, Command, Preisabruf.
- **Am Meter**: `http://gplugk.local` = `192.168.0.130`: Tasmota **15.5.0**, ESP32-C3, gPlugK-Script 6.9.26 (Kamstrup DLMS Push). Realpfad `z.Eo` (live, z.B. 42'872.724 kWh am 18.10.), 3-Tage-Soak-Test der Zählererfassung und CSV. Zweite Tasmota-Version im Test → deckt 15.3.0 und 15.5.0 ab.

Beide Script-Varianten (L+G `gplug_script.txt`, Kamstrup `gplugk_script.txt`) liefern dieselben JSON-Schlüssel unter `z` — der Default-Pfad `["z","Eo"]` gilt gerätetypübergreifend.

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
- [ ] OTA-URL für das gPlug-Build ≥ 15.3.0 und Upgrade-Anleitung (Screenshot `Information`-Seite, `Upgrade`-Seite) für die Hausaufgaben-Mail.
- [x] BKW-API: Folgetags-Serie ab 16:33–17:03 lokal (gemessen So 18.10.), danach nur noch Folgetag abrufbar.
- [ ] BKW-API: Messung an einem Werktag wiederholen (Abrufe 15:00–18:00 lokal, alle 15 min).
- [ ] Venue-WLAN (Glue, Hermann kennt die Infrastruktur): Kapazität ≥ 50 Clients, kein Captive Portal, **keine Client-Isolation** (Notebook muss gPlug erreichen), ausgehend HTTPS 443 frei (`api.bkw.ch`, LLM-Provider). Bestätigung von Hermann einholen; Test vor Ort am Workshop-Tag beim Aufbau.
- [ ] Hermanns Antworten auf offene Fragen in `INTENT.md` §6.
- [ ] Infomaniak-LLM: ein Feature der Referenz-App damit bauen lassen, Qualität bewerten, Fallback-Provider festlegen.
- [ ] opencode.ai: Permission-Konfiguration prüfen (Shell-Kommandos auf `upload.sh`/`brcmd.sh`/`log.sh` begrenzbar? Schreibzugriff nur im Repo?), Infomaniak als OpenAI-kompatibler Provider konfigurierbar? Windows-Install getestet?
- [ ] Aufwand/Offerte (20 h) gegen §4a-Scope abgleichen.

## 4. Deliverables (fertig, getestet, bis Ende Oktober)

| # | Datei | Inhalt | Test |
|---|---|---|---|
| 1 | `app/spot.be` | Referenz-App Kern (F1, F2, F5), Stufe-1-Grafik, Tages-CSV — **v0.2 vorhanden**, Desktop-Harness grün, auf 192.168.0.201 live getestet (18.10.); Chart refaktoriert 19.10. (Harness-HTML identisch) | ≥ 3 Tage auf gplugk (Meter) — offen |
| 2 | Simulator | in `spot.be` integriert (`sim: true`): Zähler-Tageskurve, Backfill des laufenden Tages, Preis-Fallback aus Folgetag | erledigt |
| 3 | `autoexec.be` | `load("spot")`, Kommentar | vorhanden (`app/autoexec.be`), auf .201 installiert 18.10., BrRestart lädt App, 1 UI-Block, Fetch OK |
| 4 | `bkw.json` auf dem Gerät | gecachte API-Antwort, `SpotFetch file` **vorhanden** in `spot.be` | am Workshop-Tag morgens frische Antwort speichern und mit ausliefern |
| 1a | `app/desktop_harness.be` + `persist.be`/`path.be` | spot.be ohne Gerät durchspielen (Tag simulieren, CSV, Commands, HTML) | läuft: `berry desktop_harness.be` |
| 5 | `reference/gplug_script.txt` + `reference/read_sensors_sample.json` | gPlug-Script (SML/DLMS, Descriptor `z`) und `read_sensors()`-Ausgabe — **vorhanden**, von Gerät 192.168.0.201 gezogen (18.10.) | Zähler-Pfad `["z","Eo"]` daraus abgeleitet |
| 6 | `TASMOTA_BERRY_API.md` | Agent-Kontext | Agent baut Übung ohne Halluzination |
| 7 | `AGENTS.md` | Regeln für opencode.ai: Dateien, Upload-Befehl, Tests, „nie `tasmota.web_send` ausserhalb `web_sensor`“ usw. | Trockenlauf mit Agent |
| 8 | `upload.sh`, `brcmd.sh`, `log.sh` (+ `.ps1`) | Agent-Werkzeuge: Upload + `BrRestart`, Berry-Ausdruck via `/cm?cmnd=Br`, Konsole lesen | Agent löst Übung A allein, Mensch prüft nur |
| 9 | `RUNBOOK.md` | Teilnehmer-Schritte mit erwarteter Ausgabe pro Schritt (Screenshots) | von einer unbeteiligten Person durchgespielt |
| 10 | Agent-Setup | Standard: Docker-Image (`Dockerfile`, `docker-run.sh`/`.ps1`, opencode 2.0.32 + berry + git, nur Repo gemountet). Fallback: opencode 2.0 nativ + `opencode.json` (Infomaniak-Provider, Berechtigungen auf Repo + Skripte) — Image vorhanden, auf macOS getestet 19.10. | Install + erste Agent-Antwort auf Mac, Win, Linux < 10 min |
| 11 | `EXERCISES.md` | Übungen A/B/C mit Prompt-Vorlage, Ergebnis, Prüfschritt — **Übung A vorhanden** (19.10.), B/C Entwurf | Übung A nach Refactor erneut mit Infomaniak-LLM durchspielen (Ziel ≤ 4 Uploads), B/C offen |
| 12 | Demo-Transkript | 3 Ausschnitte aus Referenz-App-Entwicklung (guter Prompt, Halluzination, Korrektur) | auf Beamer lesbar |
| 13 | `AGENTS.md`-Ergänzung | Werkzeuge beschreiben, verbotene Kommandos (`Reset`, `Restart`, `Upgrade`), Regel „nach jedem Upload `log.sh` lesen“ | Agent hält sich daran im Trockenlauf |

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
- Beides in der Hausaufgaben-Mail mit Test-Kommando (`opencode --version`, erste Frage an Agent).

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

Massnahmen: `parse_file` liest mit `readbytes`; `upload.sh` prüft nach `BrRestart` den Heap und startet unter 80 kB (`MIN_HEAP`) das Gerät neu; Cheat-Sheet und `AGENTS.md` nennen beide Fallen. Lehrinhalt für Block 4: Agent-Sitzung zeigt, wie 14 Iterationen das Gerät leise aushungern.

## 6. Vor Ort

- [ ] 4 Reserve-gPlugs mit Firmware + Referenz-App (für defekte/alte Geräte).
- [ ] 2 Ersatz-USB-Kabel (Daten, nicht nur Laden), 1 Notebook mit esptool als Flash-Station.
- [ ] WLAN-Zettel pro Tisch, Beamer, Verlängerungskabel.
- [ ] Offline-Kopie aller Dateien auf USB-Stick (falls WLAN-Ausfall).
- [ ] 1 Helfer pro 8 Teilnehmende für Block 2.

## 7. Risiken (Rangfolge)

1. Firmware/Partition passt nicht → Block 2 platzt. Mitigation: §3 Punkt 1, Hausaufgabe, Reserve-Geräte.
2. Venue-WLAN blockiert oder überlastet. Mitigation: Vorab-Test, Offline-JSON, Hotspot-Fallback.
3. Agent-Setup (opencode/Docker) frisst Zeit. Mitigation: Image als Hausaufgabe vorab bauen lassen (Download nicht im Venue-WLAN), Option D als Fallback, Hausaufgabe mit Test-Kommando, Helfer prüfen in Block 1 beim Einlass.
4. Agent halluziniert Tasmota-API. Mitigation: Cheat-Sheet + `AGENTS.md` im Kontext — und als Demo bewusst zeigen, das ist Lehrinhalt.
5. Zu viel Scope live. Mitigation: nur eine Übung, Referenz-App fertig.
6. Infomaniak-LLM zu schwach für Berry → Übung scheitert, Teilnehmende schliessen „KI taugt nicht“. Mitigation: Übungen vorab mit genau diesem Modell durchspielen (Deliverable 11), Fallback-Modell konfiguriert.
7. Agent führt destruktives Kommando auf Gerät aus (`Reset 1`, falsches `Upgrade`). Mitigation: `brcmd.sh` filtert Kommandoliste, `AGENTS.md` verbietet, Reserve-Geräte.
