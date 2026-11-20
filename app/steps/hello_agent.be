# hello_agent.be – Schritt 0 (Teil B): Hello World, vom Agenten erstellt
# Musterlösung. Hochladen ohne Neustart, danach laden:
#   ./upload.sh --no-restart app/hello_agent.be
#   ./brcmd.sh 'load("hello_agent")'
# Steht nicht in autoexec.be: der nächste BrRestart (Upload von spot.be) entfernt die App.

import global

class HelloAgent
  # Zeile im Sensorbereich der WebUI, wird alle paar Sekunden neu geholt
  def web_sensor()
    try
      var heap = tasmota.memory("heap_free")
      tasmota.web_send("{s}Hallo opencode{m}Heap frei " + str(heap) + " kB{e}")
    except .. as e, m
      log("HELLO: web_sensor " + str(e) + " " + str(m), 2)
    end
  end
end

# Nochmals laden ersetzt die alte Instanz, statt eine zweite Zeile anzuhängen
if global.contains("hello_agent") && global.hello_agent != nil
  tasmota.remove_driver(global.hello_agent)
end
global.hello_agent = HelloAgent()
tasmota.add_driver(global.hello_agent)
log("HELLO: Hallo vom Agenten", 2)
