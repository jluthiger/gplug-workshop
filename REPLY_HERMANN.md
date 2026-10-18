Lieber Hermann

Danke für die konkretisierte Feature-Liste und die Angaben zum Anlass. Die Anforderungen sind in ein Intent-Dokument übersetzt, die BKW-API und die Tasmota-Berry-Umgebung geprüft und ein Vorbereitungsplan für den Workshop skizziert. Hier die wichtigsten Punkte, am Schluss die offenen Fragen.

**1. BKW-API**

- Endpoint liefert 96 Viertelstundenwerte, 21 kB JSON, ohne Auth. Zeitstempel in UTC; «22–22 Uhr» ist der lokale Kalendertag.
- Der Endpoint akzeptiert laut Swagger-Spezifikation keine Parameter. Der Folgetag lässt sich also nicht anfordern; es muss abgefragt werden, bis die Serie serverseitig wechselt. Eine Messung am 18.10. mit Abrufen alle 30 Minuten zeigt den Wechsel auf den Folgetag zwischen 16:33 und 17:03 Uhr. Danach liefert der Endpoint nur noch den Folgetag, der laufende Tag ist nicht mehr abrufbar. Die App ruft deshalb ab 17:15 Uhr mehrfach ab, bis die neue Serie da ist. Die Messung stammt von einem Sonntag und wird an einem Werktag wiederholt.
- Wichtig aus der Spezifikation: fehlende Werte werden weggelassen, die Antwort kann also weniger als 96 Einträge enthalten. Die App ordnet jeden Wert über seinen eigenen Zeitstempel zu, nicht per Zählung.
- Das Schema folgt dem VSE-Standard für dynamische Tarife. Andere EVU mit dynamischem Tarif dürften dasselbe Format liefern. Das stützt die Idee einer zweiten App für Bezugstarife: Es wäre im Wesentlichen ein anderer Adapter, der Rest bleibt gleich.
- ENTSO-E direkt ist auf dem ESP32 nicht praktikabel (Token, XML, mehrere hundert kB). Der BKW-Endpoint basiert auf ENTSO-E Day-Ahead, enthält aber die BKW-Vergütungslogik, also nicht den rohen Spotpreis.

**2. Speicher und Parsing**

Die 21 kB JSON werden nicht als Map geladen (das wäre ein Vielfaches an RAM), sondern direkt im String nach Zeitstempel und Wert durchsucht. Die Preise liegen als 2-Byte-Integer in einem festen Puffer (3 × 100 Slots, wegen Sommer-/Winterzeit-Tagen mit 92 bzw. 100 Viertelstunden). Nach dem Parsen wird der String freigegeben. Heap vor und nach dem Abruf wird geloggt, das ist ein Abnahmekriterium.

**3. Scope und Reihenfolge**

Mit rund 20 Stunden lässt sich nicht alles in gleicher Tiefe bauen, und am Workshop-Abend bleiben realistisch 3 Stunden, davon mindestens eine für Setup. Vorschlag:

- Referenz-App (fertig vor dem Workshop): Preisabruf, Zählererfassung mit Simulator, Tasmota-Command «SpotPrices», Grafik des aktuellen Tages (96 Werte), Tageszeile in der Monats-CSV.
- Teilnehmer-Übungen mit dem Coding-Agenten: dritte Kurve oder 3-Tage-Ansicht, Stunden-CSV mit Aufbewahrung, optional Shelly schalten oder MQTT-Publish.

Die Übungen verändern den Datenfluss nicht, nur Darstellung und Ablage. Wenn etwas schiefgeht, bleibt der Kern intakt. Der Plan geht davon aus, dass das Arbeiten mit einem Coding-Agenten auf einem Embedded-Gerät der Hauptfokus des Abends ist und die Berry-App das Übungsobjekt (siehe Frage 1). Deshalb wird die Referenz-App selbst mit dem Agenten gebaut und der Verlauf als Demo-Material aufbewahrt: ein guter Prompt, ein Fehlversuch, die Korrektur durch Kontext.

**4. Sandbox**

