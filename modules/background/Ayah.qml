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

    readonly property bool blurEnabled: !GameMode.enabled
    readonly property color accent: Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary)
    readonly property color onCard: Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface)
    readonly property color subColour: Colours.pick(Colours.palette.m3base04, Colours.palette.m3onSurfaceVariant)

    implicitWidth: Math.min(layout.implicitWidth + Tokens.padding.large * 2 * ayahScale, 720 * ayahScale)
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2 * ayahScale

    visible: Quran.ready
    opacity: Quran.ready ? 1 : 0

    Behavior on opacity {
        Anim {}
    }

    Item {
        id: container

        anchors.fill: parent

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Colours.pick(Colours.palette.m3base00, Colours.palette.m3shadow)
            shadowOpacity: 0.7
            shadowBlur: 0.4
        }

        Loader {
            asynchronous: true
            anchors.fill: parent
            active: root.blurEnabled

            sourceComponent: MultiEffect {
                source: ShaderEffectSource {
                    sourceItem: root.wallpaper
                    sourceRect: Qt.rect(root.absX, root.absY, root.width, root.height)
                }
                maskSource: plate
                maskEnabled: true
                blurEnabled: true
                blur: 1
                blurMax: 64
                autoPaddingEnabled: false
            }
        }

        StyledRect {
            id: plate

            anchors.fill: parent
            radius: Tokens.rounding.extraLarge * root.ayahScale
            opacity: 0.72
            color: Colours.pick(Colours.palette.m3base00, Colours.palette.m3surface)

            layer.enabled: root.blurEnabled
        }

        StyledRect {
            anchors.fill: parent
            radius: plate.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(root.accent, 0.35)
        }

        StyledRect {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: -2 * root.ayahScale
            implicitWidth: refPill.implicitWidth + Tokens.padding.medium * 2 * root.ayahScale
            implicitHeight: refPill.implicitHeight + Tokens.padding.small * 2 * root.ayahScale
            radius: Tokens.rounding.full
            color: root.accent

            Row {
                id: refPill

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall * root.ayahScale

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "menu_book"
                    color: Colours.on(root.accent)
                    fontStyle: Tokens.font.icon.builders.small.build()
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Quran.ready ? `سورة ${Quran.surahName} • ${Quran.ref}` : ""
                    color: Colours.on(root.accent)
                    font: Tokens.font.label.builders.small.weight(Font.DemiBold).build()
                }
            }
        }

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: Tokens.padding.large * root.ayahScale
            anchors.topMargin: Tokens.padding.extraLarge * root.ayahScale
            spacing: Tokens.spacing.small * root.ayahScale

            StyledText {
                Layout.fillWidth: true
                Layout.maximumWidth: 640 * root.ayahScale
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 4
                elide: Text.ElideRight
                text: Quran.text
                color: root.onCard
                font: Tokens.font.headline.builders.small.family("Noto Naskh Arabic").weight(Font.Medium).build()
                lineHeight: 1.6
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.small * root.ayahScale

                StyledRect {
                    Layout.preferredWidth: 28 * root.ayahScale
                    Layout.preferredHeight: 2
                    radius: Tokens.rounding.full
                    color: Qt.alpha(root.accent, 0.6)
                }

                StyledText {
                    text: "﷽"
                    color: root.accent
                    font: Tokens.font.title.builders.small.build()
                }

                StyledRect {
                    Layout.preferredWidth: 28 * root.ayahScale
                    Layout.preferredHeight: 2
                    radius: Tokens.rounding.full
                    color: Qt.alpha(root.accent, 0.6)
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quran.next()
        }
    }
}
