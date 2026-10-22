# Meeting Notizen

## Klärung

Vorbereitung: Es kann nicht erwartet werden, dass die Teilnehmer vor dem Kurs Vorbereitungsarbeiten ausführen. Die Kursvoraussetzungen sind lediglich:

- Eigenen gPlug mitbringen
- Ein Notebook mit USB Port & Kabel mitbringen
- Software: Docker, Texteditor oder eine beliebige Entwicklungsumgebung.
- Optional: Seinen eigenen Claude-Code Zugang mitnehmen

zu 1. BKW-API

- Es gibt keine fehlende Werte der API. Entweder alles oder nichts!

zu 2. Speicher und Parsing

- Was bedeutet genau "Die 21 kB JSON werden nicht als Map geladen (das wäre ein Vielfaches an RAM)"? Vielfaches vom RAM?

zu 3. Scope und Reihenfolge

- Simulator:
  - Takt konfigurierbar. 5min, 15min, 60min
  - Der Smartmeter gibt Stromwerte in kW aus.

## Offene Fragean

- Hauptfokus: ok

- Reboot: keine Persistenz notwendig. Die Grafik ist nach Neustart bis zum nächsten Preisabruf leer.

- Fehlende Preise: Slot leer lassen (Vorschlag) oder Vorstundenwert übernehmen?

- WLAN bei Glue: vorhanden

## Antworten auf Fragen aus dem Meeting

**„Vielfaches an RAM“ (zu 2.)** – Gemeint ist ein Vielfaches *der 21 kB*, nicht des Gesamt-RAM. Mit
`json.load` wird jeder der 96 Einträge zu einer Map mit Strings, einer Liste und einer weiteren Map;
jedes Berry-Objekt hat Verwaltungsaufwand. Geschätzt ein Mehrfaches der 21 kB, zusätzlich zum
21-kB-String, der während des Parsens auch im Speicher liegt. Bei ~120 kB freiem Heap reicht das
nicht (unter ~50 kB startet das Gerät neu, gemessen 19.10.). Darum durchsucht die App den Text direkt
und speichert nur 2 Byte pro Preis. Formulierung im Intent wird präzisiert: „ein Mehrfaches der 21 kB“.

**Fehlende Preise (offene Frage 3)** – Durch „alles oder nichts“ (zu 1.) erledigt. Die Grafik füllt
keine Lücken auf. Die bestehende Prüfung (Slot leer lassen, Serie mit < 48 Werten verwerfen) bleibt als
Absicherung, kostet nichts.

**Simulator (zu 3.)** – Die App liest heute den Zählerstand `z.Eo` (kWh) und bildet die Differenz pro
¼ h. Der Simulator rechnet bereits intern mit einer Leistung in kW (Tageskurve) und zählt sie zum
Zählerstand hoch. Der Smart Meter liefert beides: Leistung `Po` (kW) und Zählerstand `Eo` (kWh).
Die Energie aus dem Zählerstand ist genauer als die aufsummierte Momentanleistung. Rückfrage an
Hermann siehe unten.

**Reboot** – Passt zum Vorschlag: Grafik nach Neustart leer bis zum nächsten Abruf. Die App speichert
heute noch Zählerstand und Zeitpunkt via `persist`, damit die erste ¼ h nach Neustart nicht fehlt.
Das ist keine Anforderung mehr und kann bleiben oder entfallen.

## Beobachtungen zum Bild `final-app.jpg`

Das Bild weicht deutlich von der Referenz-App ab (heute: 1 Tag, ¼-h-Werte, Vergütungsbalken +
Preislinie in einem Chart):

- **3 Tage** (Do–Sa) mit **Stundenwerten** statt 1 Tag mit ¼-h-Werten.
- Oberes Chart: **Einspeisung in kWh** als Balken (grün), orange bei Preis < 0, Spotpreis als Linie
  (Rp.), negativer Bereich schattiert, Marke „jetzt“.
- Unteres Chart: **Vergütung in CHF/h** (gelb positiv, rot negativ) mit Summe Σ über 3 Tage.
- Im Intent war das Stufe 2 bzw. Übung A (Energiekurve, 3-Tage-Ansicht). Abnahmekriterium §7
  („3 Kurven über 72 Stunden“) passt bereits zum Bild, widerspricht aber Entscheid 6.1 (Stufe 1 = 1 Tag).
- **Datenproblem**: BKW liefert nur den aktuellen bzw. ab ~17 Uhr nur den Folgetag. Vergangene Tage
  hat das Gerät nur, wenn es 3 Tage durchgelaufen ist. Nach Neustart (keine Persistenz) sind sie weg.
  Am Workshop-Abend gibt es daher ohne Simulator-Auffüllung höchstens 1–2 Tage.

