#- spot.be — gPlug Spot-Einspeisung, Referenz-App v0.2
   Tasmota >= 15.3.0, ESP32-C3. Siehe INTENT.md.

   Funktionen
     F1  BKW-Einspeisepreise laden (stündlicher Cron, nur wenn Preise fehlen), 2-Byte-Ringpuffer
     F2  Einspeisezähler alle 15 min lesen (Smart Meter oder Simulator), Differenz speichern
     F3  WebUI: Tageschart (96 Viertelstunden) mit Vergütung, Preis, Jetzt-Marke
     F4  Tageszeile in /spot_YYYY-MM.csv, max. 2 Monatsdateien
     F5  Command SpotPrices [15] — nächste 10 h als JSON

   Laden:  Br load("spot")     oder   load("spot") in autoexec.be
   Test:   SpotStatus, SpotFetch, SpotFetch file, SpotTick, SpotPrices, SpotPrices 15

   Zeit: alle Zeitstempel intern als "lokale Epoche" (tasmota.rtc("local")).
   Tag = lokale Mitternacht, Slot = Viertelstunde 0..99 (DST-Tage haben 92/100).
   BKW liefert UTC; jeder Preis wird einzeln auf lokalen Tag/Slot abgebildet,
   damit es auch mit falsch konfigurierter Zeitzone konsistent bleibt.
-#

import string
import math
import json
import persist
import path

# ============================ Konfiguration ============================
spot_cfg = {
  "sim": true,                 # true: Zähler-Simulator statt Smart Meter (Workshop ohne Meter)
  "meter_path": ["z", "Eo"],   # JSON-Pfad zum Einspeisezähler in tasmota.read_sensors()
  "url": "https://api.bkw.ch/api/dyntariffs/v1/Tariffs/energyreturn",
  "days": 4,                   # Tage im Ringpuffer (heute, morgen, gestern, vorgestern)
  "csv_dir": "/",              # Ablage der CSV-Dateien
  "csv_hourly": false          # ERWEITERUNGSPUNKT Übung B: Stundenwerte zusätzlich ablegen
}

# ============================ Zeit-Helfer ===============================
def spot_now()          return tasmota.rtc("local") end
def spot_day(t)         return t - (t % 86400) end          # lokale Mitternacht
def spot_slot(t)        return (t % 86400) / 900 end         # Viertelstunde 0..99
def spot_round(x)       return x >= 0 ? int(x + 0.5) : int(x - 0.5) end
def spot_time_ok()      return tasmota.rtc("utc") > 1700000000 end

# Zeitzone: Sommerzeit rechnet Tasmota nur mit `Timezone 99` (Regeln TimeDst/TimeStd,
# Standard = CET/CEST). Fester Offset (z.B. +01:00 ab Werk) = im Sommer 1 h falsch
# -> Slots, Chart und CSV-Tag verschoben. Liefert Warntext oder nil.
def spot_tz_warn()
  var r = tasmota.cmd("Timezone", true)
  if r == nil || !r.contains("Timezone") || r["Timezone"] == 99 return nil end
  return string.format("Timezone %s fest, Sommerzeit fehlt: 'Timezone 99' setzen", str(r["Timezone"]))
end

