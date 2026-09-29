import "center"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property var lock
    readonly property real centerScale: Math.min(1, (lock.screen?.height ?? 1440) / 1440)
    readonly property int centerWidth: Tokens.sizes.lock.centerWidth * centerScale

    Layout.preferredWidth: centerWidth
    Layout.fillWidth: false
    Layout.fillHeight: true

    spacing: Tokens.spacing.largeIncreased

    Clock {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.padding.large
        centerScale: root.centerScale
    }

    // One pass over the base08-0F run, fading out at both ends, so the whole
    // spectrum is present without turning into a stripe: the clock's underline.
    StyledRect {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: -Tokens.spacing.medium

        implicitWidth: Math.round(root.centerWidth * 0.7)
        implicitHeight: Math.max(3, Math.round(4 * root.centerScale))
        radius: implicitHeight / 2

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0.0
                color: Qt.alpha(Accents.base08, 0)
            }
            GradientStop {
                position: 0.1
                color: Accents.base08
            }
            GradientStop {
                position: 0.2
                color: Accents.base09
            }
            GradientStop {
                position: 0.3
                color: Accents.base0A
            }
            GradientStop {
                position: 0.4
                color: Accents.base0B
            }
            GradientStop {
                position: 0.5
                color: Accents.base0C
            }
            GradientStop {
                position: 0.6
                color: Accents.base0D
            }
            GradientStop {
                position: 0.7
                color: Accents.base0E
            }
            GradientStop {
                position: 0.9
                color: Accents.base0F
            }
            GradientStop {
                position: 1.0
                color: Qt.alpha(Accents.base0F, 0)
            }
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter

        text: Time.format("dddd • d MMM").toUpperCase()
        color: Accents.ink(5, 0.3)
        font: Tokens.font.title.builders.medium.weight(Font.DemiBold).build()
    }

    ProfilePic {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.spacing.extraExtraLarge * root.centerScale
        Layout.bottomMargin: Tokens.spacing.extraLarge * root.centerScale
        centerWidth: root.centerWidth
    }

    PasswordInput {
        Layout.alignment: Qt.AlignHCenter
        centerScale: Math.max(0.8, root.centerScale)
        centerWidth: root.centerWidth
        lock: root.lock
    }

    StateMessage {
        Layout.fillWidth: true
        pam: root.lock.pam
    }
}
