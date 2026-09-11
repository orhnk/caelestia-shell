import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils


Item {
    id: root

    implicitWidth: layout.implicitWidth + Tokens.padding.small * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.small * 2

    Component.onCompleted: Salat.reload()

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: Salat.nextIndex < 0 || Salat.nextNow
            text: Salat.nextIndex < 0 ? Tr.tr("Prayer times") : Salat.nextIn
            color: Accents.base0D
            font: Tokens.font.headline.builders.small.weight(Font.DemiBold).build()
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            visible: Salat.nextIndex >= 0 && !Salat.nextNow
            spacing: Tokens.spacing.extraSmall

            TextMetrics {
                id: digitMetrics

                font: Tokens.font.clock.size(36).weight(Font.DemiBold).build()
                text: "00"
            }

            StyledText {
                Layout.preferredWidth: digitMetrics.width
                horizontalAlignment: Text.AlignHCenter
                text: Salat.nextHours
                color: Accents.base0D
                font: digitMetrics.font
            }

            StyledText {
                text: ":"
                color: Accents.base0D
                opacity: Time.seconds % 2 === 0 ? 1 : 0.3
                font: digitMetrics.font

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            StyledText {
                Layout.preferredWidth: digitMetrics.width
                horizontalAlignment: Text.AlignHCenter
                text: String(Salat.nextMins).padStart(2, "0")
                color: Accents.base0D
                font: digitMetrics.font
            }
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: text.length > 0
            text: Salat.hijri
            color: Colours.pick(Colours.palette.m3base04, Colours.palette.m3onSurfaceVariant)
            font: Tokens.font.body.builders.small.letterSpacing(1).build()
            elide: Text.ElideRight
        }

        Repeater {
            model: Salat.prayers

            Item {
                id: row

                required property var modelData
                required property int index

                readonly property bool isNext: index === Salat.nextIndex
                readonly property color prayerColor: Accents.prayerColor(index)

                Layout.fillWidth: true
                implicitHeight: rowLayout.implicitHeight + Tokens.padding.small * 2

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.medium
                    color: row.isNext ? row.prayerColor : "transparent"

                    Behavior on color {
                        CAnim {}
                    }
                }

                RowLayout {
                    id: rowLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.small
                    anchors.rightMargin: Tokens.padding.small
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.fillWidth: true
                        text: Salat.label(row.modelData.name)
                        color: row.isNext ? Colours.on(row.prayerColor) : row.prayerColor
                        font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: row.modelData.display
                        color: row.isNext ? Colours.on(row.prayerColor) : row.prayerColor
                        font: Tokens.font.mono.builders.medium.weight(Font.Medium).build()
                    }
                }
            }
        }
    }
}
