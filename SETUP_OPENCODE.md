# Setup: opencode mit eigenem Zugang

Für die Arbeit nach dem Workshop: Coding-Agent [opencode](https://opencode.ai) mit einem
Open-Source-Modell von [Infomaniak AI Services](https://www.infomaniak.com/en/hosting/ai-services/open-source-models)
(Verarbeitung in der Schweiz) oder mit Claude von Anthropic. Am Workshop-Tag nicht nötig, der
Zugang steckt dann im Docker-Image. Zeitbedarf ca. 15 min.

Befehle für Linux, macOS und Ubuntu in WSL. Windows mit PowerShell:
[`WINDOWS_POWERSHELL.md`](WINDOWS_POWERSHELL.md).

## 1. Infomaniak AI Tools aktivieren

1. Konto anlegen bzw. einloggen: <https://manager.infomaniak.com>.
2. AI Tools öffnen: <https://manager.infomaniak.com/v3/ng/products/cloud/ai-tools>, Produkt
   bestellen/aktivieren (eines pro Organisation). Neukunden erhalten 1 Mio. Gratis-Credits für
   einen Monat. Eine **Kreditkarte** muss hinterlegt sein, sonst antwortet die API nicht.
   Empfehlung: **Ausgabenlimite** setzen.
3. **Product-ID** notieren: die Zahl in der URL (`…/products/cloud/ai-tools/<PRODUCT_ID>`).

## 2. API-Token erstellen

1. <https://manager.infomaniak.com/v3/ng/profile/user/token/list> → **Token erstellen**.
2. Scope **AI Tools** (`ai-tools`), Gültigkeit nach Bedarf.
3. Token **sofort kopieren**, er wird nur einmal angezeigt.

> **Sicherheit:** Der Token verursacht Kosten. Nie committen, nicht in Chats oder Screenshots
> zeigen. Nicht mehr gebraucht: im Manager widerrufen.

## 3. Zugang testen und Variablen setzen

```sh
export INFOMANIAK_PRODUCT_ID=123456          # eigene Product-ID
export INFOMANIAK_API_KEY=xxxxxxxxxxxxxxxx   # eigener Token

curl -s https://api.infomaniak.com/2/ai/$INFOMANIAK_PRODUCT_ID/openai/v1/models \
  -H "Authorization: Bearer $INFOMANIAK_API_KEY"
```

Erwartet: JSON mit `"data": [...]` und Modell-IDs. `"Invalid Authentication"`: Token oder
Product-ID falsch, oder Kreditkarte fehlt.

`export` gilt nur im aktuellen Terminal, und opencode sieht nur die Variablen des Terminals, aus dem
es startet. Dauerhaft: die zwei `export`-Zeilen ans Ende von `~/.bashrc` anhängen (macOS:
`~/.zshrc`), z.B. mit `nano ~/.bashrc`, dann **neues** Terminal öffnen. Der Token steht danach im
Klartext im Home-Verzeichnis: nur auf dem eigenen Notebook.

Prüfen (zeigt den Token nicht an), erwartet `ID=123456 KEY=gesetzt`:

```sh
echo "ID=$INFOMANIAK_PRODUCT_ID KEY=${INFOMANIAK_API_KEY:+gesetzt}"
```

## 4. opencode starten

**Standard: Docker.** Der Agent sieht nur den Workshop-Ordner. Docker einrichten: `RUNBOOK.md`,
*Was du brauchst*. Im Workshop-Ordner:

```sh
./docker-run.sh             # opencode im Container
./docker-run.sh bash        # Shell im Container, Test: opencode --version → v2.0.32
./docker-run.sh --build     # Image lokal aus dem Dockerfile bauen (2–3 min)
```

Ausserhalb des Workshop-Tags lädt das Skript das Basis-Image ohne Zugang: Variablen aus Schritt 3
müssen gesetzt sein.

Gesetzte `INFOMANIAK_*`-Variablen haben Vorrang vor dem Zugang im Image, `GPLUG` wird
durchgereicht. Sitzungen bleiben im Docker-Volume `gplug-workshop-data`. Im Image sind auch
`berry` (Desktop-Test) und `git`. Das gPlug ist aus dem Container nur über seine **IP** erreichbar
(`.gplug`), `.local`-Namen gehen nicht.

**Ohne Docker** (nur wenn Docker nicht läuft): `curl -fsSL https://opencode.ai/v2/install | bash`
(ohne `/v2` kommt opencode 1.x; bestehendes 1.x: `opencode upgrade --major`), dann im Repo-Ordner
`opencode`. Der Agent sieht dann grundsätzlich das ganze Notebook; `opencode.json` und `AGENTS.md`
begrenzen das, ersetzen die Isolation aber nicht: Shell-Befehle vor dem Bestätigen lesen.

Nach dem Start: unten im TUI steht `Qwen3.5 122B-A10B (Infomaniak AI (Schweiz))`. Erste Frage:
`Lies INTENT.md. Erkläre in 5 Sätzen, was app/spot.be tut.` `AGENTS.md` wird automatisch geladen,
`/init` ist nicht nötig.

| Befehl im TUI | Wirkung |
|---|---|
| `/models` | Modell wechseln |
| `/new` | neue Sitzung (frischer Kontext) |
| `/undo`, `/redo` | letzte Änderung des Agenten zurücknehmen / wiederholen |
| `Shift+Tab` | Agent wechseln: **build** (ändert Dateien) ↔ **plan** (nur lesen/planen) |
| `@datei` | Datei in den Kontext geben, z.B. `@TASMOTA_BERRY_API.md` |

## 5. Provider-Konfiguration

[`opencode.json`](opencode.json) im Repo definiert den Provider `infomaniak`. opencode liest sie
beim Start im Repo-Ordner. Kern davon:

```json
"options": {
  "baseURL": "https://api.infomaniak.com/2/ai/{env:INFOMANIAK_PRODUCT_ID}/openai/v1",
  "apiKey": "{env:INFOMANIAK_API_KEY}"
},
"model": "infomaniak/Qwen/Qwen3.5-122B-A10B-FP8",
"small_model": "infomaniak/mistralai/Ministral-3-14B-Instruct-2512"
```

`{env:…}` liest die Variablen aus Schritt 3, Token und ID stehen nie in der Datei. `small_model`
erledigt Nebenaufgaben (Sitzungstitel). Der Block `permission` erlaubt Edits im Repo, fragt bei
Shell-Befehlen nach und verbietet `rm`, `sudo` und Zugriffe ausserhalb. Token alternativ in
opencode: `/connect` → **Other** → `infomaniak`; `INFOMANIAK_PRODUCT_ID` braucht es weiterhin.

## 6. Modell wählen

Wichtig für Agenten ist zuverlässiges **Tool Calling**. Preise pro 1 Mio. Tokens (in/out) laut
[models.dev](https://models.dev), Stand Oktober 2026.

| Modell-ID | Kontext | Preis in/out | Einsatz |
|---|---|---|---|
| `Qwen/Qwen3.5-122B-A10B-FP8` | 200k | 0.50 / 3.97 | **Standard**: schnell, gut im Coden, günstig |
| `moonshotai/Kimi-K2.6` | 256k | 0.74 / 3.72 | stärkster Agent, bei kniffligen Aufgaben |
| `Qwen/Qwen3.5-397B-A17B-FP8` | 200k | 0.99 / 4.46 | Fallback, wenn 122B nicht weiterkommt |
| `mistralai/Mistral-Small-4-119B-2603` | 256k | 0.25 / 0.93 | günstig, europäisch |
| `mistralai/Ministral-3-14B-Instruct-2512` | 100k | 0.37 / 0.50 | `small_model`, Nebenaufgaben |

Weitere Modelle in `opencode.json` unter `models` ergänzen (ID exakt wie in der Liste aus
Schritt 3). Embedding-Modelle (`bge_…`, `mini_lm_…`) taugen nicht für Agenten.

### Alternative: Claude-Modelle von Anthropic

Eingebauter Provider in opencode, `opencode.json` bleibt. Verarbeitung bei Anthropic (USA).
Ein claude.ai-Abo (Pro/Max) gilt **nicht** für opencode, nötig ist ein **API-Key**.

1. <https://console.anthropic.com>: Konto anlegen, unter **Billing** Guthaben laden und
   Ausgabenlimite setzen.
2. **API Keys** → **Create Key**, sofort kopieren.
3. In opencode: `/connect` → **Anthropic** → **Manually enter API Key**. Bleibt bei Docker im
   Volume `gplug-workshop-data` gespeichert.
4. `/models` → z.B. `claude-sonnet-5-5` (Standard) oder `claude-haiku-5-5` (günstig).

Ohne Docker geht auch `export ANTHROPIC_API_KEY=…`. Fest einstellen: in `opencode.json`
`"model": "anthropic/claude-sonnet-5-5"`. Gleiche Sicherheitsregeln wie beim Infomaniak-Token.

## 7. Arbeitsweise

1. **Planen** im `plan`-Agent mit der Prompt-Vorlage aus `EXERCISES.md`.
2. **Kontext geben**: `@INTENT.md @TASMOTA_BERRY_API.md @app/spot.be`, sonst erfinden Modelle
   Tasmota-API.
3. **Umsetzen** im `build`-Agent, kleine Schritte.
4. **Testen** auf dem Gerät, Fehlermeldung aus der Konsole **wörtlich** zurückgeben.
5. Funktionierende Stände sichern (Kopie von `app/spot.be` oder `git commit`); bei Irrweg `/undo`.

## Fehlerbehebung

| Symptom | Ursache / Lösung |
|---|---|
| `Invalid Authentication` (401) | Token falsch/abgelaufen, Product-ID falsch, Kreditkarte fehlt |
| Provider `infomaniak` fehlt in `/models` | opencode nicht im Repo-Ordner gestartet, oder JSON-Fehler in `opencode.json` |
| `method_not_found` | `INFOMANIAK_PRODUCT_ID` im aktuellen Terminal nicht gesetzt, Schritt 3 |
| `model not found` | Modell-ID weicht ab, Liste aus Schritt 3 prüfen |
| Agent «redet» nur, ändert nichts | `plan`-Agent aktiv (`Shift+Tab`), oder Modell schwach im Tool Calling: Qwen3.5 oder Kimi K2.6 |
| Antworten brechen ab | `limit.output` des Modells in `opencode.json` erhöhen |
| Agent erreicht gPlug im Container nicht | IP statt `.local`-Name in `.gplug`; gleiches WLAN |
| Datei im Container gehört `root` (Linux) | Container mit `./docker-run.sh` starten, nicht direkt `docker run` |
| Kosten im Blick behalten | Infomaniak-Manager → AI Tools → Verbrauch |

## Quellen

- Infomaniak AI Tools: <https://www.infomaniak.com/fr/support/faq/2845> · API: <https://developer.infomaniak.com/docs/api>
- opencode: <https://opencode.ai/docs/> (Provider, Berechtigungen)
- Modellkatalog: <https://models.dev>
- Anthropic: <https://console.anthropic.com> · <https://docs.anthropic.com/en/docs/about-claude/models>
