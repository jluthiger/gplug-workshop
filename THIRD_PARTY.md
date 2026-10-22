# Fremde Inhalte und Lizenzen

Eigener Code und eigene Dokumente: MIT, siehe `LICENSE`.

| Inhalt | Herkunft | Stand |
|---|---|---|
| gPlug-Scripts (`gplug_script.txt`, `gplugk_script.txt`) | gplug.ch | Aus dem Repo entfernt, Lizenz nicht auffindbar. Aufs Gerät lädt der Workshop sie nicht; Teilnehmende haben sie schon auf dem gPlug |
| `reference/read_sensors_*.json` | Ausgabe eigener gPlug-Geräte | Messwerte, ohne Schlüssel |
| `TASMOTA_BERRY_API.md` | Zusammenfassung von <https://tasmota.github.io/docs/Berry/> (Tasmota, GPL-3.0) | Eigene Verdichtung, Quelle genannt |
| BKW-Tarifdaten (`bkw.json`, `app/spot_*.csv`) | <https://api.bkw.ch/api/dyntariffs/> | Swagger nennt weder Lizenz noch Nutzungsbedingungen; Zweck laut BKW: Energiemanagement, Prognose. Daten werden live geholt, `bkw.json` nicht committen |
| Berry-Interpreter (Docker-Build) | <https://github.com/berry-lang/berry> | MIT, wird beim Build geladen |
| opencode (Docker-Build) | <https://opencode.ai> | wird beim Build geladen, nicht im Repo |

Die Decryption-Keys in den Scripts sind Platzhalter (`dKEY=""`). Eigenen Zählerschlüssel nie committen.

## Entscheide (20./22.10.2026)

- **BKW-API**: keine Lizenz und keine Nutzungsbedingungen angegeben. Risiko akzeptiert: die App liest nur öffentliche Tarifdaten, im Repo liegen keine BKW-Daten.
- **Zählerschlüssel**: `reference/gplugk_script.txt` enthielt einen echten Schlüssel (`jluthiger/gplug-workshop` ab Commit `f6ceda4`, entfernt 22.10. in `9d9e2d2`; `gplug-ch/ki-workshop` in `d9dded0`, entfernt 20.10.). Schlüssel am Zähler/beim Netzbetreiber ersetzen lassen. Verlauf bereinigen (Rewrite + Force-Push) nur nach ausdrücklicher Freigabe.
