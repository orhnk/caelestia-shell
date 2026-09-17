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

    // Face, size and weight of the big time left / clock. The family is pinned here
    // rather than taken from `appearance.font.clock`, because that setting is
    // the theme's mono font (a nerd font), which reads poorly as a clock at
    // this size. Rubik is the shell's own default clock face.
    property string clockFamily: "Rubik"
    property int clockSize: 44
    // Rubik is a variable font (wght 300-900), so in-between values interpolate
    // too - a raw number like 850 works as well as a named step:
    // Medium 500 / DemiBold 600 / Bold 700 / ExtraBold 800 / Black 900.
    property int clockWeight: Font.ExtraBold

    // AM/PM label keeps the 32:20 ratio the two used to have.
    readonly property int amPmSize: Math.round(root.clockSize * 0.625)

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: 0

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: `${root.hour}:${root.minute}`
            color: Accents.base06
            font: Tokens.font.clock.family(root.clockFamily).size(root.clockSize).weight(root.clockWeight).build()
        }

        Loader {
            asynchronous: true
            Layout.alignment: Qt.AlignHCenter

            active: GlobalConfig.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: Time.amPmStr
                color: Accents.base0F
                font: Tokens.font.clock.family(root.clockFamily).size(root.amPmSize).weight(root.clockWeight).build()
            }
        }
    }
}
