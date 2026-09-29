pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property Item wallpaper
    required property real absX
    required property real absY

    property real ayahScale: 1

    readonly property color ink: Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface)
    readonly property color fillLight: Colours.palette.m3base07
    readonly property color strokeFlat: Quran.outline === "" ? "transparent" : Quran.outline

    // Translation under the verse: base01 glyphs inside a base05 outline drawn
    // at the verse's own width, so both read as one layer.
    readonly property color translationFill: Colours.pick(Colours.palette.m3base01, Colours.palette.m3surfaceContainer)
    readonly property bool translationShown: Quran.translationEnabled && Quran.translatedText !== ""

    // The verse's own font, shared with the GradientText below so the metrics
    // used for spacing can never drift from what is actually rendered.
    readonly property font verseFont: Tokens.font.headline.builders.medium.scale(root.fitScale * root.ayahScale).family(Quran.fontFamily).weight(Font.DemiBold).letterSpacing(0).build()

    // Full-spectrum wheel: one stop per base08-0F entry, so every blend is
    // between neighboring hues only (short distances stay vivid, never gray).
    // The order never changes; each ayah just starts the wheel at a random
    // entry, so the look varies without altering the spectrum itself.
    readonly property int phaseIdx: Math.floor(Quran.spectrumPhase * Accents.charSpectrum.length) % Accents.charSpectrum.length

    function wheelColor(k: int, step: int): color {
        const n = Accents.charSpectrum.length;
        return Accents.charSpectrum[(root.phaseIdx + k * step) % n];
    }

    property Gradient verseGradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: root.wheelColor(0, 1) }
        GradientStop { position: 0.125; color: root.wheelColor(1, 1) }
        GradientStop { position: 0.25; color: root.wheelColor(2, 1) }
        GradientStop { position: 0.375; color: root.wheelColor(3, 1) }
        GradientStop { position: 0.5; color: root.wheelColor(4, 1) }
        GradientStop { position: 0.625; color: root.wheelColor(5, 1) }
        GradientStop { position: 0.75; color: root.wheelColor(6, 1) }
        GradientStop { position: 0.875; color: root.wheelColor(7, 1) }
        GradientStop { position: 1.0; color: root.wheelColor(8, 1) }
    }


    // Smart fullness sizing: measure the verse at base size, then take the
    // largest scale that still fits maxLines within the card. Single-line
    // verses keep the full user size; longer ones shrink just enough to fill
    // the same box, preserving the fullness ratio.
    TextMetrics {
        id: meter

        font: Tokens.font.headline.builders.medium.family(Quran.fontFamily).weight(Font.DemiBold).build()
        text: Quran.text
    }

    // Metrics of the verse as it is rendered (scaled font), used to tuck the
    // translation into the verse's descender whitespace.
    FontMetrics {
        id: verseFm

        font: root.verseFont
    }

    // Arabic faces keep their ink near the baseline but their line box holds the
    // font's full descent, so most of the gap under the verse is empty descender
    // space rather than spacing. Take most of it back - proportional to the
    // rendered font, so the tuck follows the verse whatever size it ends up.
    readonly property real verseDescentTuck: Math.max(0, verseFm.descent) * 0.55

    // Letter count: strips tashkeel/diacritics (explicit ranges, no
    // Unicode property escapes so every JS engine handles it), spaces and
    // tatweel, then counts code points instead of UTF-16 units.
    // E.g. 1:1 counts 19, not 39.
    readonly property int letterCount: {
        const stripped = (Quran.text ?? "").replace(/[\u064B-\u065F\u0670\u06D6-\u06ED]/g, "").replace(/[\s\u0640]/g, "");
        return [...stripped].length;
    }

    // Lines grow with the text (~70 chars per line), the scale then fills
    // exactly maxLines across the card width. No magic gains or floors.
    readonly property int maxLines: Math.max(3, Math.min(9, Math.round(Quran.text.length / 70)))

    readonly property real fitScale: {
        // Faces that draw small (see Quran.fontFactors) get their size scaled up
        // here. The width-derived cap is left unscaled so a boosted face can
        // never spill past maxLines - the multiplier only raises the user-size
        // ceiling that normally limits compact faces.
        const factor = Quran.fontSizeFactor;
        if (root.letterCount < 45)
            return 2.7 * factor;
        const adv = meter.advanceWidth;
        if (adv <= 0)
            return Quran.fontScale * factor;
        return Math.min(Quran.fontScale * factor, Math.max(root.maxLines * root.cardWidth / (adv * root.ayahScale), 0.15));
    }

    // Translation under the verse: its own face, always smaller than the verse
    // it follows, sized relative to the rendered verse (dynamic) but clamped so
    // it stays readable and subordinate.
    readonly property int translationPointSize: {
        const bodyPx = Tokens.font.body.medium.pointSize;
        const versePx = Tokens.font.headline.medium.pointSize * root.fitScale * root.ayahScale;
        return Math.round(Math.max(bodyPx * 0.85, Math.min(bodyPx * 2, versePx * Quran.translationScale)));
    }

    readonly property real cardWidth: parent ? Math.min(parent.width, 1100 * ayahScale) : 640 * ayahScale

    anchors.centerIn: parent

    width: cardWidth
    height: layout.implicitHeight
    implicitWidth: cardWidth
    implicitHeight: layout.implicitHeight

    visible: Quran.ready
    opacity: Quran.ready ? 1 : 0

    Behavior on opacity {
        Anim {}
    }

    ParallelAnimation {
        id: verseFade

        Anim {
            target: layout
            property: "opacity"
            from: 0
            to: 1
        }
        Anim {
            target: layout
            property: "scale"
            from: 0.98
            to: 1
        }
    }

    Connections {
        target: Quran
        function onTextChanged(): void {
            if (Quran.ready)
                verseFade.restart();
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        // Negative spacing: pull the row below up into the verse's descent
        // whitespace, roughly halving the visible gap (auras overlap harmlessly).
        spacing: -40 * root.ayahScale
        transformOrigin: Item.Center

        GradientText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            text: Quran.text
            font: root.verseFont
            fill: Quran.fgVerse === "" ? root.fillLight : Quran.fgVerse
            gradient: root.verseGradient
            gradientAngle: Quran.gradientAngle
            strokeColor: root.strokeFlat
            outlineWidth: 2.5 * root.ayahScale
            auraWidth: 14 * root.ayahScale
            auraStrength: 0.55 * Quran.auraScale
            maximumLineCount: root.maxLines
            lineH: 1.0
        }

        // The translation sits between the verse and its surah signature:
        // smaller than the verse, base01 glyphs under a base05 outline that is
        // as wide as the verse's own.
        GradientText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            // 40 * ayahScale cancels the negative row spacing above, so what is
            // left is the real gap: a sliver of breathing room minus the verse's
            // descender space (see verseDescentTuck).
            Layout.topMargin: 40 * root.ayahScale + Tokens.spacing.extraSmall - root.verseDescentTuck
            visible: root.translationShown
            text: Quran.translatedText
            font: Quran.translationFont ? Tokens.font.body.builders.medium.size(root.translationPointSize).family(Quran.translationFont).build() : Tokens.font.body.builders.medium.size(root.translationPointSize).build()
            fill: root.translationFill
            strokeColor: root.ink
            outlineWidth: 2.5 * root.ayahScale
            auraWidth: 0
            auraStrength: 0
            lineH: 1.0
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            // With the translation in between, the ref line can no longer tuck
            // into the verse's descent - give it a normal gap instead.
            Layout.topMargin: root.translationShown ? Tokens.spacing.small + 40 * root.ayahScale : 0
            text: Quran.ready ? `سورة ${Quran.surahName} • ${Quran.ref}` : ""
            color: Quran.fgRef === "" ? Colours.palette.m3base03 : Quran.fgRef
            font: Tokens.font.label.builders.medium.scale(1.5).family("Aref Ruqaa").weight(Font.DemiBold).letterSpacing(0).build()
        }
    }
}
