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

    Component.onCompleted: Salat.reload()

    function arabicName(name: string): string {
        if (name === "Dhuhr" && Salat.isFriday)
            return "الجمعة";
        const names = {
            "Fajr": "الفجر",
            "Sunrise": "الشروق",
            "Dhuhr": "الظهر",
            "Asr": "العصر",
            "Maghrib": "المغرب",
            "Isha": "العشاء"
        };
        return names[name] ?? name;
    }

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: 0

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
                implicitWidth: rowLayout.implicitWidth
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
                    layoutDirection: Qt.RightToLeft

                    StyledText {
                        text: root.arabicName(row.modelData.name)
                        horizontalAlignment: Text.AlignRight
                        color: row.isNext ? Colours.on(row.prayerColor) : row.prayerColor
                        font: Tokens.font.body.builders.medium.family("Noto Kufi Arabic").weight(Font.Black).build()
                        elide: Text.ElideRight
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: row.modelData.display
                        horizontalAlignment: Text.AlignLeft
                        color: row.isNext ? Colours.on(row.prayerColor) : row.prayerColor
                        font: Tokens.font.body.builders.medium.family("Noto Kufi Arabic").weight(Font.Black).build()
                    }
                }
            }
        }
    }
}
