# Issue 2026-11-06 – gPlugK Burgistein: Abstürze und Load > 100 % bei offener WebUI

Quelle: `issues/261106-burgistein.png`. Gerät: gPlugK (Kamstrup via Script/SML, Tasmota 15.5.0),
App: `spot.tapp` = `app/steps/spot_4.be` (Referenz, 3 Tage, 2 Charts).

## Befund

**Alle drei Punkte haben dieselbe Ursache: `web_sensor()` rechnet und sendet bei jedem AJAX-Refresh
(2.3 s) das ganze Chart neu, und Berry auf dem ESP32-C3 braucht dafür ~1 s.** Nicht "amok", kein
Command-Loop: ein Callback, 20–30× über dem 50-ms-Limit aus AGENTS.md, im Dauerbetrieb.

### Messung 6.11. auf dem Testgerät gPlugM (192.168.0.202, Tasmota 15.3.0, Starter-App: 1 Chart, 96 Werte)

| Messgrösse | Wert |
|---|---|
| LoadAvg WebUI zu / offen | 10 / 20–73 |
| Heap WebUI zu / offen | 129 / 121–126 kB |
| `/?m=1` pro Refresh | 4.9 kB, 620–760 ms (TTFB 30–200 ms, Download ~530 ms) |
| Chunks pro Antwort | 10 à 0.3–0.8 kB; Abstand 90–110 ms bei Berry-gebauten Chunks, 1–15 ms bei vorgebauten (Legende, Fuss) |

Berry-Kosten auf dem C3 (je 96 Aufrufe, `tasmota.millis()`):

| Operation | ms / 96 | pro Aufruf |
|---|---|---|
| `store.price(key, s)` | 60 | 0.6 ms |
| `store.day_index(key)` (3 Tage) | 34 | 0.35 ms – davon `for i:0..n` (Range-Objekt) ~0.2 ms, `while` 4× schneller |
| Methodenaufruf (leer) | ~10 | 0.1 ms |
| `string.format` mit 2 Floats + `s +=` | 45 | 0.47 ms |
| `string.format` 2 Ints | 17 | 0.18 ms |
| ein `<rect>` (4 Floats) formatieren + anhängen | 143 | 1.5 ms |
| `bytes.geti` | 4 | 0.04 ms |
| `day_sums(key)` (1 Aufruf) | 99 | – |
| `value_range` + `nice_range` (1 Aufruf) | 63 | – |

Starter: ~350 ms Berry + ~300 ms Netz ≈ 650 ms gemessen. Hochgerechnet auf `spot_4.be`
(`day_sums` 100, `fill_hours` 576 Store-Lookups ≈ 350, `chart_start`/`count` 100 Lookups ≈ 60,
85 Balken ≈ 130, Polyline + 3 `data-`-Attribute ≈ 110, Achsen ≈ 30): **≈ 0.8–1.0 s Berry + Netz ≈ 1.5 s**,
genau der Wert aus der Issue.

Sensorbereich von `spot_4.be` (Harness, Sim-Daten, 12.8 kB; Issue: 9.7 kB): `<rect>` 85 Stück 5.7 kB
(45 %), `<text>`/`<line>` 2.9 kB, `data-p/e/v` 0.8 kB, ~40 `web_send`-Aufrufe.

### 2. Load AVG > 100 %
Erklärt (siehe oben). Berry läuft im Tasmota-Loop; während ~1.5 s von 2.3 s steht er. Tasmota-Heap
schwankt um Chunk-/TCP-Puffer und Berry-Strings (`s += ...` bis 1.7 kB pro Häppchen), Berry-Heap bleibt
konstant, weil der GC die Strings sofort freigibt. Folgeschaden am gPlugK, den die Issue nicht nennt:
das Script liest in der Blockade den Kamstrup nicht (Serial/SML), MQTT-Keepalive und WLAN leiden.

### 1. Abstürze (Instruction access fault, EPC = EXCVADDR = 546b49e4)
EPC ist keine Code-Adresse (Flash-Code 0x42xxxxxx) → Sprung ins Leere = kaputter Rücksprung oder
Funktionszeiger, typisch für Heap-Korruption/fehlgeschlagene Allokation. Nur bei offener WebUI, alle
30–40 min, plus sofort beim Wiederöffnen (Vollseite = Sensorbereich + Cursor-Script). Wahrscheinlichste
Kette: Heap am gPlugK in Ruhe nur ~76 kB (Script + SML ≈ 45 kB mehr als gPlugM), beim Rendern −10 kB
plus Fragmentierung; INTENT.md: unter ~50 kB startet das Gerät bei grossen Allokationen neu. Auf dem
gPlugM (120 kB) nicht reproduzierbar. Beweis fehlt: `EPC`/`CallChain` gegen das ELF der gPlug-15.5.0-
Firmware dekodieren (gplug.ch). Web-Suche: kein passender Tasmota-Report.

