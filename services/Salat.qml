pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.utils

Singleton {
    id: root

    property int method: 2
    property int reminderMins: 5
    property list<var> prayers
    property int nextIndex: -1
    property string day
    property string hijri
    property bool isFriday: false
    property string nextIn
    property int nextHours
    property int nextMins
    property bool nextNow
    property string remindedKey

    readonly property list<string> names: ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]

    function label(name: string): string {
        if (name === "Dhuhr" && isFriday)
            return Tr.tr("Jumu'ah");
        const labels = {
            "Fajr": Tr.tr("Fajr"),
            "Dhuhr": Tr.tr("Dhuhr"),
            "Asr": Tr.tr("Asr"),
            "Maghrib": Tr.tr("Maghrib"),
            "Isha": Tr.tr("Isha")
        };
        return labels[name] ?? name;
    }

    function formatTime(hhmm: string): string {
        const parts = hhmm.split(":");
        const date = new Date();
        date.setHours(Number(parts[0]), Number(parts[1]), 0, 0);
        return Qt.formatDateTime(date, GlobalConfig.services.useTwelveHourClock ? "h:mm A" : "hh:mm");
    }

    function dayStamp(date: var): string {
        return `${String(date.getDate()).padStart(2, "0")}-${String(date.getMonth() + 1).padStart(2, "0")}-${date.getFullYear()}`;
    }

    function updateNext(): void {
        if (!prayers.length) {
            nextIndex = -1;
            return;
        }

        const now = new Date();
        const nowMins = now.getHours() * 60 + now.getMinutes();
        let next = -1;
        prayers = prayers.map(p => {
            const parts = p.time.split(":");
            const mins = Number(parts[0]) * 60 + Number(parts[1]);
            return {
                name: p.name,
                time: p.time,
                display: p.display,
                passed: mins <= nowMins
            };
        });
        for (let i = 0; i < prayers.length; i++) {
            if (!prayers[i].passed) {
                next = i;
                break;
            }
        }
        nextIndex = next === -1 ? 0 : next;

        const parts = prayers[nextIndex].time.split(":");
        let left = Number(parts[0]) * 60 + Number(parts[1]) - nowMins;
        if (left < 0)
            left += 24 * 60;
        const h = Math.floor(left / 60);
        const m = left % 60;
        nextHours = h;
        nextMins = m;
        nextNow = left <= 0;
        if (left <= 0)
            nextIn = Tr.tr("now");
        else if (h > 0)
            nextIn = Tr.tr("%1h %2m").arg(h).arg(m);
        else
            nextIn = Tr.tr("%1m").arg(m);

        if (left <= reminderMins) {
            const key = `${day}:${nextIndex}`;
            if (remindedKey !== key) {
                remindedKey = key;
                const name = label(prayers[nextIndex].name);
                Toaster.toast(name, left <= 0 ? Tr.tr("Time for prayer") : Tr.tr("In %1").arg(nextIn), `salat:${nextIndex}`);
            }
        }
    }

    function fetchTimings(): void {
        const loc = Weather.loc;
        if (!loc || loc.indexOf(",") === -1)
            return;

        const [lat, lon] = loc.split(",").map(s => s.trim());
        const stamp = dayStamp(new Date());
        const url = `https://api.aladhan.com/v1/timings/${stamp}?latitude=${lat}&longitude=${lon}&method=${method}`;

        Requests.get(url, text => {
            let json;
            try {
                json = JSON.parse(text);
            } catch (error) {
                console.warn(lc, `Unable to parse response from aladhan: ${error}`);
                return;
            }

            const timings = json.data?.timings;
            if (!timings)
                return;

            const hijri = json.data?.date?.hijri;
            if (hijri)
                root.hijri = `${hijri.day} ${hijri.month?.en ?? ""} ${hijri.year}`;
            root.isFriday = json.data?.date?.gregorian?.weekday?.en === "Friday";

            prayers = names.map(n => {
                const time = String(timings[n] ?? "00:00").split(" ")[0];
                return {
                    name: n,
                    time: time,
                    display: formatTime(time),
                    passed: false
                };
            });
            day = stamp;
            updateNext();
        }, error => {
            console.warn(lc, `Aladhan request failed: ${error}`);
        });
    }

    function reload(): void {
        if (Weather.loc)
            fetchTimings();
    }

    Connections {
        function onLocChanged(): void {
            root.fetchTimings();
        }

        target: Weather
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.prayers.length || root.day !== root.dayStamp(new Date()))
                root.fetchTimings();
            else
                root.updateNext();
        }
    }

    Timer {
        id: settingsSaveTimer

        interval: 1000
        onTriggered: salatStorage.setText(JSON.stringify({
            reminderMins: root.reminderMins
        }))
    }

    onReminderMinsChanged: settingsSaveTimer.restart()

    FileView {
        id: salatStorage

        printErrors: false
        path: `${Paths.cache}/salat.json`
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (Number.isFinite(Number(data.reminderMins)))
                    root.reminderMins = Math.max(0, Math.min(60, Math.round(Number(data.reminderMins))));
            } catch (error) {
                console.warn(lc, `Unable to parse saved salat settings: ${error}`);
            }
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => setText("{}"));
            else
                console.warn(lc, `Unable to load saved salat settings: ${err}`);
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.salat"
        defaultLogLevel: LoggingCategory.Info
    }
}
