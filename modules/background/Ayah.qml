pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property Item wallpaper
    required property real absX
    required property real absY

    property real ayahScale: 1

    readonly property color accent: Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary)
    readonly property color ink: Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface)
    readonly property color borderColor: Colours.pick(Colours.palette.m3base03, Colours.palette.m3outline)
    readonly property color shadowColor: Colours.pick(Colours.palette.m3base0B, Colours.palette.m3primary)

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



    width: cardWidth
    height: layout.implicitHeight
    implicitWidth: cardWidth
    implicitHeight: layout.implicitHeight

    visible: Quran.ready
    opacity: Quran.ready ? 1 : 0

    Behavior on opacity {
        Anim {}
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.small * root.ayahScale

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.shadowColor
            shadowBlur: 0.35
            shadowOpacity: 0.9
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 3 * root.ayahScale
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            maximumLineCount: root.maxLines
            elide: Text.ElideRight
            text: Quran.text
            color: root.ink
            style: Text.Outline
            styleColor: root.borderColor
            font: Tokens.font.headline.builders.small.scale(root.textScale * root.ayahScale).family("Noto Naskh Arabic").weight(Font.Medium).build()
            lineHeight: 1.6
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: Quran.ready ? `سورة ${Quran.surahName} • ${Quran.ref}` : ""
            color: root.accent
            style: Text.Outline
            styleColor: root.borderColor
            font: Tokens.font.label.builders.small.weight(Font.DemiBold).build()
        }
    }
}