# ============================ Ringpuffer ================================
# Pro Tag 100 Slots x 2 Byte für Preis (1/10000 CHF/kWh) und Energie (0.01 kWh).
# 0x7FFF = ungültig. Tage werden über ihre lokale Mitternacht (Epoche) adressiert.
class SpotStore
  static INVALID = 0x7FFF
  static SLOTS = 100
  var ndays, keys, prices, energy

  def init(ndays)
    self.ndays = ndays
    self.keys = []
    for i:0..ndays-1 self.keys.push(0) end
    self.prices = bytes(-(ndays * self.SLOTS * 2))
    self.energy = bytes(-(ndays * self.SLOTS * 2))
    for i:0..ndays-1 self.clear_day(i) end
  end

  def clear_day(i)
    for s:0..self.SLOTS-1
      self.prices.seti((i * self.SLOTS + s) * 2, self.INVALID, 2)
      self.energy.seti((i * self.SLOTS + s) * 2, self.INVALID, 2)
    end
  end

  def day_index(key)
    for i:0..self.ndays-1
      if self.keys[i] == key return i end
    end
    return -1
  end

  # Tag finden oder den ältesten Tag dafür freigeben
  def day_alloc(key)
    var i = self.day_index(key)
    if i >= 0 return i end
    i = 0
    for j:1..self.ndays-1
      if self.keys[j] < self.keys[i] i = j end
    end
    self.keys[i] = key
    self.clear_day(i)
    return i
  end

  def get(buf, key, slot)
    var i = self.day_index(key)
    if i < 0 || slot < 0 || slot >= self.SLOTS return nil end
    var v = buf.geti((i * self.SLOTS + slot) * 2, 2)
    return v == self.INVALID ? nil : v
  end

  def set(buf, key, slot, v)
    if slot < 0 || slot >= self.SLOTS return end
    var i = self.day_alloc(key)
    buf.seti((i * self.SLOTS + slot) * 2, v, 2)
  end

  def price(key, slot)     return self.get(self.prices, key, slot) end
  def energy_at(key, slot) return self.get(self.energy, key, slot) end
  def set_price(key, slot, v)  self.set(self.prices, key, slot, v) end
  def set_energy(key, slot, v) self.set(self.energy, key, slot, v) end

  # Anzahl gültiger Werte eines Tages
  def count(buf, key)
    var n = 0
    for s:0..self.SLOTS-1
      if self.get(buf, key, s) != nil n += 1 end
    end
    return n
  end
end

