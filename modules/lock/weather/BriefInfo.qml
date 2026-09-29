import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property int rootHeight

    spacing: Tokens.spacing.extraSmall

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: Weather.description
        color: Accents.ink(4, 0.4)
        font: Tokens.font.body.large
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.medium

        StyledText {
            id: temp

            animate: true
            text: Weather.temp
            color: Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary)
            font: Tokens.font.headline.builders.large.scale(1.5).weight(Font.DemiBold).width(80).build()
        }

        MaterialIcon {
            animate: true
            text: Weather.icon
            color: Colours.pick(Colours.palette.m3base0C, Colours.palette.m3secondary)
            fontStyle: Tokens.font.headline.builders.large.scale(1.5).build()
        }
    }

    StyledText {
        visible: root.rootHeight > Tokens.sizes.lock.showWeatherDetailsHeight
        Layout.alignment: Qt.AlignHCenter
        animate: true
        // TRANSLATORS: %1 = apparent temperature, unit already included
        text: Tr.tr("Feels like %1").arg(Weather.temp)
        color: Accents.ink(4, 0.4)
        font: Tokens.font.body.large
    }

    StyledText {
        visible: root.rootHeight > Tokens.sizes.lock.showWeatherDetailsHeight
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: {
            const today = Weather.forecast[0];
            // TRANSLATORS: %1/%2 = today's max and min temperature, units already included
            return Tr.tr("High %1 • Low %2").arg(Weather.formatTemp(today?.maxTempC)).arg(Weather.formatTemp(today?.minTempC));
        }
        color: Accents.ink(4, 0.4)
        font: Tokens.font.body.medium
    }
}
