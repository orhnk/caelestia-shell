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

    // Aladhan calculation method id (13 = Diyanet/Turkey) and school (0 = Shafi, 1 = Hanafi)
    property int method: 13
    property int school: 0
    // IP geolocation (ipapi.co, like dir3) is the primary location source;
    // the weather service location is only a fallback.
    property string ipLoc
    property bool ipPending: false
    property double ipBlockedUntil: 0
    property double lastIpAttempt: 0
    property int reminderMins: 5
    property list<var> prayers
    property int nextIndex: -1
    property string day
    property bool isFriday: false
    property string nextIn
    property int nextHours
    property int nextMins
    property bool nextNow
    property string remindedKey

    // "loc|m<method>s<school>|YYYY-M" -> { "DD-MM-YYYY": { fajr, sunrise, dhuhr, asr, maghrib, isha } }
    // The method/school tag keeps cached times from surviving a settings change.
    property var monthCache: ({})
    property var diskMonths: ({})
    property bool ready: false
    property double lastRequestAt: 0
    property var pendingFetch
    property var pendingRetry

    readonly property list<string> names: ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
    readonly property var retryableStatus: [408, 425, 429, 500, 502, 503, 504]

    // Fallback angles per method id; replaced by the live methods table
    // (GET /v1/methods) whenever it can be fetched. Default = MWL (18/17).
    readonly property var methodAngles: ({
        1: [18, 18],
        2: [15, 15],
        3: [18, 17],
        5: [19.5, 17.5],
        7: [15, 15],
        13: [18, 17]
    })
    // method id -> { fajr: angle|null, ishaAngle: angle|null, ishaInterval: mins|null }
    property var methodParams: ({})
    // [{ id, name }] sorted by id, from the live table (persisted for offline)
    property list<var> methodList

    function parseMinutes(raw: var): int {
        const m = String(raw ?? "").match(/(\d+(?:\.\d+)?)\s*min/);
        return m ? Math.round(Number(m[1])) : -1;
    }

    function fetchMethods(): void {
        Requests.get("https://api.aladhan.com/v1/methods", text => {
            let json;
            try {
                json = JSON.parse(text);
            } catch (error) {
                console.warn(lc, `Unable to parse methods from aladhan: ${error}`);
                return;
            }
            const data = json.data && typeof json.data === "object" ? json.data : null;
            if (!data)
                return;
            const params = {};
            const list = [];
            for (const key of Object.keys(data)) {
                const entry = data[key] ?? {};
                if (!Number.isFinite(Number(entry.id)))
                    continue;
                const id = Math.round(Number(entry.id));
                const p = entry.params ?? {};
                params[id] = {
                    fajr: Number.isFinite(Number(p.Fajr)) ? Number(p.Fajr) : null,
                    ishaAngle: Number.isFinite(Number(p.Isha)) ? Number(p.Isha) : null,
                    ishaInterval: parseMinutes(p.Isha)
                };
                list.push({
                    id: id,
                    name: String(entry.name ?? key)
                });
            }
            if (Object.keys(params).length) {
                methodParams = params;
                methodList = list.sort((a, b) => a.id - b.id);
                settingsSaveTimer.restart();
            }
        }, error => {
            console.warn(lc, `Aladhan methods request failed: ${error}`);
        });
    }

    function anglesFor(id: int): var {
        const live = methodParams[id];
        if (live && (live.fajr !== null || live.ishaAngle !== null || live.ishaInterval >= 0))
            return live;
        const fallback = methodAngles[id] ?? [18, 17];
        return {
            fajr: fallback[0],
            ishaAngle: fallback[1],
            ishaInterval: -1
        };
    }

    function label(name: string): string {
        if (name === "Dhuhr" && isFriday)
            return Tr.tr("Jumu'ah");
        const labels = {
            "Fajr": Tr.tr("Fajr"),
            "Sunrise": Tr.tr("Sunrise"),
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

    function activeLoc(): string {
        if (ipLoc && ipLoc.indexOf(",") !== -1)
            return ipLoc;
        return Weather.loc ?? "";
    }

    function fetchIpLoc(): void {
        if (ipPending || Date.now() < ipBlockedUntil)
            return;
        // Skip when the last attempt was less than an hour ago
        if (Date.now() - lastIpAttempt < 3600000 && ipLoc)
            return;
        ipPending = true;
        lastIpAttempt = Date.now();

        Requests.get("https://ipapi.co/json/", text => {
            ipPending = false;
            let json;
            try {
                json = JSON.parse(text);
            } catch (error) {
                console.warn(lc, `Unable to parse response from ipapi: ${error}`);
                return;
            }
            const lat = Number(json.latitude);
            const lon = Number(json.longitude);
            if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
                console.warn(lc, `ipapi lookup failed: ${json.reason ?? "invalid response"}`);
                return;
            }
            // ipapi.co rejects empty clients with 429 - a UA makes it work
            ipLoc = `${lat},${lon}`;
            fetchTimings();
        }, (error, metadata) => {
            ipPending = false;
            if (metadata?.statusCode === 429)
                ipBlockedUntil = Date.now() + 61000;
            else
                console.warn(lc, `ipapi request failed: ${error}`);
        }, {
            "User-Agent": `caelestia-shell/${CUtils.version} (+https://github.com/caelestia-dots/shell)`
        });
    }

    function locKey(): string {
        const loc = activeLoc();
        if (!loc || loc.indexOf(",") === -1)
            return "";
        const [lat, lon] = loc.split(",").map(s => Number(s.trim()));
        if (!Number.isFinite(lat) || !Number.isFinite(lon))
            return "";
        return `${lat.toFixed(4)},${lon.toFixed(4)}|`;
    }

    function cacheKey(year: int, month: int): string {
        return `${locKey()}m${root.method}s${root.school}|${year}-${month}`;
    }

    function cleanTime(raw: string): string {
        return String(raw ?? "00:00").split(" ")[0];
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
                // Strictly less than, so the prayer whose minute has just
                // arrived is still the current one. With <= the selected prayer
                // always had left > 0, which meant the "now" state below
                // (nextNow, nextIn = "now", the "Time for prayer" toast and the
                // dashboard showing the live clock) could never be reached, and
                // the highlight moved on a minute early.
                passed: mins < nowMins
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
                const nowText = prayers[nextIndex].name === "Sunrise" ? Tr.tr("Sunrise") : Tr.tr("Time for prayer");
                Toaster.toast(name, left <= 0 ? nowText : Tr.tr("In %1").arg(nextIn), `salat:${nextIndex}`);
            }
        }
    }

    function applyDay(): bool {
        const now = new Date();
        const stamp = dayStamp(now);
        const key = cacheKey(now.getFullYear(), now.getMonth() + 1);
        if (key.startsWith("|"))
            return false;
        const entry = (monthCache[key] ?? {})[stamp] ?? (diskMonths[key] ?? {})[stamp];
        // Entries cached before sunrise was added are refetched instead of
        // showing a 00:00 sunrise.
        if (!entry || !entry.sunrise)
            return false;

        prayers = names.map(n => {
            const time = entry[n.toLowerCase()] ?? "00:00";
            return {
                name: n,
                time: time,
                display: formatTime(time),
                passed: false
            };
        });
        day = stamp;
        isFriday = now.getDay() === 5;
        updateNext();
        return true;
    }

    function calendarUrl(year: int, month: int, lat: string, lon: string): string {
        return `https://api.aladhan.com/v1/calendar/${year}/${month}?latitude=${lat}&longitude=${lon}&method=${method}&school=${school}`;
    }

    function fetchMonth(year: int, month: int, attempt: int): void {
        const loc = activeLoc();
        if (!loc || loc.indexOf(",") === -1) {
            fetchIpLoc();
            return;
        }

        // Politeness pace: min 0.12s between upstream requests
        const wait = 120 - (Date.now() - lastRequestAt);
        if (wait > 0) {
            pendingFetch = [year, month, attempt];
            paceTimer.interval = wait;
            paceTimer.restart();
            return;
        }
        lastRequestAt = Date.now();

        const [lat, lon] = loc.split(",").map(s => s.trim());
        Requests.get(calendarUrl(year, month, lat, lon), text => {
            let json;
            try {
                json = JSON.parse(text);
            } catch (error) {
                console.warn(lc, `Unable to parse response from aladhan: ${error}`);
                fetchFailed(year, month, attempt, -1);
                return;
            }

            const data = Array.isArray(json.data) ? json.data : null;
            if (!data || !data.length) {
                fetchFailed(year, month, attempt, -1);
                return;
            }

            const schedules = {};
            for (const e of data) {
                const dateStr = String(e.date?.gregorian?.date ?? "");
                if (!/^\d{2}-\d{2}-\d{4}$/.test(dateStr))
                    continue;
                const timings = e.timings ?? {};
                const day = {};
                let usable = true;
                for (const n of ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"]) {
                    const raw = timings[n[0].toUpperCase() + n.slice(1)] ?? timings[n];
                    if (!raw) {
                        usable = false;
                        break;
                    }
                    day[n] = cleanTime(raw);
                }
                if (usable)
                    schedules[dateStr] = day;
            }
            if (!Object.keys(schedules).length) {
                fetchFailed(year, month, attempt, -1);
                return;
            }

            const key = cacheKey(year, month);
            monthCache[key] = schedules;
            diskMonths[key] = schedules;
            settingsSaveTimer.restart();
            applyDay();
        }, (error, metadata) => {
            fetchFailed(year, month, attempt, metadata?.statusCode ?? -1);
        });
    }

    function fetchFailed(year: int, month: int, attempt: int, status: int): void {
        if ((retryableStatus.includes(status) || status === -1) && attempt < 2) {
            pendingRetry = [year, month, attempt + 1];
            retryTimer.interval = 600 * (attempt + 1);
            retryTimer.restart();
            return;
        }
        console.warn(lc, "Aladhan request failed, falling back to offline calculator");
        offlineCompute();
    }

    function fetchTimings(): void {
        if (applyDay())
            return;
        const now = new Date();
        fetchMonth(now.getFullYear(), now.getMonth() + 1, 0);
    }

    function offlineCompute(): void {
        const spec = anglesFor(method);
        const fajrAngle = spec.fajr ?? 18;
        const asrFactor = school === 1 ? 2 : 1;
        const now = new Date();

        const loc = activeLoc();
        let lat = 41.0, lon = 29.0;
        if (loc && loc.indexOf(",") !== -1) {
            const parts = loc.split(",").map(s => s.trim());
            if (Number.isFinite(Number(parts[0])))
                lat = Number(parts[0]);
            if (Number.isFinite(Number(parts[1])))
                lon = Number(parts[1]);
        }

        const clamp = v => Math.max(-1, Math.min(1, v));
        const latR = lat * Math.PI / 180;
        const tzHours = -new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTimezoneOffset() / 60;
        const startOfYear = new Date(now.getFullYear(), 0, 0);
        const n = Math.floor((now - startOfYear) / 86400000);
        const declR = -23.44 * Math.cos(2 * Math.PI * (n + 10) / 365.25) * Math.PI / 180;
        const b = 2 * Math.PI * (n - 81) / 364;
        const eot = 9.87 * Math.sin(2 * b) - 7.53 * Math.cos(b) - 1.5 * Math.sin(b);
        const transit = 720 - eot - 4 * (lon - 15 * tzHours);

        const hourOffset = altDeg => {
            const aR = altDeg * Math.PI / 180;
            const cosH = clamp((Math.sin(aR) - Math.sin(latR) * Math.sin(declR)) / (Math.cos(latR) * Math.cos(declR)));
            return Math.acos(cosH) * 180 / Math.PI * 4;
        };
        const toTime = total => {
            total = ((total % 1440) + 1440) % 1440;
            let h = Math.floor(total / 60);
            let m = Math.round(total % 60);
            if (m === 60) {
                m = 0;
                h += 1;
            }
            return `${String(h % 24).padStart(2, "0")}:${String(m).padStart(2, "0")}`;
        };

        const sunOff = hourOffset(-0.833);
        const fajrOff = hourOffset(-fajrAngle);
        const ishaOff = spec.ishaAngle !== null && spec.ishaAngle !== undefined ? hourOffset(-spec.ishaAngle) : -1;
        const zenith = Math.abs(lat - declR * 180 / Math.PI);
        const asrAlt = Math.atan(1 / (Math.tan(zenith * Math.PI / 180) + asrFactor)) * 180 / Math.PI;

        const maghribMins = transit + sunOff;
        const times = {
            fajr: toTime(transit - fajrOff),
            sunrise: toTime(transit - sunOff),
            dhuhr: toTime(transit),
            asr: toTime(transit + hourOffset(asrAlt)),
            maghrib: toTime(maghribMins),
            isha: ishaOff >= 0 ? toTime(transit + ishaOff) : toTime(maghribMins + (spec.ishaInterval >= 0 ? spec.ishaInterval : 90))
        };
        prayers = names.map(n => {
            const time = times[n.toLowerCase()];
            return {
                name: n,
                time: time,
                display: formatTime(time),
                passed: false
            };
        });
        day = dayStamp(now);
        isFriday = now.getDay() === 5;
        updateNext();
    }

    // Initial load, called from the storage FileView below once settings are
    // restored. It lives here rather than in the dashboard widget: called from
    // there it also ran on every dashboard open (the Loader recreates the
    // content each time), so the static methods table was re-fetched over the
    // network constantly - and if the dashboard was never opened, methodList
    // stayed empty even though the nexus method picker reads it.
    function reload(): void {
        fetchMethods();
        if (activeLoc())
            fetchTimings();
        else
            fetchIpLoc();
    }

    function refresh(): void {
        const now = new Date();
        const key = cacheKey(now.getFullYear(), now.getMonth() + 1);
        delete monthCache[key];
        monthCacheChanged();
        delete diskMonths[key];
        diskMonthsChanged();
        settingsSaveTimer.restart();
        fetchTimings();
    }

    function clearCache(): void {
        monthCache = ({});
        diskMonths = ({});
        settingsSaveTimer.restart();
        fetchTimings();
    }

    Connections {
        function onLocChanged(): void {
            monthCache = ({});
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
        id: paceTimer

        repeat: false
        onTriggered: {
            if (root.pendingFetch) {
                const [year, month, attempt] = root.pendingFetch;
                root.pendingFetch = null;
                root.fetchMonth(year, month, attempt);
            }
        }
    }

    Timer {
        id: retryTimer

        repeat: false
        onTriggered: {
            if (root.pendingRetry) {
                const [year, month, attempt] = root.pendingRetry;
                root.pendingRetry = null;
                root.fetchMonth(year, month, attempt);
            }
        }
    }

    Timer {
        id: settingsSaveTimer

        interval: 1000
        onTriggered: {
            // Drop legacy cache entries saved without a method/school tag
            // so stale timetables can never resurface after a settings change.
            const months = {};
            for (const k of Object.keys(root.diskMonths)) {
                if (k.indexOf("|m") !== -1)
                    months[k] = root.diskMonths[k];
            }
            salatStorage.setText(JSON.stringify({
                reminderMins: root.reminderMins,
                method: root.method,
                school: root.school,
                months: months,
                methods: root.methodList
            }));
        }
    }

    onReminderMinsChanged: settingsSaveTimer.restart()
    onMethodChanged: {
        settingsSaveTimer.restart();
        if (root.ready)
            refresh();
    }
    onSchoolChanged: {
        settingsSaveTimer.restart();
        if (root.ready)
            refresh();
    }

    FileView {
        id: salatStorage

        printErrors: false
        path: `${Paths.cache}/salat.json`
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (Number.isFinite(Number(data.reminderMins)))
                    root.reminderMins = Math.max(0, Math.min(60, Math.round(Number(data.reminderMins))));
                if (Number.isFinite(Number(data.method)))
                    root.method = Math.round(Number(data.method));
                if (data.school === 0 || data.school === 1)
                    root.school = data.school;
                if (data.months && typeof data.months === "object")
                    root.diskMonths = data.months;
                if (Array.isArray(data.methods) && data.methods.length)
                    root.methodList = data.methods.filter(m => Number.isFinite(Number(m?.id)));
            } catch (error) {
                console.warn(lc, `Unable to parse saved salat settings: ${error}`);
            }
            root.ready = true;
            root.reload();
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => setText("{}"));
            else
                console.warn(lc, `Unable to load saved salat settings: ${err}`);
            root.ready = true;
            root.reload();
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.salat"
        defaultLogLevel: LoggingCategory.Info
    }
}
