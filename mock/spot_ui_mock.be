#- spot_ui_mock.be — UI-Mock für Entwurf 1 (ui-drafts/draft1_kompakt.png)
   Zweck: Darstellung auf dem echten gPlug prüfen. Keine Netzwerkzugriffe,
   keine Zählerwerte, nur synthetische Daten.
   Laden:  Br load("spot_ui_mock")      (Tasmota-Konsole)
   Test:   SpotMockNow 30               (verschiebt "jetzt" auf Slot 30 = 07:30)
   Tasmota >= 15.3.0

   Platzierung: Berry-Driver werden nach den C-Drivern (SML, gPlug) aufgerufen,
   unser HTML landet also unten im Sensorbereich <div id='l1'>. Ein <style>-Tag
   im gelieferten HTML wird vom Browser angewendet: #l1 wird Flex-Spalte, unser
   Block bekommt order:-1 und rutscht damit nach oben. Rein CSS, kein Script.
-#

import math
import string

class SpotMock
  var p      # 96 Preise, CHF/kWh (real)
  var e      # 96 Einspeisung pro 1/4h, kWh (real)
  var now    # aktueller Slot 0..95

  def init()
    self.now = 60                       # 15:00
    self.p = []
    self.e = []
    for i:0..95
      var h = i / 4.0
      var pr = 0.09
      pr += 0.07 * math.exp(-((h-7.5)*(h-7.5))/3)
      pr += 0.11 * math.exp(-((h-19.0)*(h-19.0))/4)
      pr -= 0.16 * math.exp(-((h-13.0)*(h-13.0))/3.5)   # Mittagsdelle, wird negativ
      self.p.push(pr)
      var en = 0.0
      if h >= 7.5 && h <= 18.0
        en = 0.45 * math.exp(-((h-12.7)*(h-12.7))/7)
      end
      self.e.push(en)
    end
  end

  # ---- SVG-Koordinaten (viewBox 340x158, Plot x 30..300, y 10..130) ----
  static X0 = 30.0
  static PW = 270.0                     # Plotbreite
  static BW = 270.0 / 96                # Slotbreite
  def vy(v)  return 130.0 - (v + 0.02) / 0.11 * 120.0 end   # Vergütung CHF/Slot, -0.02..0.09
  def py(pr) return 130.0 - (pr + 0.05) / 0.30 * 120.0 end  # Preis CHF/kWh, -0.05..0.25

  # ---- Hauptseite: wird bei jedem WebRefresh aufgerufen ----
  def web_sensor()
    var sum_e = 0.0
    var sum_v = 0.0
    for i:0..self.now-1
      sum_e += self.e[i]
      sum_v += self.e[i] * self.p[i]
    end
    var col = sum_v >= 0 ? "#47c266" : "#ff5661"

    # Sensor-Tabelle der Vorgänger schliessen (falls offen), eigenen Block öffnen,
    # per CSS an den Anfang von #l1 schieben
    tasmota.web_send("</table>"
      "<style>#l1{display:flex;flex-direction:column}</style>"
      "<div style='order:-1;width:100%'>")

    # Kopfzeilen, grösser als die normalen Sensorzeilen
    tasmota.web_send("<table style='width:100%;font-size:1.25em;margin:4px 0 2px'>")
    tasmota.web_send(string.format("<tr><th>Spotpreis jetzt</th><td style='color:#f5a623'>%.1f Rp/kWh</td></tr>", self.p[self.now] * 100))
    tasmota.web_send(string.format("<tr><th>Einspeisung heute</th><td>%.2f kWh</td></tr>", sum_e))
    tasmota.web_send(string.format("<tr><th>Vergütung heute</th><td style='color:%s'>%.2f CHF</td></tr>", col, sum_v))
    tasmota.web_send("</table>")

    self.send_svg()
    tasmota.web_send("<div style='font-size:.9em;color:#aaa;text-align:center;margin:2px 0 8px'>"
      "<span style='color:#47c266'>&#9632;</span> Vergütung/&#188;h &nbsp; "
      "<span style='color:#ff5661'>&#9632;</span> Kosten &nbsp; "
      "<span style='color:#f5a623'>&#8212;</span> Spotpreis &nbsp; "
      "<span style='color:#1fa3ec'>&#9478;</span> jetzt</div>")

    tasmota.web_send("{t}")
    tasmota.web_send(string.format("{s}Nächste Stunde{m}%.1f Rp/kWh{e}", self.p[(self.now + 4) % 96] * 100))
    tasmota.web_send("{s}Zähler Einspeisung{m}4'321.56 kWh{e}")
    tasmota.web_send("</table><hr style='border:0;border-top:1px solid #aaa;margin:8px 0'></div>")
    tasmota.web_send("{t}")             # Tabelle für nachfolgende Driver / Core wieder öffnen
  end

  def send_svg()
    var x0 = self.X0
    var bw = self.BW
    var s = "<svg viewBox='0 0 340 158' style='width:100%;display:block;margin:6px 0' xmlns='http://www.w3.org/2000/svg'>"
    # Gitter + linke Achse (Rp pro 1/4h)
    for v: [0.0, 0.03, 0.06, 0.09]
      var y = self.vy(v)
      s += string.format("<line x1='%.0f' y1='%.1f' x2='%.0f' y2='%.1f' stroke='#444' stroke-width='0.5'/>", x0, y, x0 + self.PW, y)
      s += string.format("<text x='%.0f' y='%.1f' fill='#47c266' font-size='10' text-anchor='end'>%d</text>", x0 - 4, y + 3.5, int(v * 100 + 0.5))
    end
    s += string.format("<text x='%.0f' y='20' fill='#47c266' font-size='8'>Rp/&#188;h</text>", x0 + 4)
    # rechte Achse (Rp/kWh)
    for pr: [-0.05, 0.05, 0.15, 0.25]
      s += string.format("<text x='%.0f' y='%.1f' fill='#f5a623' font-size='10'>%d</text>", x0 + self.PW + 4, self.py(pr) + 3.5, int(pr * 100 + (pr >= 0 ? 0.5 : -0.5)))
    end
    s += string.format("<text x='%.0f' y='20' fill='#f5a623' font-size='8' text-anchor='end'>Rp/kWh</text>", x0 + self.PW - 4)
    tasmota.web_send(s)

    # Balken Vergütung, in Häppchen senden
    s = ""
    for i:0..self.now-1
      var v = self.e[i] * self.p[i]
      var x = x0 + i * bw
      var top = v >= 0 ? self.vy(v) : self.vy(0)
      var bot = v >= 0 ? self.vy(0) : self.vy(v)
      var hgt = bot - top
      if hgt < 0.3 hgt = 0.3 end
      s += string.format("<rect x='%.1f' y='%.1f' width='%.1f' height='%.1f' fill='%s'/>", x, top, bw * 0.8, hgt, v >= 0 ? "#47c266" : "#ff5661")
      if i % 16 == 15
        tasmota.web_send(s)
        s = ""
      end
    end
    tasmota.web_send(s)

    # Preislinie
    s = "<polyline fill='none' stroke='#f5a623' stroke-width='1.5' points='"
    for i:0..95
      s += string.format("%.1f,%.1f ", x0 + (i + 0.5) * bw, self.py(self.p[i]))
      if i % 24 == 23
        tasmota.web_send(s)
        s = ""
      end
    end
    s += "'/>"

    # Jetzt-Marke, x-Achse, Stundenbeschriftung
    var xn = x0 + self.now * bw
    s += string.format("<line x1='%.1f' y1='10' x2='%.1f' y2='130' stroke='#1fa3ec' stroke-dasharray='3,2'/>", xn, xn)
    s += string.format("<line x1='%.0f' y1='130' x2='%.0f' y2='130' stroke='#aaa'/>", x0, x0 + self.PW)
    for h: [0, 6, 12, 18, 24]
      var x = x0 + self.PW * h / 24
      s += string.format("<line x1='%.1f' y1='130' x2='%.1f' y2='133' stroke='#aaa'/>", x, x)
      s += string.format("<text x='%.1f' y='148' fill='#aaa' font-size='11' text-anchor='middle'>%02d</text>", x, h)
    end
    s += "</svg>"
    tasmota.web_send(s)
  end

  # ---- Testkommando: SpotMockNow <slot 1..95> ----
  def cmd_now(cmd, idx, payload)
    var n = int(payload)
    if n < 1 n = 1 end
    if n > 95 n = 95 end
    self.now = n
    tasmota.resp_cmnd(string.format('{"SpotMockNow":%d}', n))
  end
end

spot_mock = SpotMock()
tasmota.add_driver(spot_mock)
tasmota.add_cmd("SpotMockNow", /cmd, idx, payload -> spot_mock.cmd_now(cmd, idx, payload))
log("SPOTMOCK: loaded, heap_free=" + str(tasmota.memory("heap_free")) + " kB", 2)
