# Übungen – Arbeiten mit dem Coding-Agenten auf dem gPlug

📄 [Diese Übung als PDF (A4)](docs/EXERCISES.pdf) · [Begriffe: LEGENDE.md](LEGENDE.md)

Du übst den **Arbeitszyklus mit dem Agenten**: planen lassen → umsetzen lassen → Log lesen →
Fehler wörtlich zurückgeben → selbst prüfen. Die Berry-App `app/spot.be` ist nur das
Übungsobjekt. Vorher machst du den Zyklus einmal von Hand (Schritt 0). Von oben nach unten lesen und
Punkt für Punkt aufklappen (▸).

## Überblick: Hello World, dann vom Starter zur Referenz-App in 4 Schritten, dazu Schritt 5

**Teil A:** ein Hello World **von Hand** (Schritt 0, ohne Agent und Skripte). **Teil B:** zuerst
dasselbe Hello World **mit opencode** (Schritt 0), dann vom **Starter** (nur Preislinie) zum Zielbild
`docs/zielbild.jpg`. **Im Zeitplan: Schritt 0 von Hand (~10 min), dann Schritt 0 mit opencode
(~10 min) und Schritte 1 und 2** (Übungsblock 65 min, davon 20 min Puffer). Optional: 3 und 4 für Schnelle, 5 für Fortgeschrittene.

<details>
<summary>Alle Schritte im Überblick (Tabelle)</summary>

| Schritt | Ziel | Sichtbares Resultat | Lernziel KI |
|---|---|---|---|
| 0 Hello World (Teil A) | `app/hello.be` von Hand hochladen und laden | Zeile «Hallo gPlug» in der WebUI, `HELLO:` in der Konsole | – (Zyklus ohne Agent sehen) |
| Starter | – | Preislinie, 1 Tag, ¼ h | – |
| 0 Hello World (Teil B) | `app/hello_agent.be` von opencode schreiben, hochladen und laden lassen | Zeile «Hallo opencode» in der WebUI, `HELLO:` im Log | Vom Ein-Satz-Prompt zum vollständigen Prompt: was fehlt, rät der Agent; plan und build unterscheiden |
| 1 Energie-Balken | Einspeisung pro ¼ h als grüne Balken, eigene kWh-Achse links | Solarkurve unter der Preislinie | Kontext geben: Erweiterungspunkt und Datenquelle nennen |
| 2 Negativpreis | Balken orange bei Preis < 0, Bereich unter 0 Rp. schattiert, Legende | Mittagstief fällt auf | Kleine, prüfbare Aufgabe; Testfall benennen (Sim: Mittagstief < 0) |
| 3 3 Tage, Stundenwerte | x-Achse 72 h, Tagesnamen, 00/12-Marken; Stunde = Mittel (Preis) bzw. Summe (Energie) | Do–Sa wie im Zielbild | Umbauen statt anbauen; Heap vorher/nachher messen |
| 4 Vergütungs-Chart | Zweites Chart darunter: CHF/h gelb/rot, Σ über 3 Tage | Zielbild komplett | Auf eigenem Ergebnis aufbauen; Wiederverwendung einfordern |
| 5 2 Tage, Viertelstunden | 192 ¼-h-Werte: gestern + heute, ab Preisen für morgen heute + morgen; Preis als Treppe | Preisspitzen innerhalb der Stunde sichtbar | Konstanten statt Zahlen; Kosten (Bytes, ms, Heap) messen lassen |

**Checkpoints**: `app/steps/spot_0.be` (Starter) … `spot_5.be` enthalten den fertigen Stand nach
jedem Schritt. Wer hängen bleibt, kopiert selbst den passenden nach `app/spot.be`.

</details>

---

# Teil A – Von Hand, ohne Agent

Nur Texteditor und Browser. Kein opencode, kein Terminal, keine Skripte.

## Schritt 0 – Hello World von Hand (alle, ~10 min)

**Ziel:** Du hast den ganzen Zyklus einmal von Hand gemacht: **Code schreiben → aufs Gerät
laden → laufen lassen → Resultat ansehen → ändern.** In der WebUI steht die Zeile «Hallo gPlug».

Kursleitung zeigt es am Beamer (3 min), danach alle selbst. Punkt für Punkt aufklappen. Wenn die
Zeile steht und aufgeräumt ist, weiter mit Schritt 7 im Runbook deines Systems (Starter aufs Gerät), danach
hier bei *Teil B*.

<details open>
<summary><b>Schritt 0 – Anleitung</b> (zuklappen, wenn erledigt)</summary>

Menünamen wie auf dem gPlug (deutsch), in Klammern englisch.

<details>
<summary><b>Die App <code>app/hello.be</code></b></summary>

Liegt fertig im Workshop-Ordner. Im Texteditor öffnen:

```berry
# hello.be – Schritt 0: Hello World auf dem gPlug
# Von Hand hochladen (Werkzeuge -> Dateisystem verwalten), laden in der Konsole mit:
#   Br load("hello")
# Steht nicht in autoexec.be: der nächste BrRestart (Upload des Starters) entfernt die App.

import global

class Hello
  var start                       # tasmota.millis() beim Laden

  def init()
    self.start = tasmota.millis()
  end

  # Zeile im Sensorbereich der WebUI, wird alle paar Sekunden neu geholt
  def web_sensor()
    var s = (tasmota.millis() - self.start) / 1000
    tasmota.web_send("{s}Hallo gPlug{m}läuft seit " + str(s) + " s{e}")
  end
end

# Nochmals laden ersetzt die alte Instanz, statt eine zweite Zeile anzuhängen
if global.contains("hello") && global.hello != nil
  tasmota.remove_driver(global.hello)
end
global.hello = Hello()
tasmota.add_driver(global.hello)
log("HELLO: Hallo Welt", 2)
```

</details>

<details>
<summary><b>1. Hochladen</b></summary>

WebUI → *Werkzeuge* (*Tools*) → *Dateisystem verwalten* (*Manage File system*) → Datei
`app/hello.be` wählen → hochladen.

Erwartet: `hello.be` erscheint in der Dateiliste.

