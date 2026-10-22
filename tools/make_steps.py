#!/usr/bin/env python3
# Erzeugt Starter und Checkpoints aus der Referenz-App app/steps/spot_4.be. Die Stände
# unterscheiden sich nur in F3 (Chart) und wenigen Zeilen davor; alles andere kommt aus der Referenz.
#   tools/make_steps.py          prüft nur, ob app/spot.be (Starter) und app/steps/spot_1..3.be
#                                aktuell sind (Exit 1, wenn nicht)
#   tools/make_steps.py --write  schreibt sie neu. Überschreibt app/spot.be: nur zur Vorbereitung,
#                                nie am Workshop (dort ist app/spot.be die Arbeit der Teilnehmenden)
# Ablauf bei Änderungen: Referenz spot_4.be ändern und testen, dann dieses Skript, dann alle
# Stände mit dem Desktop-Harness prüfen. Änderungen in F3 der Referenz hier in f3() nachziehen.
import sys, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF = os.path.join(ROOT, "app", "steps", "spot_4.be")
TARGETS = {0: os.path.join(ROOT, "app", "spot.be")}
for _n in (1, 2, 3):
    TARGETS[_n] = os.path.join(ROOT, "app", "steps", "spot_%d.be" % _n)

base = open(REF).read()

HEAD_F3 = {
    0: "     F3  WebUI: Tageschart (96 Viertelstunden) mit Spotpreis und Jetzt-Marke, Cursor mit Werten\n",
    1: "     F3  WebUI: Tageschart (96 Viertelstunden) mit Einspeisung (Balken) und Spotpreis (Linie),\n         Jetzt-Marke, Cursor mit Werten\n",
    2: "     F3  WebUI: Tageschart (96 Viertelstunden) mit Einspeisung (Balken, orange bei Preis < 0) und\n         Spotpreis (Linie), Jetzt-Marke, Cursor mit Werten\n",
    3: "     F3  WebUI: 3 Tage mit Stundenwerten, Einspeisung (Balken, orange bei Preis < 0) und\n         Spotpreis (Linie), Jetzt-Marke, Cursor mit Werten\n",
    4: "     F3  WebUI: 3 Tage mit Stundenwerten. Oben Einspeisung (Balken) + Spotpreis (Linie),\n         unten Vergütung CHF/h mit Summe. Jetzt-Marke, Cursor mit Werten\n",
}
VARS = {
    0: "  var bw                  # Breite eines Werts in SVG-Einheiten (CH_W / CH_N)\n",
    3: "  var bw                  # Breite eines Werts in SVG-Einheiten (CH_W / CH_N)\n"
       "  var hp, he              # Stundenwerte des Charts (Preis, Energie), siehe fill_hours\n",
    4: "  var bw                  # Breite eines Werts in SVG-Einheiten (CH_W / CH_N)\n"
       "  var hp, he, hv          # Stundenwerte des Charts (Preis, Energie, Vergütung), siehe fill_hours\n",
}
VARS[1] = VARS[2] = VARS[0]
INIT = {
    0: "    self.bw = self.CH_W / self.CH_N\n",
    3: "    self.bw = self.CH_W / self.CH_N\n    self.hp = bytes(-(self.CH_N * 4))\n    self.he = bytes(-(self.CH_N * 4))\n",
    4: "    self.bw = self.CH_W / self.CH_N\n    self.hp = bytes(-(self.CH_N * 4))\n    self.he = bytes(-(self.CH_N * 4))\n    self.hv = bytes(-(self.CH_N * 4))\n",
}
INIT[1] = INIT[2] = INIT[0]


def cut(s, a, b):
    i = s.index(a)
    j = s.index(b, i)
    return s[:i], s[j:]


