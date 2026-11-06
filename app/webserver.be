# Desktop-Stub für das Tasmota-Modul webserver (nur für desktop_harness.be). Nicht aufs Gerät laden.
# on() merkt sich die Handler, content_send landet wie tasmota.web_send in tasmota.out.
class webserver_stub
  static HTTP_GET = 1
  static handlers = {}
  static def on(path, f, m) webserver_stub.handlers[path] = f end
  static def content_open(code, ctype) end
  static def content_send(s) tasmota.out.push(s) end
  static def content_close() end
  static def has_arg(a) return false end
  static def arg(a) return "" end
end
return webserver_stub
