# Intent: gPlug Berry App „Spot-Einspeisung“ (v0.2)

Zweck dieses Dokuments: verbindliche Beschreibung *was* die Tasmota-Berry-App leisten soll und *welche Randbedingungen* gelten. Es dient als Auftrag für die Implementierung (Mensch oder Coding-Agent, z.B. opencode.ai) und als Grundlage für den DIY-Anlass vom 12. November 2026.

- Quelle: RFC-Mail von Hermann (Feature-Liste v0.2)
- Sprache/Plattform: Berry auf Tasmota (ESP32, gPlug)
  - Sprachreferenz: <https://tasmota.github.io/docs/_media/BERRY_LANGUAGE_REFERENCE.txt>
  - Tasmota-API (webclient, cron, Commands, WebUI, Dateien): `TASMOTA_BERRY_API.md` in diesem Ordner — **beides** muss dem Coding-Agent als Kontext vorliegen, die Sprachreferenz allein enthält keine Tasmota-Funktionen.
- Lieferziel App: Ende Oktober 2026
- Tasmota-Version: **mindestens 15.3.0** (festgelegt 18.10.). Referenz-App wird auf dieser Version getestet; Versionsnummer steht als Kommentar in `autoexec.be`.

## 0. Workshop-Rahmen (prov.)

- Do 12.11.2026, 17:00, max. 20 Plätze + 4 Reserve. Abendveranstaltung → ca. 3 h netto.
- **BYOD**: Teilnehmende bringen eigenen gPlug (vorhanden oder via Webshop beschafft) und eigenes Notebook mit USB mit. Kein Pre-Flashing durch Veranstalter möglich.
- Folgen für die App:
  - Geräte kommen mit unterschiedlicher Firmware-**Version**, Heim-WLAN und realer SM-Konfiguration → Mindest-Firmware-Version, Upgrade **vor Ort** per Datei-Upload (keine Vorbereitung durch Teilnehmende, entschieden 22.10.), SM-Pfad konfigurierbar, Simulator für den Abend. Berry, UFS und SML sind auf allen Webshop-gPlugs aktiv (geklärt 18.10.).
  - Kein Smart Meter vor Ort → Simulator (`sim: true` in `spot.be`) ist Pflicht, nicht Option.
  - Vor Ort entwickeln Teilnehmende **eine kleine Ergänzung** auf einer fertigen Referenz-App (siehe §4a), nicht die App selbst.
- **Hauptthema des Workshops ist der Umgang mit KI** (Coding-Agent), die Berry-App ist das Übungsobjekt. Folgen für die App: Code muss für einen Agenten gut lesbar und erweiterbar sein (klare Modulgrenzen, Kommentare, keine Tricks), und die Referenz-App wird selbst **mit dem Agenten gebaut** — Prompts und Verlauf werden als Lehrmaterial aufbewahrt (Ablage: interne Kursleitungs-Notizen).
- Optionale Teilnehmer-Erweiterungen laut Sketch: Last via Shelly schalten, Integration Drittsysteme → beides über F5 (Command) bzw. `webclient` zum Shelly machbar (§3 F6).
- Zwei Scope-Varianten existieren (kurzer Sketch: stündlich, 1 Tag; RFC v0.2: ¼-h, 3 Tage). **Dieses Dokument folgt v0.2**. Grafik der Referenz-App: **3 Tage mit Stundenwerten** gemäss Zielbild `docs/zielbild.jpg` (entschieden 22.10., ersetzt „zuerst 1 Tag“ vom 18.10.).

## 1. Ziel

Die App macht die dynamische Einspeisevergütung der BKW auf dem gPlug sichtbar und nutzbar:

1. Spotmarkt-Einspeisepreise der BKW täglich laden und speichersparsam im RAM halten.
2. Die ins Netz eingespeiste Energie pro Viertelstunde aus dem Smart Meter (SM) erfassen.
3. Preis, Energie und Vergütung der letzten 3 Tage als SVG-Grafik im gPlug WebUI zeigen.
4. Tagessummen monatlich als CSV im Filesystem ablegen.
5. Die Preise der nächsten 10 Stunden per Tasmota-Command anbieten, damit andere Apps/Geräte Lasten lokal optimieren können (Command ist auch via HTTP und MQTT erreichbar).

Die App ist als **Vorlage** gedacht: eine zweite App für dynamische *Bezugs*tarife (Groupe-E Vario, EKZ dynamisch, …) soll mit gleichem Aufbau nur durch Austausch des Tarif-Adapters entstehen.

## 2. Datenquelle BKW

```
GET https://api.bkw.ch/api/dyntariffs/v1/Tariffs/energyreturn
accept: application/json
```