### 3. Datenmenge 9.7 kB / 3 s
Richtig beobachtet, aber die Bytes sind nicht der Haupttreiber: Berry-Rechenzeit (Store-Lookups,
Float-Formatierung) und Chunk-Anzahl zählen mehr. Beides senken.

## Massnahmen (Reihenfolge = Wirkung)

1. **Chart nicht mehr bei jedem Refresh senden.** Sensorbereich nur Kopf-/Fusszeilen (~1 kB) und ein
   Platzhalter `<div id='spotchart' data-v='<slot>'>`. SVG über eigenen Handler
   (`webserver.on("/spot.svg")` in `web_add_handler`); das Cursor-Script (läuft ausserhalb des
   Sensorbereichs, hat schon einen MutationObserver auf `#l1`) holt es einmal pro Seite und neu nur bei
   `data-v`-Wechsel (alle 15 min). Refresh-Kosten: ~1.5 s → wenige 10 ms.
2. **Store-Lookups billiger.** `SpotStore.get` ruft pro Wert `day_index` (Range-Objekt + Schleife) und
   zwei Methoden: 0.6 ms. Pro Tag den Index einmal holen und mit `buf.geti(off + s*2, 2)` lesen
   (`fill_hours`, `day_sums`, `count`): 576 Lookups → 3. In `day_index` `while` statt `for`. Spart ~0.5 s
   in `spot_4.be`.
3. **`day_sums` nicht pro Refresh**, sondern in `on_quarter` berechnen und cachen (auch für
   `json_append`): −100 ms pro Refresh.
4. **SVG schlanker:** Balken je Kurve als ein `<path d='M..v..h..'>` statt 85 `<rect>` (5.7 → ~1.5 kB,
   1 Format statt 4 pro Balken); ganzzahlige Koordinaten (viewBox ×10, `%d` statt `%.1f`, Soft-Float auf
   C3); Achsenstil per `<style>` statt Attribute pro Element. Ziel ≤ 5 kB.
5. **Weniger Writes:** Häppchen ~1 kB (CH_SEND_EVERY grösser), Liste + `concat` statt `s +=`.
6. Sofortmassnahme ohne Code (Mensch entscheidet): `WebRefresh 10000` am gPlugK → Last ¼.
7. Heap-Budget im Projekt: AGENTS/INTENT rechnen mit ~120 kB frei (gPlugM ohne Zähler). Mit Script +
   SML sind es ~75 kB; `upload.sh` würde dort bei jedem Upload neu starten (Schwelle 100 kB).

## Prüfplan

- gPlugK: `Status 0` → Heap/LoadAvg in Ruhe; WebUI 10 min offen, LoadAvg/Heap/`tasmota.memory()`
  (`frag`, `stack_low`) alle 30 s via `brcmd.sh` mitschreiben.
- Gegenprobe `WebRefresh 10000`: bleiben die Abstürze aus → Render-Last bestätigt.
- Nach Massnahme 1: `/?m=1` im Browser < 100 ms (`performance.getEntriesByType('resource')`),
  LoadAvg < 30, kein Absturz über 4 h.
- Backtrace dekodieren (ELF von gplug.ch) für die endgültige Absturzursache.

## Umsetzung v0.12.0 (6.11., Branch `fix/webui-load`, `app/steps/spot_4.be`)

Gemessen am gPlugM (Tasmota 15.3.0, Simulator), WebUI offen, Chrome `performance`-Einträge:

| Stand | Refresh `/?m=1` | LoadAvg | Chart |
|---|---|---|---|
| vorher (v0.11.1) | 12.8 kB, Ø 1171 ms | 56–129 | im Refresh |
| Fix 1: Store direkt lesen, Summen cachen | 12.8 kB, Ø 682 ms | 27–68 | im Refresh |
| Fix 2+3: Chart über `/spot.svg`, Balken als `<path>` | 1.9 kB, Ø 178 ms | 9–16 | 7.1 kB, ~510 ms, nur bei Datenwechsel |

Geprüft: Harness `HARNESS OK` (Stub `app/webserver.be`), Rendering, Legende ein/aus, Cursor,
Nachladen bei `SpotTick` (data-v 2→4, drei Fetches), kein `SPOT:`-Fehler im Log, Heap nach `gc` 108 kB.

Offen: `tools/make_steps.py` (Starter, Schritte 1–3, EXERCISES.md) an die neue F3-Struktur anpassen;
Gegenprobe am gPlugK (Abstürze weg?); Backtrace-Dekodierung bleibt für die endgültige Absturzursache.
