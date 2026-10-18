# Desktop-Stub für das Tasmota-Modul path (nur für desktop_harness.be). Nicht aufs Gerät laden.
import os
class path_stub
  static def listdir(d) return os.listdir(d == "" ? "." : d) end
  static def remove(f) return os.remove(f) end
  static def exists(f) return os.path.exists(f) end
end
return path_stub
