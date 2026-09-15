pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property string text
    property int surah: 1
    property int ayah: 1
    property string surahName: "الفاتحة"
    property string ref: `${surah}:${ayah}`
    property string mode: "random"
    property bool ready: false
    property int count: 0

    // Live-decorated by naqqash (persisted, see saveTimer).
    property real fontScale: 1.0
    property string fontFamily: "Noto Nastaliq Urdu"
    property bool fontRandom: true

    // Every family here must cover Arabic (verified via `fc-list :lang=ar`).
    readonly property list<string> fontPool: [
        "Noto Naskh Arabic", "Noto Sans Arabic", "Noto Kufi Arabic", "Noto Nastaliq Urdu",
        "IBM Plex Sans Arabic", "IBM Plex Sans Arabic Light", "IBM Plex Sans Arabic Medium",
        "Scheherazade New", "Scheherazade New Medium",
        "Amiri", "Amiri Quran",
        "Reem Kufi", "Reem Kufi Medium", "Square Kufic",
        "KFGQPC Kufi Extended", "KFGQPC Kufi Stylistic",
        "IranNastaliq", "Diwani Letter", "Aref Ruqaa", "Raqq",
        "Islamic Palestine", "B Fantezy", "Sayeh2", "Mj_Faten",
        "(A) Arslan Wessam B", "AGA Kyrawan V.2", "khalaad Abeer", "Old Antic Bold"
    ]

    // Compact faces, picked with 40% probability (see TODO.md).
    readonly property list<string> smallFonts: [
        "IBM Plex Sans Arabic", "Noto Kufi Arabic", "Noto Sans Arabic"
    ]
    property string fgVerse: ""
    property string fgRef: ""
    property string outline: ""
    property real auraScale: 1.0

    property var verses: []
    property int index: -1
    property bool stateLoaded: false
    property bool dataLoaded: false

    function maybeInit(): void {
        if (!stateLoaded || !dataLoaded || ready || !verses.length)
            return;
        if (root.mode === "sequential" && root.index >= 0)
            applyIndex((root.index + 1) % verses.length);
        else
            applyIndex(pickIndex());
    }

    readonly property list<string> surahNames: [
        "الفاتحة", "البقرة", "آل عمران", "النساء", "المائدة", "الأنعام", "الأعراف", "الأنفال", "التوبة", "يونس",
        "هود", "يوسف", "الرعد", "إبراهيم", "الحجر", "النحل", "الإسراء", "الكهف", "مريم", "طه",
        "الأنبياء", "الحج", "المؤمنون", "النور", "الفرقان", "الشعراء", "النمل", "القصص", "العنكبوت", "الروم",
        "لقمان", "السجدة", "الأحزاب", "سبأ", "فاطر", "يس", "الصافات", "ص", "الزمر", "غافر",
        "فصلت", "الشورى", "الزخرف", "الدخان", "الجاثية", "الأحقاف", "محمد", "الفتح", "الحجرات", "ق",
        "الذاريات", "الطور", "النجم", "القمر", "الرحمن", "الواقعة", "الحديد", "المجادلة", "الحشر", "الممتحنة",
        "الصف", "الجمعة", "المنافقون", "التغابن", "الطلاق", "التحريم", "الملك", "القلم", "الحاقة", "المعارج",
        "نوح", "الجن", "المزمل", "المدثر", "القيامة", "الإنسان", "المرسلات", "النبأ", "النازعات", "عبس",
        "التكوير", "الانفطار", "المطففين", "الانشقاق", "البروج", "الطارق", "الأعلى", "الغاشية", "الفجر", "البلد",
        "الشمس", "الليل", "الضحى", "الشرح", "التين", "العلق", "القدر", "البينة", "الزلزلة", "العاديات",
        "القارعة", "التكاثر", "العصر", "الهمزة", "الفيل", "قريش", "الماعون", "الكوثر", "الكافرون", "النصر",
        "المسد", "الإخلاص", "الفلق", "الناس"
    ]

    function dayOfYear(): int {
        const now = new Date();
        return Math.floor((now - new Date(now.getFullYear(), 0, 0)) / 86400000);
    }

    function pickIndex(): int {
        if (!verses.length)
            return -1;
        if (root.mode === "daily")
            return dayOfYear() % verses.length;
        if (root.mode === "sequential") {
            const next = (root.index + 1) % verses.length;
            return next < 0 ? 0 : next;
        }
        return Math.floor(Math.random() * verses.length);
    }

    function applyIndex(i: int): void {
        if (i < 0 || i >= verses.length)
            return;
        root.index = i;
        const v = verses[i];
        root.surah = v.surah;
        root.ayah = v.ayah;
        root.text = v.text;
        root.surahName = surahNames[v.surah - 1] ?? "";
        root.ref = `${v.surah}:${v.ayah}`;
        root.ready = true;
        if (root.fontRandom)
            rollFont();
        saveTimer.restart();
    }

    function next(): void {
        if (!verses.length)
            return;
        let i = pickIndex();
        if (root.mode === "random" && verses.length > 1) {
            while (i === root.index)
                i = Math.floor(Math.random() * verses.length);
        }
        applyIndex(i);
    }

    function setMode(m: string): void {
        if (m !== "random" && m !== "daily" && m !== "sequential")
            return;
        root.mode = m;
        if (verses.length)
            applyIndex(pickIndex());
        else
            saveTimer.restart();
    }

    function setVerse(s: int, a: int): bool {
        if (!verses.length || s < 1 || s > surahNames.length || a < 1)
            return false;
        for (let i = 0; i < verses.length; i++) {
            if (verses[i].surah === s && verses[i].ayah === a) {
                applyIndex(i);
                return true;
            }
        }
        return false;
    }

    function random(): void {
        if (!verses.length)
            return;
        let i = Math.floor(Math.random() * verses.length);
        if (verses.length > 1) {
            while (i === root.index)
                i = Math.floor(Math.random() * verses.length);
        }
        applyIndex(i);
    }

    function setFontScale(v: real): void {
        if (isNaN(v) || v < 0.25 || v > 4)
            return;
        root.fontScale = v;
        saveTimer.restart();
    }

    function setFontFamily(f: string): void {
        if (f === "random") {
            root.fontRandom = true;
            root.rollFont();
        } else {
            root.fontRandom = false;
            root.fontFamily = (f === "" || f === "default") ? "Noto Nastaliq Urdu" : f;
        }
        saveTimer.restart();
    }

    function rollFont(): void {
        if (!fontPool.length)
            return;
        const pickFrom = list => list[Math.floor(Math.random() * list.length)];
        const rest = fontPool.filter(f => !smallFonts.includes(f));
        const big = rest.length ? rest : fontPool;
        let f = root.fontFamily;
        let guard = 0;
        while (f === root.fontFamily && guard++ < 10)
            f = Math.random() < 0.4 ? pickFrom(smallFonts) : pickFrom(big);
        root.fontFamily = f;
    }

    function setPaint(which: string, c: string): void {
        const v = (c === "" || c === "default") ? "" : c;
        if (which === "ref")
            root.fgRef = v;
        else if (which === "outline")
            root.outline = v;
        else
            root.fgVerse = v;
        saveTimer.restart();
    }

    function setAuraScale(v: real): void {
        if (isNaN(v) || v < 0 || v > 3)
            return;
        root.auraScale = v;
        saveTimer.restart();
    }

    function describe(): string {
        return `verse: ${root.surahName} ${root.ref}\nmode: ${root.mode}\nfont: ${root.fontFamily} x${root.fontScale}${root.fontRandom ? " (random)" : ""}\nfg: ${root.fgVerse || "default"}\nfgRef: ${root.fgRef || "default"}\noutline: ${root.outline || "default"}\naura: ${root.auraScale}\ntext: ${root.text}`;
    }

    IpcHandler {
        function current(): string {
            return root.ready ? `${root.surahName} ${root.ref}\n${root.text}` : "not ready";
        }

        function verse(surah: string, ayah: string): string {
            const s = Number(surah);
            const a = Number(ayah);
            if (!Number.isInteger(s) || !Number.isInteger(a))
                return "usage: verse <surah> <ayah>";
            return root.setVerse(s, a) ? `ok ${root.surahName} ${root.ref}` : "verse not found";
        }

        function random(): string {
            root.random();
            return root.ready ? `ok ${root.surahName} ${root.ref}` : "not ready";
        }

        function mode(m: string): string {
            if (m !== "random" && m !== "daily" && m !== "sequential")
                return "usage: mode <random|daily|sequential>";
            root.setMode(m);
            return `ok ${root.mode}`;
        }

        function fontSize(scale: string): string {
            const v = Number(scale);
            if (isNaN(v))
                return "usage: fontSize <scale 0.25..4>";
            root.setFontScale(v);
            return `ok ${root.fontScale}`;
        }

        function fontFamily(name: string): string {
            root.setFontFamily(name);
            return `ok ${root.fontFamily}`;
        }

        function fg(color: string): string {
            root.setPaint("verse", color);
            return `ok ${root.fgVerse || "default"}`;
        }

        function fgRef(color: string): string {
            root.setPaint("ref", color);
            return `ok ${root.fgRef || "default"}`;
        }

        function outline(color: string): string {
            root.setPaint("outline", color);
            return `ok ${root.outline || "default"}`;
        }

        function aura(scale: string): string {
            const v = Number(scale);
            if (isNaN(v))
                return "usage: aura <scale 0..3>";
            root.setAuraScale(v);
            return `ok ${root.auraScale}`;
        }

        function status(): string {
            return root.describe();
        }

        function fonts(): string {
            return root.fontPool.join("\n");
        }

        target: "quran"
    }

    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: stateFile.setText(JSON.stringify({
            mode: root.mode,
            index: root.index,
            fontScale: root.fontScale,
            fontFamily: root.fontFamily,
            fontRandom: root.fontRandom,
            fgVerse: root.fgVerse,
            fgRef: root.fgRef,
            outline: root.outline,
            auraScale: root.auraScale
        }))
    }

    FileView {
        id: stateFile
        printErrors: false
        path: `${Paths.state}/quran.json`
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data.mode === "random" || data.mode === "daily" || data.mode === "sequential")
                    root.mode = data.mode;
                if (Number.isInteger(data.index))
                    root.index = data.index;
                if (typeof data.fontScale === "number" && data.fontScale >= 0.25 && data.fontScale <= 4)
                    root.fontScale = data.fontScale;
                if (typeof data.fontFamily === "string" && data.fontFamily)
                    root.fontFamily = data.fontFamily;
                if (data.fontRandom === true || data.fontRandom === false)
                    root.fontRandom = data.fontRandom;
                if (typeof data.fgVerse === "string")
                    root.fgVerse = data.fgVerse;
                if (typeof data.fgRef === "string")
                    root.fgRef = data.fgRef;
                if (typeof data.outline === "string")
                    root.outline = data.outline;
                if (typeof data.auraScale === "number" && data.auraScale >= 0 && data.auraScale <= 3)
                    root.auraScale = data.auraScale;
            } catch (e) {
                console.warn(lc, `Unable to parse quran state: ${e}`);
            }
            root.stateLoaded = true;
            maybeInit();
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => setText("{}"));
            root.stateLoaded = true;
            maybeInit();
        }
    }

    FileView {
        path: `${Quickshell.shellDir}/data/quran.txt`
        onLoaded: {
            const lines = text().split("\n");
            const list = [];
            for (const line of lines) {
                const sep1 = line.indexOf("|");
                const sep2 = line.indexOf("|", sep1 + 1);
                if (sep1 === -1 || sep2 === -1)
                    continue;
                const s = Number(line.slice(0, sep1));
                const a = Number(line.slice(sep1 + 1, sep2));
                const t = line.slice(sep2 + 1).trim();
                if (!Number.isInteger(s) || !Number.isInteger(a) || !t)
                    continue;
                list.push({ surah: s, ayah: a, text: t });
            }
            root.verses = list;
            root.count = list.length;
            root.dataLoaded = true;
            maybeInit();
        }
    }

    LoggingCategory {
        id: lc
        name: "caelestia.qml.services.quran"
        defaultLogLevel: LoggingCategory.Info
    }
}