</details>

<details>
<summary><b>2. Laden</b></summary>

*Werkzeuge* → *Konsole* (*Console*), eingeben:

```
Br load("hello")
```

Erwartet: `HELLO: Hallo Welt`, danach `RESULT = {"Br":"true"}`. Keine Zeile mit `BRY:` und
Fehlermeldung.

</details>

<details>
<summary><b>3. Resultat ansehen</b></summary>

*Hauptmenü* (*Main Menu*).

Erwartet: Zeile **Hallo gPlug**, rechts **läuft seit N s**; die Sekunden zählen bei jedem
Refresh (alle paar Sekunden) hoch.

</details>

<details>
<summary><b>4. Ändern, nochmals</b></summary>

In `app/hello.be` den Text `Hallo gPlug` durch den eigenen Namen ersetzen, speichern, Punkte 1–3
wiederholen (gleicher Dateiname überschreibt).

Erwartet: die Zeile zeigt den neuen Text, die Sekunden beginnen bei 0, es bleibt **eine** Zeile
(die App ersetzt beim Laden ihre alte Instanz).

</details>

<details>
<summary><b>5. Optional: Fehler ansehen</b></summary>

Ein `end` löschen, hochladen, laden.

Erwartet: `BRY:`-Zeile mit Fehler und Zeilennummer. So sehen Berry-Fehler aus; du brauchst sie
in den nächsten Schritten wieder. Danach `end` wieder einfügen, hochladen, laden.

</details>

<details>
<summary><b>6. Aufräumen</b></summary>

*Werkzeuge* → *Konsole*, eingeben:

```
Br tasmota.remove_driver(global.hello) global.hello = nil
```

Erwartet: im *Hauptmenü* ist die Zeile «Hallo gPlug» weg. Die Datei `hello.be` darf auf dem
Gerät bleiben (sie steht nicht in `autoexec.be`, startet also nie von selbst) oder unter
*Dateisystem verwalten* gelöscht werden.

</details>

</details>

---

# Teil B – Mit dem Agenten

Ab hier arbeitest du mit opencode. Was du in Schritt 0 von Hand gemacht hast, erledigen Skripte:
`upload.sh` = hochladen + laden, `log.sh` = Konsole lesen, `brcmd.sh` = `Br …` in der Konsole.
Zuerst lässt du den Agenten dasselbe Hello World bauen (Schritt 0 mit opencode), dann geht es an
die App `app/spot.be`.

## Vorbereitung (5 min)

Der Starter ist auf dem Gerät (Runbook deines Systems, Schritt 7; Übersicht `RUNBOOK.md`).

1. Geräte-IP prüfen (RUNBOOK, Schritt 7.1): `cat .gplug`
2. Gerät antwortet mit `"Sim":true`. **`HeapFree` notieren** (Ausgangswert, z.B. 125).
   ```sh
   ./brcmd.sh 'tasmota.cmd("SpotStatus")'
   ```
3. WebUI des gPlug im Browser offen lassen (`http://192.168.x.y`).
4. opencode starten: `./docker-run.sh` (ohne Docker: `opencode` im Repo-Ordner; Windows mit
   PowerShell: `.\docker-run.ps1`).
5. Prompts kopierst du aus diesem Dokument und fügst sie in opencode ein: macOS **Cmd+V**, Windows
   **Ctrl+V** oder Rechtsklick, Linux **Ctrl+Shift+V** (Ctrl+V fügt im Terminal nichts ein).

<details>
<summary>Starter: was schon da ist</summary>

Ausgangspunkt für Schritt 1, Stand auch in `app/steps/spot_0.be`.

![Starter: nur die Preislinie, 1 Tag](docs/steps/schritt_0.png)

Daten vollständig, Darstellung minimal:

- Im Hintergrund: Preisabruf (F1), Zähler mit Simulator inkl. Zeitraffer, `Po` und gefüllten
  Vortagen (F2), Tages-CSV (F4), `SpotPrices` (F5). Der Speicher hält **3 Tage** Preise und Energie.
- Textzeilen über dem Chart: Spotpreis jetzt, Einspeisung heute, Vergütung heute. Damit sind die
  Daten sichtbar, bevor sie gezeichnet werden; Schritt 1 lässt sich an «Einspeisung heute» prüfen.
- Chart: **nur die Preislinie** (cyan, `COL_PRICE`), 1 Tag mit 96 ¼-h-Werten, Achse Rp./kWh
  rechts, Nulllinie, «jetzt»-Marke (grau), Legende aus `chart_curves()`. Farben wie im Zielbild;
  `COL_ENERGY` (grün), `COL_NEG` (orange), `COL_PAY` (gelb), `COL_COST` (rot) sind schon definiert.
