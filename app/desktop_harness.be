#- desktop_harness.be — spot.be ohne Gerät testen (Desktop-Berry, /usr/local/bin/berry)
   Stubs für tasmota, webclient, persist, path. Simuliert einen Tag mit Simulator-Zähler,
   Preisabruf aus bkw.json, Command-Ausgaben, Tagesende mit CSV und Web-HTML.
   Aufruf im Ordner mit spot.be und bkw.json:   berry desktop_harness.be
   Ergebnis: sensor.html (Sensorbereich wie im WebUI), spot_YYYY-MM.csv
-#
import string
import os

# ---- Zeit (UTC-Epoche <-> Kalender), wie Tasmota: strptime = UTC, rtc.local = utc + tz
def days_from_civil(y, m, d)
  if m <= 2 y -= 1 end
  var era = (y >= 0 ? y : y - 399) / 400
  var yoe = y - era * 400
  var mp = (m + 9) % 12
  var doy = (153 * mp + 2) / 5 + d - 1
  var doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
  return era * 146097 + doe - 719468
end
def civil_from_days(z)
  z += 719468
  var era = (z >= 0 ? z : z - 146096) / 146097
  var doe = z - era * 146097
  var yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  var y = yoe + era * 400
  var doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  var mp = (5 * doy + 2) / 153
  var d = doy - (153 * mp + 2) / 5 + 1
  var m = mp < 10 ? mp + 3 : mp - 9
  if m <= 2 y += 1 end
  return [y, m, d]
end

NOW_UTC = 0          # wird im Szenario gesetzt
TZ_MIN = 60          # wie das Testgerät: +01:00 fix

class Tas
  var out, drivers, cmds, crons, rules, resp, heap, net_up
  def init() self.out = [] self.drivers = [] self.cmds = {} self.crons = {} self.rules = {} self.heap = 150 end
  def rtc(k)
    var m = {"utc": NOW_UTC, "local": NOW_UTC + TZ_MIN * 60, "timezone": TZ_MIN, "restart": NOW_UTC - 3600}
    return k == nil ? m : m[k]
  end
  def time_dump(t)
    var days = t / 86400
    var rem = t % 86400
    var c = civil_from_days(days)
    return {"year": c[0], "month": c[1], "day": c[2], "hour": rem / 3600, "min": (rem % 3600) / 60, "sec": rem % 60, "weekday": (days + 4) % 7, "epoch": t}
  end
  def strftime(fmt, t)
    var d = self.time_dump(t)
    fmt = string.replace(fmt, "%Y", string.format("%04d", d["year"]))
    fmt = string.replace(fmt, "%m", string.format("%02d", d["month"]))
    fmt = string.replace(fmt, "%d", string.format("%02d", d["day"]))
    fmt = string.replace(fmt, "%H", string.format("%02d", d["hour"]))
    fmt = string.replace(fmt, "%M", string.format("%02d", d["min"]))
    fmt = string.replace(fmt, "%S", string.format("%02d", d["sec"]))
    return fmt
  end
  def time_str(t) return self.strftime("%Y-%m-%dT%H:%M:%S", t) end
  def strptime(s, fmt)          # nur "YYYY-MM-DDTHH:MM:SS"
    if size(s) < 19 return nil end
    var y = int(s[0..3]) var mo = int(s[5..6]) var d = int(s[8..9])
    var h = int(s[11..12]) var mi = int(s[14..15]) var se = int(s[17..18])
    var e = days_from_civil(y, mo, d) * 86400 + h * 3600 + mi * 60 + se
    return {"epoch": e, "year": y, "month": mo, "day": d, "hour": h, "min": mi, "sec": se, "unparsed": ""}
  end
  def version() return 0x0F030000 end
  def cmd(c, mute) return c == "Timezone" ? {"Timezone": TZ_MIN == 60 ? "+01:00" : 99} : {} end
  def memory(k) return self.heap end
  def gc() return 0 end
  def web_send(s) self.out.push(s) end
  def response_append(s) self.resp = s end
  def resp_cmnd(s) self.resp = s end
  def resp_cmnd_done() self.resp = "Done" end
  def add_driver(d) self.drivers.push(d) end
  def remove_driver(d) var i = self.drivers.find(d) if i != nil self.drivers.remove(i) end end
  def remove_cron(id) self.crons.remove(id) end
  def remove_rule(id) end
  def add_cmd(n, f) self.cmds[n] = f end
  def add_cron(p, f, id) self.crons[id] = f end
  def add_rule(t, f, id) self.rules[t] = f end
  def set_timer(ms, f, id) f() end
  def remove_timer(id) end
  def when_network_up(f) self.net_up = f end     # Harness ruft es nach der Pfad-Konfiguration
  def read_sensors() return '{"Time":"2026-10-18T17:04:11","z":{"SMid":"","Eo":0.0}}' end
