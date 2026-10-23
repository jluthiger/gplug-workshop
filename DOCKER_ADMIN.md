# Docker-Image für den Workshop: Anleitung Kursleitung

Teilnehmende laden ein fertiges Image von GitHub (`ghcr.io/gplug-ch/ki-workshop`), nichts bauen,
keinen Key eintippen. Dafür veröffentlicht die Kursleitung zwei Tags:

| Tag | Inhalt | Wann |
|---|---|---|
| `base` | `Dockerfile`: Debian, opencode 2.0.32, `berry`, `git`. Keine Secrets. | einmal, bleibt |
| `workshop` | `Dockerfile.workshop`: `base` + `ENV INFOMANIAK_PRODUCT_ID`/`INFOMANIAK_API_KEY` | Workshop-Morgen, danach löschen |

`docker-run.sh` / `docker-run.ps1` laden `:workshop`, wenn es lokal fehlt; `--build` baut stattdessen
aus dem `Dockerfile` (Fallback nach dem Workshop). Werte aus der eigenen Shell (`INFOMANIAK_*`,
`GPLUG`) werden nur durchgereicht, wenn gesetzt, und überschreiben dann die Werte im Image.

**Risiko:** Das Image ist öffentlich, der Key darin für jeden sichtbar (`docker history`). Deshalb:
Token mit Ablaufdatum Workshop-Tag + 1, Ausgabenlimite im Infomaniak-Manager, Image und Token
sofort nach dem Workshop löschen.

## 1. Einmalig: Werkzeuge

Auf dem Mac der Kursleitung, Docker Desktop läuft.

```sh
gh auth refresh -s write:packages,delete:packages      # Browser-Login, Scopes erweitern
gh auth token | docker login ghcr.io -u <github-user> --password-stdin
docker buildx create --use                              # Builder für amd64 + arm64
```

Prüfen: `docker buildx ls` zeigt einen Builder mit `linux/amd64*, linux/arm64*`.

## 2. Einmalig: Org darf öffentliche Packages

GitHub-Org `gplug-ch` sperrt öffentliche Packages standardmässig (im Paket-Dialog steht dann
„Setting is disabled by organization administrators“). Als Org-Admin:

1. <https://github.com/organizations/gplug-ch/settings/packages>
2. *Package creation* → **Public** erlauben → speichern.

Fehlt der Abschnitt, sperrt eine Enterprise-Richtlinie darüber; dann Fallback: Image unter dem
persönlichen Konto veröffentlichen (`ghcr.io/<github-user>/ki-workshop`) und `IMAGE` in
`tools/publish-image.sh`, `docker-run.sh`, `docker-run.ps1` entsprechend ändern.

## 3. Basis-Image veröffentlichen

```sh
tools/publish-image.sh base
```

Baut `Dockerfile` für `linux/amd64` und `linux/arm64` und pusht `ghcr.io/gplug-ch/ki-workshop:base`
(erster Lauf ca. 5–10 min, Berry wird für beide Architekturen kompiliert).

Das neue Package ist **privat**. Auf *public* stellen:

1. <https://github.com/orgs/gplug-ch/packages/container/ki-workshop/settings>
2. *Danger Zone* → *Change package visibility* → **Public** → `ki-workshop` eintippen → bestätigen.

Prüfen ohne Login (Mac):

```sh
curl -s 'https://ghcr.io/token?scope=repository:gplug-ch/ki-workshop:pull' | grep -c token   # 1 = öffentlich
```

Pull-Test auf einem fremden Notebook (Windows): `docker pull ghcr.io/gplug-ch/ki-workshop:base`.
`denied` = noch privat.

Repo `gplug-ch/ki-workshop` ebenfalls auf *public* (ZIP-Link im Runbook braucht das).

## 4. Vortag: Infomaniak

1. Manager → AI Tools → **Ausgabenlimite** setzen.
2. <https://manager.infomaniak.com/v3/ng/profile/user/token/list> → Token erstellen, Scope
   `ai-tools`, **Ablauf = Workshop-Tag + 1**. Token sofort kopieren (nur einmal sichtbar).
3. Product-ID: Zahl in der URL der AI Tools (`…/ai-tools/<PRODUCT_ID>`).

Test:

```sh
curl -s https://api.infomaniak.com/2/ai/<PRODUCT_ID>/openai/v1/models -H "Authorization: Bearer <TOKEN>" | head -c 200
```

## 5. Workshop-Morgen: Workshop-Image

```sh
export INFOMANIAK_PRODUCT_ID=123456
export INFOMANIAK_API_KEY=xxxxxxxx
tools/publish-image.sh workshop
```

Pusht `ghcr.io/gplug-ch/ki-workshop:workshop` (schnell, nur eine `ENV`-Schicht auf `base`).
Package ist schon public, Tag wird es automatisch.

Test auf dem Mac, als wäre man Teilnehmer:

```sh
docker rmi -f ghcr.io/gplug-ch/ki-workshop:workshop   # lokale Kopie weg, erzwingt Pull
unset INFOMANIAK_PRODUCT_ID INFOMANIAK_API_KEY
./docker-run.sh bash -c 'env | grep INFOMANIAK; opencode --version'
./docker-run.sh                                        # Modell-Liste lädt, erste Frage antwortet
```

## 6. Nach dem Workshop

```sh
tools/delete-image.sh        # löscht nur :workshop samt Teil-Manifesten, fragt vorher
```

Danach Token im Infomaniak-Manager widerrufen (Link druckt das Skript). `:base` und das Package
bleiben, damit auch die Sichtbarkeit *public*: der nächste `:workshop`-Push (Schritt 5) ist sofort
öffentlich. Ohne `:workshop` meldet `docker-run.sh` „Image nicht ladbar“; wer das Repo später
nutzt, baut mit `./docker-run.sh --build` lokal.

Erst wenn das ganze Package weg soll: GitHub-Package-Seite → *Danger Zone* → *Delete this
package*. Dann ist nach dem nächsten Push Schritt 3 (Sichtbarkeit) wieder nötig.

## Fehlerbilder

| Meldung | Ursache | Behebung |
|---|---|---|
| `Image nicht ladbar (Workshop vorbei?)` bei Teilnehmenden | Package privat oder Tag `:workshop` fehlt | Schritt 3 (Sichtbarkeit) bzw. 5 |
| `denied` bei `docker pull` | wie oben; auf dem Mac klappt es, weil eingeloggt | Sichtbarkeit prüfen mit dem `curl`-Test in Schritt 3 |
| „Setting is disabled by organization administrators“ | Org-Richtlinie | Schritt 2 |
| `buildx` kennt nur eine Plattform | kein Container-Builder | `docker buildx create --use` |
| Push `unauthorized` | `gh`-Token ohne `write:packages` oder Docker-Login abgelaufen | Schritt 1 wiederholen |
| Teilnehmer-Terminal: `Invalid Authentication` vom Modell | Token abgelaufen/widerrufen oder Kreditkarte fehlt | Schritt 4 prüfen, `:workshop` neu pushen |