- Simulator gibt dem heutigen Tag ein Mittagstief mit negativen Preisen (Testfall Schritt 2).
- Vorhandene Helfer: `chart_curves()`, `send_polyline(...)`, `value_range(...)`, `nice_range(...)`
  (runde Achsenstufen), `y_scale(...)`, `send_data_attr(...)` (Werte für den Cursor),
  Farbkonstanten `COL_...`, Datenzugriff `self.store.price(key, slot)` (1/10'000 CHF/kWh) und
  `self.store.energy_at(key, slot)` (0.01 kWh), beide `nil` = Lücke.
- Kommentare `# ERWEITERUNGSPUNKT Schritt 1` … `Schritt 4` am Anfang von `F3  Chart`; jeder
  Checkpoint enthält nur noch die Punkte der offenen Schritte.
- Cursor-Script in allen Stufen gleich: es zeigt jeden vorhandenen Wert (`data-p`, `data-e`,
  `data-v`) und rechnet die Zeit aus `data-m` (15 oder 60 min). Kein Schritt ändert das Script.

</details>

## Farbcode: plan oder build

opencode hat zwei Agenten. Der aktive steht unten im Eingabefeld, **`Shift+Tab`** wechselt. Der
Gesprächsverlauf bleibt erhalten.

> [!NOTE]
> **🔵 PLAN** – Agent liest nur. Für den Prompt «planen».

> [!TIP]
> **🟢 BUILD** – Agent ändert Dateien und führt Befehle aus (nach Freigabe). Für «umsetzen» und
> «Fehler zurückgeben».

> [!WARNING]
> **⚠️ Stolperstein** – was hier typischerweise schiefgeht.

Merkregel: **planen = plan, alles andere = build.** opencode startet im **build**-Agent.

## Schritt 0 – Hello World mit opencode (alle, ~10 min)

**Ziel:** Dasselbe wie in Teil A, aber der Agent schreibt die App und fährt den Zyklus selbst:
**planen → schreiben → hochladen → laden → Log lesen.** In der WebUI steht die Zeile
«Hallo opencode». Du beginnst mit einem Prompt aus einem Satz, siehst, was dem Agenten fehlt, und
schreibst ihn besser. Dabei lernst du die beiden Agenten (plan, build) und die drei Skripte kennen.

<details open>
<summary><b>Schritt 0 – Anleitung</b> (zuklappen, wenn erledigt)</summary>

<details>
<summary><b>0.1 Einfacher Prompt</b> 🔵</summary>

> **🔵 PLAN** – `Shift+Tab`, bis unten `Plan` steht. Prompt einfügen, genau so kurz.

```
Schreibe eine Hello-World-App für den gPlug.
```

So beginnt fast jeder. Der Agent schreibt einen Plan und ändert nichts (plan-Agent liest nur).

*Warum im plan-Agent?* Der Prompt lässt fast alles offen. Im Plan siehst du gefahrlos, was der
Agent daraus macht.

</details>

<details>
<summary><b>0.2 Plan lesen und besprechen</b></summary>

Plan lesen, mit der Nachbarin oder dem Nachbarn vergleichen. Die Pläne unterscheiden sich: der
Agent musste raten.

- **Datei:** Welche legt er an oder ändert er? `app/hello.be`, `app/spot.be` und
  `app/autoexec.be` sollen bleiben, wie sie sind.
- **Resultat:** Wo erscheint «Hello World»: im Log, in der WebUI, oder steht es nicht da?
- **Aufs Gerät:** Wie lädt er hoch, wie startet er die App? Nach `./upload.sh` ohne
  `--no-restart` läuft nur, was in `autoexec.be` steht: die Hello-App wäre gleich wieder weg.
- **Prüfung:** Woran erkennt er, dass es läuft? Liest er das Log?
- **Erfunden:** Nennt er Funktionen, die nicht in `TASMOTA_BERRY_API.md` stehen?

Ist der Plan trotzdem brauchbar: Woher wusste der Agent das? (opencode liest `AGENTS.md` von
selbst; der Rest war Glück oder geraten.)

*Warum besprechen?* Was im Prompt fehlt, füllt der Agent mit Annahmen. Die Lücken im Plan zeigen
dir, was in einen Prompt gehört.

</details>

<details>
<summary><b>0.3 Prompt verbessern</b> 🔵</summary>

> **🔵 PLAN** – nicht umschalten. Eigenen Prompt schreiben, der die Lücken aus 0.2 schliesst.

In einen guten Prompt gehört:

1. **Kontext:** was der Agent zuerst lesen soll (`@AGENTS.md`, `@TASMOTA_BERRY_API.md`, Vorlage
   `@app/hello.be`).
2. **Aufgabe:** neue Datei `app/hello_agent.be` (nur diese erlaubt `AGENTS.md` dem Agenten).
3. **Sichtbares Resultat:** Zeile in der WebUI, links «Hallo opencode», rechts «Heap frei N kB»;
   beim Laden `HELLO: Hallo vom Agenten` im Log.
4. **Grenzen:** `hello.be`, `spot.be`, `autoexec.be` nicht ändern; nochmals laden ersetzt die
   alte Instanz.
5. **Prüfung:** `./upload.sh --no-restart`, `./brcmd.sh 'load("hello_agent")'`, `./log.sh`.
6. **Noch nichts ändern**, nur Plan.

<details>
<summary>Beispiel eines vollständigen Prompts (erst nach dem eigenen Versuch aufklappen)</summary>

```
Lies @AGENTS.md, @TASMOTA_BERRY_API.md und als Vorlage @app/hello.be.

Aufgabe: Lege eine neue Datei app/hello_agent.be an, eine eigene Hello-World-App für den gPlug.

Vorgaben: Klasse HelloAgent mit web_sensor(), die im Sensorbereich der WebUI eine Zeile zeigt:
links "Hallo opencode", rechts "Heap frei N kB" aus tasmota.memory("heap_free"). Body von
web_sensor() in try/except, Fehler mit log("HELLO: ...", 2). Instanz in global.hello_agent;
nochmals laden ersetzt die alte Instanz (wie in hello.be). Beim Laden log("HELLO: Hallo vom
Agenten", 2). app/hello.be, app/spot.be und app/autoexec.be nicht ändern.

Schreibe einen Plan: Inhalt der Datei und wie du das Ergebnis prüfst (upload.sh --no-restart,
brcmd.sh, log.sh). Noch nichts ändern.
```

</details>

Neuen Plan mit dem aus 0.1 vergleichen: Was ist jetzt festgelegt, was rät der Agent noch?

*Warum zuerst planen?* Der Plan zeigt, ob der Agent Vorlage und Regeln gelesen hat, bevor er etwas anfasst.

> **⚠️ Plan ablehnen bei:** Änderungen an `hello.be`, `spot.be` oder `autoexec.be` · `BrRestart`
> oder `Restart` · Funktionen, die nicht in `TASMOTA_BERRY_API.md` stehen.

</details>

<details>
<summary><b>0.4 Umsetzen lassen</b> 🟢</summary>

> **🟢 BUILD** – `Shift+Tab`, bis unten `Build` steht. Prompt einfügen.

```
Setze den Plan um, in dieser Reihenfolge:
1. app/hello_agent.be anlegen.
2. ./upload.sh --no-restart app/hello_agent.be
3. ./brcmd.sh 'load("hello_agent")' – muss {"Br":"true"} liefern.
4. ./log.sh, jede Zeile mit BRY: oder HELLO: wörtlich zeigen.
Melde in drei Zeilen: was angelegt, was geprüft. Die WebUI prüfe ich selbst.
```

Shell-Befehle einzeln freigeben, nur `./upload.sh`, `./brcmd.sh`, `./log.sh`.

*Warum `--no-restart`?* Ohne startet `upload.sh` Berry neu (`BrRestart`); danach läuft nur, was
in `autoexec.be` steht, also der Starter, nicht die Hello-App. Darum hochladen ohne Neustart und
mit `load("hello_agent")` starten, wie in Teil A mit `Br load("hello")`.

> **⚠️** Agent antwortet nur mit Text: noch plan aktiv, auf build schalten.

</details>

<details>
<summary><b>0.5 Log lesen, Resultat prüfen</b></summary>

Ausgabe von `./log.sh` selbst lesen. Erwartet: `HELLO: Hallo vom Agenten`, keine Zeile mit
`BRY:`. Bei einem Fehler die Zeilen wörtlich zurückgeben (🟢 BUILD):

```
./log.sh zeigt nach dem Laden:
<Zeilen wörtlich einfügen>
Behebe nur diesen Fehler, lade neu hoch, lade die App und lies das Log erneut.
```

Browser, *Hauptmenü*. Erwartet: Zeile **Hallo opencode**, rechts **Heap frei N kB**, **eine**
Zeile, auch wenn der Agent mehrmals geladen hat. Der Starter (Preislinie) läuft daneben weiter.

Datei `app/hello_agent.be` im Editor öffnen und mit `app/hello.be` vergleichen: Was hat der
Agent übernommen, was ist neu?

</details>

<details>
<summary><b>0.6 Aufräumen</b></summary>

```sh
./brcmd.sh 'tasmota.remove_driver(global.hello_agent) global.hello_agent = nil'
```

Erwartet: die Zeile «Hallo opencode» ist weg. Ohne Aufräumen entfernt sie der erste Upload in
Schritt 1 (`BrRestart`).

Hängen geblieben? `cp app/steps/hello_agent.be app/hello_agent.be`, dann die Befehle 2–4 aus
0.4 selbst im Terminal.

</details>

</details>

## Schritt 1 – Energie-Balken (Pflicht, ~20 min)

**Ziel:** Die App zeigt neben dem Preis auch deine Einspeisung: grüne Balken (kWh pro
Viertelstunde) hinter der Preislinie, eigene Achse links.

<details open>
<summary><b>Schritt 1 – Anleitung</b> (zuklappen, wenn erledigt)</summary>

![Ziel Schritt 1: grüne Energie-Balken, kWh-Achse links](docs/steps/schritt_1.png)

<details>
<summary><b>1.1 Planen lassen</b> 🔵</summary>

> **🔵 PLAN** – `Shift+Tab`, bis unten `Plan` steht. Prompt einfügen.

```
Lies @AGENTS.md, @TASMOTA_BERRY_API.md und in @app/spot.be den Abschnitt "F3  Chart" mit dem
Kommentar "ERWEITERUNGSPUNKT Schritt 1".

Aufgabe: Im Tageschart soll die eingespeiste Energie pro Viertelstunde (kWh) als grüne Balken
hinter der Preislinie erscheinen.

Vorgaben: Datenquelle self.store.energy_at(key, slot) (0.01 kWh, nil = Lücke). Kurzbuchstabe e,
Farbe COL_ENERGY. Eine neue Achse links mit kWh von 0 bis Tagesmaximum (ausdrücklich erlaubt),
Preisachse rechts unverändert. Legendeneintrag "Einspeisung" mit &#9632;, ein-/ausblendbar.
Bestehende Helfer verwenden: chart_curves, value_range, y_scale. Kein JavaScript, nichts anderes
ändern.

Schreibe einen Plan: welche Methoden du änderst oder neu anlegst und wie du das Ergebnis prüfst
(Desktop-Harness, upload.sh, log.sh, Heap). Frag nach, wenn etwas unklar ist. Noch nichts ändern.
```

*Warum zuerst planen?* Einen falschen Ansatz im Plan zu erkennen kostet eine Minute, im Code einen Upload und
Rückbau.

> **⚠️ Plan ablehnen bei:** eigener Zeichenschleife ausserhalb `send_bars` · Checkboxen oder
> `<script>` (laufen in Tasmota nie) · weiteren Achsen · Funktionen, die nicht in
> `TASMOTA_BERRY_API.md` stehen · Änderungen ausserhalb der Aufgabe. Im plan-Agent bleiben,
> Vorgabe zitieren, neuen Plan verlangen.

</details>

<details>
<summary><b>1.2 Umsetzen lassen</b> 🟢</summary>

> **🟢 BUILD** – `Shift+Tab`, bis unten `Build` steht. Prompt einfügen.

```
Setze den Plan um, in dieser Reihenfolge:
1. Änderung in app/spot.be.
2. cd app && berry desktop_harness.be – muss mit HARNESS OK enden.
3. ./upload.sh app/spot.be, danach ./log.sh. Jede Zeile mit BRY: oder SPOT: wörtlich zeigen.
4. ./brcmd.sh 'tasmota.gc()' und ./brcmd.sh 'tasmota.memory("heap_free")', Heap melden.
Melde in fünf Zeilen: was geändert, was geprüft, was offen. Die WebUI prüfe ich selbst.
```

Shell-Befehle einzeln freigeben, nur `./upload.sh`, `./log.sh`, `./brcmd.sh`, `berry`, `cp`, `git`.

*Warum Harness zuerst und feste Reihenfolge?* Der Harness findet Syntaxfehler in Sekunden ohne Gerät; die feste Reihenfolge
verhindert übersprungene Prüfungen.

> **⚠️** Agent antwortet nur mit Text: noch plan aktiv, auf build schalten. Aufs Gerät gehört
> nur `app/spot.be`. Kein `BrRestart`/`Restart` über `brcmd.sh`.

</details>

<details>
<summary><b>1.3 Log lesen, Fehler zurückgeben</b> 🟢</summary>

Ausgabe von `./log.sh` selbst lesen:

- **`BRY:`** – Berry konnte die App nicht laden oder ausführen (Syntax, strict mode), meist mit
  Zeilennummer.
- **`SPOT:`** – die App hat in einem Callback einen Fehler abgefangen (`SPOT: page_svg …`).
- Keines von beiden: App geladen, weiter bei 1.4.

> **🟢 BUILD** – nicht umschalten. Fehlerzeilen wörtlich zurückgeben.

```
./log.sh zeigt nach dem Upload:
<Zeilen wörtlich einfügen>
Behebe nur diesen Fehler, lade neu hoch und lies das Log erneut.
```

*Warum Log lesen und wörtlich zurückgeben?* `upload.sh` meldet `OK`, sobald die Datei auf dem Gerät liegt; ob Berry sie laden
konnte, steht nur im Log. Aus der wörtlichen Meldung findet der Agent die Stelle, aus «geht
nicht» rät er.

> **⚠️** `BRY:`-Fehler direkt beim Laden: oft fehlendes `var` (strict mode). Zweimal derselbe
> Fehler: anhalten, Kursleitung fragen oder Checkpoint nehmen.

</details>

<details>
<summary><b>1.4 Resultat prüfen</b></summary>

```sh
./brcmd.sh 'tasmota.cmd("SpotStatus")'            # HeapFree nahe Ausgangswert
./brcmd.sh 'tasmota.gc()'; ./brcmd.sh 'tasmota.memory("heap_free")'   # > 100 kB
```

Browser: Seite **neu laden** (sonst fehlen Chart oder Cursor). Erwartet:

- Grüne Balken mit Tageskurve (Sim: Maximum um 12:40, Sockel 0.075 kWh/¼ h).
- Achse links in kWh, Preisachse rechts unverändert, Legende mit «Einspeisung».
- Summe der Balken ≈ «Einspeisung heute» in der Kopfzeile.

*Warum Heap?* Nur ~110 kB RAM frei. Jeder Upload kostet ~1 kB; fällt der Wert stärker, ist die
Änderung schuld.

> **⚠️ Das Resultat kann falsch sein, auch wenn alles «OK» meldet.** `HARNESS OK` und ein
> sauberes Log beweisen nur, dass der Code läuft, nicht, dass er richtig rechnet. Typisch:
> **falsche Skala** (Balken mit Preis-Skala gezeichnet und nur 1–2 Pixel hoch; Achse zeigt «30»
> statt «0.30» kWh; Balkenhöhe passt nicht zur Achse).
>
> **Selbst nachrechnen:** Höchster Balken = Zahl oben an der kWh-Achse? Sockel ≈ 0.075 kWh?
> Summe ≈ «Einspeisung heute»? Stimmt eine Zahl nicht: mit konkreten Werten zurück an den
> Agenten (🟢 BUILD).

</details>

<details>
<summary><b>1.5 Stand sichern</b></summary>

```sh
cp app/spot.be spot_schritt1.be      # oder: git add app/spot.be && git commit -m "Schritt 1"
```

*Warum sichern?* Rückweg, wenn Schritt 2 schiefgeht, und Vergleich per `diff`.

Hängen geblieben? `cp app/steps/spot_1.be app/spot.be && ./upload.sh app/spot.be`

</details>

</details>

## Schritt 2 – Negativpreis hervorheben (Pflicht, ~15 min)

**Ziel:** Die App zeigt, wann Einspeisen Geld kostet: Balken orange bei Preis < 0, Bereich unter
0 Rp. schattiert.

<details open>
<summary><b>Schritt 2 – Anleitung</b> (zuklappen, wenn erledigt)</summary>

![Ziel Schritt 2: orange Balken bei Preis < 0, Bereich unter 0 schattiert](docs/steps/schritt_2.png)

<details>
<summary><b>2.1 Planen lassen</b> 🔵</summary>

> **🔵 PLAN** – zurück auf plan: `Shift+Tab`, bis unten `Plan` steht. Prompt einfügen.

```
Lies in @app/spot.be den Abschnitt "F3  Chart" mit dem Kommentar "ERWEITERUNGSPUNKT Schritt 2".

Aufgabe: Energie-Balken in Slots mit negativem Preis orange (COL_NEG) statt grün. Bereich unter
der Nulllinie halbtransparent schattieren mit Text "negativer Preis", nur wenn der Tag negative
Preise hat. Legendeneintrag "Einspeisung bei Preis < 0" in Orange.

Nichts anderes ändern. Nenne im Plan, wie du prüfst, dass orange Balken genau bei negativem
Preis erscheinen (der Simulator liefert heute ein Mittagstief < 0). Noch nichts ändern.
```

*Warum ein Testfall im Prompt?* «Orange genau dort, wo der Preis < 0 ist» kann der Agent
prüfen, «mach es orange» nicht.

> **⚠️ Plan ablehnen bei:** zweiter Balken-Methode statt Farbwahl in `send_bars` · Checkboxen,
> `<script>`, weiteren Achsen · Prüfung über `SpotPrices` (zeigt nur die nächsten 10 h).

</details>

<details>
<summary><b>2.2 Umsetzen lassen</b> 🟢</summary>

> **🟢 BUILD** – `Shift+Tab`, bis unten `Build` steht. Gleicher Prompt wie in Schritt 1.

```
Setze den Plan um, in dieser Reihenfolge:
1. Änderung in app/spot.be.
2. cd app && berry desktop_harness.be – muss mit HARNESS OK enden.
3. ./upload.sh app/spot.be, danach ./log.sh. Jede Zeile mit BRY: oder SPOT: wörtlich zeigen.
4. ./brcmd.sh 'tasmota.gc()' und ./brcmd.sh 'tasmota.memory("heap_free")', Heap melden.
Melde in fünf Zeilen: was geändert, was geprüft, was offen. Die WebUI prüfe ich selbst.
```

*Warum derselbe Prompt?* Gleiche Meldung bei jedem Schritt: du siehst sofort, wenn eine Prüfung
fehlt.

> **⚠️ Scope-Creep** («bei der Gelegenheit habe ich auch …»): «nichts anderes ändern»
> wiederholen, mit `/undo` zurücknehmen.

</details>

<details>
<summary><b>2.3 Log lesen, Fehler zurückgeben</b> 🟢</summary>

`./log.sh` lesen. Zeile mit `BRY:` oder `SPOT:`-Fehler:

> **🟢 BUILD** – nicht umschalten. Fehlerzeilen wörtlich zurückgeben.

```
./log.sh zeigt nach dem Upload:
<Zeilen wörtlich einfügen>
Behebe nur diesen Fehler, lade neu hoch und lies das Log erneut.
```

*Warum «nur diesen Fehler»?* Sonst baut der Agent bei der Fehlersuche weiteres um.

> **⚠️** Zweimal derselbe Fehler: `cp spot_schritt1.be app/spot.be`, neu planen.

</details>

<details>
<summary><b>2.4 Resultat prüfen</b></summary>

```sh
./brcmd.sh 'tasmota.cmd("SpotStatus")'            # HeapFree nahe Ausgangswert
./brcmd.sh 'tasmota.gc()'; ./brcmd.sh 'tasmota.memory("heap_free")'   # > 100 kB
diff spot_schritt1.be app/spot.be | head -40      # wenige Stellen (oder git diff --stat)
```

Browser: Seite **neu laden**. Erwartet:

- Orange Balken genau dort, wo die Preislinie unter 0 liegt (Sim: Mittagstief), sonst grün.
- Schattierung mit Text «negativer Preis» unter der Nulllinie, Legendeneintrag in Orange.
- Balkenhöhen wie nach Schritt 1.

*Warum der `diff`?* Er zeigt, was der Agent wirklich geändert hat, unabhängig von seiner Meldung.

</details>

<details>
<summary><b>2.5 Stand sichern</b></summary>

```sh
cp app/spot.be spot_schritt2.be      # oder: git add app/spot.be && git commit -m "Schritt 2"
```

Hängen geblieben? `cp app/steps/spot_2.be app/spot.be && ./upload.sh app/spot.be`

</details>

</details>

**Pflichtteil geschafft.** Ablauf ab jetzt: 🔵 planen → Plan prüfen → 🟢 umsetzen → Log lesen →
Heap und WebUI prüfen → sichern.

## Schritt 3 – 3 Tage mit Stundenwerten (für Schnelle, ~20 min)

**Ziel:** Die App zeigt den ganzen Speicher: 3 Tage nebeneinander mit Stundenwerten und
Tagesnamen («Do 11.06.»).

<details>
<summary><b>Schritt 3 – Anleitung aufklappen</b></summary>

![Ziel Schritt 3: 3 Tage mit Stundenwerten und Tagesnamen](docs/steps/schritt_3.png)

> **🔵 PLAN** – Prompt einfügen. Plan prüfen: jede geänderte Methode aufgelistet, keine Kopien,
> Heap-Messung vorher/nachher.

```
Lies in @app/spot.be den Abschnitt "F3  Chart" mit dem Kommentar "ERWEITERUNGSPUNKT Schritt 3".

Aufgabe: Das Chart zeigt 3 Tage mit 72 Stundenwerten statt einem Tag mit 96 Viertelstunden.
Stundenwert: Preis = Mittel, Energie = Summe der 4 Viertelstunden, Lücke wenn alle 4 fehlen.
Stundenwerte einmal pro page_svg-Aufruf in feste bytes-Puffer rechnen (fill_hours), nicht pro Kurve.
x-Achse mit gestrichelten Tagesgrenzen, Marken 00 und 12, Tagesname mit Datum ("Do 11.06.").
"jetzt"-Marke über alle 3 Tage richtig. Orange-Regel aus Schritt 2 pro Stunde.

Baue die bestehenden Methoden um (Bereich als Parameter), kopiere sie nicht. Miss den Heap vor
und nach der Änderung (tasmota.gc(), dann heap_free). Liste im Plan jede Methode auf, die du
änderst, und warum. Noch nichts ändern.
```

> **🟢 BUILD** – wie in Schritt 1–2: «umsetzen» → Log → Heap und WebUI → sichern
> (`cp app/spot.be spot_schritt3.be`).

**Erwartet:** 3 Tage, Tagesnamen, 72 Balken, Preislinie in Stundenstufen. Heap höchstens ~2 kB
tiefer als vorher.

> **⚠️ Kopieren statt umbauen** (`send_x_axis_3d`, `value_range2`): «Bau die bestehende Methode
> um, lösche die Kopie.»

<details>
<summary>Vorgaben im Detail</summary>

- 72 Werte. Stundenwert: Preis = **Mittel**, Energie = **Summe** der 4 Viertelstunden. Fehlen
  alle 4 Werte: Lücke. Stundenwerte **einmal pro Aufruf** von `page_svg` (Handler `/spot.svg`) rechnen
  (`fill_hours(start)` in feste `bytes`-Puffer), Kurven lesen sie mit `hour_p(i)`/`hour_e(i)`.
  Grund: 72 × 4 Store-Zugriffe pro Kurve überschreiten sonst die 50-ms-Grenze.
- x-Achse: Tagesgrenzen gestrichelt, Marken 00 und 12, Tagesname mit Datum unter jedem Tag.
- «jetzt»-Marke an der richtigen Stunde über alle 3 Tage (ältester Tag links; ab ~17 Uhr ist der
  jüngste Tag morgen).
- Orange-Regel aus Schritt 2 gilt pro Stunde (Stundenpreis < 0).
- Bestehende Methoden umbauen, nicht kopieren: `value_range`, `send_polyline`, `send_bars`,
  `send_x_axis` bekommen den Bereich (Starttag, Anzahl Werte) als Parameter.
- **Heap**: vor und nach der Änderung `tasmota.gc()` + `heap_free` messen, Differenz melden.
  Mehr als 5 kB Einbruch beim Rendern: anhalten.

</details>

<details>
<summary>Prompts «umsetzen» und «Fehler zurückgeben», Checkpoint</summary>

```
Setze den Plan um, in dieser Reihenfolge:
1. Änderung in app/spot.be.
2. cd app && berry desktop_harness.be – muss mit HARNESS OK enden.
3. ./upload.sh app/spot.be, danach ./log.sh. Jede Zeile mit BRY: oder SPOT: wörtlich zeigen.
4. ./brcmd.sh 'tasmota.gc()' und ./brcmd.sh 'tasmota.memory("heap_free")', Heap melden.
Melde in fünf Zeilen: was geändert, was geprüft, was offen. Die WebUI prüfe ich selbst.
```

```
./log.sh zeigt nach dem Upload:
<Zeilen wörtlich einfügen>
Behebe nur diesen Fehler, lade neu hoch und lies das Log erneut.
```

Hängen geblieben? `cp app/steps/spot_3.be app/spot.be && ./upload.sh app/spot.be`

</details>

</details>

## Schritt 4 – Vergütungs-Chart (für Schnelle, ~15 min)

**Ziel:** Die App zeigt, was die Einspeisung einbringt: zweites, flaches Chart «Vergütung CHF/h»
mit Summe Σ über die 3 Tage. Damit ist das Zielbild erreicht.

<details>
<summary><b>Schritt 4 – Anleitung aufklappen</b></summary>

![Ziel Schritt 4: zweites Chart Vergütung CHF/h mit Summe](docs/steps/schritt_4.png)

> **🔵 PLAN** – Prompt einfügen. Plan prüfen: nennt er, was er wiederverwendet (`fill_hours`,
> Zeichenmethoden) und was neu ist?

```
Lies in @app/spot.be den Abschnitt "F3  Chart" mit dem Kommentar "ERWEITERUNGSPUNKT Schritt 4".

Aufgabe: Unter dem Chart ein zweites, flaches Chart "Vergütung CHF/h": pro Stunde Summe aus
Preis × Energie der 4 Viertelstunden, Balken gelb (COL_PAY) bei >= 0, rot (COL_COST) bei < 0,
Achse links in CHF, Summe "Σ x.xx CHF" oben rechts über die 3 Tage. Gleiche x-Positionen wie
oben, "jetzt"-Marke auch unten.

Verwende die Stundenwert-Hilfsmethode aus Schritt 3 und die bestehenden Zeichenmethoden weiter.
Sende stückweise mit tasmota.web_send. Nenne im Plan, welche Methoden du wiederverwendest und
welche neu sind. Noch nichts ändern.
```

> **🟢 BUILD** – wie in Schritt 1–2: «umsetzen» → Log → Heap und WebUI → sichern
> (`cp app/spot.be spot_schritt4.be`).

**Erwartet:** Zielbild `docs/zielbild.jpg`: zwei Charts, Stunden übereinander, Σ = «Vergütung
heute» + Vortage. Heap > 100 kB.

> **⚠️** Neue Schleife für die Vergütung statt Mitrechnen in `fill_hours`, oder kopierte
> Zeichenmethoden fürs zweite Chart: ablehnen.

<details>
<summary>Vorgaben im Detail</summary>

- Vergütung pro Stunde = Summe über die 4 Viertelstunden von Preis × Energie. In `fill_hours` aus
  Schritt 3 mitrechnen (dritter Puffer, `hour_v(i)`), nicht neu schleifen.
- Balken gelb (`COL_PAY`) bei ≥ 0, rot (`COL_COST`) bei < 0. Nulllinie, Achse links mit Max/0/Min
  in CHF. Text «negativ = Einspeisung kostet» unten links, nur wenn es negative Werte gibt.
- Titel «Vergütung CHF/h» links, «Σ x.xx CHF» rechts.
- Gleiche x-Positionen wie oben (Stunde n liegt in beiden Charts übereinander), «jetzt»-Marke auch
  unten.
- Stückweise senden wie das obere Chart (`tasmota.web_send` pro Teil), kein Gesamtstring.
- Rendering ohne Heap-Einbruch > 5 kB.

</details>

<details>
<summary>Prompts «umsetzen» und «Fehler zurückgeben», Checkpoint</summary>

```
Setze den Plan um, in dieser Reihenfolge:
1. Änderung in app/spot.be.
2. cd app && berry desktop_harness.be – muss mit HARNESS OK enden.
3. ./upload.sh app/spot.be, danach ./log.sh. Jede Zeile mit BRY: oder SPOT: wörtlich zeigen.
4. ./brcmd.sh 'tasmota.gc()' und ./brcmd.sh 'tasmota.memory("heap_free")', Heap melden.
Melde in fünf Zeilen: was geändert, was geprüft, was offen. Die WebUI prüfe ich selbst.
```

```
./log.sh zeigt nach dem Upload:
<Zeilen wörtlich einfügen>
Behebe nur diesen Fehler, lade neu hoch und lies das Log erneut.
```

Hängen geblieben? `cp app/steps/spot_4.be app/spot.be && ./upload.sh app/spot.be`

</details>

</details>

## Schritt 5 – 2 Tage mit Viertelstunden (für Fortgeschrittene, ~25 min)

**Ziel:** Die App zeigt die Preise so fein, wie BKW sie publiziert: beide Charts mit 2 Tagen zu
je 96 Viertelstunden, Preis als Treppe.

Voraussetzung: Schritt 4 fertig, sonst `cp app/steps/spot_4.be app/spot.be && ./upload.sh app/spot.be`.

<details>
<summary><b>Schritt 5 – Anleitung aufklappen</b></summary>

![Ziel Schritt 5: 2 Tage mit 192 Viertelstunden, Preis als Treppe](docs/steps/schritt_5.png)

> **🔵 PLAN** – Prompt einfügen. Plan prüfen: jede geänderte Methode genannt, Konstanten statt
> Zahlen, Messung von SVG-Grösse, Laufzeit und Heap.

```
Lies in @app/spot.be den Abschnitt "F3  Chart" mit dem Kommentar "ERWEITERUNGSPUNKT Schritt 5".

Aufgabe: Beide Charts zeigen 2 Tage mit je 96 Viertelstunden (192 Werte) statt 3 Tage mit
Stundenwerten. Tage: gestern + heute; sobald Preise für morgen da sind, heute + morgen (chart_start).
Neue Konstanten CH_DAYS = 2 und CH_Q = 1 (Viertelstunden pro Wert), CH_N = 192, CH_MIN = 15; keine
dieser Zahlen fest im Chart-Code. fill_hours wird fill_values und rechnet CH_Q Viertelstunden pro Wert.
Preis als Treppenlinie (jeder Wert waagrecht über seine Breite) in send_polyline. send_bars sendet
Pfade ab 600 Byte in Stücken. x-Achse pro Tag 00/06/12/18, data-d pro Tag, unten "CHF/¼h".

Baue die bestehenden Methoden um, kopiere sie nicht. Nenne im Plan jede geänderte Methode und
wie du SVG-Grösse (Desktop-Harness), Laufzeit von fill_values (tasmota.millis() mit brcmd.sh) und
Heap misst. Noch nichts ändern.
```

> **🟢 BUILD** – wie in Schritt 1–2: «umsetzen» → Log → Heap und WebUI → sichern
> (`cp app/spot.be spot_schritt5.be`).

**Erwartet:** 2 Tage, 192 schmale Balken, Preis als Treppe mit ¼-h-Stufen. Vor 17 Uhr gestern +
heute, danach heute + morgen. Agent meldet SVG-Bytes, ms und Heap.

> **⚠️** Zahlen statt Konstanten: Gegenprobe mit `CH_DAYS = 3`, `CH_Q = 4`, `CH_N = 72`,
> `CH_MIN = 60` verlangen (muss Chart aus Schritt 4 ergeben). Zweite Zeichenmethode für die
> Treppe: ablehnen.

<details>
<summary>Hintergrund, Vorgaben und Referenzwerte</summary>

Hintergrund: BKW publiziert inzwischen **verschiedene Preise pro Viertelstunde** (z.B.
16 Uhr: 32.8 / 34.4 / 46.5 / 48.9 Rp.). Das Stundenmittel aus Schritt 3
glättet die Spitzen weg (Mittel 40.6 Rp.). Die Daten im Speicher sind schon Viertelstunden, nur
die Darstellung fasst zusammen.

- Tage: **gestern (Verlauf) + heute**; sobald Preise für morgen da sind (BKW ab ca. 17 Uhr),
  **heute + morgen**. In `chart_start`.
- Neue Konstanten `CH_DAYS = 2` und `CH_Q = 1` (Viertelstunden pro Wert), dazu `CH_N = 192`,
  `CH_MIN = 15`. Keine 2, 96, 192 oder 24 mehr als Zahl im Chart-Code.
- `fill_hours` umbauen (umbenennen in `fill_values`, `hour_*` in `val_*`): `CH_Q` Viertelstunden pro Wert;
  Preis = Mittel, Energie und Vergütung = Summe wie bisher.
- Preis als **Treppenlinie**: jeder Wert waagrecht über seine ganze Breite (`send_polyline`
  umbauen, keine zweite Zeichenmethode).
- `send_bars` sendet einen Pfad, sobald er `PATH_MAX` (600) Byte lang ist, und beginnt einen neuen.
  Grund: 192 Balken ergäben ~3 kB pro Pfad-String.
- x-Achse pro Tag: Marken 00/06/12/18, Tagesname; `data-d` mit einem Eintrag pro Tag. Unteres
  Chart: «Vergütung CHF/¼h». Cursor zeigt die Viertelstunde (`data-m` = 15).
- **Kosten messen und melden**: Grösse von `/spot.svg` im Desktop-Harness (`SVG … bytes`),
  Laufzeit von `fill_values` auf dem Gerät, Heap vor/nach. Grenzen: SVG < 16 kB, Heap > 100 kB.
- Referenzwerte (`app/steps/spot_5.be`): Harness `SVG … bytes = 12204` (Schritt 4: 7010),
  `fill_values` 57 ms auf dem C3, Heap 111 kB stabil nach mehrfachem Rendern.

</details>

<details>
<summary>Prompts «umsetzen» und «Fehler zurückgeben»</summary>

```
Setze den Plan um, in dieser Reihenfolge:
1. Änderung in app/spot.be.
2. cd app && berry desktop_harness.be – muss mit HARNESS OK enden.
3. ./upload.sh app/spot.be, danach ./log.sh. Jede Zeile mit BRY: oder SPOT: wörtlich zeigen.
4. ./brcmd.sh 'tasmota.gc()' und ./brcmd.sh 'tasmota.memory("heap_free")', Heap melden.
Melde in fünf Zeilen: was geändert, was geprüft, was offen. Die WebUI prüfe ich selbst.
```

```
./log.sh zeigt nach dem Upload:
<Zeilen wörtlich einfügen>
Behebe nur diesen Fehler, lade neu hoch und lies das Log erneut.
```

</details>

</details>

## Bonus (wer fertig ist)

<details>
<summary>Zwei Ideen: CSV mit Stundenwerten, Schwellwert an Shelly/MQTT</summary>

- **CSV mit Stundenwerten**: zusätzlich zur Tageszeile `spot_h_YYYY-MM.csv`, Aufbewahrung zwei
  Monate. Erweiterungspunkt `cfg["csv_hourly"]` und `day_end()`. Lehrt: Testbarkeit einfordern
  (Funktion mit Datums-Parameter verlangen).
- **Schwellwert an Shelly/MQTT**: bei Preis unter/über Schwelle ein HTTP-schaltbares Gerät
  schalten oder per `mqtt.publish` melden. Erweiterungspunkt `json_append()` / neuer Command. Lehrt:
  Drittsystem-API als Kontext geben (Shelly-Doku-Auszug), sonst rät der Agent.

</details>

## Checkliste Abschlussrunde

Ergebnisse zeigen ist Teil des Abschlusses (15 min): 2–3 Teilnehmende zeigen kurz, je ca. 3 min.

- Der Prompt, der funktioniert hat (wörtlich).
- Der Prompt, der schiefging, und was der Agent daraus gemacht hat.
- Anzahl Upload-Zyklen und erreichter Schritt.
- `HeapFree` am Anfang und am Ende.
