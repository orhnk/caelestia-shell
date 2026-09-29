pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property real centerScale

    // Reverse outline: the hours are base02 filled and base05 rimmed, the
    // minutes the other way round, so the two halves of the clock read as one
    // lockup instead of two unrelated digits.
    readonly property color hourFill: Colours.pick(Colours.palette.m3base02, Colours.palette.m3surfaceContainer)
    readonly property color hourStroke: Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface)
    readonly property color minuteFill: Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface)
    readonly property color minuteStroke: Colours.pick(Colours.palette.m3base02, Colours.palette.m3surfaceContainer)

    function calcTopOff(metrics: TextMetrics): real {
        return metrics.tightBoundingRect.y - metrics.boundingRect.y;
    }

    implicitWidth: hours.implicitWidth + minutes.implicitWidth + Tokens.spacing.small
    implicitHeight: hourMetrics.tightBoundingRect.height

    GradientText {
        id: hours

        y: -root.calcTopOff(hourMetrics)
        text: Time.hourStr
        font: Tokens.font.headline.builders.large.scale(7 * root.centerScale).width(30).build()
        fill: root.hourFill
        strokeColor: root.hourStroke
        outlineWidth: 4 * root.centerScale
        auraWidth: 0
        auraStrength: 0
        lineH: 1.0

        TextMetrics {
            id: hourMetrics

            text: hours.text
            font: hours.font
        }
    }

    GradientText {
        id: minutes

        anchors.right: parent.right
        y: -root.calcTopOff(minuteMetrics)

        text: Time.minuteStr
        font: Tokens.font.headline.builders.large.scale((GlobalConfig.services.useTwelveHourClock ? 3.8 : 7) * root.centerScale).width(30).build()
        fill: root.minuteFill
        strokeColor: root.minuteStroke
        outlineWidth: 4 * root.centerScale
        auraWidth: 0
        auraStrength: 0
        lineH: 1.0

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
