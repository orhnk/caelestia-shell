import "dash"
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.services

GridLayout {
    id: root

    required property ScreenState screenState
    required property FileDialog facePicker

    rowSpacing: Tokens.spacing.medium
    columnSpacing: Tokens.spacing.medium

    Rect {
        Layout.column: 2
        Layout.columnSpan: 3
        Layout.preferredWidth: Tokens.sizes.dashboard.userWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.extraLarge

        User {
            id: user

            screenState: root.screenState
            facePicker: root.facePicker
        }
    }

    Rect {
        Layout.row: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: Tokens.sizes.dashboard.weatherWidth
        Layout.preferredHeight: weather.implicitHeight

        radius: Tokens.rounding.extraLarge * 1.5

        SmallWeather {
            id: weather
        }
    }

    Rect {
        Layout.row: 1
        Layout.preferredWidth: Math.max(countdown.implicitWidth, prayerTimes.implicitWidth)
        Layout.fillHeight: true
        implicitHeight: clockColumn.implicitHeight + Tokens.padding.small * 2

        radius: Tokens.rounding.large

        ColumnLayout {
            id: clockColumn

            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            spacing: Tokens.spacing.small

            PrayerTimes {
                id: prayerTimes

                Layout.fillWidth: true
                Layout.preferredHeight: prayerTimes.implicitHeight
            }

            DateTime {
                id: countdown

                Layout.fillWidth: true
                Layout.fillHeight: true
                hour: Salat.nextNow || Salat.nextIndex < 0 ? Time.hourStr : String(Salat.nextHours)
                minute: Salat.nextNow || Salat.nextIndex < 0 ? Time.minuteStr : String(Salat.nextMins).padStart(2, "0")
            }
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 1
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.preferredHeight: calendar.implicitHeight

        radius: Tokens.rounding.extraLarge

        Calendar {
            id: calendar

            screenState: root.screenState
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 4
        Layout.preferredWidth: resources.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.large

        Resources {
            id: resources
        }
    }

    Rect {
        Layout.row: 0
        Layout.column: 5
        Layout.rowSpan: 2
        Layout.preferredWidth: media.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.extraLarge * 2

        Media {
            id: media
        }
    }

    component Rect: StyledRect {
        color: Colours.pick(Colours.tPalette.m3base02, Colours.tPalette.m3surfaceContainer)
    }
}
