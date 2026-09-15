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

    // Full-spectrum wheel: one stop per base08-0F entry, so every blend is
    // between neighboring hues only (short distances stay vivid, never gray).
    // Each surah rotates the wheel to its own starting phase.
    readonly property int phaseIdx: Quran.surah % Accents.charSpectrum.length

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

        font: Tokens.font.headline.builders.small.family(Quran.fontFamily).weight(Font.DemiBold).build()
        text: Quran.text
    }

    readonly property real fitScale: {
        const adv = meter.advanceWidth;
        if (adv <= 0)
            return Quran.fontScale;
        const s = 0.92 * root.maxLines * root.cardWidth / (adv * root.ayahScale);
        return Math.min(Quran.fontScale, Math.max(s, 0.4));
    }
    readonly property int maxLines: Quran.text.length > 400 ? 7 : 5

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
        // Pull the ref line up into the verse's descent whitespace,
        // roughly halving the visible gap (auras overlap harmlessly).
        spacing: -40 * root.ayahScale
        transformOrigin: Item.Center

        GradientText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            text: Quran.text
            font: Tokens.font.headline.builders.small.scale(root.fitScale * root.ayahScale).family(Quran.fontFamily).weight(Font.DemiBold).letterSpacing(0).build()
            fill: Quran.fgVerse === "" ? root.fillLight : Quran.fgVerse
            gradient: root.verseGradient
            strokeColor: root.strokeFlat
            outlineWidth: 2.5 * root.ayahScale
            auraWidth: 14 * root.ayahScale
            auraStrength: 0.55 * Quran.auraScale
            maximumLineCount: root.maxLines
            lineH: 1.6
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: Quran.ready ? `سورة ${Quran.surahName} • ${Quran.ref}` : ""
            color: Quran.fgRef === "" ? Colours.palette.m3base03 : Quran.fgRef
            font: Tokens.font.label.builders.medium.scale(1.5 * Quran.fontScale).family("Aref Ruqaa").weight(Font.DemiBold).letterSpacing(0).build()
        }
    }
}
