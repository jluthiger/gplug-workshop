# Übungen – Arbeiten mit dem Coding-Agenten auf dem gPlug

Gegenstand der Übungen ist der **Arbeitszyklus mit dem Agenten**: Kontext geben → kleine,
prüfbare Aufgabe formulieren → Code aufs Gerät laden → Konsole lesen → Fehler wörtlich
zurückgeben. Die Berry-App `app/spot.be` ist nur das Übungsobjekt. Jede Übung ist so gewählt, dass
sie den Datenfluss nicht verändert und bei Fehlern den Kern der App nicht beschädigt.

Grundlagen: `AGENTS.md` (Regeln und Werkzeuge, liest der Agent automatisch), `TASMOTA_BERRY_API.md`
(die Tasmota-API, ohne die der Agent rät), `SETUP_OPENCODE.md` §8 (Arbeitsweise im Agenten).

## Vorbereitung (5 min, für alle Übungen)

1. Geräte-IP eintragen: `echo 192.168.x.y > .gplug`
2. Gerät antwortet: `./brcmd.sh 'tasmota.cmd("SpotStatus")'` → JSON mit `"Sim":true`, `"prices":96`.
   **`HeapFree` notieren** (Ausgangswert, z.B. 125).
3. WebUI des gPlug im Browser offen lassen (`http://192.168.x.y`).
4. opencode starten: `./docker-run.sh` (Windows: `.\docker-run.ps1`) bzw. `opencode` im Repo-Ordner.

## Übung A – Energiekurve im Tageschart

### Aufgabe

Das Chart zeigt heute Balken (Vergütung pro ¼ h) und die Preislinie. Ergänze eine **dritte Kurve:
die eingespeiste Energie pro Viertelstunde (kWh) als Linie.**

Vorgaben:

- Datenquelle `self.store.energy_at(key, slot)` (Einheit 0.01 kWh, `nil` = Lücke).
- Eigene Skala von 0 bis zum Tagesmaximum. **Keine zusätzliche Achsenbeschriftung** – der
  Cursor (Maus über dem Chart) zeigt den kWh-Wert jedes Slots schon exakt an.
- Eintrag «Energie» in der Legende, der die Kurve per Klick ein- und ausblendet wie die anderen.
- Cursor-Script unverändert, kein JavaScript, keine neue Schleife, nichts anderes ändern.

### Was schon da ist (nicht neu bauen lassen)

In `app/spot.be`, Abschnitt `F3  Chart`, steht ein Kommentar `ERWEITERUNGSPUNKT Übung A` mit dem
Rezept. Vorhanden sind: Legende mit Toggle (aus der Tabelle `chart_curves()`), Cursor mit kWh-Wert,
die Helfer `day_range(...)`, `y_scale(...)` und `send_polyline(...)`, Farbkonstanten `COL_...`.
Die Lösung berührt **drei Stellen** und ist etwa fünf Zeilen lang.

### Zeitplan (65 min)

| Zeit | Schritt |
|---|---|
| 0–5 | Vorbereitung oben, `HeapFree` notiert |
| 5–15 | **Plan-Agent** (`Shift+Tab` bis `plan`): Prompt 1. Plan lesen. Schlägt er eine dritte Achse, Checkboxen oder eine eigene Zeichenschleife vor: ablehnen, auf die Vorgaben verweisen |
| 15–40 | **Build-Agent** (`Shift+Tab` bis `build`): Prompt 2. Shell-Befehle einzeln freigeben (nur `./upload.sh`, `./log.sh`, `./brcmd.sh`, `berry`, `git`). Fehler mit Prompt 3 zurückgeben |
| 40–50 | Prüfschritte unten selbst durchgehen |
| 50–60 | Vertiefung: in `/new` denselben Auftrag als Einzeiler («mach eine Energiekurve») stellen und vergleichen; funktionierenden Stand mit `git commit` sichern |
| 60–65 | Drei Zeilen Notizen für die Zeigerunde (siehe Checkliste unten) |

