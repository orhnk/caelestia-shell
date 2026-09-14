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
    readonly property color fillDark: Colours.palette.m3base01
    property color outlineColor: Quran.outline === "" ? Qt.alpha(Colours.palette.m3base00, 0.85) : Quran.outline

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

    property Gradient refGradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: root.wheelColor(0, 2) }
        GradientStop { position: 0.25; color: root.wheelColor(1, 2) }
        GradientStop { position: 0.5; color: root.wheelColor(2, 2) }
        GradientStop { position: 0.75; color: root.wheelColor(3, 2) }
        GradientStop { position: 1.0; color: root.wheelColor(4, 2) }
    }

    readonly property real textScale: {
        const len = Quran.text.length;
        if (len <= 70)
            return 2.1;
        if (len <= 130)
            return 1.8;
        if (len <= 220)
            return 1.5;
        if (len <= 400)
            return 1.3;
        return 1.05;
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
        spacing: 0
        transformOrigin: Item.Center

        GradientText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            text: Quran.text
            font: Tokens.font.headline.builders.small.scale(root.textScale * root.ayahScale).family("Noto Nastaliq Urdu").weight(Font.DemiBold).letterSpacing(0).build()
            fill: root.fillLight
            gradient: root.verseGradient
            outlineWidth: 2.5 * root.ayahScale
            auraWidth: 14 * root.ayahScale
            auraStrength: 0.55
            maximumLineCount: root.maxLines
            lineH: 1.6
        }

        GradientText {
            Layout.alignment: Qt.AlignHCenter
            text: Quran.ready ? `سورة ${Quran.surahName} • ${Quran.ref}` : ""
            font: Tokens.font.label.builders.medium.scale(1.5).weight(Font.DemiBold).letterSpacing(0).build()
            fill: root.fillDark
            gradient: root.refGradient
            outlineWidth: 1.5 * root.ayahScale
            auraWidth: 6 * root.ayahScale
            auraStrength: 0.5
        }
    }
}
