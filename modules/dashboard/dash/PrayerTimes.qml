import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils


Item {
    id: root

    clip: true

    implicitWidth: layout.implicitWidth + Tokens.padding.small * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.small * 2

    Component.onCompleted: {
        Salat.reload();
        updateNameCol();
    }

    property real nameColWidth: 0

    function updateNameCol(): void {
        let w = 0;
        for (const n of Salat.names) {
            nameMetrics.text = Salat.label(n);
            w = Math.max(w, nameMetrics.advanceWidth);
        }
        nameColWidth = w;
    }

    Connections {
        target: Salat

        function onPrayersChanged(): void {
            root.updateNameCol();
        }
    }

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: 0

        TextMetrics {
            id: timeMetrics

            font: Tokens.font.mono.builders.medium.weight(Font.DemiBold).build()
            text: GlobalConfig.services.useTwelveHourClock ? "00:00 AM" : "00:00"
        }

        TextMetrics {
            id: nameMetrics

            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: Salat.nextIndex < 0
            text: Tr.tr("Prayer times")
            color: Accents.base0D
            font: Tokens.font.headline.builders.small.weight(Font.DemiBold).build()
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
                // rowLayout.implicitWidth excludes its own anchored margins;
                // add them back so the highlight covers name and time fully.
                implicitWidth: rowLayout.implicitWidth + Tokens.padding.small * 2
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
                        Layout.preferredWidth: root.nameColWidth
                        text: Salat.label(row.modelData.name)
                        color: row.isNext ? Colours.on(row.prayerColor) : row.prayerColor
                        font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                        elide: Text.ElideRight
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        Layout.preferredWidth: timeMetrics.width
                        horizontalAlignment: Text.AlignRight
                        text: row.modelData.display
                        color: row.isNext ? Colours.on(row.prayerColor) : row.prayerColor
                        font: Tokens.font.mono.builders.medium.weight(Font.DemiBold).build()
                    }
                }
            }
        }
    }
}