def f3(S):
    o = []
    w = o.append
    days = S >= 3
    w("""  # ---------------------------------------------------------------- F3  Chart
  # Sensorbereich = Kopfzeilen -> SVG -> Legende -> Fusszeilen. Tasmota ruft web_sensor() bei
  # jedem WebRefresh (2.3 s). Darum: ein Durchlauf pro Kurve und Versand in Häppchen
  # (tasmota.web_send), nie das ganze SVG als ein String. web_send nur aus web_sensor() und den
  # send_*-Helfern, nirgends sonst.
  #
""")
    if S == 0:
        w("""  # Das Chart zeigt den heutigen Tag mit 96 Viertelstunden: Spotpreis Rp/kWh als Linie, Achse rechts.
  # Einheiten aus dem Ringpuffer: Preis 1/10000 CHF/kWh (Rp/kWh = p/100), Energie 0.01 kWh.
  # nil = kein Wert = Lücke im Chart.
""")
    elif S <= 2:
        w("""  # Das Chart zeigt den heutigen Tag mit 96 Viertelstunden: Einspeisung kWh/¼h als Balken
  # (Achse links), Spotpreis Rp/kWh als Linie (Achse rechts); 0 kWh liegt auf 0 Rp.
  # Einheiten aus dem Ringpuffer: Preis 1/10000 CHF/kWh (Rp/kWh = p/100), Energie 0.01 kWh.
  # nil = kein Wert = Lücke im Chart.
""")
    elif S == 3:
        w("""  # Das Chart zeigt 72 Stunden = 3 Tage: Einspeisung kWh/h als Balken (orange bei Preis < 0,
  # Achse links), Spotpreis Rp/kWh als Linie (Achse rechts), Bereich unter 0 Rp schattiert.
  # Stundenwerte einmal pro Aufruf rechnen (fill_hours): Preis 1/10000 CHF/kWh (Mittel der 4
  # Viertelstunden), Energie 0.01 kWh (Summe). nil = Lücke. Tage mit 23/25 h (DST) als 24 h gezeichnet.
""")
    else:
        w("""  # Das SVG enthält zwei Charts mit gemeinsamer x-Achse (72 Stunden = 3 Tage):
  #   oben   Einspeisung kWh/h als Balken (orange bei Preis < 0), Spotpreis Rp/kWh als Linie,
  #          Bereich unter 0 Rp schattiert. Achse links kWh, rechts Rp; 0 kWh liegt auf 0 Rp.
  #   unten  Vergütung CHF/h als Balken (gelb, rot bei < 0), Achse links CHF, Summe oben rechts.
  # Stundenwerte einmal pro Aufruf rechnen (fill_hours): Preis 1/10000 CHF/kWh (Mittel der 4
  # Viertelstunden), Energie 0.01 kWh (Summe), Vergütung 1e-6 CHF (Summe von Energie x Preis).
  # nil = Lücke im Chart. Tage mit 23/25 h (DST) werden als 24 h gezeichnet.
""")
    # Erweiterungspunkte für die noch offenen Schritte
    hints = {
        1: """  # ERWEITERUNGSPUNKT Schritt 1 (Energie-Balken): Kurve 'e' in chart_curves(), neue Methode
  #   send_bars (ein Balken pro Wert ab y_of(0), Häppchen wie send_polyline), kWh-Skala mit 0 auf
  #   der 0-Rp-Linie, kWh-Beschriftung links in send_axes, data-e in send_svg_open (der Cursor zeigt
  #   dann kWh). Farbe COL_ENERGY.
""",
        2: """  # ERWEITERUNGSPUNKT Schritt 2 (Negativpreis): Balkenfarbe COL_NEG statt COL_ENERGY, wenn der Preis
  #   im selben Wert < 0 ist; in send_axes den Bereich unter der 0-Rp-Linie schattieren, nur wenn
  #   es negative Preise gibt. Legendentext von 'e' ergänzen.
""",
        3: """  # ERWEITERUNGSPUNKT Schritt 3 (3 Tage, Stundenwerte): CH_N = 72, CH_MIN = 60; Stundenwerte einmal
  #   pro web_sensor in feste bytes-Puffer rechnen; value_range, send_bars, send_polyline lesen dann
  #   daraus. send_x_axis mit Tagesgrenzen und Tagesnamen, data-d für den Cursor.
""",
        4: """  # ERWEITERUNGSPUNKT Schritt 4 (Vergütung): zweites Chart unterhalb (viewBox höher), Vergütung
  #   pro Stunde in fill_hours mitrechnen, Balken mit send_bars, Summe über alle Stunden, data-v
  #   für den Cursor (zeigt dann CHF).
""",
    }
    rest = [hints[k] for k in range(S + 1, 5)]
    if rest:
        w("  #\n" + "".join(rest))
    w("\n")
    # Geometrie
    if S == 4:
        w("""  # Geometrie des SVG (viewBox 0 -8 340 254; y < 0 ist Platz für die Cursor-Werte):
  static CH_X0 = 30.0
  static CH_W = 270.0
  static CH_Y_TOP = 10.0         # oberes Chart
  static CH_Y_BASE = 130.0
  static CH_H = 120.0
  static CV_Y_TOP = 180.0        # unteres Chart (Vergütung)
  static CV_Y_BASE = 232.0
  static CV_H = 52.0
""")
    else:
        w("""  # Geometrie des SVG (viewBox 0 -8 340 166; y < 0 ist Platz für die Cursor-Werte):
  static CH_X0 = 30.0
  static CH_W = 270.0
  static CH_Y_TOP = 10.0
  static CH_Y_BASE = 130.0
  static CH_H = 120.0
""")
    if days:
        w("""  static CH_N = 72               # Werte im Chart: Stunden von 3 Tagen
  static CH_MIN = 60             # Minuten pro Wert
  static CH_SEND_EVERY = 24      # nach so vielen Werten wird der Teilstring gesendet
  static INV = 0x7FFFFFFF        # ungültiger Stundenwert in den Puffern von fill_hours
  static DAY_NAMES = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"]
""")
    else:
        w("""  static CH_N = 96               # Werte im Chart: Viertelstunden eines Tages (DST-Tage: 92/100, Rest fällt weg)
  static CH_MIN = 15             # Minuten pro Wert
  static CH_SEND_EVERY = 24      # nach so vielen Werten wird der Teilstring gesendet
""")
    if S >= 1:
        w("""  static E_STEPS = [5, 10, 20, 25, 50, 100, 200, 250, 500, 1000]   # Achsenstufen kWh (0.01 kWh)
""")
    w("""  static P_STEPS = [100, 200, 500, 1000, 2000, 5000, 10000]          # Achsenstufen Rp (1/10000 CHF)

  # Farben (Legende, Kurven, Kopfzeilen, Cursor-Script)
  static COL_ENERGY = "#7bc96f"
  static COL_NEG = "#f0a35e"
  static COL_PRICE = "#5bc8f5"
  static COL_PAY = "#f5d04c"
  static COL_COST = "#ff6b6b"
  static COL_NOW = "#bbb"
  static COL_AXIS = "#aaa"
  static COL_GRID = "#444"
  static COL_ZERO = "#888"

  # Kurven des Charts, eine Zeile pro Kurve: [Kurzbuchstabe k, Legenden-HTML].
  # Daraus folgen: SVG-Gruppe id='s<k>', Legenden-Span id='l<k>', Body-Klasse 'h<k>' = ausgeblendet.
  def chart_curves()
    return [
""")
    if S == 1:
        w("""      ["e", string.format("<span style='color:%s'>&#9632;</span> Einspeisung", self.COL_ENERGY)],
""")
    elif S >= 2:
        w("""      ["e", string.format("<span style='color:%s'>&#9632;</span> Einspeisung &nbsp; "
                          "<span style='color:%s'>&#9632;</span> bei Preis &lt; 0", self.COL_ENERGY, self.COL_NEG)],
""")
    w("""      ["p", string.format("<span style='color:%s'>&#8212;</span> Spotpreis", self.COL_PRICE)],
""")
    if S == 4:
        w("""      ["v", string.format("<span style='color:%s'>&#9632;</span> Vergütung", self.COL_PAY)],
""")
    w("""      ["n", string.format("<span style='color:%s'>&#9478;</span> jetzt", self.COL_NOW)]
    ]
  end

  # Legende + CSS aus chart_curves(), einmal in init() gebaut (self.legend_html).
  # Klick auf einen Eintrag schaltet die Body-Klasse 'h<k>' um; das CSS blendet dann die SVG-Gruppe
  # aus und dimmt den Eintrag. Zustand auf <body>, weil Tasmota den Sensorbereich alle paar
  # Sekunden per AJAX ersetzt; Scripts darin laufen nicht, Klassen auf <body> überleben.
  def build_legend()
    var hide = []
    var dim = []
    var spans = []
    for c: self.chart_curves()
      hide.push(string.format("body.h%s #s%s", c[0], c[0]))
      dim.push(string.format("body.h%s #l%s", c[0], c[0]))
      spans.push(string.format("<span id='l%s' onclick=\\"document.body.classList.toggle('h%s')\\">%s</span>", c[0], c[0], c[1]))
    end
    return "<style>" + hide.concat(",") + "{display:none}" + dim.concat(",") + "{opacity:.35}</style>"
      "<div style='font-size:.9em;color:#aaa;text-align:center;margin:2px 0 8px;cursor:pointer;user-select:none'>"
      + spans.concat(" &nbsp; ") + "</div>"
  end

  # ---- Werte und Skalen
""")
    if days:
        w("""  # Erster Tag des Charts: 3 Tage bis heute, oder bis morgen, sobald Preise für morgen da sind.
  def chart_start(now)
    var key = spot_day(now)
    return self.store.count(self.store.prices, key + 86400) > 0 ? key - 86400 : key - 2 * 86400
  end

""")
        if S == 3:
            w("""  # Stundenwerte der 72 Stunden ab start in hp/he schreiben (je 4 Byte pro Stunde).
  # Ein Durchlauf über die Viertelstunden; alle Kurven lesen danach nur noch hour_*().
  def fill_hours(start)
    for i:0..self.CH_N-1
      var key = start + (i / 24) * 86400
      var s0 = (i % 24) * 4
      var ps = 0  var pn = 0  var es = 0  var en = 0
      for s:s0..s0+3
        var p = self.store.price(key, s)
        var e = self.store.energy_at(key, s)
        if p != nil  ps += p  pn += 1 end
        if e != nil  es += e  en += 1 end
      end
      self.hp.seti(i * 4, pn > 0 ? spot_round(ps / real(pn)) : self.INV, 4)
      self.he.seti(i * 4, en > 0 ? es : self.INV, 4)
    end
  end

  def hour_get(buf, i)
    var v = buf.geti(i * 4, 4)
    return v == self.INV ? nil : v
  end
  def hour_p(i) return self.hour_get(self.hp, i) end
  def hour_e(i) return self.hour_get(self.he, i) end

""")
        else:
            w("""  # Stundenwerte der 72 Stunden ab start in hp/he/hv schreiben (je 4 Byte pro Stunde).
  # Ein Durchlauf über die Viertelstunden; alle Kurven lesen danach nur noch hour_*().
  def fill_hours(start)
    for i:0..self.CH_N-1
      var key = start + (i / 24) * 86400
      var s0 = (i % 24) * 4
      var ps = 0  var pn = 0  var es = 0  var en = 0  var vs = 0.0  var vn = 0
      for s:s0..s0+3
        var p = self.store.price(key, s)
        var e = self.store.energy_at(key, s)
        if p != nil  ps += p  pn += 1 end
        if e != nil  es += e  en += 1 end
        if p != nil && e != nil  vs += e * p  vn += 1 end
      end
      self.hp.seti(i * 4, pn > 0 ? spot_round(ps / real(pn)) : self.INV, 4)
      self.he.seti(i * 4, en > 0 ? es : self.INV, 4)
      self.hv.seti(i * 4, vn > 0 ? spot_round(vs) : self.INV, 4)
    end
  end

  def hour_get(buf, i)
    var v = buf.geti(i * 4, 4)
    return v == self.INV ? nil : v
  end
  def hour_p(i) return self.hour_get(self.hp, i) end
  def hour_e(i) return self.hour_get(self.he, i) end
  def hour_v(i) return self.hour_get(self.hv, i) end

""")
    w("""  # Wertebereich [lo, hi] der Chart-Werte: lo <= 0, hi >= floor, damit die Achse nie entartet.
  # value_at(i) liefert den Rohwert (int) oder nil.
  def value_range(value_at, floor)
    var lo = 0
    var hi = floor
    for i:0..self.CH_N-1
      var v = value_at(i)
      if v == nil continue end
      if v < lo lo = v end
      if v > hi hi = v end
    end
    return [lo, hi]
  end

  # Achse mit runden Stufen: [lo, hi] auf ein Vielfaches von step erweitern, höchstens 4 Stufen.
  # steps: aufsteigende Kandidaten in der Einheit der Werte. 0 liegt immer auf einer Stufe.
  def nice_range(r, steps)
    var step = steps[-1]
    for c: steps
      if (r[1] - r[0]) <= 4 * c  step = c  break end
    end
    var lo = -((-r[0] + step - 1) / step) * step
    var hi = ((r[1] + step - 1) / step) * step
    return [lo, hi, step]
  end

  # Lineare y-Skala: Wert lo -> base (unten), hi -> base - h (oben). Liefert eine Funktion.
  # x-Position eines Werts i: linker Rand CH_X0 + i * bw, Mitte CH_X0 + (i + 0.5) * bw.
  def y_scale(lo, hi, base, h)
    return / v -> base - (v - lo) * h / (hi - lo)
  end

  # ---- Sensorbereich
  def web_sensor()
    if !spot_time_ok() return end
    try
      var now = spot_now()
      var key = spot_day(now)
      self.send_header(key, spot_slot(now), self.day_sums(key))
""")
    if days:
        w("""      var start = self.chart_start(now)
      self.fill_hours(start)
      self.send_svg(start, now)
""")
    else:
        w("""      self.send_svg(key, now)
""")
    w("""      tasmota.web_send(self.legend_html)
      self.send_footer(now)
    except .. as e, m
      log("SPOT: web_sensor " + str(e) + " " + str(m), 2)
    end
  end

""")
    # Kopf und Fuss unverändert aus der Referenz
    hf = base[base.index("  # Kopfzeilen oberhalb des Tasmota-Hauptmenüs."):base.index("  # ---- SVG")]
    w(hf)
    # ---- SVG
    P = "self.hour_p(i)" if days else "self.store.price(start, i)"
    E = "self.hour_e(i)" if days else "self.store.energy_at(start, i)"
    first = "start" if days else "start"
    if S == 4:
        w("""  # ---- SVG
  # Beide Charts in einem SVG, damit Cursor und x-Achse gemeinsam sind. Jede Kurve ist eine
  # SVG-Gruppe id='s<k>' (siehe chart_curves).
  def send_svg(start, now)
""")
    else:
        w("""  # ---- SVG
  # Das Chart ab start (lokale Mitternacht des ersten Tages). Jede Kurve ist eine SVG-Gruppe
  # id='s<k>' (siehe chart_curves).
  def send_svg(start, now)
""")
    if S >= 1:
        w(f"""    var er = self.nice_range(self.value_range(/ i -> {E}, 10), self.E_STEPS)    # 0.01 kWh
""")
    w(f"""    var pr = self.nice_range(self.value_range(/ i -> {P}, 100), self.P_STEPS)   # 1/10000 CHF/kWh
""")
    if S == 4:
        w("""    var vr = self.value_range(/ i -> self.hour_v(i), 10000)     # 1e-6 CHF, mind. 0.01 CHF
""")
    w("""    var py = self.y_scale(pr[0], pr[1], self.CH_Y_BASE, self.CH_H)
""")
    if S >= 1:
        w("""    var y0 = py(0)
    var ey = self.y_scale(0, er[1], y0, y0 - self.CH_Y_TOP)    # 0 kWh auf der 0-Rp-Linie
""")
    if S == 4:
        w("""    var vy = self.y_scale(vr[0], vr[1], self.CV_Y_BASE, self.CV_H)
""")
    w("""    self.send_svg_open(start)
""")
    w("""    self.send_axes(ey, py, er, pr)
""" if S >= 1 else """    self.send_axes(py, pr)
""")
    if S == 1:
        w(f"""    self.send_bars("e", / i -> {E}, / i, v -> self.COL_ENERGY, ey)
""")
    elif S == 2:
        w(f"""    self.send_bars("e", / i -> {E}, / i, v -> self.energy_color(start, i), ey)
""")
    elif S >= 3:
        w(f"""    self.send_bars("e", / i -> {E}, / i, v -> self.energy_color(i), ey)
""")
    w(f"""    self.send_polyline("p", self.COL_PRICE, / i -> {P}, py)
    self.send_x_axis(start)
""")
    if S == 4:
        w("""    self.send_pay_axes(vy, vr)
    self.send_bars("v", / i -> self.hour_v(i), / i, v -> v < 0 ? self.COL_COST : self.COL_PAY, vy)
""")
    w("""    self.send_now_marker("n", start, now)
    tasmota.web_send("</svg>")
  end

""")
    if S == 2:
        w("""  # Einspeisung bei negativem Preis kostet: orange statt grün
  def energy_color(key, i)
    var p = self.store.price(key, i)
    return p != nil && p < 0 ? self.COL_NEG : self.COL_ENERGY
  end

""")
    if S >= 3:
        w("""  # Einspeisung bei negativem Preis kostet: orange statt grün
  def energy_color(i)
    var p = self.hour_p(i)
    return p != nil && p < 0 ? self.COL_NEG : self.COL_ENERGY
  end

  # Tagesbezeichnung "Do 11.06." für den Tag key (lokale Mitternacht; 1.1.1970 war ein Donnerstag)
  def day_label(key)
    return self.DAY_NAMES[(key / 86400 + 4) % 7] + " " + tasmota.strftime("%d.%m.", key)
  end

""")
    # svg open
    attrs = "data-p / data-e / data-v" if S == 4 else ("data-p / data-e" if S >= 1 else "data-p")
    w(f"""  # Öffnendes <svg>. Vertrag mit dem Cursor-Script (web_add_main_button): #spotsvg trägt
  # data-x0, data-bw (SVG-Einheiten), data-n (Anzahl Werte), data-m (Minuten pro Wert), data-y2
  # (Unterkante der Cursor-Linie){", data-d (3 Tagesbezeichnungen)" if days else ""} und {attrs} (Werte oder '-').
  # Das Script zeigt Zeit und jeden vorhandenen Wert: data-p Rp/kWh, data-e kWh, data-v CHF.
  def send_svg_open(start)
""")
    vb = "254" if S == 4 else "166"
    y2 = "self.CV_Y_BASE" if S == 4 else "self.CH_Y_BASE"
    if days:
        w(f"""    tasmota.web_send(string.format("<svg id='spotsvg' viewBox='0 -8 340 {vb}' style='width:100%%;display:block;margin:24px 0 6px' "
      "xmlns='http://www.w3.org/2000/svg' data-x0='%.0f' data-bw='%.4f' data-n='%d' data-m='%d' data-y2='%.0f' data-d='%s,%s,%s'",
      self.CH_X0, self.bw, self.CH_N, self.CH_MIN, {y2},
      self.day_label(start), self.day_label(start + 86400), self.day_label(start + 2 * 86400)))
""")
    else:
        w(f"""    tasmota.web_send(string.format("<svg id='spotsvg' viewBox='0 -8 340 {vb}' style='width:100%%;display:block;margin:24px 0 6px' "
      "xmlns='http://www.w3.org/2000/svg' data-x0='%.0f' data-bw='%.4f' data-n='%d' data-m='%d' data-y2='%.0f'",
      self.CH_X0, self.bw, self.CH_N, self.CH_MIN, {y2}))
""")
    w(f"""    self.send_data_attr("p", / i -> {P})
""")
    if S >= 1:
        w(f"""    self.send_data_attr("e", / i -> {E})
""")
    if S == 4:
        w("""    self.send_data_attr("v", / i -> self.hour_v(i))
""")
    w("""    tasmota.web_send(">")
  end

  # Ein Attribut data-<name>='w0,w1,...' mit allen Werten ('-' = keiner). In Häppchen von
  # CH_SEND_EVERY Werten gesendet, damit nie die ganze Liste als String im RAM liegt.
  def send_data_attr(name, value_at)
    var s = " data-" + name + "='"
    for i:0..self.CH_N-1
      var v = value_at(i)
      s += (v == nil ? "-" : str(v)) + (i < self.CH_N-1 ? "," : "'")
      if i % self.CH_SEND_EVERY == self.CH_SEND_EVERY - 1
        tasmota.web_send(s)
        s = ""
      end
    end
  end

""")
    # axes
    if S == 0:
        w("""  # Gitter und Preisachse rechts in runden Stufen (nice_range), Nulllinie, Einheit oben.
  # Weitere Achsen nur nach Rückfrage (AGENTS.md).
  def send_axes(py, pr)
    var x0 = self.CH_X0
    var x1 = self.CH_X0 + self.CH_W
    var s = ""
""")
    else:
        w("""  # Gitter und Preisachse rechts in runden Stufen (nice_range), Nulllinie, kWh-Achse links,
  # Einheiten oben. Weitere Achsen nur nach Rückfrage (AGENTS.md).
  def send_axes(ey, py, er, pr)
    var x0 = self.CH_X0
    var x1 = self.CH_X0 + self.CH_W
    var y0 = py(0)
    var s = ""
""")
    if S >= 2:
        w("""    if pr[0] < 0
      s += string.format("<rect x='%.0f' y='%.1f' width='%.0f' height='%.1f' fill='%s' fill-opacity='.12'/>", x0, y0, self.CH_W, self.CH_Y_BASE - y0, self.COL_COST)
      s += string.format("<text x='%.0f' y='%.0f' fill='%s' font-size='8'>negativer Preis</text>", x0 + 4, self.CH_Y_BASE - 4, self.COL_COST)
    end
""")
    w("""    var p = pr[0]
    while p <= pr[1]
      s += string.format("<line x1='%.0f' y1='%.1f' x2='%.0f' y2='%.1f' stroke='%s' stroke-width='0.5'/>", x0, py(p), x1, py(p), self.COL_GRID)
      s += string.format("<text x='%.0f' y='%.1f' fill='%s' font-size='10'>%.0f</text>", x1 + 4, py(p) + 3.5, self.COL_PRICE, p / 100.0)
      p += pr[2]
    end
    s += string.format("<line x1='%.0f' y1='%.1f' x2='%.0f' y2='%.1f' stroke='%s' stroke-width='0.7'/>", x0, py(0), x1, py(0), self.COL_ZERO)
""")
    if S >= 1:
        w("""    var e = 0
    while e <= er[1]
      s += string.format("<text x='%.0f' y='%.1f' fill='%s' font-size='10' text-anchor='end'>%s</text>", x0 - 4, ey(e) + 3.5, self.COL_ENERGY,
        e == 0 ? "0" : string.format(er[2] % 10 == 0 ? "%.1f" : "%.2f", e / 100.0))
      e += er[2]
    end
    s += string.format("<text x='%.0f' y='4' fill='%s' font-size='8' text-anchor='end'>kWh</text>", x0 - 4, self.COL_ENERGY)
""")
    w("""    s += string.format("<text x='%.0f' y='4' fill='%s' font-size='8'>Rp.</text>", x1 + 4, self.COL_PRICE)
    tasmota.web_send(s)
  end

""")
    if S == 4:
        w(base[base.index("  # Unteres Chart: Titel, Summe"):base.index("  # Balken pro ")])
    if S >= 1:
        w("""  # Balken pro Wert in der Gruppe id='s<cid>': ab der Nulllinie y_of(0) nach oben bzw. unten.
  # value_at(i) -> Rohwert oder nil (kein Balken), color_at(i, v) -> Farbe.
  def send_bars(cid, value_at, color_at, y_of)
    var s = string.format("<g id='s%s'>", cid)
    var bw = self.bw
    var y0 = y_of(0)
    for i:0..self.CH_N-1
      var v = value_at(i)
      if v != nil
        var top = v >= 0 ? y_of(v) : y0
        var h = v >= 0 ? y0 - top : y_of(v) - y0
        if h < 0.3 h = 0.3 end
        s += string.format("<rect x='%.1f' y='%.1f' width='%.1f' height='%.1f' fill='%s'/>",
          self.CH_X0 + i * bw + bw * 0.1, top, bw * 0.8, h, color_at(i, v))
      end
      if i % self.CH_SEND_EVERY == self.CH_SEND_EVERY - 1
        tasmota.web_send(s)
        s = ""
      end
    end
    tasmota.web_send(s + "</g>")
  end

""")
    w(base[base.index("  # Eine Kurve als Linie in der Gruppe"):base.index("  # Gestrichelte Marke")])
    # now marker
    w("""  # Gestrichelte Marke "jetzt"%s.
  def send_now_marker(cid, start, now)
    var xn = self.CH_X0 + (now - start) * self.bw / (self.CH_MIN * 60)
    if xn < self.CH_X0 || xn > self.CH_X0 + self.CH_W return end
    var s = string.format("<g id='s%%s' stroke='%%s' stroke-dasharray='3,2'>", cid, self.COL_NOW)
    s += string.format("<line x1='%%.1f' y1='%%.0f' x2='%%.1f' y2='%%.0f'/>", xn, self.CH_Y_TOP, xn, self.CH_Y_BASE)
""" % (" in beiden Charts" if S == 4 else ""))
    if S == 4:
        w("""    s += string.format("<line x1='%.1f' y1='%.0f' x2='%.1f' y2='%.0f'/>", xn, self.CV_Y_TOP, xn, self.CV_Y_BASE)
""")
    w("""    s += string.format("<text x='%.1f' y='%.0f' fill='%s' stroke='none' font-size='7' text-anchor='middle'>jetzt</text></g>", xn, self.CH_Y_TOP - 3, self.COL_NOW)
    tasmota.web_send(s)
  end

""")
    # x axis
    if days:
        x = base[base.index("  # Grundlinie, Marken 00 und 12"):base.index("  # ---- Cursor-Script")]
        if S == 3:
            x = x.replace("Tagesgrenzen gestrichelt über beide Charts", "Tagesgrenzen gestrichelt")
            x = x.replace("""      if d > 0                                       # nicht durch die Beschriftung, darum zwei Stücke
        s += string.format("<line x1='%.1f' y1='%.0f' x2='%.1f' y2='%.0f' stroke='%s' stroke-dasharray='2,3'/>", x, self.CH_Y_TOP, x, self.CH_Y_BASE, self.COL_AXIS)
        s += string.format("<line x1='%.1f' y1='%.0f' x2='%.1f' y2='%.0f' stroke='%s' stroke-dasharray='2,3'/>", x, self.CV_Y_TOP, x, self.CV_Y_BASE, self.COL_AXIS)
      end""", """      if d > 0
        s += string.format("<line x1='%.1f' y1='%.0f' x2='%.1f' y2='%.0f' stroke='%s' stroke-dasharray='2,3'/>", x, self.CH_Y_TOP, x, self.CH_Y_BASE, self.COL_AXIS)
      end""")
            assert "CV_" not in x
        w(x)
    else:
        w("""  # Grundlinie und Stundenmarken 00..24.
  def send_x_axis(start)
    var x0 = self.CH_X0
    var y = self.CH_Y_BASE
    var s = string.format("<line x1='%.0f' y1='%.0f' x2='%.0f' y2='%.0f' stroke='%s'/>", x0, y, x0 + self.CH_W, y, self.COL_AXIS)
    for h: [0, 6, 12, 18, 24]
      var x = x0 + self.CH_W * h / 24
      s += string.format("<line x1='%.1f' y1='%.0f' x2='%.1f' y2='%.0f' stroke='%s'/>", x, y, x, y + 3, self.COL_AXIS)
      s += string.format("<text x='%.1f' y='%.0f' fill='%s' font-size='11' text-anchor='middle'>%02d</text>", x, y + 18, self.COL_AXIS, h)
    end
    tasmota.web_send(s)
  end

""")
    # cursor (identisch in allen Stufen)
    w("""  # ---- Cursor-Script
  # Cursor-Linie mit Werten beim Überfahren/Antippen des Charts. Das Script steht ausserhalb des
  # Sensorbereichs (web_add_main_button rendert unterhalb der Sensoren) und läuft einmal pro
  # Seitenaufruf; im Sensorbereich liefe es nie, weil Tasmota den per AJAX ersetzt. Ablauf:
  #   1. bei jeder Mausbewegung das aktuelle #spotsvg suchen (nach jedem Refresh ein neues Element)
  #   2. einmal eine Gruppe <g id='cur'> mit Linie und Text anhängen
  #   3. Mausposition -> SVG-x -> Wert i (data-x0, data-bw, data-n)
  #   4. Zeit aus i und data-m (mit Tag aus data-d, falls vorhanden), dazu jeder vorhandene Wert:
  #      data-p Rp/kWh, data-e kWh, data-v CHF. Neue Werte brauchen nur ihr data-Attribut.
  #   5. MutationObserver auf #l1: nach jedem AJAX-Refresh letzte Mausposition erneut anwenden
  # Gleich in allen Ausbaustufen. Der String ist absichtlich kompakt; Änderungen nur mit Test im Browser.
  def web_add_main_button()
    import webserver
    webserver.content_send(string.format("<script>(function(){var N='http://www.w3.org/2000/svg',L=null;"
      "function f(ev){var s=document.getElementById('spotsvg');if(!s)return;var d=s.dataset;"
      "var g=s.getElementById('cur');if(!g){g=document.createElementNS(N,'g');g.id='cur';"
      "g.innerHTML=\\"<line y1='10' y2='\\"+d.y2+\\"' stroke='#fff' stroke-width='.7'/><text x='170' y='-1' font-size='9' fill='#fff' text-anchor='middle'></text>\\";s.appendChild(g);}"
      "var t=ev.touches?ev.touches[0]:ev;L={clientX:t.clientX,clientY:t.clientY};"
      "var el=document.elementFromPoint(t.clientX,t.clientY);if(!el||!el.closest('#spotsvg')){g.style.display='none';return;}"
      "var r=s.getBoundingClientRect(),x=(t.clientX-r.left)*340/r.width,x0=+d.x0,bw=+d.bw,i=Math.floor((x-x0)/bw);"
      "if(i<0||i>=+d.n){g.style.display='none';return;}g.style.display='';"
      "var xc=x0+(i+.5)*bw,l=g.firstChild,tx=g.lastChild;l.setAttribute('x1',xc);l.setAttribute('x2',xc);"
      "function a(k){return d[k]?d[k].split(',')[i]:'-'}var p=a('p'),e=a('e'),v=a('v'),mm=i*d.m;"
      "var h=(d.d?d.d.split(',')[Math.floor(mm/1440)]+' ':'')+('0'+Math.floor(mm%%1440/60)).slice(-2)+':'+('0'+mm%%60).slice(-2);"
      "tx.innerHTML=h+'  <tspan fill=\\"%s\\">'+(p=='-'?'–':(p/100).toFixed(1)+' Rp/kWh')+'</tspan>'"
      "+(e=='-'?'':' · <tspan fill=\\"%s\\">'+(e/100).toFixed(2)+' kWh</tspan>')"
      "+(v=='-'?'':' · <tspan fill=\\"'+(v<0?'%s':'%s')+'\\">'+(v/1e6).toFixed(3)+' CHF</tspan>');}"
      "document.addEventListener('mousemove',f);document.addEventListener('touchstart',f,{passive:true});document.addEventListener('touchmove',f,{passive:true});"
      "var l1=document.getElementById('l1');if(l1)new MutationObserver(function(){if(L)f(L);}).observe(l1,{childList:true});})();</script>",
      self.COL_PRICE, self.COL_ENERGY, self.COL_COST, self.COL_PAY))
  end

""")
    return "".join(o)