## Auswirkung „keine Vorbereitung“

`WORKSHOP_PREP.md` §2 plant eine Hausaufgaben-Mail. Fällt sie weg, muss vor Ort in den Setup-Block:

- Firmware-Upgrade auf ≥ 15.3.0 (bis zu 20 Geräte gleichzeitig über Gäste-WLAN)
- `Timezone 99`, Geräte ins Workshop-WLAN bringen
- Docker-Image laden (gross, über Gäste-WLAN), Agent-Zugang testen
- Editor: Hermann nennt ihn als Voraussetzung, also mitbringen ok.

Setup-Block (≥ 1 h) wird damit sehr knapp.

## Nächste Schritte

**Rückfragen an Hermann – beantwortet 22.10.**

1. Simulator-Takt 5/15/60 min → **Zeitraffer**: Grafik soll sich am Abend schneller füllen.
2. Simulator gibt **zusätzlich `Po` (kW)** aus, wie der echte Meter. App rechnet weiter mit `Eo`.
3. `final-app.jpg` ist das Ziel der **Referenz-App** (vor dem Workshop fertig), nicht der Übungen.
4. Vergangene Tage im Simulator-Modus mit **Fake-Preisen und -Energie auffüllen**: ja.
5. WLAN bei Glue: ok.
6. **Keine Mail vorab**: Firmware-Upgrade, `Timezone 99` usw. finden vor Ort statt.

**Eigene Arbeiten**

Dokumente:

- [ ] `INTENT.md`: §2 „Fehlende Werte werden weggelassen“ ergänzen mit „laut Hermann: alles oder
      nichts“; §6.3 (Reboot) und §6.9 (Lücken) als entschieden markieren; F1 „Vielfaches“ präzisieren.
- [ ] `INTENT.md` F3/§4a/§6.1: Stufe 1 neu = Bild `final-app.jpg` (3 Tage, Stundenwerte, zwei Charts:
      Einspeisung kWh + Preislinie, Vergütung CHF/h mit Σ). Widerspruch zu §7 damit aufgelöst.
- [ ] `EXERCISES.md`: Übung A (Energiekurve) und 3-Tage-Ansicht entfallen als Übung, weil in der
      Referenz-App. Neue Übungen festlegen (Kandidaten: Stunden-CSV mit Aufbewahrung, Shelly
      schalten, MQTT-Publish, Tele-JSON). Erweiterungspunkte im neuen Chart-Code vorsehen.
- [ ] `WORKSHOP_PREP.md`: Hausaufgaben-Mail streichen. Firmware-Upgrade, `Timezone 99`,
      Docker-Image und Agent-Test in den Setup-Block verschieben, Zeitplan neu rechnen
      (Setup > 1 h wahrscheinlich, Übungszeit entsprechend kürzen).
- [ ] Budget prüfen: grösserer Scope der Referenz-App gegen 20-h-Budget und Lieferziel Ende Oktober;
      Hermann informieren, falls es nicht reicht.

App (`app/spot.be`):

- [ ] Simulator-Zeitraffer: Konfig-Wert `sim_min` (5/15/60), Cron mit fester Id. Bei Zeitraffer
      jeder Takt = eine ¼ h (Wert für Wert vorwärts), damit die Grafik in Minuten statt Stunden
      wächst. Klären beim Bauen: Wie verhalten sich „jetzt“-Marke und echte Uhrzeit dazu?
- [ ] Simulator liefert `Po` (kW) zusätzlich zum Zählerstand (z.B. in `SpotStatus` und WebUI-Zeile).
- [ ] Simulator-Auffüllung: 2 vergangene Tage mit Fake-Preisen (inkl. negativer Preise, wie im Bild)
      und Fake-Energie, deutlich als „(Sim)“ markiert.
- [ ] Chart neu: 3 Tage, Stundenwerte (Preis = Mittel, Energie/Vergütung = Summe der 4 ¼ h),
      oberes Chart Energie-Balken (orange bei Preis < 0) + Preislinie + Schattierung negativer
      Bereich + „jetzt“; unteres Chart Vergütung CHF/h (positiv/negativ farbig) + Σ.
      Stückweise senden, Kurventabelle `chart_curves()` beibehalten.
- [ ] Heap messen (Testgerät .201): Rendering ohne Einbruch > 5 kB, Heap nach Upload > 100 kB.
- [ ] Desktop-Harness anpassen (`HARNESS OK`), Screenshot gegen `final-app.jpg` vergleichen.

Vor Ort:

- [ ] Firmware-Datei und Docker-Image lokal bereitstellen (USB-Stick oder lokaler Server), damit das
      Gäste-WLAN nicht 20 × gross herunterlädt. Reserve-Geräte mit fertiger Firmware mitnehmen.