Antwort (geprüft am 2026-10-18): ca. **21 kB**, davon < 3 % Nutzdaten.

```json
{
  "publication_timestamp": "2026-10-18T11:10:00Z",
  "prices": [
    { "start_timestamp": "2026-10-17T22:00:00Z",
      "end_timestamp":   "2026-10-17T22:15:00Z",
      "feed_in": [ { "unit": "CHF_kWh", "value": 0.194 } ] },
    ...
  ]
}
```

- 96 Einträge à 15 min; aktuell haben die 4 Werte einer Stunde denselben Preis.
- Zeitstempel sind **UTC**. „22–22 Uhr“ entspricht dem lokalen Kalendertag (00:00–24:00 CEST; im Winter 23:00Z–23:00Z).
- `publication_timestamp` wird alle 5 min hochgezählt (geprüft 11:10Z und 11:15Z am 18.10.) und sagt **nichts** darüber aus, wann die Serie des Folgetags erscheint. Massgebend ist allein `prices[0].start_timestamp`.
- Ein erfolgreicher Abruf pro Serie genügt.
- Keine Angaben zu Rate-Limits oder Auth; Abruffrequenz trotzdem auf wenige Versuche pro Tag begrenzen.
- Aus der Swagger-Spezifikation (<https://api.bkw.ch/api/dyntariffs/swagger/v1/swagger.json>, gelesen 18.10.):
  - Endpoint akzeptiert **keine Query-Parameter** (400 bei jedem Parameter). Der Folgetag kann nicht angefordert werden; die Serie wechselt serverseitig. Gemessen am So 18.10.: Wechsel zwischen **16:33 und 17:03 lokal** (14:33–15:03 UTC). Danach liefert der Endpoint **nur noch den Folgetag** — der laufende Tag ist nicht mehr abrufbar. Eine Messung an einem Werktag steht aus.
  - „Fehlende Werte werden weggelassen“ → die Antwort kann **weniger als 96 Einträge** enthalten. Jeder Eintrag muss über seinen eigenen `start_timestamp` dem Slot zugeordnet werden; Zählen der Einträge ist nicht zulässig. Laut Hermann (21.10.) liefert die BKW in der Praxis **alles oder nichts**; die Zuordnung per Zeitstempel bleibt als Absicherung.
  - Werte basieren auf ENTSO-E Day-Ahead; Schema folgt dem **VSE-Standard für dynamische Tarife**. Andere EVU mit dynamischem Tarif nutzen voraussichtlich dasselbe Format → Adapter-Design (§4) bestätigt.
  - `/Tariffs` und `/Tariffs/energyreturn` liefern dasselbe.

## 3. Funktionale Anforderungen

### F1 – Preise abrufen und halten

- Abruf per `webclient` (HTTPS), zeitgesteuert per `tasmota.add_cron`:
  - Nach Boot, sobald Netz **und** Uhrzeit gültig sind (`tasmota.when_network_up`, Rule `Time#Initialized`).
  - **Stündlicher Cron (hh:05)**, Abruf nur wenn nötig: aktueller Preis fehlt, Preis in 6 h fehlt, oder ab 17 Uhr der Preis für morgen 12:00 fehlt. Damit ergeben sich die Abrufe 17:05, 18:05, … bis der Folgetag da ist, plus Nachholen nach Boot — ohne feste Uhrzeitenliste. (Umgesetzt in `app/spot.be`; Messung 18.10.: Wechsel 16:33–17:03 lokal.)
  - **Zeitzone**: jeder Preis wird einzeln über `UTC + tasmota.rtc("timezone")` auf lokalen Tag/Slot abgebildet. Die Serie beginnt daher nicht zwingend um Slot 0 (bei Geräten mit fester Zone +01:00 wie dem Testgerät beginnt sie um 23:00 des Vortags). Zähler und Preise verwenden dieselbe Gerätezeit → Produkt bleibt konsistent, auch wenn die Zone falsch konfiguriert ist. **Voraussetzung: `Timezone 99`** (Regeln `TimeDst`/`TimeStd`, Tasmota-Standard = CET/CEST); ab Werk steht der gPlug auf festem `+01:00` und geht im Sommer 1 h nach. Die App prüft beim Laden und stündlich `tasmota.cmd("Timezone")`: bei ≠ 99 rote Warnzeile in der WebUI, `"Warn"` in `SpotStatus`, Log-Eintrag. Die Uhr selbst kommt per NTP, nur die Zonenregel muss stimmen.
  - Da der Endpoint nach dem Wechsel nur den Folgetag liefert, hat ein Gerät, das nach ~17:00 erstmals abruft, für den laufenden Tag keine Preise. **Workshop-Fallback** (nur `sim=true`): fehlende heutige Preise werden aus dem Folgetag kopiert und in der UI als „(Sim)“ gekennzeichnet. Zusätzlich `SpotFetch file` liest `/bkw.json` aus dem Dateisystem (kein Internet nötig).
- Bei HTTP-Fehler (Code ≠ 200 oder negativ) oder Parse-Fehler: max. 3 Wiederholungen im Abstand von 10 min, dann bis zum nächsten Cron-Termin warten. Jeder Fehler wird geloggt.
- `webclient.get_string()` verwirft Antworten **> 32 KB** und schneidet bei fragmentiertem Heap **still ab** (gemessen 19.10., 65 kB frei: 8.7 von 21 kB, Chart endete um 09:45). Die App lädt deshalb mit `webclient.write_file("/spot_dl.json")` ins Flash und parst die Datei in 2-kB-Blöcken (`parse_file`), RAM-Bedarf unabhängig von der Antwortgrösse. Flash-Schreiben: ein Download pro Abruf (wenige pro Tag). Blockweise lesen mit `f.readbytes(n)`, nicht `f.read(n)` (leckt ~1.5 × n Byte pro Durchlauf, Tasmota 15.3).
- Heap-Haushalt gemessen (19.10., Tasmota 15.3.0, ESP32-C3): nach Neustart mit App ~130 kB frei. Dauerhafte Kosten: `BrRestart`-Zyklus ~1 kB (ausserhalb Berry, nur `Restart 1` gibt es zurück), erster `load("spot")` ohne Restart ~20 kB (zweite Kopie der Klassen, danach stabil), Abruf + Parse 0 kB, lesbarer Chart-Code (F3: kleine Methoden, Konstanten, Kurventabelle) ~5 kB Berry-Heap mehr als die kompakte Fassung (bewusst, 19.10.). Unter ~70 kB liefert `get_string()` abgeschnittene Antworten, unter ~50 kB startet das Gerät bei 21-kB-Antworten neu (`MEMORY ALLOCATION FAILED`). `upload.sh` startet das Gerät unter 100 kB automatisch neu (bis 19.10. 80 kB: eine Übung-A-Sitzung trieb den Heap danach mit Abrufen und Verbindungen bis 58 kB).
- Pro Serie nur speichern:
  - Startzeitpunkt der Serie (erster `start_timestamp`, als Epoch-Sekunden)
  - die Preise als **2-Byte signed int** in der Einheit 1/10'000 CHF/kWh (0.194 → 1940; Wertebereich ±3.27 CHF/kWh, negative Preise möglich)
- Ringpuffer der **letzten 3 Serien** (≈ 3 × 96 × 2 Byte ≈ 0.6 kB) in einem `bytes`-Objekt fester Grösse.
- Neue Serie nur übernehmen, wenn ihr Startzeitpunkt neuer als die jüngste gespeicherte ist (Abruf idempotent).
- **Parse-Strategie** (kein `json.load` auf der Gesamtantwort — die Map wäre ein Vielfaches der 21 kB):
  1. `s = wc.get_string()` (21 kB String).
  2. Erstes `"start_timestamp":"` suchen (`string.find`), die 19 Zeichen danach mit `tasmota.strptime(.., "%Y-%m-%dT%H:%M:%S")` zu Epoch wandeln (UTC; auf dem Gerät prüfen, ob `strptime` den Wert als UTC oder lokal interpretiert, ggf. `tasmota.rtc("timezone")` korrigieren). Dieser Wert ist der Serienstart.
  3. Puffer der neuen Serie mit „ungültig“ (`0x7FFF`) füllen. Schleife über alle Einträge: `"start_timestamp":"` → Epoch → Slot = `(epoch − Serienstart) / 900`; dann `"value":` → Zahl bis zum nächsten `}` → `real()` × 10000, runden → 2-Byte-Int an Slot. Einträge dürfen fehlen (Spec); Slot ausserhalb 0..99 → Eintrag ignorieren. Serie verwerfen, wenn weniger als 48 gültige Slots.
  4. `s = nil`, `wc = nil`, `tasmota.gc()`. Der Download bleibt nur so lange im Speicher wie die Schleife läuft.
  - Fallback bei Speichermangel oder > 32 KB: `wc.write_file("/bkw.json")`, Datei mit `readline()` zeilenweise durchsuchen, danach `path.remove`.
- **Heap-Logging** (Abnahmekriterium): vor Beginn des Abrufs und nach `tasmota.gc()` je eine Logzeile `log("SPOT: heap_free=" + str(tasmota.memory("heap_free")) + " kB")`. Differenz muss ≤ 2 kB sein.

### F2 – Einspeisezähler erfassen

- Alle 15 min (Cron `0 */15 * * * *`) den Einspeisezähler (kWh) des SM aus `tasmota.read_sensors()` lesen (liefert einen JSON-**String**, der mit `json.load` geparst wird; Ergebnis ist klein).
- Der JSON-Pfad zum Zähler ist **konfigurierbar** als Liste von Schlüsseln. **Default `["z", "Eo"]`** (geprüft 18.10. auf gPlugM/L+G mit Tasmota 15.3.0 und gPlugK/Kamstrup mit 15.5.0, Script 6.9.26 in beiden Varianten): die gPlug-Scripts (gplug.ch, nicht im Repo; Tasmota Script, SML-Treiber `sensor53`, Descriptor `z`) liefern den Export-Zähler OBIS 2.8.0 als `z.Eo` in kWh mit 3 Dezimalen; `read_sensors()` ergibt `{"Time":"…","z":{"Eo":…}}` (ca. 0.5 kB). Beispielausgabe liegt in `reference/`.
- Zähler werden vom Meter nur **1× pro Minute** aktualisiert; ein Abruf zur vollen Viertelstunde ist bis 60 s alt. Akzeptiert.
- Die JSON enthält **kein Frische-Kennzeichen**: ein abgehängter Meter liefert weiter den letzten Stand (bzw. 0.0 nach Boot). Die App markiert einen Slot als ungültig, wenn `Eo` fehlt oder nach dem Boot noch 0.0 ist; ein stehender Zähler bei angeschlossenem Meter ist nicht von „keine Einspeisung“ unterscheidbar und wird als 0 gewertet.
- Für Entwicklung und Workshop ohne Smart Meter: **Simulator** (in `spot.be`, Flag `sim`), der eine Einspeiseleistung als Tageskurve rechnet und daraus den Fake-Zähler hochzählt. Anforderungen (Meeting 21./22.10.):
  - Gibt wie der echte Meter **Leistung `Po` (kW)** und **Zählerstand `Eo` (kWh)** aus. Die App rechnet weiterhin mit `Eo`.
  - **Zeitraffer**: Takt konfigurierbar **5, 15 oder 60 min** (Echtzeit); jeder Takt rückt die Simulation um eine ¼ h vor, damit sich die Grafik am Workshop-Abend sichtbar füllt. Takt 15 min = Echtzeit. Vorschlag: „jetzt“-Marke und Slot folgen der Simulationszeit; Zusammenspiel mit echter Uhr und Preisabruf beim Bauen klären.
  - **Vortage auffüllen**: die 2 Tage vor heute mit Fake-Preisen (inkl. negativer Preise) und Fake-Energie, in der UI als „(Sim)“ markiert, damit die 3-Tage-Grafik vom Start weg voll ist.
  - **Negativpreis heute**: im Sim-Modus erhält auch der heutige Tag ein Mittagstief mit negativen Preisen (z.B. 12–15 Uhr), auch wenn die BKW-Serie keine hat; als „(Sim)“ markiert. Grund: Testfall für Schritt 2 der Übung, solange das Chart nur einen Tag zeigt (entschieden 22.10.).
- Den letzten Zählerstand im RAM halten.
- Differenz zur vorherigen Viertelstunde, gerundet auf **0.01 kWh**, als 2-Byte int (Einheit 0.01 kWh, max. 327 kWh pro Slot) speichern. Abweichung von der RFC-Mail (0.1 kWh): gleicher Speicherbedarf, aber Anlagen unter 400 W liefern sonst nur 0/0.1-Sprünge in der Grafik.
- Gerundet wird auf Basis der Zählerstände (Differenz der gerundeten Stände), damit sich Rundungsfehler nicht aufsummieren.
- Ringpuffer der letzten **3 × 96** Differenzwerte, gleich ausgerichtet wie die Preisserien (Slot = Viertelstunde seit Serienbeginn).
- Fehlender Messwert (Boot, SM nicht lesbar): Slot als „ungültig“ markieren (z.B. `0x7FFF`), nicht als 0.

### F3 – SVG-Grafik im gPlug WebUI

- **Referenz-App (Zielbild `docs/zielbild.jpg`, entschieden 22.10.):** 3 Tage mit **72 Stundenwerten** als inline-SVG, eingebunden über einen Berry-Driver (`tasmota.add_driver`, `web_sensor`), zwei Diagramme untereinander mit gemeinsamer Zeitachse (Tagesnamen, 00/12-Marken):
  - Oben: **Einspeisung** (kWh/h) als Balken, grün; orange bei Preis < 0. **Spotpreis** (Rp./kWh) als Linie mit eigener Skala rechts. Bereich unter 0 Rp. schattiert („negativer Preis“). Marke „jetzt“.
  - Unten: **Vergütung** (CHF/h) als Balken, gelb positiv, rot negativ („Einspeisung kostet“). Summe **Σ CHF** über die 3 Tage.
  - Abweichung vom bisherigen Stand (1 Tag, ¼-h-Werte, ein Diagramm): die Referenz-App ist der **Endstand der Übungen**, nicht der Ausgangspunkt (22.10.).
- **Starter (an Teilnehmende im Docker-Container):** Grafik zeigt **nur die Preislinie**, 1 Tag mit 96 ¼-h-Werten, Achse Rp./kWh rechts, Nulllinie, „jetzt“-Marke, Legende. Daten (F1, F2 inkl. Simulator und Vortage, F4 Tageszeile, F5) und Textzeilen (Spotpreis jetzt, Einspeisung heute, Vergütung heute) sind vollständig. Helfer `chart_curves()`, `send_polyline`, `value_range`, `nice_range`, `y_scale`, `send_data_attr` vorhanden; Kommentare `# ERWEITERUNGSPUNKT Schritt 1`…`4`. Cursor-Script in allen Stufen identisch (zeigt vorhandene `data-p/e/v`).
- **Vom Starter zur Referenz-App in 4 Schritten** (Details, Vorgaben und Prompts in `EXERCISES.md`):
  1. Energie-Balken (grün) mit kWh-Achse links.
  2. Negativpreis: Balken orange bei Preis < 0, Bereich unter 0 schattiert.
  3. 3 Tage mit 72 Stundenwerten, Tagesnamen, 00/12-Marken.
  4. Zweites Chart Vergütung CHF/h (gelb/rot) mit Σ.
  - Schritte 1–2 Pflicht, 3–4 für Schnelle. Nach jedem Schritt ein geprüfter Checkpoint `app/steps/spot_N.be` (Desktop-Harness grün, auf Testgerät Heap > 100 kB); `spot_4.be` = Referenz-App.
- Farben (Zielbild, gelten schon im Starter; Preislinie wechselt von bisher orange auf cyan, damit orange für Einspeisung bei Preis < 0 frei ist, entschieden 22.10.): Preis cyan, Einspeisung grün, Einspeisung bei Preis < 0 orange, Vergütung gelb, Kosten rot, „jetzt“ grau.
- Stundenwert = Mittel (Preis) bzw. Summe (Energie, Vergütung) der 4 Viertelstunden.
- SVG als String stückweise erzeugen und senden (`tasmota.web_send`), kein grosser Gesamtstring im RAM.
- Ungültige Slots erzeugen Lücken, keine Nullwerte.

### F4 – CSV-Ablage

- Am Tagesende (lokale Mitternacht, nach dem letzten 15-min-Slot) **eine Zeile** an die Monatsdatei anhängen, z.B. `/spot_2026-10.csv`:
  `Datum;Energie_kWh;Verguetung_CHF` — Trennzeichen `;`, Dezimalpunkt `.`, Datum `YYYY-MM-DD`, Kopfzeile beim Anlegen der Datei.
- Maximal **2 Monatsdateien** (aktueller Monat und Vormonat): ältere beim Monatswechsel löschen (`path.listdir`, `path.remove`).
- Optional (Setting): Stundenwerte des Tages in eine zusätzliche Datei, z.B. `/spot_h_2026-10.csv`, mit derselben Aufbewahrungsregel.
- Dateien zeilenweise anhängen (`open(..., "a")`), nie ganze Datei im RAM aufbauen.

### F5 – Tasmota-Command

- Command registrieren via `tasmota.add_cmd`, Name z.B. `SpotPrices`.
- Antwort via `tasmota.resp_cmnd` als JSON mit den Preisen der **nächsten 10 Stunden** ab der laufenden Stunde. Ohne Parameter stündlich (10 Werte), mit Parameter `15` viertelstündlich (40 Werte). Feld `Res` (Minuten) sagt dem Empfänger, was er bekommt:

  ```json
  SpotPrices    → {"SpotPrices":{"Start":"2026-10-18T14:00:00","Res":60,"Unit":"CHF/kWh","Prices":[0.194,0.190,...]}}
  SpotPrices 15 → {"SpotPrices":{"Start":"2026-10-18T14:00:00","Res":15,"Unit":"CHF/kWh","Prices":[0.194,0.194,0.194,0.194,0.190,...]}}
  ```

- Stundenwert = Mittel der 4 Viertelstunden (heute identisch, da BKW pro Stunde einen Preis liefert).
- Sind weniger als 10 Stunden verfügbar (Folgetag noch nicht publiziert), nur die vorhandenen liefern.
- Keine Serie im RAM oder Uhrzeit ungültig: `{"SpotPrices":{"Error":"no data"}}` statt Exception.
- Erreichbar über Konsole, HTTP (`/cm?cmnd=SpotPrices`) und MQTT.

### F6 – Optionale Teilnehmer-Erweiterungen (nicht Teil der Referenz-App)

Beispiele, die auf F5 bzw. `webclient` aufsetzen und in ≤ 30 min mit Agent-Hilfe machbar sind:

- **Shelly schalten**: Cron stündlich, `SpotPrices`-Daten lesen, bei Preis unter/über Schwelle `webclient.GET("http://<shelly-ip>/relay/0?turn=on")`.
- **MQTT-Publish** der Tagessumme (`mqtt.publish`) für ein Drittsystem.
- **Tele-JSON**: Preis und Tagessumme via `json_append` in `tele/SENSOR` einblenden.

## 4. Nicht-funktionale Anforderungen

- **RAM**: Dauerbedarf der Nutzdaten ≈ 1.2 kB (2 × 0.6 kB + Zeitstempel/Zustand). Kein dauerhaft gehaltener JSON-String oder Map.
- **Robustheit**: Netzwerk-, Parse- und Sensorfehler mit `try/except` abfangen und loggen (`log(...)`). Die App darf Tasmota nie blockieren oder abstürzen lassen.
- **Zeit**: Erst arbeiten, wenn die Uhrzeit gültig ist (NTP synchronisiert).
- **Sommer-/Winterzeit**: Tage mit 23 h bzw. 25 h haben 92 bzw. 100 Viertelstunden. Ringpuffer-Slots daher für **100 Werte pro Serie** auslegen oder Länge pro Serie mitführen.
- **Flash**: wenige Schreibzugriffe (eine Zeile pro Tag, optional 24 Zeilen pro Tag).
- **Persistenz über Reboot**: laut Hermann (21.10.) **nicht notwendig**. Ringpuffer bleiben flüchtig; nach Reboot ist die Grafik bis zum nächsten Preisabruf leer. Die App hält trotzdem den letzten Zählerstand via `persist` (nur bei Tageswechsel und `save_before_restart`), damit die erste ¼ h nach Neustart nicht fehlt; darf entfallen. Begründung: Flash-Schonung, einfacher Code.
- **Firmware**: Mindestversion Tasmota **15.3.0**. App prüft beim Start `tasmota.version() < 0x0F030000` und loggt eine Warnung, wenn älter (kein Abbruch).
- **Erweiterbarkeit**: Tarifabruf in eigener Klasse/Funktion kapseln (Adapter), damit ein Bezugs-Tarif (Groupe-E, EKZ) ohne Änderung von Speicher, Grafik, CSV und Command ergänzt werden kann.
- **Lesbarkeit**: Code für Workshop-Teilnehmende nachvollziehbar (eine Datei bzw. wenige Klassen, kommentiert).

## 4a. Umsetzungsreihenfolge

Budget (ca. 20 h) reicht nicht für alle fünf Features plus Workshop-Material in gleicher Tiefe. Reihenfolge:

1. **Kern (Referenz-App, fertig vor dem Workshop):** F1 Preise, F2 Zähler + Simulator, F5 Command. Damit ist die App als Datenlieferant nutzbar und testbar.
2. **F3 SVG-Grafik:** zuerst Referenz-App nach Zielbild (3 Tage, zwei Diagramme) inkl. Simulator-Zeitraffer und Vortage (F2) bauen, dann daraus rückwärts die Checkpoints `spot_3` … `spot_1` und den Starter (nur Preislinie) ableiten. Generator `tools/make_steps.py`: Referenz `spot_4.be` ändern, `tools/make_steps.py --write`, alle Stände mit dem Harness prüfen. Die 4 Schritte dazwischen sind die Teilnehmer-Übung (siehe F3, `EXERCISES.md`; ersetzt Übung A, 22.10.).
3. **F4 CSV:** Tageszeile in der Referenz-App und im Starter; Stundenwerte und Aufbewahrungsregel als Bonus-Übung.

Die Übungen sind so gewählt, dass sie den Datenfluss nicht verändern (nur Darstellung und Ablage) und bei Fehlern den Kern nicht beschädigen. Jede Übung wird **mit dem Coding-Agenten** gelöst; geübt wird der Arbeitszyklus Kontext geben → Aufgabe formulieren → Code auf Gerät laden → Konsole prüfen → Fehler an den Agenten zurückgeben. Der Code der Referenz-App ist daher so strukturiert, dass der Agent die Erweiterungspunkte (`web_sensor`, CSV-Funktion, Command) ohne Lesen des ganzen Files findet: eine Klasse pro Zuständigkeit, Kommentarblock `# ERWEITERUNGSPUNKT:` an den vorgesehenen Stellen. Der Chart-Code ist so gebaut (Kurventabelle `chart_curves()`, Helfer `send_polyline`/`value_range`/`y_scale`), dass eine neue Kurve drei Stellen berührt (refaktoriert 19.10., Ausgabe byte-identisch). Für die 4 Schritte heisst das: Schritt 1–2 fügen an, Schritt 3 baut die Helfer um (Bereich als Parameter), Schritt 4 verwendet sie wieder.

## 5. Abgrenzung (nicht Teil der App)

- Laststeuerung selbst (übernehmen andere Apps/Geräte via Command F5).
- Persistenz der RAM-Ringpuffer über einen Reboot hinaus (siehe offene Fragen).
- Workshop-Infrastruktur: Docker-Sandbox mit opencode.ai, Anbindung Infomaniak-API bzw. gPlug-API, Aufwand/Offerte. Wird separat beantwortet.

## 6. Offene Fragen

1. **„144 Werte“**: *Entschieden (22.10., ersetzt 18.10.):* Referenz-App zeigt **3 Tage mit 72 Stundenwerten** gemäss `docs/zielbild.jpg` (siehe F3).
2. **Abrufzeitpunkt**: *Gemessen (So 18.10.):* Wechsel auf den Folgetag zwischen 16:33 und 17:03 lokal; danach nur noch Folgetag abrufbar. Cron-Zeiten in F1 entsprechend gesetzt. F5 kann ab ~17:00 die volle 10-h-Vorschau liefern. Offen: Bestätigung an einem Werktag (Messung wiederholen).
3. **Reboot**: *Geklärt (21.10.):* keine Persistenz notwendig, Grafik nach Reboot leer bis zum nächsten Abruf (siehe §4).
7. **Firmware**: *Geklärt (18.10.):* gPlugs aus dem Webshop gplug.ch haben Berry, UFS und SML aktiviert. Mindestversion **15.3.0**; ältere Geräte werden vor Ort per Datei-Upload aktualisiert (22.10.).
8. **Preisquelle**: *Entschieden (18.10.):* BKW-Vergütung via `energyreturn`-Endpoint reicht. Kein Proxy, kein roher Spotpreis. (ENTSO-E direkt wäre auf dem ESP32 ohnehin nicht praktikabel: Token, XML, > 400 kB.)
9. **Lückenhafte Serien**: *Geklärt (21.10.):* BKW liefert alles oder nichts. Slot-leer-Logik bleibt als Absicherung, kein Auffüllen mit Vorstundenwert.
10. **Simulator**: *Entschieden (22.10.):* Zeitraffer 5/15/60 min, zusätzlich `Po` (kW), Vortage mit Fake-Daten auffüllen (siehe F2).
11. **Vorbereitung Teilnehmende**: *Entschieden (22.10.):* keine Vorab-Mail; Firmware-Upgrade, `Timezone 99` und Agent-Setup vor Ort (Ablauf: `RUNBOOK.md`).
4. **„Kosten“**: *Geklärt (18.10.):* Es gibt eine Grösse, `Vergütung = Preis × Einspeisung` pro Slot. Negativer Preis → negativer Wert = Kosten. Bezug wird nicht erfasst. Folgen: Grafik zeigt Balken unter null, CSV-Tagessumme kann negativ sein.
5. **Auflösung**: *Entschieden (18.10.):* 0.01 kWh pro Viertelstunde (siehe F2). Tagessumme ist bei beiden Auflösungen auf ±1 Einheit genau, da auf Zählerständen gerundet wird; der Unterschied liegt nur in der Darstellung pro Slot.
6. **Command-Format**: *Entschieden (18.10.):* stündlich als Default, `SpotPrices 15` liefert Viertelstundenwerte, Feld `Res` kennzeichnet die Auflösung (siehe F5).

## 7. Abnahmekriterien

- Nach Boot und gültiger Zeit liegt innert 1 h eine Preisserie im RAM. Freier Heap nach Abruf ≈ Heap vor Abruf (±2 kB).
- Nach 15 min erscheint der erste Energie-Slot. Ungültige Slots werden als Lücke angezeigt.
- WebUI zeigt die SVG mit 3 Kurven über 72 Stunden. Rendering ohne Heap-Einbruch > 5 kB.
- Nach Mitternacht existiert die Zeile des Vortags in der Monats-CSV. Beim Monatswechsel bleiben max. 2 Dateien.
- `SpotPrices` liefert gültiges JSON über Konsole, HTTP und MQTT.
- Kein Absturz bei: API nicht erreichbar, ungültiges JSON, SM nicht lesbar, DST-Wechsel.

## 8. Abkürzungen und Begriffe

| Begriff | Bedeutung |
|---|---|
| API | Application Programming Interface; hier die HTTP-Schnittstelle der BKW |
| Berry | Skriptsprache, die in Tasmota auf ESP32 eingebettet ist |
| BKW | BKW Energie AG, Berner Energieversorger; Betreiberin der Tarif-API |
| BYOD | Bring Your Own Device; Teilnehmende bringen eigenes Gerät und Notebook |
| CEST / CET | Mitteleuropäische Sommerzeit (UTC+2) / Winterzeit (UTC+1) |
| CHF | Schweizer Franken |
| Coding-Agent | KI-Werkzeug, das Code schreibt und ausführt (hier opencode.ai) |
| Cron | Zeitplaner mit Minuten/Stunden-Muster; in Tasmota `tasmota.add_cron` |
| CSV | Comma-Separated Values; Textdatei mit einer Datenzeile pro Zeile, hier mit `;` getrennt |
| Day-Ahead | Strombörsen-Auktion am Vortag für jede Stunde/Viertelstunde des Folgetags |
| DIY | Do It Yourself |
| DST | Daylight Saving Time; Umstellung Sommer-/Winterzeit |
| EKZ | Elektrizitätswerke des Kantons Zürich |
| ENTSO-E | European Network of Transmission System Operators for Electricity; publiziert Day-Ahead-Preise |
| Epoch | Sekunden seit 1.1.1970 UTC; Zeitformat von `tasmota.rtc()` |
| ESP32 | Mikrocontroller im gPlug |
| EVU | Elektrizitätsversorgungsunternehmen (Energieversorger) |
| Flash | Nichtflüchtiger Speicher des ESP32; Dateisystem und Firmware; begrenzte Schreibzyklen |
| gPlug | Tasmota-basiertes Gerät von gPlug.ch mit Smart-Meter-Anbindung |
| Heap | Dynamischer Arbeitsspeicher; freier Heap = verfügbares RAM zur Laufzeit |
| HTTP / HTTPS | Webprotokoll, unverschlüsselt / verschlüsselt |
| JSON | JavaScript Object Notation; Textformat der API-Antworten |
| KI | Künstliche Intelligenz |
| MQTT | Nachrichtenprotokoll für IoT; Tasmota publiziert und empfängt darüber Commands |
| NTP | Network Time Protocol; liefert dem gPlug die Uhrzeit |
| OTA | Over The Air; Firmware-Update über WLAN |
| Persist | Tasmota-Berry-Modul, das Werte in `_persist.json` über Reboots hält |
| RAM | Arbeitsspeicher; flüchtig, auf dem ESP32 ca. 100–200 kB frei |
| RFC | Request for Comments; hier: Hermanns Vorschlag zur Diskussion |
| Ringpuffer | Fester Speicherbereich, in dem der älteste Eintrag überschrieben wird |
| Shelly | WLAN-Schaltsteckdose/Relais mit HTTP-API |
| Slot | Eine Viertelstunde im Ringpuffer (Index 0–99 pro Tag) |
| SM | Smart Meter; Stromzähler mit Datenschnittstelle |
| SML | Smart Message Language; Protokoll zum Auslesen von Smart Metern, in Tasmota als SML-Treiber |
| Spotmarkt / Spot | Kurzfristiger Strommarkt (Day-Ahead, Intraday) |
| SVG | Scalable Vector Graphics; Vektorgrafik-Format im Browser |
| Swagger | Maschinenlesbare API-Beschreibung (OpenAPI) |
| Tasmota | Open-Source-Firmware für ESP-Geräte |
| Tasmota-Command | Textbefehl, den Tasmota über Konsole, HTTP (`/cm?cmnd=`) oder MQTT annimmt |
| UFS | Universal File System; Dateisystem-Unterstützung in Tasmota |
| USB | Universal Serial Bus; hier zum Flashen/Konsole |
| UTC | Koordinierte Weltzeit |
| VSE | Verband Schweizerischer Elektrizitätsunternehmen |
| WebUI | Weboberfläche des gPlug im Browser |
| XML | Extensible Markup Language; Format der ENTSO-E-API |

Begriffe des Workshops (opencode, `plan`/`build`, Starter, Checkpoint, …): siehe `LEGENDE.md`.