### Prompt 1 – planen (Plan-Agent)

```
Lies @AGENTS.md, @TASMOTA_BERRY_API.md und in @app/spot.be den Abschnitt "F3  Chart" mit dem
Kommentar "ERWEITERUNGSPUNKT Übung A".

Aufgabe: Im Tageschart soll eine dritte Kurve die eingespeiste Energie pro Viertelstunde (kWh)
als Linie zeigen.

Vorgaben: Datenquelle self.store.energy_at(key, slot) (0.01 kWh, nil = Lücke). Eigene Skala von
0 bis zum Tagesmaximum, keine zusätzliche Achsenbeschriftung (der Cursor zeigt den kWh-Wert
schon). Eintrag "Energie" in der Legende, der die Kurve wie die anderen ein- und ausblendet.
Bestehende Helfer verwenden: chart_curves, day_range, y_scale, send_polyline. Keine neue
Schleife, kein JavaScript, keine Änderung am Cursor-Script, nichts anderes ändern.

Schreibe einen Plan: welche Methoden du an höchstens drei Stellen änderst und wie du das
Ergebnis prüfst (Desktop-Harness, upload.sh, log.sh, SpotStatus, Heap). Frag nach, wenn etwas
unklar ist. Noch nichts ändern.
```

### Prompt 2 – umsetzen (Build-Agent)

```
Setze den Plan um, in dieser Reihenfolge:
1. Änderung in app/spot.be.
2. cd app && berry desktop_harness.be – muss mit HARNESS OK enden; app/sensor.html muss
   <g id='se'> enthalten.
3. ./upload.sh app/spot.be, danach ./log.sh. Jede Zeile mit BRY: oder SPOT: wörtlich zeigen.
4. ./brcmd.sh 'tasmota.cmd("SpotStatus")' und den Heap melden.
Melde in fünf Zeilen: was geändert, was geprüft, was offen. Die WebUI prüfe ich selbst.
```

### Prompt 3 – Fehler zurückgeben

```
./log.sh zeigt nach dem Upload:
<Zeilen wörtlich einfügen>
Behebe nur diesen Fehler, lade neu hoch und lies das Log erneut.
```

### Erwartetes Resultat

- Legende hat einen vierten Eintrag «Energie»; Klick blendet die Linie aus und ein.
- Die Linie hat ihr Maximum oben am Chart (eigene Skala) und Lücken, wo Energie fehlt.
- Maus über dem Chart: Cursor zeigt unverändert Zeit, Rp/kWh, kWh, Rp; der kWh-Wert passt zur
  Höhe der Linie.
- `./log.sh`: `SPOT: v0.2 geladen` nach dem Upload, keine Zeile mit `BRY:`.
- `SpotStatus` unverändert bis auf `HeapFree` (höchstens ~1 kB tiefer pro Upload).
- `git diff --stat app/spot.be`: eine Datei, etwa 5 Zeilen an 3 Stellen.

> Ist der Preis über den Tag fast konstant (Simulator, ruhiger Markt), liegt die Energielinie
> auf den Oberkanten der Balken. Das ist richtig – Vergütung = Energie × Preis – und kein Fehler.
> Balken per Klick ausblenden, dann sieht man die Linie allein.

### Prüfschritte

```sh
cd app && berry desktop_harness.be | tail -1      # HARNESS OK
grep -c "id='se'" sensor.html; cd ..              # 1
./upload.sh app/spot.be                           # OK ... heap_free N kB
./log.sh                                          # keine BRY:-Zeile
./brcmd.sh 'tasmota.cmd("SpotStatus")'            # prices 96, HeapFree nahe Ausgangswert
./brcmd.sh 'tasmota.gc()'; ./brcmd.sh 'tasmota.memory("heap_free")'
git diff --stat app/spot.be
```

