import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils


Item {
    id: root

    implicitWidth: layout.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    Component.onCompleted: Salat.reload()

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Salat.nextIndex >= 0 ? `${Salat.label(Salat.prayers[Salat.nextIndex]?.name ?? "")} · ${Tr.tr("in %1").arg(Salat.nextIn)}` : Tr.tr("Prayer times")
            color: Accents.base0D
            font: Tokens.font.title.small
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: text.length > 0
            text: Salat.hijri
            color: Colours.pick(Colours.palette.m3base04, Colours.palette.m3onSurfaceVariant)
            font: Tokens.font.body.small
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
                implicitHeight: rowLayout.implicitHeight + (isNext ? Tokens.padding.small * 2 : 0)

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
                    anchors.leftMargin: row.isNext ? Tokens.padding.small : 0
                    anchors.rightMargin: row.isNext ? Tokens.padding.small : 0
                    spacing: Tokens.spacing.medium

                    StyledText {
                        Layout.fillWidth: true
                        text: Salat.label(row.modelData.name)
                        color: row.isNext ? Colours.on(row.prayerColor) : row.prayerColor
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: row.modelData.display
                        color: row.isNext ? Colours.on(row.prayerColor) : row.prayerColor
                        font: Tokens.font.body.small
                    }
                }
            }
        }
    }
}