def stage(S):
    s = base
    a, b = cut(s, "     F3  WebUI:", "     F4  ")
    s = a + HEAD_F3[S] + b
    a, b = cut(s, "  var bw  ", "\n  def init(cfg)")
    s = a + VARS[S] + b
    a, b = cut(s, "    self.bw = self.CH_W / self.CH_N\n", "    self.legend_html")
    s = a + INIT[S] + b
    a, b = cut(s, "  # ---------------------------------------------------------------- F3  Chart", "  # Telemetrie (tele/SENSOR")
    return a + f3(S) + b


def main():
    write = "--write" in sys.argv[1:]
    # Die Referenz muss sich selbst reproduzieren, sonst passt f3() nicht mehr zur Referenz
    if stage(4) != base:
        print("FEHLER: f3() erzeugt nicht mehr die Referenz spot_4.be, Generator nachziehen")
        return 1
    stale = 0
    for S, path in sorted(TARGETS.items()):
        s = stage(S)
        old = open(path).read() if os.path.exists(path) else None
        rel = os.path.relpath(path, ROOT)
        if old == s:
            print("OK      " + rel)
        elif write:
            open(path, "w").write(s)
            print("GESCHRIEBEN " + rel + " (%d Byte)" % len(s))
        else:
            print("VERALTET " + rel)
            stale += 1
    return 1 if stale else 0


if __name__ == "__main__":
    sys.exit(main())