Der Agent muss das gPlug im Workshop-WLAN erreichen, um Code hochzuladen und die Konsole zu lesen. Aus der Cloud geht das nicht. Der Agent läuft deshalb lokal auf dem Notebook. Vorschlag: opencode.ai nativ installiert, Arbeitsverzeichnis auf den Workshop-Ordner begrenzt, Berechtigungen über die opencode-Konfiguration. Docker bleibt als Option für Teilnehmende, die echte Isolation wollen oder Docker schon haben. Die Anforderung «kein Zugriff auf das ganze Notebook» ist nur mit Docker vollständig erfüllt; die native Variante begrenzt den Agenten auf das Verzeichnis, nicht auf OS-Ebene. Infomaniak wird als Provider im Repo vorkonfiguriert und vorher getestet, ob das Modell mit Berry zurechtkommt; sonst braucht es ein Fallback-Modell.

**5. Teilnehmer bringen eigenen gPlug**

Gut, dass Berry, UFS und SML auf allen Webshop-Geräten aktiv sind. Zwei Folgen: Erstens gilt Tasmota 15.3.0 als Mindestversion; ältere Geräte machen das OTA-Upgrade als Hausaufgabe, weil die Berry-API zwischen Releases ändert. Zweitens gibt es vor Ort keinen Smart Meter, daher wird ein Zähler-Simulator mitgeliefert, damit sich die Grafik am Abend füllt. Die Geräte müssen ins Workshop-WLAN und danach zurück ins Heim-WLAN; das kommt in die Anleitung.

**6. Offene Fragen**

Vorab die Lesart von «Vergütung/Kosten»: eine Grösse, Preis mal Einspeisung pro Viertelstunde; bei negativem Preis wird sie negativ, das sind die Kosten. Der Bezug wird nicht erfasst. Bitte melden, falls das anders gemeint ist. Die Energiemenge wird mit 0.01 kWh statt 0.1 kWh Auflösung gespeichert: gleicher Speicherbedarf, aber Anlagen unter 400 W würden sonst in der Grafik nur zwischen 0 und 0.1 springen; die Tagessumme ist bei beiden Varianten gleich genau.

1. Hauptfokus: Ist «Arbeiten mit einem Coding-Agenten auf einem Embedded-Gerät» der Hauptfokus des Workshops, mit der Berry-App als Übungsobjekt? Zeitplan, Übungen und Demo-Material sind darauf ausgelegt; wäre der Fokus die App selbst, müsste der Abend anders aufgebaut werden.
2. Reboot: Vorschlag ist, nur Zählerstand und Tagessumme zu persistieren; die Grafik ist nach Neustart bis zum nächsten Preisabruf leer. Einverstanden?
3. Fehlende Preise: Slot leer lassen (Vorschlag) oder Vorstundenwert übernehmen?
4. WLAN bei Glue: Da die Infrastruktur dort bekannt ist, bitte kurz bestätigen, dass das Gäste-WLAN rund 50 Clients (20 gPlugs + Notebooks) verkraftet, kein Captive Portal hat (gPlugs können sich sonst nicht anmelden) und ausgehend HTTPS auf api.bkw.ch sowie den LLM-Provider erlaubt. Zudem: Können die Notebooks die gPlugs im selben Netz direkt erreichen (keine Client-Isolation)? Ohne das kann der Agent keinen Code auf das Gerät laden.

**7. Angebot**

Zur Frage, ob die Tasmota-App bis Ende Oktober mit opencode.ai erstellt werden kann: Ja. Die Referenz-App gemäss Punkt 3 wird vollständig mit opencode.ai entwickelt, der Verlauf wird dokumentiert und dient am Workshop als Anschauungsmaterial. Zähler-Simulator, Cheat-Sheet und Agent-Konfiguration entstehen dabei als Nebenprodukt und sind inbegriffen. Die Referenz-App wird als Open-Source-Projekt auf GitHub veröffentlicht; Teilnehmende und bestehende gPlug-Kunden können sie damit direkt beziehen und weiterentwickeln. Das vorgeschlagene Entgelt von 1'000 Fr gegen Rechnung (20 h zu 50 Fr/h) wird angenommen. Lieferung bis Ende Oktober.

Die drei Dokumente (Intent, Tasmota-Berry-Cheat-Sheet für den Agenten, Workshop-Vorbereitung) folgen, sobald die Fragen oben beantwortet sind, dann sind sie konsistent.

Herzliche Grüsse
Jürg