end
tasmota = Tas()
def log(m, l) print("LOG:", m) end

class webclient
  var url
  def begin(u) self.url = u return self end
  def add_header(a, b) end
  def set_timeouts(a, b) return self end
  def GET() return 200 end
  def write_file(name)                     # kopiert bkw.json, wie der Download aufs Gerät
    var f = open("bkw.json", "r")
    var s = f.read()
    f.close()
    f = open(name, "w")
    f.write(s)
    f.close()
    return size(s)
  end
  def close() end
end

# persist und path: Stub-Module persist.be / path.be im selben Ordner (import findet sie dort)

# ---- Szenario ----------------------------------------------------------------
def local_epoch(y, m, d, h, mi) return days_from_civil(y, m, d) * 86400 + h * 3600 + mi * 60 - TZ_MIN * 60 end

# Globale Namen aus spot.be müssen vor dem Kompilieren dieses Chunks existieren
spot = nil
spot_cfg = nil
spot_now = nil
spot_day = nil

NOW_UTC = local_epoch(2026, 10, 18, 6, 0)          # 06:00 lokal
compile("spot.be", "file")()
spot.cfg["csv_dir"] = ""                             # CSV ins aktuelle Verzeichnis
spot.cfg["dl_file"] = "spot_dl.json"                 # Download ins aktuelle Verzeichnis
tasmota.net_up()                                     # Netz da -> Preisabruf
assert(tasmota.drivers.size() == 1)
print("after load: prices today =", spot.store.count(spot.store.prices, spot_day(spot_now())),
      "energy backfilled =", spot.store.count(spot.store.energy, spot_day(spot_now())))

# Viertelstunden bis 17:15 lokal
var t = NOW_UTC
while t <= local_epoch(2026, 10, 18, 17, 15)
  NOW_UTC = t
  spot.on_quarter()
  t += 900
end
print("energy slots today =", spot.store.count(spot.store.energy, spot_day(spot_now())), "counter =", spot.cnt)

tasmota.cmds["SpotPrices"]("SpotPrices", 1, "")
print("CMD:", tasmota.resp)
tasmota.cmds["SpotPrices"]("SpotPrices", 1, "15")
print("CMD15:", tasmota.resp[0..140], "...")
tasmota.cmds["SpotStatus"]("SpotStatus", 1, "")
print("STATUS:", tasmota.resp)
spot.json_append()
print("TELE:", tasmota.resp)

# Web-HTML einsammeln
tasmota.out = []
spot.web_sensor()
def untoken(s)
  s = string.replace(s, "{t}", "<table style='width:100%'>")
  s = string.replace(s, "{s}", "<tr><th>")
  s = string.replace(s, "{m}", "</th><td>")
  s = string.replace(s, "{e}", "</td></tr>")
  return s
end
var html = "<table style='width:100%'>"
for s: tasmota.out html += untoken(s) end
html += "</table>"
var f = open("sensor.html", "w")
f.write(html)
f.close()
print("HTML chunks =", tasmota.out.size(), "bytes =", size(html))

# Tagesende: 00:00 lokal am 19.10. -> CSV für 18.10., Aufbewahrung 2 Dateien
f = open("spot_2026-08.csv", "w") f.write("alt\n") f.close()
f = open("spot_2026-09.csv", "w") f.write("alt\n") f.close()
NOW_UTC = local_epoch(2026, 10, 19, 0, 0)
spot.on_quarter()
f = open("spot_2026-10.csv", "r")
print("CSV:", f.read())
f.close()
var left = []
for n: os.listdir(".") if string.find(n, "spot_20") == 0 left.push(n) end end
print("CSV files left:", left)
assert(left.size() == 2, "retention failed")
print("HARNESS OK")
