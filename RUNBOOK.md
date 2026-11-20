# Runbook – Einrichten vor Ort

Ziel: in **40 min** vom eigenen Notebook und gPlug zu einem laufenden Agenten und dem Starter auf dem
Gerät. Danach beginnt die Übung (`EXERCISES.md`). Begriffe: [`LEGENDE.md`](LEGENDE.md).

## Wähle dein System

Jedes Runbook ist vollständig: von oben nach unten durcharbeiten, die anderen brauchst du nicht.

| Notebook | Runbook | Terminal |
|---|---|---|
| Windows | [`RUNBOOK_WINDOWS.md`](RUNBOOK_WINDOWS.md) | Ubuntu in WSL (empfohlen) oder PowerShell |
| macOS | [`RUNBOOK_MACOS.md`](RUNBOOK_MACOS.md) | Terminal |
| Linux | [`RUNBOOK_LINUX.md`](RUNBOOK_LINUX.md) | beliebig; Einfügen mit Ctrl+Shift+V |

## Ablauf (in allen Runbooks gleich)

| Schritt | Was | Zeit |
|---|---|---|
| 1 | Workshop-Ordner herunterladen | 5 min |
| 2 | Zugangsdaten für das Sprachmodell | – |
| 3 | Docker-Image laden, Agent testen | 10 min |
| 4 | gPlug ins Workshop-WLAN | 10 min |
| 5 | Firmware prüfen, Zeitzone | 5–10 min |
| 6 | Hello World von Hand (Übung Schritt 0) | 10 min |
| 7 | Starter aufs Gerät | 5 min |

Erst Notebook (Schritte 1–3), dann gPlug (4–5) mit Helfern, dann Hello World (6), zuletzt Starter (7).

Die Schrittnummern sind in allen drei Runbooks dieselben. «Runbook Schritt 7» in `EXERCISES.md`
meint Schritt 7 im Runbook deines Systems.
