pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
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

    readonly property color accent: Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary)
    readonly property color ink: Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface)

    readonly property real textScale: {
        const len = Quran.text.length;
        if (len <= 70)
            return 1.4;
        if (len <= 130)
            return 1.2;
        if (len <= 220)
            return 1.0;
        if (len <= 400)
            return 0.85;
        return 0.7;
    }
    readonly property int maxLines: Quran.text.length > 400 ? 7 : 5

    readonly property real cardWidth: 640 * ayahScale

    readonly property list<color> bandColors: [Accents.base08, Accents.base09, Accents.base0A, Accents.base0B, Accents.base0C, Accents.base0D, Accents.base0E, Accents.base0F]
    readonly property list<real> bandBlurs: [0.3, 0.32, 0.35, 0.38, 0.42, 0.46, 0.5, 0.55]
    readonly property list<int> bandOffsets: [0, 3, 6, 9, 12, 15, 18, 21]
    readonly property list<real> bandScales: [1.0, 1.01, 1.02, 1.03, 1.04, 1.05, 1.06, 1.07]
    readonly property list<real> bandOpacities: [0.75, 0.68, 0.6, 0.52, 0.45, 0.38, 0.3, 0.24]

    width: cardWidth
    height: layout.implicitHeight
    implicitWidth: cardWidth
    implicitHeight: layout.implicitHeight

    visible: Quran.ready
    opacity: Quran.ready ? 1 : 0

    Behavior on opacity {
        Anim {}
    }

    Repeater {
        model: 8

        MultiEffect {
            required property int index

            anchors.fill: parent
            source: layout
            shadowEnabled: true
            shadowColor: root.bandColors[index]
            shadowBlur: root.bandBlurs[index]
            shadowOpacity: root.bandOpacities[index]
            shadowHorizontalOffset: 0
            shadowVerticalOffset: root.bandOffsets[index]
            shadowScale: root.bandScales[index]
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.small * root.ayahScale

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            maximumLineCount: root.maxLines
            elide: Text.ElideRight
            text: Quran.text
            color: root.ink
            font: Tokens.font.headline.builders.small.scale(root.textScale * root.ayahScale).family("Noto Naskh Arabic").weight(Font.Medium).build()
            lineHeight: 1.6
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: Quran.ready ? `سورة ${Quran.surahName} • ${Quran.ref}` : ""
            color: root.accent
            font: Tokens.font.label.builders.small.weight(Font.DemiBold).build()
        }
    }
}
