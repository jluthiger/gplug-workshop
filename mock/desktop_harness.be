# stub of Tasmota runtime, enough to run spot_ui_mock.be on desktop Berry
import string
class Tas
  var out, drivers, cmds, resp
  def init() self.out = [] self.drivers = [] self.cmds = {} end
  def web_send(s) self.out.push(s) end
  def add_driver(d) self.drivers.push(d) end
  def add_cmd(n, f) self.cmds[n] = f end
  def memory(k) return 123 end
  def resp_cmnd(s) self.resp = s end
end
tasmota = Tas()
def log(m, l) print("LOG:", m) end

# tasmota.web_send handles {s}{m}{e}{t} tokens on device; emulate for the browser
def untoken(s)
  s = string.replace(s, "{t}", "<table style='width:100%'>")
  s = string.replace(s, "{s}", "<tr><th>")
  s = string.replace(s, "{m}", "</th><td>")
  s = string.replace(s, "{e}", "</td></tr>")
  return s
end

compile("spot_ui_mock.be", "file")()
assert(tasmota.drivers.size() == 1, "driver not registered")
var d = tasmota.drivers[0]

# command test
tasmota.cmds["SpotMockNow"]("SpotMockNow", 1, "30")
assert(d.now == 30, "cmd_now failed")
print("CMD:", tasmota.resp)
tasmota.cmds["SpotMockNow"]("SpotMockNow", 1, "999")
assert(d.now == 95)
tasmota.cmds["SpotMockNow"]("SpotMockNow", 1, "60")

# render
d.web_sensor()
var html = "<table style='width:100%'>"
for s: tasmota.out html += untoken(s) end
html += "</table>"
var f = open("sensor.html", "w")
f.write(html)
f.close()
print("CHUNKS:", tasmota.out.size(), "BYTES:", size(html))