# ============================ App ======================================
class SpotApp
  var cfg, store
  var sim_cnt              # Simulator-Zählerstand kWh
  var cnt, cnt_t           # letzter Zählerstand kWh (real) und Zeitpunkt (lokal)
  var last_fetch           # Text für UI / SpotStatus
  var tz_warn              # Zeitzonen-Warnung (String) oder nil, stündlich geprüft
  var busy

  def init(cfg)
    self.cfg = cfg
    self.store = SpotStore(cfg["days"])
    self.sim_cnt = 1000.0
    self.last_fetch = "noch kein Abruf"
    self.busy = false
    self.cnt = persist.find("spot_cnt", nil)
    self.cnt_t = persist.find("spot_cnt_t", 0)
    if tasmota.version() < 0x0F030000
      log("SPOT: Tasmota < 15.3.0, nicht getestet", 2)
    end
    self.tz_warn = spot_tz_warn()
    if self.tz_warn != nil log("SPOT: " + self.tz_warn, 2) end
    tasmota.add_cron("0 */15 * * * *", /-> self.on_quarter(), "spot_q")
    tasmota.add_cron("0 5 * * * *", /-> self.on_hour(), "spot_h")
    tasmota.when_network_up(/-> self.on_net())
    if cfg["sim"] && spot_time_ok() self.sim_backfill() end
  end

  # ---------------------------------------------------------------- F1
  def on_net()
    if spot_time_ok()
      tasmota.set_timer(3000, /-> self.fetch_if_needed())
    else
      tasmota.add_rule("Time#Initialized", /-> tasmota.set_timer(3000, /-> self.fetch_if_needed()), "spot_t")
    end
  end

  def on_hour()
    self.tz_warn = spot_tz_warn()
    self.fetch_if_needed()
  end

  # Abrufen, wenn der aktuelle Preis, der Preis in 6 h oder (ab 17 Uhr) der
  # Preis morgen Mittag fehlt. BKW liefert den Folgetag ab ca. 17 Uhr.
  def need_fetch()
    var now = spot_now()
    if self.store.price(spot_day(now), spot_slot(now)) == nil return true end
    var t6 = now + 6 * 3600
    if self.store.price(spot_day(t6), spot_slot(t6)) == nil return true end
    if tasmota.time_dump(now)["hour"] >= 17
      var tm = spot_day(now) + 86400 + 12 * 3600
      if self.store.price(spot_day(tm), spot_slot(tm)) == nil return true end
    end
    return false
  end

  def fetch_if_needed()
    if spot_time_ok() && self.need_fetch() self.fetch() end
  end

  def fetch()
    if self.busy return end
    self.busy = true
    var heap0 = tasmota.memory("heap_free")
    var n = 0
    try
      var wc = webclient()
      wc.begin(self.cfg["url"])
      wc.add_header("accept", "application/json")
      wc.set_timeouts(10000, 5000)
      var rc = wc.GET()
      if rc == 200
        var s = wc.get_string()         # ca. 21 kB, nur bis Ende parse() im RAM
        n = self.parse(s)
        s = nil
      else
        self.last_fetch = "HTTP " + str(rc)
      end
      wc.close()
      wc = nil
    except .. as e, m
      self.last_fetch = "Fehler " + str(e)
      log("SPOT: fetch " + str(e) + " " + str(m), 2)
    end
    tasmota.gc()
    if n > 0
      self.last_fetch = string.format("%d Werte um %s", n, tasmota.strftime("%H:%M", spot_now()))
      if self.cfg["sim"] self.sim_fill_prices() end
    end
    log(string.format("SPOT: fetch %s, heap %d -> %d kB", self.last_fetch, heap0, tasmota.memory("heap_free")), 2)
    self.busy = false
  end

  # Offline-Fallback: gespeicherte BKW-Antwort aus dem Dateisystem parsen (SpotFetch file)
  def fetch_file(name)
    var n = 0
    try
      var f = open(name, "r")
      var s = f.read()
      f.close()
      n = self.parse(s)
      s = nil
    except .. as e, m
      self.last_fetch = "Datei: " + str(m)
    end
    tasmota.gc()
    if n > 0
      self.last_fetch = string.format("%d Werte aus %s", n, name)
      if self.cfg["sim"] self.sim_fill_prices() end
    end
    return n
  end

  # Simulator: BKW liefert ab ca. 17 Uhr nur noch den Folgetag. Fehlen heute Preise,
  # werden sie aus dem Folgetag kopiert, damit das Chart am Workshop-Abend etwas zeigt.
  def sim_fill_prices()
    var key = spot_day(spot_now())
    var n = 0
    for s:0..self.store.SLOTS-1
      if self.store.price(key, s) == nil
        var p = self.store.price(key + 86400, s)
        if p != nil
          self.store.set_price(key, s, p)
          n += 1
        end
      end
    end
    if n > 0 self.last_fetch += string.format(", %d heute aus Folgetag (Sim)", n) end
  end

  # Werte direkt aus dem JSON-String ziehen (kein json.load der 21 kB).
  # Jeder Eintrag: "start_timestamp": "2026-10-17T22:00:00Z" ... "value": 0.194
  # Leerzeichen/Zeilenumbrüche nach den Doppelpunkten sind erlaubt.
  def parse(s)
    var tz = tasmota.rtc("timezone") * 60
    var n = 0
    var pos = 0
    while true
      var p = string.find(s, '"start_timestamp"', pos)
      if p < 0 break end
      var a = string.find(s, '"', p + 17)          # öffnendes " des Zeitstempels
      if a < 0 || a + 19 >= size(s) break end
      var ts = s[a+1..a+19]                        # 19 Zeichen ohne 'Z'
      var q = string.find(s, '"value"', a)
      if q < 0 break end
      var b = q + 7
      while b < size(s) && (s[b] == ":" || s[b] == " " || s[b] == "\n" || s[b] == "\r" || s[b] == "\t") b += 1 end
      var e = b
      while e < size(s) && string.find("-0123456789.", s[e]) >= 0 e += 1 end
      var val = real(s[b..e-1])
      var t = tasmota.strptime(ts, "%Y-%m-%dT%H:%M:%S")   # Epoche UTC
      if t != nil
        var tl = t["epoch"] + tz                           # lokale Epoche
        self.store.set_price(spot_day(tl), spot_slot(tl), spot_round(val * 10000))
        n += 1
      end
      pos = e
    end
    return n
  end

  # ---------------------------------------------------------------- F2
  # Zählerstand kWh oder nil. Pfad konfigurierbar, Meter-Ausfall = nil.
  def read_counter()
    if self.cfg["sim"] return self.sim_counter() end
    var j = json.load(tasmota.read_sensors())
    if j == nil return nil end
    var v = j
    for k: self.cfg["meter_path"]
      if !isinstance(v, map) || !v.contains(k) return nil end
      v = v[k]
    end
    v = real(v)
    return v > 0 ? v : nil          # 0.0 = Meter nicht verbunden
  end

  # Simulator: Einspeiseleistung als Tageskurve, 0.3 kW Sockel damit abends etwas sichtbar ist
  def sim_kw(t)
    var h = (t % 86400) / 3600.0
    var kw = 0.3
    if h > 6.0 && h < 20.0 kw += 1.8 * math.exp(-((h - 12.7) * (h - 12.7)) / 7) end
    return kw
  end

  def sim_counter()
    self.sim_cnt += self.sim_kw(spot_now()) * 0.25
    return self.sim_cnt
  end

  # Simulator: vergangene Slots des heutigen Tages füllen, damit das Chart nicht leer startet
  def sim_backfill()
    var now = spot_now()
    var key = spot_day(now)
    var s = 0
    while s < spot_slot(now)
      self.store.set_energy(key, s, spot_round(self.sim_kw(key + s * 900) * 0.25 * 100))
      s += 1
    end
  end

  # Alle 15 min: Differenz der letzten Viertelstunde speichern, Tagesende abschliessen
  def on_quarter()
    if !spot_time_ok() return end
    var now = spot_now()
    var c = self.read_counter()
    if c != nil
      var age = now - self.cnt_t
      if self.cnt != nil && age > 600 && age < 1500       # genau eine Viertelstunde alt
        var d = spot_round(c * 100) - spot_round(self.cnt * 100)   # Einheit 0.01 kWh
        if d < 0 d = 0 end
        if d > 32000 d = 32000 end
        var t = now - 900                                   # Slot, der gerade endete
        self.store.set_energy(spot_day(t), spot_slot(t), d)
      end
      self.cnt = c
      self.cnt_t = now
      persist.spot_cnt = c
      persist.spot_cnt_t = now
    end
    if spot_slot(now) == 0                                  # erster Slot des neuen Tages
      self.day_end(spot_day(now) - 86400)
      persist.save()
    end
  end

  # ---------------------------------------------------------------- F4
  # Summen eines Tages: [kWh, CHF, Anzahl Slots mit Energie]
  def day_sums(key)
    var e = 0
    var v = 0.0
    var n = 0
    for s:0..self.store.SLOTS-1
      var en = self.store.energy_at(key, s)
      if en == nil continue end
      e += en
      n += 1
      var p = self.store.price(key, s)
      if p != nil v += en * p end             # 0.01 kWh * 1/10000 CHF/kWh = 1e-6 CHF, real wegen Überlauf
    end
    return [e / 100.0, v / 1000000.0, n]
  end

  def day_end(key)
    var sums = self.day_sums(key)
    if sums[2] == 0 return end
    try
      var name = self.cfg["csv_dir"] + "spot_" + tasmota.strftime("%Y-%m", key) + ".csv"
      var fresh = !path.exists(name)
      var f = open(name, "a")
      if fresh f.write("Datum;Energie_kWh;Verguetung_CHF\n") end
      f.write(string.format("%s;%.2f;%.2f\n", tasmota.strftime("%Y-%m-%d", key), sums[0], sums[1]))
      f.close()
      self.csv_keep_newest("spot_", 2)
      log(string.format("SPOT: CSV %s %.2f kWh %.2f CHF", tasmota.strftime("%Y-%m-%d", key), sums[0], sums[1]), 2)
    except .. as e, m
      log("SPOT: csv " + str(e) + " " + str(m), 2)
    end
    # ERWEITERUNGSPUNKT Übung B: wenn cfg["csv_hourly"], 24 Stundenzeilen in
    # spot_h_YYYY-MM.csv schreiben und self.csv_keep_newest("spot_h_", 2) aufrufen.
  end

  # Nur die n neuesten Dateien mit Präfix behalten (Namen sind chronologisch sortierbar)
  def csv_keep_newest(prefix, n)
    var names = []
    for f: path.listdir(self.cfg["csv_dir"])
      if size(f) > size(prefix) && f[0..size(prefix)-1] == prefix && f[-4..] == ".csv" names.push(f) end
    end
    while names.size() > n
      var oldest = 0
      for i:1..names.size()-1
        if names[i] < names[oldest] oldest = i end
      end
      path.remove(self.cfg["csv_dir"] + names[oldest])
      names.remove(oldest)
    end
  end

  # ---------------------------------------------------------------- F5
  # SpotPrices      -> 10 Stundenwerte (Mittel der Viertelstunden)
  # SpotPrices 15   -> 40 Viertelstundenwerte
  def cmd_prices(cmd, idx, payload)
    if !spot_time_ok()
      tasmota.resp_cmnd('{"SpotPrices":{"Error":"no time"}}')
      return
    end
    var res = int(payload) == 15 ? 15 : 60
    var now = spot_now()
    var start = now - (now % 3600)
    var out = ""
    var n = 0
    var t = start
    while t < start + 10 * 3600
      var val = nil
      if res == 60
        var sum = 0
        var k = 0
        for q:0..3
          var p = self.store.price(spot_day(t + q * 900), spot_slot(t + q * 900))
          if p != nil
            sum += p
            k += 1
          end
        end
        if k > 0 val = sum / k end
      else
        val = self.store.price(spot_day(t), spot_slot(t))
      end
      if val == nil break end
      out += (n > 0 ? "," : "") + string.format("%.4f", val / 10000.0)
      n += 1
      t += res * 60
    end
    if n == 0
      tasmota.resp_cmnd('{"SpotPrices":{"Error":"no data"}}')
      return
    end
    tasmota.resp_cmnd(string.format('{"SpotPrices":{"Start":"%s","Res":%d,"Unit":"CHF/kWh","Prices":[%s]}}',
      tasmota.time_str(start), res, out))
  end

  # SpotFetch        -> BKW-API abrufen
  # SpotFetch file   -> /bkw.json aus dem Dateisystem (Workshop ohne Internet)
  def cmd_fetch(cmd, idx, payload)
    if payload == "file"
      self.fetch_file("/bkw.json")
    else
      self.fetch()
    end
    tasmota.resp_cmnd(string.format('{"SpotFetch":"%s"}', self.last_fetch))
  end

  def cmd_tick(cmd, idx, payload)
    self.on_quarter()
    tasmota.resp_cmnd_done()
  end

  def cmd_status(cmd, idx, payload)
    var days = ""
    for i:0..self.store.ndays-1
      var k = self.store.keys[i]
      if k == 0 continue end
      days += string.format('%s{"day":"%s","prices":%d,"energy":%d}', size(days) > 0 ? "," : "",
        tasmota.strftime("%Y-%m-%d", k), self.store.count(self.store.prices, k), self.store.count(self.store.energy, k))
    end
    tasmota.resp_cmnd(string.format('{"SpotStatus":{"Sim":%s,"Counter":%s,"CounterTime":"%s","LastFetch":"%s","Warn":%s,"HeapFree":%d,"Days":[%s]}}',
      self.cfg["sim"] ? "true" : "false", self.cnt == nil ? "null" : string.format("%.3f", self.cnt),
      self.cnt_t > 0 ? tasmota.time_str(self.cnt_t) : "", self.last_fetch,
      self.tz_warn == nil ? "null" : '"' + self.tz_warn + '"', tasmota.memory("heap_free"), days))
  end

  # ---------------------------------------------------------------- F3
  # Kopfzeilen + SVG des heutigen Tages. Wird bei jedem WebRefresh (2.3 s) gerufen,
  # daher: ein Durchlauf über die Slots, Ausgabe in Häppchen via tasmota.web_send.
  def web_sensor()
    if !spot_time_ok() return end
    var now = spot_now()
    var key = spot_day(now)
    var slot = spot_slot(now)
    var sums = self.day_sums(key)
    var pnow = self.store.price(key, slot)

    # Wertebereiche für die Achsen
    var pmin = 0
    var pmax = 100            # 1/10000 CHF/kWh, mind. 0.01
    var vmin = 0
    var vmax = 100            # 1e-6 CHF pro Slot, mind. 0.0001
    for s:0..95
      var p = self.store.price(key, s)
      if p != nil
        if p < pmin pmin = p end
        if p > pmax pmax = p end
        var e = self.store.energy_at(key, s)
        if e != nil
          var v = e * p
          if v < vmin vmin = v end
          if v > vmax vmax = v end
        end
      end
    end

    # ERWEITERUNGSPUNKT Übung A: hier weitere Kurven ergänzen (z.B. Energie kWh pro Slot)
    tasmota.web_send("</table><style>#l1{display:flex;flex-direction:column}</style><div style='order:-1;width:100%'>")
    tasmota.web_send("<table style='width:100%;font-size:1.25em;margin:4px 0 2px'>")
    tasmota.web_send(string.format("<tr><th>Spotpreis jetzt</th><td style='color:#f5a623'>%s</td></tr>",
      pnow == nil ? "–" : string.format("%.1f Rp/kWh", pnow / 100.0)))
    tasmota.web_send(string.format("<tr><th>Einspeisung heute</th><td>%.2f kWh</td></tr>", sums[0]))
    tasmota.web_send(string.format("<tr><th>Vergütung heute</th><td style='color:%s'>%.2f CHF</td></tr>",
      sums[1] >= 0 ? "#47c266" : "#ff5661", sums[1]))
    tasmota.web_send("</table>")
    self.send_svg(key, slot, pmin, pmax, vmin, vmax)
    tasmota.web_send("<div style='font-size:.9em;color:#aaa;text-align:center;margin:2px 0 8px'>"
      "<span style='color:#47c266'>&#9632;</span> Vergütung/&#188;h &nbsp; "
      "<span style='color:#ff5661'>&#9632;</span> Kosten &nbsp; "
      "<span style='color:#f5a623'>&#8212;</span> Spotpreis &nbsp; "
      "<span style='color:#1fa3ec'>&#9478;</span> jetzt</div>")
    tasmota.web_send("{t}")
    var pnext = self.store.price(spot_day(now + 3600), spot_slot(now + 3600))
    tasmota.web_send(string.format("{s}Nächste Stunde{m}%s{e}", pnext == nil ? "–" : string.format("%.1f Rp/kWh", pnext / 100.0)))
    tasmota.web_send(string.format("{s}Preise{m}%s{e}", self.last_fetch))
    tasmota.web_send(string.format("{s}Zähler %s{m}%s{e}", self.cfg["sim"] ? "(Simulator)" : "Einspeisung",
      self.cnt == nil ? "–" : string.format("%.3f kWh", self.cnt)))
    if self.tz_warn != nil
      tasmota.web_send(string.format("{s}<span style='color:#ff5661'>&#9888; Zeitzone</span>{m}<span style='color:#ff5661'>%s</span>{e}", self.tz_warn))
    end
    tasmota.web_send("</table><hr style='border:0;border-top:1px solid #aaa;margin:8px 0'></div>{t}")
  end

  def send_svg(key, slot, pmin, pmax, vmin, vmax)
    var x0 = 30.0
    var pw = 270.0
    var bw = pw / 96
    var vy = / v -> 130.0 - (v - vmin) * 120.0 / (vmax - vmin)
    var py = / p -> 130.0 - (p - pmin) * 120.0 / (pmax - pmin)

    var s = "<svg viewBox='0 0 340 158' style='width:100%;display:block;margin:6px 0' xmlns='http://www.w3.org/2000/svg'>"
    for i:0..3                                # Gitter + linke Achse (Rp pro 1/4h)
      var v = vmin + (vmax - vmin) * i / 3
      s += string.format("<line x1='%.0f' y1='%.1f' x2='%.0f' y2='%.1f' stroke='#444' stroke-width='0.5'/>", x0, vy(v), x0 + pw, vy(v))
      s += string.format("<text x='%.0f' y='%.1f' fill='#47c266' font-size='10' text-anchor='end'>%.1f</text>", x0 - 4, vy(v) + 3.5, v / 10000.0)
    end
    if vmin < 0
      s += string.format("<line x1='%.0f' y1='%.1f' x2='%.0f' y2='%.1f' stroke='#888' stroke-width='0.7'/>", x0, vy(0), x0 + pw, vy(0))
    end
    for i:0..3                                # rechte Achse (Rp/kWh)
      var p = pmin + (pmax - pmin) * i / 3
      s += string.format("<text x='%.0f' y='%.1f' fill='#f5a623' font-size='10'>%.0f</text>", x0 + pw + 4, py(p) + 3.5, p / 100.0)
    end
    s += string.format("<text x='%.0f' y='20' fill='#47c266' font-size='8'>Rp/&#188;h</text>", x0 + 4)
    s += string.format("<text x='%.0f' y='20' fill='#f5a623' font-size='8' text-anchor='end'>Rp/kWh</text>", x0 + pw - 4)
    tasmota.web_send(s)

    s = ""                                    # Balken Vergütung
    for i:0..95
      var p = self.store.price(key, i)
      var e = self.store.energy_at(key, i)
      if p == nil || e == nil continue end
      var v = e * p
      var top = v >= 0 ? vy(v) : vy(0)
      var h = v >= 0 ? vy(0) - top : vy(v) - top
      if h < 0.3 h = 0.3 end
      s += string.format("<rect x='%.1f' y='%.1f' width='%.1f' height='%.1f' fill='%s'/>", x0 + i * bw, top, bw * 0.8, h, v >= 0 ? "#47c266" : "#ff5661")
      if i % 16 == 15
        tasmota.web_send(s)
        s = ""
      end
    end
    tasmota.web_send(s)

    s = ""                                    # Preislinie, Lücken bei fehlenden Werten
    var open_line = false
    for i:0..95
      var p = self.store.price(key, i)
      if p == nil
        if open_line
          s += "'/>"
          open_line = false
        end
        continue
      end
      if !open_line
        s += "<polyline fill='none' stroke='#f5a623' stroke-width='1.5' points='"
        open_line = true
      end
      s += string.format("%.1f,%.1f ", x0 + (i + 0.5) * bw, py(p))
      if i % 24 == 23
        tasmota.web_send(s)
        s = ""
      end
    end
    if open_line s += "'/>" end

    var xn = x0 + slot * bw                   # Jetzt-Marke, x-Achse, Stunden
    s += string.format("<line x1='%.1f' y1='10' x2='%.1f' y2='130' stroke='#1fa3ec' stroke-dasharray='3,2'/>", xn, xn)
    s += string.format("<line x1='%.0f' y1='130' x2='%.0f' y2='130' stroke='#aaa'/>", x0, x0 + pw)
    for h: [0, 6, 12, 18, 24]
      var x = x0 + pw * h / 24
      s += string.format("<line x1='%.1f' y1='130' x2='%.1f' y2='133' stroke='#aaa'/>", x, x)
      s += string.format("<text x='%.1f' y='148' fill='#aaa' font-size='11' text-anchor='middle'>%02d</text>", x, h)
    end
    s += "</svg>"
    tasmota.web_send(s)
  end

  # Telemetrie (tele/SENSOR, Status 10): ERWEITERUNGSPUNKT Übung C (MQTT/Drittsysteme)
  def json_append()
    if !spot_time_ok() return end
    var now = spot_now()
    var key = spot_day(now)
    var p = self.store.price(key, spot_slot(now))
    var sums = self.day_sums(key)
    tasmota.response_append(string.format(',"Spot":{"Price":%s,"EnergyToday":%.2f,"RevenueToday":%.2f}',
      p == nil ? "null" : string.format("%.4f", p / 10000.0), sums[0], sums[1]))
  end

  def save_before_restart()
    persist.save()
  end
end

# ============================ Start ====================================
# Erneutes load("spot") (Entwicklung): alte Instanz abmelden, sonst doppelte UI/Crons.
import global
if global.contains("spot") && global.spot != nil   # strict: kein direkter Zugriff auf undeklariertes `spot`
  tasmota.remove_driver(global.spot)
  tasmota.remove_cron("spot_q")
  tasmota.remove_cron("spot_h")
  tasmota.remove_rule("spot_t")
end
spot = SpotApp(spot_cfg)
tasmota.add_driver(spot)
tasmota.add_cmd("SpotPrices", /c, i, p -> spot.cmd_prices(c, i, p))
tasmota.add_cmd("SpotFetch",  /c, i, p -> spot.cmd_fetch(c, i, p))
tasmota.add_cmd("SpotTick",   /c, i, p -> spot.cmd_tick(c, i, p))
tasmota.add_cmd("SpotStatus", /c, i, p -> spot.cmd_status(c, i, p))
log(string.format("SPOT: v0.2 geladen, sim=%s, heap_free=%d kB", spot_cfg["sim"] ? "true" : "false", tasmota.memory("heap_free")), 2)
