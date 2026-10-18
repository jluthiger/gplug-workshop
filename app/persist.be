# Desktop-Stub für das Tasmota-Modul persist (nur für desktop_harness.be). Nicht aufs Gerät laden.
class Persist
  var d
  def init() self.d = {} end
  def member(k) return self.d.find(k) end
  def setmember(k, v) self.d[k] = v end
  def find(k, dflt) return self.d.contains(k) ? self.d[k] : dflt end
  def has(k) return self.d.contains(k) end
  def save() print("PERSIST save", self.d) end
end
return Persist()