Im Browser: Seite neu laden, «Vergütung/¼h» ausblenden, Linie allein betrachten, mit der Maus
einen Slot anfahren und den kWh-Wert mit der Linienhöhe vergleichen.

### Stolpersteine (aus dem Probelauf, 30 min, 14 Uploads)

1. **«Die Kurve fehlt»** – sie liegt auf den Balkenspitzen (siehe Kasten oben). Balken ausblenden.
2. **Dritte Achse.** Der Agent will Achsenwerte für kWh beschriften; sie überlappen die Preisachse
   oder werden am Rand abgeschnitten, und es kostet vier Prompts Layout. Nein sagen, Vorgabe zitieren.
3. **Checkboxen / `onchange` im Chart** funktionieren nie: Tasmota ersetzt den Sensorbereich alle
   paar Sekunden per AJAX, Scripts darin laufen nicht. Legende über `chart_curves()` erweitern.
4. **Eigene Zeichenschleife.** Der Agent kopiert die Polyline-Logik (gern zweimal, Kontur + Linie).
   `send_polyline` einfordern; eine Kurve ist ein Aufruf.
5. **Heap.** Jeder Upload kostet ~1 kB, der erst ein Neustart zurückgibt; `upload.sh` startet das
   Gerät unter 80 kB selbst neu. Scheitert der Agent zweimal gleich: anhalten, Log selbst lesen.
6. **Erfundene API** (`webserver.content_send` in `web_sensor`, nicht existierende `tasmota.*`-
   Funktionen). Auf `TASMOTA_BERRY_API.md` verweisen; nur dort Genanntes gilt.
7. **`BrRestart` / `Restart` über `brcmd.sh`** sind gesperrt (Absturz bzw. Reboot). App neu laden
   nur über `./upload.sh`.
8. **Fehlendes `var`** für eine neue Instanzvariable → `BRY:`-Fehler mit Zeilennummer beim Laden
   (strict mode). Zeile wörtlich an den Agenten.
9. **Scope-Creep** («bei der Gelegenheit habe ich auch …»): «nichts anderes ändern» wiederholen,
   Änderung mit `/undo` zurücknehmen.
10. **Stubs aufs Gerät** (`persist.be`, `path.be`, `desktop_harness.be`): `upload.sh` lehnt ab.
    Der Agent soll nur `app/spot.be` hochladen.
11. **Shell-Freigaben.** opencode fragt vor jedem Befehl. Nur `./upload.sh`, `./log.sh`,
    `./brcmd.sh`, `berry`, `git` freigeben; alles andere ablehnen und den Agenten fragen, wozu.

## Übung B – CSV mit Stundenwerten (Entwurf, folgt)

Ziel: zusätzlich zur Tageszeile eine Stundendatei `spot_h_YYYY-MM.csv`, Aufbewahrung zwei Monate.
Erweiterungspunkt: `cfg["csv_hourly"]` und `day_end()` (Kommentar `ERWEITERUNGSPUNKT Übung B`).
Prüfschritt: Dateimanager zeigt die Datei; Tageswechsel per `Br` simulieren. Lehrt: Testbarkeit
einfordern (Funktion mit Datums-Parameter verlangen).

## Übung C – Schwellwert an Shelly/MQTT (Entwurf, folgt)

Ziel: bei Preis unter/über Schwelle ein HTTP-schaltbares Gerät schalten. Erweiterungspunkt:
`json_append()` / neuer Command (Kommentar `ERWEITERUNGSPUNKT Übung C`). Prüfschritt: Konsole zeigt
den Schaltbefehl. Lehrt: Drittsystem-API als Kontext geben (Shelly-Doku-Auszug), sonst rät der Agent.

## Checkliste Zeigerunde

- Der Prompt, der funktioniert hat (wörtlich).
- Der Prompt, der schiefging, und was der Agent daraus gemacht hat.
- Anzahl Upload-Zyklen bis zum Ergebnis.
- `HeapFree` am Anfang und am Ende.
