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

    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: stateFile.setText(JSON.stringify({
            mode: root.mode,
            index: root.index
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
