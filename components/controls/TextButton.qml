import QtQuick
import Caelestia.Config
import qs.components
import qs.services

ButtonBase {
    id: root

    property alias text: label.text
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

    implicitWidth: label.implicitWidth + horizontalPadding * 2
    implicitHeight: label.implicitHeight + verticalPadding * 2

    StyledText {
        id: label

        anchors.centerIn: parent
        color: root.onColour
        font: root.font
    }
}
