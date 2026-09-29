pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property real centerScale

    // Two consecutive hues out of the base08-0F run, rolled per lock screen, so
    // the clock is not the same pair of theme colours every time: the hours take
    // the first, the minutes the second.
    readonly property var clockRun: Accents.spectrumRun(2)

    function calcTopOff(metrics: TextMetrics): real {
        return metrics.tightBoundingRect.y - metrics.boundingRect.y;
    }

    implicitWidth: hours.implicitWidth + minutes.implicitWidth + Tokens.spacing.small
    implicitHeight: hourMetrics.tightBoundingRect.height

    StyledText {
        id: hours

        y: -root.calcTopOff(hourMetrics)
        text: Time.hourStr
        color: Accents.runAt(root.clockRun, 0)
        font: Tokens.font.headline.builders.large.scale(7 * root.centerScale).width(30).build()

        TextMetrics {
            id: hourMetrics

            text: hours.text
            font: hours.font
        }
    }

    StyledText {
        id: minutes

        anchors.right: parent.right
        y: -root.calcTopOff(minuteMetrics)

        text: Time.minuteStr
        color: Accents.runAt(root.clockRun, 1)
        font: Tokens.font.headline.builders.large.scale((GlobalConfig.services.useTwelveHourClock ? 3.8 : 7) * root.centerScale).width(30).build()

        TextMetrics {
            id: minuteMetrics

            text: minutes.text
            font: minutes.font
        }
    }

    Loader {
        anchors.left: minutes.left
        anchors.leftMargin: minuteMetrics.tightBoundingRect.x
        y: hourMetrics.tightBoundingRect.height - implicitHeight

        active: GlobalConfig.services.useTwelveHourClock
        asynchronous: true

        sourceComponent: StyledRect {
            color: Colours.pick(Colours.tPalette.m3base03, Colours.tPalette.m3surfaceContainerHigh)
            radius: Tokens.rounding.large

            implicitWidth: minuteMetrics.tightBoundingRect.width
            implicitHeight: amPmMetrics.tightBoundingRect.height + Tokens.padding.large * 2

            StyledText {
                id: amPm

                anchors.centerIn: parent
                width: amPmMetrics.tightBoundingRect.width
                height: amPmMetrics.tightBoundingRect.height
                transform: Translate {
                    x: -amPmMetrics.tightBoundingRect.x
                    y: -root.calcTopOff(amPmMetrics)
                }

                text: Time.amPmStr
                color: Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface)
                font: Tokens.font.headline.builders.small.scale(2 * root.centerScale).width(30).build()

                TextMetrics {
                    id: amPmMetrics

                    text: amPm.text
                    font: amPm.font
                }
            }
        }
    }
}
