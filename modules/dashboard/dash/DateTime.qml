pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    property string hour: Time.hourStr
    property string minute: Time.minuteStr

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        TextMetrics {
            id: digitMetrics

            font: Tokens.font.clock.size(24).weight(Font.DemiBold).build()
            text: "00"
        }

        StyledText {
            Layout.preferredWidth: digitMetrics.width
            horizontalAlignment: Text.AlignHCenter
            text: root.hour
            color: Accents.base0A
            font: digitMetrics.font
        }

        StyledText {
            text: ":"
            color: Accents.base0F
            font: digitMetrics.font
        }

        StyledText {
            Layout.preferredWidth: digitMetrics.width
            horizontalAlignment: Text.AlignHCenter
            text: root.minute
            color: Accents.base0A
            font: digitMetrics.font
        }

        Loader {
            asynchronous: true
            Layout.alignment: Qt.AlignVCenter

            active: GlobalConfig.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: Time.amPmStr
                color: Accents.base0F
                font: Tokens.font.clock.size(15).weight(Font.DemiBold).build()
            }
        }
    }
}
