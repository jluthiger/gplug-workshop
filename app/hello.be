# hello.be – Schritt 0: Hello World auf dem gPlug
# Von Hand hochladen (Werkzeuge -> Dateisystem verwalten), laden in der Konsole mit:
#   Br load("hello")
# Steht nicht in autoexec.be: der nächste BrRestart (Upload des Starters) entfernt die App.

import global

class Hello
  var start                       # tasmota.millis() beim Laden

  def init()
    self.start = tasmota.millis()
  end

  # Zeile im Sensorbereich der WebUI, wird alle paar Sekunden neu geholt
  def web_sensor()
    var s = (tasmota.millis() - self.start) / 1000
    tasmota.web_send("{s}Hallo gPlug{m}läuft seit " + str(s) + " s{e}")
  end
end

# Nochmals laden ersetzt die alte Instanz, statt eine zweite Zeile anzuhängen
if global.contains("hello") && global.hello != nil
  tasmota.remove_driver(global.hello)
end
global.hello = Hello()
tasmota.add_driver(global.hello)
log("HELLO: Hallo Welt", 2)
