# Tasmota Berry API — Cheat-Sheet

Compact reference for the Tasmota-specific Berry API (ESP32). Companion to the Berry *language* reference
(<https://tasmota.github.io/docs/_media/BERRY_LANGUAGE_REFERENCE.txt>), which covers syntax, lists, maps, bytes,
strings, `json`, `file` — but **none** of the functions below. Source: <https://tasmota.github.io/docs/Berry/>,
condensed to what a data/telemetry app needs. Verified against docs on 2026-10-18.

## 1. Lifecycle and rules of the road

- `autoexec.be` in the filesystem runs at boot. Keep it to `load("spot.be")`.
- `load("file.be")` loads and runs a script; `BrRestart` (console command) restarts the Berry VM and re-runs `autoexec.be` — use this to iterate without reboot.
- Berry **blocks Tasmota while it runs**. Never block > 50 ms. Long work → split with `tasmota.set_timer`. Never busy-wait.
- Network calls before Wi-Fi is up crash. Wrap first network use in `tasmota.when_network_up(f)`.
- Wall-clock is invalid until NTP sync. Gate time-based logic on `tasmota.rtc("utc") > 1700000000`. Don't rely on the rule `Time#Initialized` after boot: it fires as soon as NTP syncs, often **before** your `when_network_up` callback registers it (seen 19.10. on 15.3.0; app fetched nothing until the next cron). Poll with `tasmota.set_timer(2000, …)` until the clock is valid instead.
- Uncaught exceptions kill the current callback, not Tasmota. Still wrap every callback body in `try ... except .. as e, m  log("X: " + e + " " + m, 2) end`.
- Console: `print(x)` → Berry console; `log(msg, level)` → Tasmota log (level 2 = info, 3 = debug, default 3). Use `log` for anything the user should see.
- Heap: ESP32 without PSRAM has ~100–200 kB free. `tasmota.memory("heap_free")` → kB. `tasmota.gc()` forces collection, returns Berry-allocated bytes.

## 2. `tasmota` object

### Time

| Call | Returns |
|---|---|
| `tasmota.rtc()` | `{'local': epoch, 'utc': epoch, 'timezone': minutes, 'restart': epoch}`; `tasmota.rtc("utc")` = single value, no map alloc |
| `tasmota.time_dump(epoch)` | `{'year','month','day','hour','min','sec','weekday','epoch'}` |
| `tasmota.time_str(epoch)` | `"2021-04-27T21:53:27"` |
| `tasmota.strftime(fmt, epoch)` | C `strftime`, e.g. `"%Y-%m-%d"` |
| `tasmota.strptime(str, fmt)` | map like `time_dump` + `unparsed`, or `nil`. Treats input as naive time; check on device whether `epoch` is UTC or local before trusting it for UTC strings. |
| `tasmota.millis()` | ms since boot; `tasmota.time_reached(t)` for safe comparisons |

### Timers and cron

```berry
tasmota.set_timer(5000, f, "id")        # once, after 5000 ms; id optional
tasmota.remove_timer("id")
tasmota.defer(f)                        # run after current event loop
tasmota.add_cron("0 */15 * * * *", f, "q15")   # 6 fields, FIRST IS SECONDS; local time
tasmota.add_cron("0 0 14,16,18 * * *", f, "fetch")
tasmota.remove_cron("q15")
tasmota.next_cron("q15")                # next epoch (local)
```

To call a method of an instance, pass a closure: `tasmota.add_cron("...", /-> self.tick(), "id")`.

### Rules (event hooks)

```berry
tasmota.add_rule("Time#Initialized", /-> on_time_ok(), "t_init")   # NTP synced
tasmota.add_rule("Mqtt#Connected", f)
tasmota.add_rule("System#Boot", f)
tasmota.remove_rule("Time#Initialized", "t_init")
```

Rule function signature: `def f(value, trigger, msg)`, all optional.

### Custom commands

```berry
def spot_prices(cmd, idx, payload, payload_json)
  import string
  tasmota.resp_cmnd(string.format('{"SpotPrices":{"Start":"%s","Prices":[%s]}}', start, csv))
end
tasmota.add_cmd("SpotPrices", spot_prices)
```

- `cmd` name as registered, `idx` number suffix (default 1), `payload` raw string, `payload_json` map or `nil`.
- Responses: `tasmota.resp_cmnd(json_string)` (full custom JSON), `resp_cmnd_done()`, `resp_cmnd_error()`, `resp_cmnd_failed()`, `resp_cmnd_str(s)`.
- Reachable from console, `http://<ip>/cm?cmnd=SpotPrices`, MQTT `cmnd/<topic>/SpotPrices`.
- Cannot override native commands. Names case-insensitive.
- `tasmota.cmd("Status 10", true)` runs any command from Berry, returns parsed map (`true` = mute log).

### Sensors and telemetry

- `tasmota.read_sensors()` → JSON **string** of all sensors (like teleperiod). Parse with `json.load`, may return `nil`.
- In a driver: `json_append()` + `tasmota.response_append(',"Spot":{"Price":0.194}')` adds to tele/SENSOR.

### Misc

- `tasmota.version()` → int like `0x0F050002` (15.5.0.2). `tasmota.arch()` → `"esp32"`.
- `tasmota.wifi("ip")`, `tasmota.is_network_up()`.
- `tasmota.scale_int(v, fromMin, fromMax, toMin, toMax)` — integer linear scaling, handy for SVG coordinates.
- `tasmota.urlfetch(url, filename)` — one-shot download to filesystem, returns bytes or -1.

## 3. Drivers (event callbacks + Web UI)

Any class instance registered with `tasmota.add_driver(obj)`; methods are matched **by name**:

| Method | When |
|---|---|
| `every_second()` | once per second |
| `every_250ms()`, `every_100ms()`, `every_50ms()` | fast loops — avoid unless needed |
| `web_sensor()` | main page render; call `tasmota.web_send(html)` here, nothing else emits here |
| `json_append()` | teleperiod JSON; call `tasmota.response_append(...)` |
| `web_add_handler()` | web server up; the only safe place to call `webserver.on(...)` |
| `web_add_main_button()`, `web_add_config_button()` | emit a button with `webserver.content_send(...)` |
| `save_before_restart()` | flush state before restart |
| `mqtt_data(topic, idx, data, databytes)` | after `mqtt.subscribe(topic)` |

```berry
import webserver
class SpotUI
  def web_sensor()
    tasmota.web_send("{s}Spot price{m}0.194 CHF/kWh{e}")      # {s} {m} {e} = Tasmota table markup
    tasmota.web_send("<svg width='300' height='80'>...</svg>") # inline SVG works, send in chunks
  end
  def web_add_main_button()
    webserver.content_send("<p></p><form action='/spot' method='get'><button>Spot chart</button></form>")
  end
  def web_add_handler()
    webserver.on("/spot", /-> self.page(), webserver.HTTP_GET)
  end
  def page()
    webserver.content_start("Spot")       # title
    webserver.content_send_style()
    webserver.content_send("<svg ...>")   # chunked; call repeatedly, no big string needed
    webserver.content_send("</svg>")
    webserver.content_button(webserver.BUTTON_MAIN)
    webserver.content_stop()
  end
end
tasmota.add_driver(SpotUI())
```

`webserver.has_arg("x")`, `webserver.arg("x")` read query params. `webserver.content_open(200, "application/json")` + `content_send` + `content_close` for raw responses.

## 4. `webclient` (HTTP/HTTPS)

```berry
var wc = webclient()
wc.begin("https://api.bkw.ch/api/dyntariffs/v1/Tariffs/energyreturn")
wc.add_header("accept", "application/json")
wc.set_timeouts(10000, 5000)
var rc = wc.GET()                   # 200 ok; negative = connection error
if rc == 200
  var s = wc.get_string()           # closes connection, frees buffers
  # ... parse s ...
  s = nil
end
wc.close()                          # harmless if already closed
wc = nil
tasmota.gc()
```

- **`get_string()` drops responses > 32 KB, and silently truncates them when the heap is fragmented** (chunked response, no error; seen 19.10. at 65 kB free: 8.7 of 21 kB). For anything over a few kB use `wc.write_file("/file.json")` → bytes written or -1, then parse from flash in blocks with `f.read(2048)` (see `parse_file` in `app/spot.be`).
- HTTPS is insecure mode (no cert check) — fine for public read-only APIs. Cipher ECDHE_RSA_AES128_GCM_SHA256 only.
- Redirects off by default: `wc.set_follow_redirects(true)`.
- `GET()` blocks Tasmota for the duration of the request (several hundred ms). Acceptable a few times a day; never in a fast loop.
- `wc.set_auth(user, pw)`, `wc.set_useragent(s)`, `wc.POST(payload)`.

## 5. Files, `path`, `persist`

```berry
import path
path.exists("/spot_2026-10.csv")    # leading "/" optional
path.listdir("/")                   # list of names
path.remove("/old.csv")             # true on success
path.rename(a, b); path.last_modified(f)

var f = open("/spot_2026-10.csv", "a")   # modes "r", "w", "a"; raises on error
f.write("2026-10-18;3.4;0.66\n")
f.close()

f = open("/bkw.json", "r")
var line = f.readline()              # "" at EOF
f.close()
```

- Filesystem is LittleFS on internal flash, typically 300 kB–1 MB free. Minimise writes (wear).
- `persist` = tiny key/value store in `_persist.json`: `import persist; persist.last_start = 1760000000; persist.save()`. Auto-saved before restart. Not for frequent writes; not for lists/maps unless you call `persist.dirty()`.

## 6. `string`, `json`, `bytes` quick refs (Berry core, used constantly)

```berry
import string
string.find(s, "needle", from)        # index or -1
string.split(s, ";")                  # list
string.format("%.3f;%d", x, n)        # C printf subset (%d %i %s %f %.3f %x %05d)
string.tr(s, "\r", "")                # char translate/remove
s[a..b]                               # slice, inclusive; s[a..] to end
real("0.194"); int(3.7); number("12") # conversions; real() of garbage → 0
str(x)                                # to string

import json
var m = json.load(s)                  # nil on error — always check
json.dump(m)

var b = bytes(-600)                   # fixed 600 B, zero-filled
b.seti(i*2, v, 2)                     # signed 16-bit little-endian at byte offset
b.geti(i*2, 2)
b.set(0, 0x1234, 2); b.get(0, 2)      # unsigned
```

Rounding: no `math.round` — use `int(x + 0.5)` for x ≥ 0, `int(x - 0.5)` for x < 0. `import math` gives `floor`, `ceil`, `abs`, `rand()`.

## 7. Gotchas

- **`f.read(n)` leaks** (Tasmota 15.3.0, measured 19.10.): each pass over a file with `f.read(2048)` loses ~3 kB of Berry heap for good, `gc()` does not get it back. Read files in blocks with `f.readbytes(n).asstring()` or line by line with `f.readline()`; both are leak-free. `f.read()` without size is fine but needs the whole file in RAM.
- **`BrRestart` is not free**: each VM restart costs ~1 kB of heap outside Berry, and only a real `Restart 1` returns it. 20 upload cycles ≈ 20 kB. `upload.sh` reboots the device by itself when the heap drops below 100 kB.
- Memory floor: HTTPS needs ~40 kB free for the TLS handshake. Below ~50 kB a 21 kB `get_string()` reboots the device ("MEMORY ALLOCATION FAILED"); between ~50 and ~70 kB it returns a silently truncated string. Check `tasmota.memory("heap_free")` after `tasmota.gc()`, aim to stay above 90 kB.
- Cron pattern has **6 fields** (seconds first) and runs in **local** time, DST included.
- `tasmota.add_rule/add_cron/add_cmd` with the same id replace the previous registration — use ids so `BrRestart` doesn't double-register.
- `tasmota.web_send` is only valid inside `web_sensor()`; `webserver.on` only inside `web_add_handler()`. Calling elsewhere = crash or silence.
- `real()` on `"0.194"` returns `0.194`; on `"abc"` returns `0`, no exception.
- Berry `string` concatenation with `+` requires both sides strings: `"x" + str(n)`.
- Integer division: `7 / 2` → `3` for ints, `3.5` if either is real.
- Class `var` members must be declared (`var a, b`); assigning undeclared member raises.
- Tasmota compiles Berry in **strict mode**: reading an undeclared global is a `syntax_error` at load time. For "is my app already loaded?" use `import global` + `global.contains("spot")` / `global.spot`, never the bare name.
- Reload-safe script tail: `if global.contains("spot") && global.spot != nil tasmota.remove_driver(global.spot) tasmota.remove_cron(id)… end` before creating the new instance; otherwise every `load()` adds another driver (UI twice, crons twice).
- Device local time = NTP UTC + zone rule. Factory gPlug has fixed `Timezone +01:00` (no DST, 1 h off in summer); require `Timezone 99`. Check from Berry: `tasmota.cmd("Timezone", true)["Timezone"] == 99`.
- `self` is mandatory inside methods. Closures for callbacks: `/-> self.m()` or `def () self.m() end`.
- Lists: `l.push(x)`, `l.size()`, `l[-1]`, `l.resize(n)`; maps: `m.find(k, default)`, `m.contains(k)`, `m.remove(k)`.
- Large string building: append in a list and `concat` — or better, stream with `web_send`/`content_send` per chunk.
