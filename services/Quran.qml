pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
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

    // Per-ayah visual variation. The spectrum order itself never changes; only
    // which entry the gradient starts on and how far it is tilted.
    property real spectrumPhase: 0
    property real gradientAngle: 0

    // ---- Translation, shown under the verse by default --------------------
    property bool translationEnabled: true
    property string translationId: "en.sahih"
    // Family for the translation text ("" = the shell's body font).
    property string translationFont: "Amiri"
    // Fraction of the rendered verse size the translation is drawn at.
    property real translationScale: 0.34
    // Active translation parsed into a "surah:ayah" -> text map.
    property var translationIndex: ({})
    property string translatedText: ""
    property bool translationFetching: false
    property string translationFetchError: ""
    // Translations downloaded at runtime: [{ id, language, name }]
    property var fetchedTranslations: []
    // Follow the shell/system language: show the translation for that language,
    // downloading it when we don't ship it. Any explicit pick turns this off.
    property bool translationFollowLanguage: true
    // Set when a language was auto-downloaded (or the download failed), so a
    // failure isn't retried for every verse.
    property string translationAutoTried: ""

    // Language the translation follows: the shell UI language when one is set,
    // otherwise the system locale. Only the primary subtag matters, so "tr_TR"
    // and "tr-TR" both give "tr".
    readonly property string translationLanguage: {
        const raw = Tr.language || Qt.locale().name || "";
        return String(raw).split(/[_\-.@]/)[0].toLowerCase();
    }

    // Shipped in data/quran-translations/.
    readonly property var builtinTranslations: [
        { id: "en.sahih", language: "English", name: "Saheeh International" },
        { id: "de.bubenheim", language: "German", name: "Bubenheim & Elyas" },
        { id: "tr.ates", language: "Turkish", name: "Süleyman Ateş" },
    ]

    // Other Tanzil translations, downloadable on demand. The id is used
    // directly in https://tanzil.net/trans/<id>.
    readonly property var fetchableTranslations: [
        { id: "ru.kuliev", language: "Russian", name: "Elmir Kuliev" },
        { id: "ru.osmanov", language: "Russian", name: "Osmanov" },
        { id: "fr.hamidullah", language: "French", name: "Muhammad Hamidullah" },
        { id: "es.cortes", language: "Spanish", name: "Julio Cortes" },
        { id: "de.aburida", language: "German", name: "Abu Rida" },
        { id: "id.indonesian", language: "Indonesian", name: "Ministry of Religious Affairs" },
        { id: "ur.jalandhry", language: "Urdu", name: "Fateh Muhammad Jalandhry" },
        { id: "bn.bengali", language: "Bengali", name: "Muhiuddin Khan" },
        { id: "fa.ansarian", language: "Persian", name: "Hussain Ansarian" },
        { id: "zh.jian", language: "Chinese", name: "Ma Jian" },
        { id: "ja.japanese", language: "Japanese", name: "Japanese" },
        { id: "ko.korean", language: "Korean", name: "Korean" },
        { id: "it.piccardo", language: "Italian", name: "Hamza Roberto Piccardo" },
        { id: "nl.keyzer", language: "Dutch", name: "Salomo Keyzer" },
        { id: "pt.elhayek", language: "Portuguese", name: "Samir El-Hayek" },
        { id: "sv.bernstrom", language: "Swedish", name: "Knut Bernström" },
        { id: "pl.bielawskiego", language: "Polish", name: "Józef Bielawski" },
    ]

    readonly property var translationOptions: [...builtinTranslations, ...fetchedTranslations]

    // Every family here must cover Arabic (verified via `fc-list :lang=ar`).
    readonly property list<string> fontPool: [
        "(A) Arslan Wessam B",
        "AGA Kyrawan V.2",
        "Amiri Quran",
        "Amiri",
        "Aref Ruqaa",
        "B Fantezy",
        "Diwani Letter",
        // "IBM Plex Sans Arabic Light",
        // "IBM Plex Sans Arabic Medium",
        "IBM Plex Sans Arabic Bold",
        "IranNastaliq",
        "Islamic Palestine",
        "KFGQPC Kufi Extended",
        "KFGQPC Kufi Stylistic",
        "Mj_Faten",
        // "Mj_Nova",
        "Noto Kufi Arabic",
        "Noto Naskh Arabic",
        "Noto Nastaliq Urdu",
        "Noto Sans Arabic",
        "Old Antic Bold",
        "Raqq",
        "Reem Kufi Medium",
        "Reem Kufi",
        "Sayeh2",
        // "Scheherazade New Medium",
        "Scheherazade New",
        "Square Kufic",
        "khalaad Abeer"
        // "AGA Kayrawan Regular", // BROKEN
        // "MCS Hijaz S_U adorn.", // BROKEN
        // "Samir_Khouaja_Maghribi", // SEMI-WORKING FIX NEEDED
    ]

    // Some faces draw noticeably smaller than the rest at the same point size.
    // When such a face is selected its rendered size is scaled up so it reads at
    // the same visual weight (these offsets used to live as TODO notes here).
    readonly property var fontFactors: ({
        "AGA Kyrawan V.2": 2.0,
        "B Fantezy": 1.5,
        "IranNastaliq": 2.0,
        "Old Antic Bold": 1.5
    })

    // Multiplier applied to the size of the currently selected face.
    readonly property real fontSizeFactor: fontFactors[fontFamily] ?? 1.0

    // Compact faces, picked with 40% probability (see TODO.md).
    readonly property list<string> smallFonts: [
        "Amiri Quran",
        "Amiri",
        "Aref Ruqaa",
        "IBM Plex Sans Arabic Bold",
        "Noto Kufi Arabic",
        "Noto Naskh Arabic",
        "Noto Sans Arabic",
        "Scheherazade New",
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
        root.syncTranslationLanguage();
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
        root.updateTranslation();
        root.spectrumPhase = Math.random();
        root.gradientAngle = (Math.random() * 2 - 1) * 14;
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

    // Compact faces fit dense verses better: the longer the ayah, the higher
    // the small-font probability. Bands mirror maxLines so a 7-line verse
    // almost always lands compact while a one-liner stays expressive.
    function smallProb(): real {
        const len = Quran.text.length;
        if (len <= 30)
            return 0.01;
        if (len <= 70)
            return 0.25;
        if (len <= 130)
            return 0.6;
        if (len <= 220)
            return 0.85;
        if (len <= 400)
            return 0.9;
        return 0.95;
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
            f = Math.random() < smallProb() ? pickFrom(smallFonts) : pickFrom(big);
        root.fontFamily = f;
    }

    // ---- Translation helpers ----------------------------------------------

    function isBuiltinTranslation(id: string): bool {
        return builtinTranslations.some(t => t.id === id);
    }

    // Tanzil ids are "<language>.<translator>", so the id also names the
    // language the translation belongs to.
    function translationLangFor(t: var): string {
        return t && t.id ? String(t.id).split(".")[0].toLowerCase() : "";
    }

    function translationCachePath(id: string): string {
        return `${Paths.state}/quran-translation-${id}.txt`;
    }

    function translationSourcePath(id: string): string {
        if (!id)
            return "";
        return isBuiltinTranslation(id) ? `${Quickshell.shellDir}/data/quran-translations/${id}.txt` : translationCachePath(id);
    }

    function translationNameFor(id: string): string {
        const t = translationOptions.find(x => x.id === id);
        return t ? `${t.language} — ${t.name}` : id;
    }

    function parseTranslations(raw: string): var {
        const map = {};
        for (const line of String(raw).split("\n")) {
            if (!line || line[0] === "#")
                continue;
            const first = line.indexOf("|");
            const second = line.indexOf("|", first + 1);
            if (first < 0 || second < 0)
                continue;
            map[`${Number(line.slice(0, first))}:${Number(line.slice(first + 1, second))}`] = line.slice(second + 1).trim();
        }
        return map;
    }

    function updateTranslation(): void {
        translatedText = root.translationEnabled ? (root.translationIndex[root.ref] ?? "") : "";
    }

    // Keeps the shown translation in step with the language, fetching one the
    // shell doesn't ship. Silent about languages we have nothing for.
    function syncTranslationLanguage(): void {
        if (!root.translationFollowLanguage || !root.translationEnabled)
            return;
        const code = root.translationLanguage;
        if (!code)
            return;

        const have = translationOptions.find(t => translationLangFor(t) === code);
        if (have) {
            root.applyTranslation(have.id, false);
            return;
        }

        const want = fetchableTranslations.find(t => translationLangFor(t) === code);
        // No translation for this language, or we already tried to get it.
        if (!want || root.translationAutoTried === want.id)
            return;
        if (root.translationFetching || root.fetchedTranslations.some(t => t.id === want.id))
            return;

        root.translationAutoTried = want.id;
        root.fetchTranslation(want.id, want.language, want.name, false);
    }

    function setTranslationFollowLanguage(v: bool): void {
        root.translationFollowLanguage = v;
        if (v) {
            // Turning it back on is also the way to retry a failed download.
            root.translationAutoTried = "";
            root.syncTranslationLanguage();
        }
        saveTimer.restart();
    }

    function setTranslationEnabled(v: bool): void {
        root.translationEnabled = v;
        root.updateTranslation();
        if (v)
            root.syncTranslationLanguage();
        saveTimer.restart();
    }

    // manual marks an explicit pick, which stops the translation from following
    // the language.
    function applyTranslation(id: string, manual: bool): void {
        if (!id || id === root.translationId)
            return;
        if (manual)
            root.translationFollowLanguage = false;
        root.translationId = id;
        saveTimer.restart();
    }

    function setTranslationId(id: string): void {
        root.applyTranslation(id, true);
    }

    function fetchTranslation(id: string, language: string, name: string, manual: bool): void {
        if (!id || root.translationFetching)
            return;
        root.translationFetching = true;
        root.translationFetchError = "";
        Requests.get(`https://tanzil.net/trans/${id}`, text => {
            root.translationFetching = false;
            if (!text || text.indexOf("|") === -1) {
                root.translationFetchError = "Empty response";
                return;
            }
            translationWriter.path = root.translationCachePath(id);
            translationWriter.setText(text);
            const rest = root.fetchedTranslations.filter(t => t.id !== id);
            root.fetchedTranslations = [...rest, { id: id, language: language, name: name }];
            root.setTranslationEnabled(true);
            saveTimer.restart();
            if (root.translationId === id) {
                root.translationIndex = root.parseTranslations(text);
                root.updateTranslation();
            } else {
                root.applyTranslation(id, manual);
            }
        }, error => {
            root.translationFetching = false;
            root.translationFetchError = String(error);
        });
    }

    function removeFetchedTranslation(id: string): void {
        root.fetchedTranslations = root.fetchedTranslations.filter(t => t.id !== id);
        if (root.translationId === id)
            root.applyTranslation("en.sahih", false);
        // Don't immediately download the language the user just removed.
        root.translationAutoTried = id;
        translationWriter.path = root.translationCachePath(id);
        translationWriter.setText("");
        saveTimer.restart();
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

    function translationLabel(): string {
        if (!root.translationEnabled)
            return "off";
        return `${root.translationId} (${root.translationNameFor(root.translationId)})`;
    }

    function describe(): string {
        return `verse: ${root.surahName} ${root.ref}\nmode: ${root.mode}\nfont: ${root.fontFamily} x${root.fontScale}${root.fontRandom ? " (random)" : ""}\nfg: ${root.fgVerse || "default"}\nfgRef: ${root.fgRef || "default"}\noutline: ${root.outline || "default"}\naura: ${root.auraScale}\ntranslation: ${root.translationLabel()}\ntext: ${root.text}`;
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

        function translation(enabled: string): string {
            const v = enabled === "true" || enabled === "on" || enabled === "1";
            root.setTranslationEnabled(v);
            return `ok ${root.translationEnabled ? "on" : "off"}`;
        }

        function translationFollow(enabled: string): string {
            const v = enabled === "true" || enabled === "on" || enabled === "1";
            root.setTranslationFollowLanguage(v);
            return `ok ${root.translationFollowLanguage ? "on" : "off"} (${root.translationLanguage || "unknown language"} -> ${root.translationId})`;
        }

        function translationSet(id: string): string {
            if (id === "off" || id === "") {
                root.setTranslationEnabled(false);
                return "ok off";
            }
            root.setTranslationFollowLanguage(false);
            root.setTranslationEnabled(true);
            root.setTranslationId(id);
            return `ok ${root.translationId}`;
        }

        function translations(): string {
            return [...root.builtinTranslations, ...root.fetchedTranslations].map(t => `${t.id}\t${t.language}\t${t.name}`).join("\n");
        }

        function translationFetch(id: string): string {
            if (!id)
                return "usage: translationFetch <tanzil id>";
            const t = root.fetchableTranslations.find(x => x.id === id);
            root.fetchTranslation(id, t?.language ?? id, t?.name ?? id, true);
            return `ok fetching ${id}`;
        }

        function translationRemove(id: string): string {
            if (!root.fetchedTranslations.some(t => t.id === id))
                return `not fetched: ${id}`;
            root.removeFetchedTranslation(id);
            return `ok removed ${id}`;
        }

        target: "quran"
    }

    // Written from the settings UI directly (no setter), so persist those too.
    onTranslationFontChanged: saveTimer.restart()
    onTranslationScaleChanged: saveTimer.restart()

    // Re-pick (and re-download) when the shell language changes.
    Connections {
        target: Tr

        function onLanguageChanged(): void {
            root.translationAutoTried = "";
            root.syncTranslationLanguage();
        }
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
            auraScale: root.auraScale,
            translationEnabled: root.translationEnabled,
            translationId: root.translationId,
            translationFont: root.translationFont,
            translationScale: root.translationScale,
            translationFollowLanguage: root.translationFollowLanguage,
            fetchedTranslations: root.fetchedTranslations
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
                if (typeof data.translationEnabled === "boolean")
                    root.translationEnabled = data.translationEnabled;
                if (typeof data.translationId === "string" && data.translationId)
                    root.translationId = data.translationId;
                if (typeof data.translationFont === "string")
                    root.translationFont = data.translationFont;
                if (typeof data.translationScale === "number" && data.translationScale >= 0.05 && data.translationScale <= 1)
                    root.translationScale = data.translationScale;
                if (typeof data.translationFollowLanguage === "boolean")
                    root.translationFollowLanguage = data.translationFollowLanguage;
                if (Array.isArray(data.fetchedTranslations))
                    root.fetchedTranslations = data.fetchedTranslations.filter(t => t && typeof t.id === "string");
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

    // Active translation text. Reloads whenever translationId changes.
    FileView {
        id: translationFile

        printErrors: false
        watchChanges: true
        path: root.translationId ? root.translationSourcePath(root.translationId) : ""
        onLoaded: {
            root.translationIndex = root.parseTranslations(text());
            root.updateTranslation();
        }
        onLoadFailed: {
            root.translationIndex = ({});
            root.updateTranslation();
        }
    }

    // Writes fetched translations into the state-dir cache.
    FileView {
        id: translationWriter

        printErrors: false
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
