# Legende

Begriffe und Abkürzungen aus dem Workshop. Weitere Fachbegriffe (BKW-API, Tarife, Zeit): `INTENT.md` §8.

| Begriff | Bedeutung |
|---|---|
| **gPlug** | Kleiner Adapter für den Smart-Meter-Anschluss (P1/HAN), läuft mit Tasmota auf einem ESP32-C3. |
| **Tasmota** | Offene Firmware für ESP-Geräte, mit WebUI, Konsole und Berry-Skripten. |
| **ESP32-C3** | Mikrocontroller im gPlug (WLAN, wenig RAM, ca. 120 kB frei). |
| **Berry** | Kleine Skriptsprache in Tasmota; die App `app/spot.be` ist in Berry geschrieben. |
| **WebUI** | Weboberfläche des Geräts unter `http://<gplug-ip>`. |
| **Smart Meter** | Elektronischer Stromzähler mit Datenschnittstelle. |
| **SML** | Smart Message Language, Protokoll, über das der gPlug den Zähler ausliest. |
| **UFS** | Micro File System: Dateisystem im Flash des Geräts (für Skripte und CSV). |
| **OTA** | Over-the-Air: Firmware-Update per WLAN statt per Kabel. |
| **Heap / `HeapFree`** | Freier Arbeitsspeicher des Geräts. Soll über 100 kB bleiben. |
| **BKW** | Energieversorger, dessen API die dynamischen Einspeisetarife liefert. |
| **Einspeisetarif / Spotpreis** | Vergütung pro kWh für ins Netz eingespeisten Strom, hier pro Viertelstunde. |
| **Einspeisung** | Ins Netz abgegebene Energie (Export-Zählerstand `z.Eo`). |
| **Vergütung** | Einspeisung × Tarif, in CHF. |
| **kWh** | Kilowattstunde, Einheit der Energie. |
| **¼-h / Viertelstunde** | Zeitraster der Preise und Messwerte (96 Werte pro Tag). |
| **Slot** | Ein Viertelstunden-Eintrag im Speicher. |
| **Simulator (`sim`)** | Erzeugt Testwerte, wenn kein Smart Meter angeschlossen ist. |
| **Zeitraffer** | Simulator-Takt (`sim_tick`, 5/15/60 min): pro Takt rückt die Sim-Zeit eine ¼ h vor, das Chart füllt sich schneller. |
| **CSV** | Textdatei mit Semikolon-getrennten Werten, eine Zeile pro Tag. |
| **SVG** | Vektorgrafik; das Tageschart wird als SVG in die WebUI gezeichnet. |
| **JSON** | Textformat für Daten, z.B. die BKW-Antwort und Befehlsresultate. |
| **API** | Programmierschnittstelle, hier die BKW-Tarifabfrage und die Tasmota-Berry-API. |
| **Telemetrie / Tele** | Periodische Statusmeldung des Geräts als JSON. |
| **Command** | Tasmota-Befehl, z.B. `SpotStatus`; in der Konsole oder per `brcmd.sh`. |
| **`BrRestart`** | Tasmota-Befehl, der die Berry-Umgebung neu startet und `autoexec.be` lädt. |
| **`autoexec.be`** | Startskript, das beim Start `load("spot")` ausführt. |
| **Erweiterungspunkt** | Kommentar `# ERWEITERUNGSPUNKT` in `spot.be`: hier hängt die Übung an. |
| **Starter** | Ausgangsstand der Übung in `app/spot.be`: Chart zeigt nur die Spotpreis-Linie eines Tages. |
| **Referenz-App** | Endstand nach Schritt 4: 3 Tage, Einspeisung, Negativpreise, Vergütungs-Chart (`app/steps/spot_4.be`). |
| **Checkpoint** | Fertiger Stand nach einem Schritt (`app/steps/spot_N.be`), zum Aufholen nach `app/spot.be` kopieren. |
| **Coding-Agent** | KI-Assistent, der Code liest, ändert und Werkzeuge (Shell, Dateien) aufruft. |
| **opencode** | Open-Source-Coding-Agent, der im Workshop verwendet wird. |
| **TUI** | Text User Interface: Bedienoberfläche im Terminal, hier die von opencode. |
| **`plan`- / `build`-Agent** | Modi in opencode: `plan` plant nur und ändert nichts, `build` setzt um. Wechsel mit `Shift+Tab`. |
| **LLM** | Large Language Model, das Sprachmodell hinter dem Agenten (hier Qwen3.5 122B-A10B). |
| **Prompt** | Eingabe/Anweisung an das Sprachmodell. |
| **Infomaniak AI Tools** | Schweizer Dienst, der das LLM bereitstellt; Zugang per Product-ID und API-Token. |
| **API-Token** | Geheimer Schlüssel für den Zugang zu einem Dienst. Nie committen. |
| **Docker / Container** | Isolierte Laufumgebung; der Agent sieht darin nur den Projektordner. |
| **WSL / Ubuntu** | Windows-Subsystem für Linux: Ubuntu-Terminal unter Windows, darin gelten die Linux-Befehle der Unterlagen. |
| **Sandbox** | Abgeschirmte Umgebung, die den Agenten auf den Projektordner beschränkt. |
| **`AGENTS.md`** | Regeldatei, die der Coding-Agent automatisch liest. |
| **Desktop-Harness** | Test auf dem PC mit dem Berry-Interpreter, ohne Gerät (`HARNESS OK`). |
| **git / Commit** | Versionsverwaltung / gesicherter Stand der Änderungen. |
| **WLAN / IP** | Funknetz / Netzwerkadresse des Geräts, steht in `.gplug`. |
| **Abschlussrunde** | Ende der Übung: alle berichten kurz Prompt, Stolpersteine, Uploads und `HeapFree` (Checkliste in `EXERCISES.md`). |
