# Setup: opencode + Infomaniak Open-Source-LLM

Schritt-für-Schritt-Anleitung, um im Workshop-Repo mit dem Coding-Agenten
[opencode](https://opencode.ai) und einem Open-Source-Modell von
[Infomaniak AI Services](https://www.infomaniak.com/en/hosting/ai-services/open-source-models)
zu arbeiten («Vibe Coding»). Daten werden bei Infomaniak durchgehend in der Schweiz verarbeitet.

Zeitbedarf: ca. 15 min. Als Hausaufgabe vor dem Workshop erledigen.

## Übersicht

```
Notebook                                   Infomaniak (CH)
┌──────────────────────────────┐           ┌───────────────────────────────┐
│ opencode (Terminal)          │  HTTPS    │ api.infomaniak.com/2/ai/      │
│  ├ liest/schreibt Repo       │ ────────► │   <PRODUCT_ID>/openai/v1      │
│  ├ führt Shell-Befehle aus   │  Token    │ OpenAI-kompatibel, z.B.       │
│  └ opencode.json (Provider)  │           │ Qwen3.5, Kimi K2.6, Mistral   │
└──────────────────────────────┘           └───────────────────────────────┘
```

Benötigt werden zwei Werte: **Product-ID** (Nummer des AI-Tools-Produkts) und **API-Token**.

## 1. Infomaniak AI Tools aktivieren

1. Infomaniak-Konto anlegen bzw. einloggen: <https://manager.infomaniak.com>.
2. AI Tools öffnen: <https://manager.infomaniak.com/v3/ng/products/cloud/ai-tools> und das
   Produkt bestellen/aktivieren. Pro Organisation gibt es genau ein AI-Tools-Produkt.
   - Neukunden erhalten 1 Mio. Gratis-Credits für einen Monat.
   - Eine **Kreditkarte** muss hinterlegt sein, sonst antwortet die API nicht.
   - Empfehlung: im Manager eine **Ausgabenlimite** setzen.
   - Zugriff haben nur gesetzliche Vertretung, Admins und technische Mitarbeitende der Organisation.
3. **Product-ID** notieren: die Zahl in der URL bzw. Produktübersicht der AI Tools
   (`…/products/cloud/ai-tools/<PRODUCT_ID>`).

## 2. API-Token erstellen

1. <https://manager.infomaniak.com/v3/ng/profile/user/token/list> → **Token erstellen**.
2. Anwendung/Scope **AI Tools** (`ai-tools`) wählen, Gültigkeit nach Bedarf (z.B. bis Ende Workshop).
3. Mit Passwort bestätigen und Token **sofort kopieren** — er wird nur einmal angezeigt.

> **Sicherheit:** Der Token verursacht Kosten. Nie ins Repo committen, nicht in Chats/Screenshots
> zeigen. Nach dem Workshop im Manager widerrufen.

## 3. Zugang testen (ohne opencode)

Umgebungsvariablen setzen und Modellliste abfragen.

macOS / Linux (zsh/bash):

```sh
export INFOMANIAK_PRODUCT_ID=123456          # eigene Product-ID
export INFOMANIAK_API_KEY=xxxxxxxxxxxxxxxx   # eigener Token

curl -s https://api.infomaniak.com/2/ai/$INFOMANIAK_PRODUCT_ID/openai/v1/models \
  -H "Authorization: Bearer $INFOMANIAK_API_KEY"
```

Windows (PowerShell):

```powershell
$env:INFOMANIAK_PRODUCT_ID = "123456"
$env:INFOMANIAK_API_KEY    = "xxxxxxxxxxxxxxxx"

curl.exe -s "https://api.infomaniak.com/2/ai/$env:INFOMANIAK_PRODUCT_ID/openai/v1/models" `
  -H "Authorization: Bearer $env:INFOMANIAK_API_KEY"
```

Erwartet: JSON mit `"data": [...]` und Modell-IDs. `"Invalid Authentication"` → Token oder
Product-ID falsch, oder Kreditkarte fehlt.

Erster Chat-Aufruf (macOS/Linux):

```sh
curl -s https://api.infomaniak.com/2/ai/$INFOMANIAK_PRODUCT_ID/openai/v1/chat/completions \
  -H "Authorization: Bearer $INFOMANIAK_API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen3.5-122B-A10B-FP8","messages":[{"role":"user","content":"Sag Hallo auf Berndeutsch."}]}'
```

### Variablen dauerhaft setzen

> **Wichtig — Umgebungsvariablen**
>
> - `export …` (macOS/Linux) bzw. `$env:… = …` (PowerShell) gilt **nur im aktuellen
>   Terminal-Fenster** und ist nach dem Schliessen weg.
> - opencode sieht nur die Variablen des Terminals, **aus dem es gestartet wird**. Fehlt
>   `INFOMANIAK_PRODUCT_ID`, ruft opencode `…/2/ai//openai/v1` auf und meldet
>   `method_not_found` (siehe Fehlerbehebung).
> - Dauerhaft gesetzte Variablen gelten erst in **neu geöffneten** Terminals. Bereits offene
>   Fenster (auch das Terminal in VS Code — dort VS Code ganz neu starten) kennen sie nicht.
> - Der Token steht danach im Klartext in einer Datei im Home-Verzeichnis. Nur auf dem eigenen
>   Notebook so machen, Datei nie committen oder teilen. Nach dem Workshop Token widerrufen.

**macOS** (Standard-Shell zsh):

```sh
open -e ~/.zshrc      # Datei im TextEdit öffnen (wird angelegt, falls nicht vorhanden)
```

Am Ende einfügen, speichern, neues Terminal öffnen:

```sh
export INFOMANIAK_PRODUCT_ID=123456
export INFOMANIAK_API_KEY=xxxxxxxxxxxxxxxx
```

Wer bash nutzt (`echo $SHELL` zeigt `/bin/bash`): `~/.bash_profile` statt `~/.zshrc`.
Aus dem Dock oder Finder gestartete Programme lesen `~/.zshrc` nicht — opencode daher immer
aus dem Terminal starten.

**Linux**: Shell prüfen mit `echo $SHELL`, dann dieselben zwei Zeilen ans Ende von
`~/.bashrc` (bash) bzw. `~/.zshrc` (zsh) anhängen, z.B. mit `nano ~/.bashrc`. Neues Terminal
öffnen.

**Windows** (PowerShell, dauerhaft für den eigenen Benutzer):

```powershell
[Environment]::SetEnvironmentVariable("INFOMANIAK_PRODUCT_ID", "123456", "User")
[Environment]::SetEnvironmentVariable("INFOMANIAK_API_KEY", "xxxxxxxxxxxxxxxx", "User")
```

Gleichwertig: `setx INFOMANIAK_PRODUCT_ID 123456` bzw. per GUI *Einstellungen → System →
Info → Erweiterte Systemeinstellungen → Umgebungsvariablen → Benutzervariablen*. Danach
**alle** Terminal-Fenster schliessen und neu öffnen. In der Eingabeaufforderung (cmd) heissen
die Variablen `%INFOMANIAK_PRODUCT_ID%`, in PowerShell `$env:INFOMANIAK_PRODUCT_ID`.

**Windows mit WSL**: Windows-Variablen sind in WSL **nicht** sichtbar. Wer opencode in WSL
nutzt, setzt die Variablen wie unter Linux in `~/.bashrc` innerhalb von WSL.

**Prüfen** (in einem neuen Terminal, zeigt den Token nicht an):

| System | Befehl | Erwartet |
|---|---|---|
| macOS / Linux / WSL | `echo "ID=$INFOMANIAK_PRODUCT_ID KEY=${INFOMANIAK_API_KEY:+gesetzt}"` | `ID=123456 KEY=gesetzt` |
| Windows PowerShell | `"ID=$env:INFOMANIAK_PRODUCT_ID KEY=$([bool]$env:INFOMANIAK_API_KEY)"` | `ID=123456 KEY=True` |

## 4. opencode bereitstellen

Zwei Wege. **Option A (Docker) ist der Standard**: Der Agent läuft in einem Container und sieht nur
den Workshop-Ordner, nichts sonst vom Notebook. Option B nur, wenn Docker nicht läuft.

Beide nutzen **opencode 2.0** (Agent wechseln mit `Shift+Tab`). Achtung: das Install-Script
`https://opencode.ai/install` ohne `/v2` installiert opencode 1.x.

### Option A: Docker (Standard)

1. Docker installieren: [Docker Desktop](https://www.docker.com/products/docker-desktop/) für
   macOS und Windows (Windows: WSL 2 aktivieren, Installer fragt danach), unter Linux Docker Engine.
   Test: `docker run --rm hello-world`.
2. Im Workshop-Ordner das Image laden und starten (erster Start lädt
   `ghcr.io/gplug-ch/ki-workshop:workshop`, ca. 300 MB):

   | System | Befehl |
   |---|---|
   | macOS / Linux | `./docker-run.sh` |
   | Windows (PowerShell) | `.\docker-run.ps1` |

   Nach dem Workshop ist das Image gelöscht: `./docker-run.sh --build` baut es dann lokal aus
   dem `Dockerfile` (2–3 min).
3. Test im Container: `./docker-run.sh bash`, dann `opencode --version` (erwartet `opencode v2.0.32`)
   und `exit`.

Das Workshop-Image enthält den Infomaniak-Zugang des Workshop-Tags. Sind `INFOMANIAK_PRODUCT_ID`
und `INFOMANIAK_API_KEY` im eigenen Terminal gesetzt (Schritt 3), haben diese Vorrang; `GPLUG`
wird ebenfalls durchgereicht. Das Script hängt nur den Workshop-Ordner als `/work` ein. Sitzungen bleiben im Docker-Volume `gplug-workshop-data` erhalten. Im Image sind
zusätzlich `berry` (Desktop-Test) und `git`. Das gPlug ist aus dem Container über seine **IP**
erreichbar, `.local`-Namen gehen nicht → IP in `.gplug` eintragen.

### Option B: opencode direkt installieren

| System | Befehl |
|---|---|
| macOS / Linux | `curl -fsSL https://opencode.ai/v2/install \| bash` |
| Windows (in WSL) | wie Linux, in der WSL-Shell |
| bestehendes opencode 1.x | `opencode upgrade --major` |

Test:

```sh
opencode --version     # erwartet opencode v2.0.x
```

Ohne Container sieht der Agent grundsätzlich das ganze Notebook. Die Regeln in `opencode.json`
(Zugriff ausserhalb des Ordners verboten, Shell-Befehle nur nach Rückfrage) und `AGENTS.md`
begrenzen das, ersetzen die Isolation aber nicht: Shell-Befehle vor dem Bestätigen lesen.

## 5. Infomaniak als Provider konfigurieren

Das Workshop-Repo enthält bereits [`opencode.json`](opencode.json). opencode liest die Datei
automatisch, wenn es im Repo-Ordner gestartet wird. Kern davon:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "infomaniak": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Infomaniak AI (Schweiz)",
      "options": {
        "baseURL": "https://api.infomaniak.com/2/ai/{env:INFOMANIAK_PRODUCT_ID}/openai/v1",
        "apiKey": "{env:INFOMANIAK_API_KEY}"
      },
      "models": {
        "Qwen/Qwen3.5-122B-A10B-FP8": { "name": "Qwen3.5 122B-A10B", "tool_call": true }
      }
    }
  },
  "model": "infomaniak/Qwen/Qwen3.5-122B-A10B-FP8",
  "small_model": "infomaniak/mistralai/Ministral-3-14B-Instruct-2512"
}
```

- `{env:…}` liest die Werte aus Schritt 3 — Token und ID stehen nie in der Datei.
- `model` = Standardmodell für den Agenten, `small_model` = günstiges Modell für Nebenaufgaben
  (Sitzungstitel, Zusammenfassungen).
- Der Block `permission` in der Datei erlaubt Datei-Edits im Repo, fragt bei Shell-Befehlen
  nach und verbietet `rm`, `sudo` und Zugriffe ausserhalb des Repos.

Alternative für den Token: in opencode `/connect` → **Other** → Provider-ID `infomaniak` →
Token einfügen (gespeichert in `~/.local/share/opencode/auth.json`). Dann kann die Zeile
`apiKey` entfallen; `INFOMANIAK_PRODUCT_ID` braucht es weiterhin.

## 6. Modell wählen

Für Coding-Agenten zählt vor allem zuverlässiges **Tool Calling** (Dateien lesen/schreiben,
Shell). Alle unten haben es. Preise pro 1 Mio. Tokens (Input/Output) laut
[models.dev](https://models.dev), Stand Oktober 2026 — aktuelle Preise im Infomaniak-Manager.

| Modell-ID | Kontext | Preis in/out | Einsatz |
|---|---|---|---|
| `Qwen/Qwen3.5-122B-A10B-FP8` | 200k | 0.50 / 3.97 | **Standard**: schnell, gut im Coden, günstig |
| `moonshotai/Kimi-K2.6` | 256k | 0.74 / 3.72 | stärkster Agent, bei kniffligen Aufgaben |
| `Qwen/Qwen3.5-397B-A17B-FP8` | 200k | 0.99 / 4.46 | Fallback, wenn 122B nicht weiterkommt |
| `mistralai/Mistral-Small-4-119B-2603` | 256k | 0.25 / 0.93 | günstig, europäisch |
| `mistralai/Ministral-3-14B-Instruct-2512` | 100k | 0.37 / 0.50 | `small_model`, Nebenaufgaben |

Nicht für Agenten geeignet: `bge_multilingual_gemma2`, `mini_lm_l12_v2` (Embeddings).
`swiss-ai/Apertus-v1.5-70B`, `google/gemma-4-31B-it` und `nvidia/NVIDIA-Nemotron-3-Nano-…`
gehen auch, sind aber schwächer im Coden. Weitere Modelle in `opencode.json` unter `models`
ergänzen (ID exakt wie in der Modellliste aus Schritt 3).

In opencode umschalten: `/models` → Modell auswählen.

### Alternative: Claude-Modelle von Anthropic

opencode kennt Anthropic als eingebauten Provider, `opencode.json` muss dafür nicht geändert werden.
Daten werden dann bei Anthropic (USA) verarbeitet, nicht in der Schweiz.

> **Wichtig:** Ein claude.ai-Abo (Pro/Max) gilt **nicht** für opencode. Anthropic verbietet die
> Nutzung des Abos in Fremd-Tools, opencode bietet das Login seit Version 1.3.0 nicht mehr an.
> Nötig ist ein **API-Key** mit eigener, nutzungsabhängiger Abrechnung.

1. Konto auf <https://console.anthropic.com> anlegen (gleiches Login wie claude.ai möglich),
   unter **Billing** Guthaben laden und eine Ausgabenlimite setzen.
2. **API Keys** → **Create Key**, Key sofort kopieren (wird nur einmal angezeigt).
3. In opencode: `/connect` → **Anthropic** → **Manually enter API Key** → Key einfügen.
   Gespeichert in `~/.local/share/opencode/auth.json`, bei Option A im Docker-Volume
   `gplug-workshop-data` (bleibt erhalten).
4. `/models` → z.B. `claude-sonnet-5-5` (Standard) oder `claude-haiku-5-5` (günstig) wählen.

Option B ohne `/connect`: `export ANTHROPIC_API_KEY=…` im Terminal setzen (wie Schritt 3).
Der Docker-Container übernimmt diese Variable nicht, dort `/connect` verwenden.
Als Standardmodell fest einstellen: in `opencode.json` `"model": "anthropic/claude-sonnet-5-5"`.

Gleiche Sicherheitsregeln wie beim Infomaniak-Token: nie committen, nach dem Workshop in der
Console widerrufen.

## 7. Erster Start im Workshop-Repo

```sh
cd <pfad>/workshop
echo "ID=$INFOMANIAK_PRODUCT_ID KEY=${INFOMANIAK_API_KEY:+gesetzt}"   # beide müssen Werte zeigen
./docker-run.sh      # Option A (Windows: .\docker-run.ps1)
opencode             # Option B
```

Windows (PowerShell): `"ID=$env:INFOMANIAK_PRODUCT_ID"` prüfen, dann `opencode`.

opencode übernimmt die Variablen nur aus dem Terminal, in dem es gestartet wird. Leer →
Schritt 3 («Variablen dauerhaft setzen») nachholen, neues Terminal öffnen.

1. Unten im TUI prüfen: Modell `Qwen3.5 122B-A10B (Infomaniak AI (Schweiz))`.
2. Erste Frage stellen:
   ```
   Lies INTENT.md. Erkläre in 5 Sätzen, was app/spot.be tut.
   ```
   Der Agent sollte Dateien lesen (Tool-Aufrufe sichtbar) und korrekt antworten.
3. `AGENTS.md` (Regeln und Geräte-Werkzeuge für den Agenten) liegt bei und wird automatisch geladen;
   `/init` ist nicht nötig. IP des eigenen gPlug einmal eintragen: `echo 192.168.x.y > .gplug`.

Nützliche Befehle im TUI:

| Befehl | Wirkung |
|---|---|
| `/models` | Modell wechseln |
| `/new` | neue Sitzung (frischer Kontext) |
| `/undo`, `/redo` | letzte Änderung des Agenten zurücknehmen / wiederholen |
| `/share` | Sitzung teilen (nicht mit Geheimnissen!) |
| `Shift+Tab` | Agent wechseln: **build** (ändert Dateien) ↔ **plan** (nur lesen/planen) |
| `@datei` | Datei gezielt in den Kontext geben, z.B. `@TASMOTA_BERRY_API.md` |

## 8. Vibe-Coding-Arbeitsweise

1. **Planen** im `plan`-Agent mit der Prompt-Vorlage aus `EXERCISES.md` (nicht nur «Plane Übung A»).
2. **Kontext geben**: `@INTENT.md @TASMOTA_BERRY_API.md @app/spot.be` — ohne Cheat-Sheet
   erfinden Modelle Tasmota-API.
3. **Umsetzen** im `build`-Agent, kleine Schritte.
4. **Testen** auf dem Gerät, Fehlermeldung aus der Konsole **wörtlich** zurückgeben.
5. Funktionierende Stände sichern (Kopie von `app/spot.be`, wer git kennt: `git commit`); bei
   Irrweg `/undo` oder die Kopie zurückspielen.

## Fehlerbehebung

| Symptom | Ursache / Lösung |
|---|---|
| `Invalid Authentication` (401) | Token falsch/abgelaufen, Product-ID falsch, Kreditkarte fehlt |
| Provider `infomaniak` fehlt in `/models` | opencode nicht im Repo-Ordner gestartet, oder JSON-Syntaxfehler in `opencode.json` |
| `Not Found: {"result":"error","error":{"code":"method_not_found",…}}` | `INFOMANIAK_PRODUCT_ID` im aktuellen Terminal nicht gesetzt (`echo $INFOMANIAK_PRODUCT_ID`) |
| `model not found` | Modell-ID weicht ab → Liste aus Schritt 3 prüfen, in `opencode.json` korrigieren |
| Agent «redet» nur, ändert keine Dateien | Modell ohne gutes Tool Calling → auf Qwen3.5 oder Kimi K2.6 wechseln; `plan`-Agent aktiv? `Shift+Tab` |
| Antworten brechen ab | Ausgabelimit; `limit.output` im Modell in `opencode.json` erhöhen |
| Windows: Skripte laufen nicht | Option A (Docker) nutzen, dort laufen sie; sonst WSL |
| `docker: command not found` / `Cannot connect to the Docker daemon` | Docker Desktop starten, neues Terminal |
| Agent erreicht gPlug im Container nicht | IP statt `.local`-Name in `.gplug`; Notebook und gPlug im selben WLAN |
| Datei im Container geändert, gehört `root` (Linux) | Container mit `./docker-run.sh` starten, nicht direkt `docker run` |
| Kosten im Blick behalten | Infomaniak-Manager → AI Tools → Verbrauch; Ausgabenlimite setzen |

## Quellen

- Infomaniak Open-Source-Modelle: <https://www.infomaniak.com/en/hosting/ai-services/open-source-models>
- Infomaniak Startanleitung AI Tools: <https://www.infomaniak.com/fr/support/faq/2845>
- Infomaniak API-Token: <https://www.infomaniak.com/gtl/support.faq.faq_question/id/2582>
- Infomaniak API-Doku: <https://developer.infomaniak.com/docs/api>
- opencode Doku: <https://opencode.ai/docs/> · Provider: <https://opencode.ai/docs/providers/> ·
  Berechtigungen: <https://opencode.ai/docs/permissions/>
- Modellkatalog (Preise, Limits): <https://models.dev>
- Anthropic Console (API-Key): <https://console.anthropic.com> · Modelle:
  <https://docs.anthropic.com/en/docs/about-claude/models>
