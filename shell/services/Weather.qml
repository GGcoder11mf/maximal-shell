pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// wttr.in (IP-based location), refreshed every 30 min.
Singleton {
    id: root

    property bool ok: false
    property string temp: "--"
    property string feels: "--"
    property string desc: "Loading weather…"
    property string location: ""
    property string high: "--"
    property string low: "--"
    property string humidity: "--"
    property string wind: "--"
    property int code: 113
    property var hourly: []     // [{ time, temp, code }]

    function icon(c: int, night: bool): string {
        if (c === 113) return night ? "clear_night" : "sunny";
        if (c === 116) return night ? "partly_cloudy_night" : "partly_cloudy_day";
        if ([119, 122].includes(c)) return "cloud";
        if ([143, 248, 260].includes(c)) return "foggy";
        if ([200, 386, 389, 392, 395].includes(c)) return "thunderstorm";
        if ([179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].includes(c)) return "weather_snowy";
        if ([176, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 353, 356, 359].includes(c)) return "rainy";
        return "cloud";
    }
    readonly property bool night: { const h = new Date().getHours(); return h < 6 || h >= 20; }
    readonly property string currentIcon: icon(code, night)

    Timer {
        interval: 30 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["curl", "-sf", "--max-time", "15", "https://wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    const cur = j.current_condition[0], day = j.weather[0];
                    root.temp = cur.temp_C;
                    root.feels = cur.FeelsLikeC;
                    root.desc = cur.weatherDesc[0].value;
                    root.code = Number(cur.weatherCode);
                    root.humidity = cur.humidity;
                    root.wind = cur.windspeedKmph;
                    root.high = day.maxtempC;
                    root.low = day.mintempC;
                    root.location = j.nearest_area?.[0]?.areaName?.[0]?.value ?? "";
                    root.hourly = day.hourly.map(h => ({ time: String(Math.floor(Number(h.time) / 100)).padStart(2, "0") + ":00", temp: h.tempC, code: Number(h.weatherCode) }));
                    root.ok = true;
                } catch (e) {
                    root.desc = "Weather unavailable";
                }
            }
        }
    }
}
