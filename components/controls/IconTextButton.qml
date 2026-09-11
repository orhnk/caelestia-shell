import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ButtonBase {
    id: root

    property alias icon: iconLabel.text
    property alias text: label.text
    property alias spacing: row.spacing

    readonly property alias iconLabel: iconLabel
    readonly property alias label: label

    horizontalPadding: Tokens.padding.medium
    verticalPadding: Tokens.padding.small

    activeColour: type === TextButton.Filled ? Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary) : Colours.pick(Colours.palette.m3base0C, Colours.palette.m3secondary)
    inactiveColour: {
        if (!isToggle && type === TextButton.Filled)
            return Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary);
        return type === TextButton.Filled ? Colours.pick(Colours.tPalette.m3base02, Colours.tPalette.m3surfaceContainer) : Colours.pick(Colours.palette.m3base02, Colours.palette.m3secondaryContainer);
    }
    activeOnColour: {
        if (type === TextButton.Text)
            return Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary);
        return type === TextButton.Filled ? Colours.pick(Colours.palette.m3base00, Colours.palette.m3onPrimary) : Colours.pick(Colours.palette.m3base00, Colours.palette.m3onSecondary);
    }
    inactiveOnColour: {
        if (!isToggle && type === TextButton.Filled)
            return Colours.pick(Colours.palette.m3base00, Colours.palette.m3onPrimary);
        if (type === TextButton.Text)
            return Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary);
        return type === TextButton.Filled ? Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface) : Colours.pick(Colours.palette.m3base0C, Colours.palette.m3onSecondaryContainer);
    }

    implicitWidth: row.implicitWidth + horizontalPadding * 2
    implicitHeight: row.implicitHeight + verticalPadding * 2

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        MaterialIcon {
            id: iconLabel

            Layout.alignment: Qt.AlignVCenter
            color: root.onColour
            fill: root.internalChecked ? 1 : 0
            fontStyle: {
                const f = Qt.font(root.font);
                f.pointSize = Math.round(root.font.pointSize * 1.2);
                return f;
            }

            Behavior on fill {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        StyledText {
            id: label

            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: 1
            color: root.onColour
            font: root.font
        }
    }
}
