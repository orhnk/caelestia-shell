import QtQuick
import Caelestia.Config
import qs.components
import qs.services

ButtonBase {
    id: root

    property alias icon: label.text
    readonly property alias label: label

    font: Tokens.font.icon.medium
    padding: type === IconButton.Text ? Tokens.padding.extraSmall / 2 : Tokens.padding.small

    activeColour: type === IconButton.Filled ? Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary) : Colours.pick(Colours.palette.m3base0C, Colours.palette.m3secondary)
    inactiveColour: {
        if (!isToggle && type === IconButton.Filled)
            return Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary);
        return type === IconButton.Filled ? Colours.pick(Colours.tPalette.m3base02, Colours.tPalette.m3surfaceContainer) : Colours.pick(Colours.palette.m3base02, Colours.palette.m3secondaryContainer);
    }
    activeOnColour: type === IconButton.Filled ? Colours.pick(Colours.palette.m3base00, Colours.palette.m3onPrimary) : type === IconButton.Tonal ? Colours.pick(Colours.palette.m3base00, Colours.palette.m3onSecondary) : Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary)
    inactiveOnColour: {
        if (!isToggle && type === IconButton.Filled)
            return Colours.pick(Colours.palette.m3base00, Colours.palette.m3onPrimary);
        return type === IconButton.Tonal ? Colours.pick(Colours.palette.m3base0C, Colours.palette.m3onSecondaryContainer) : Colours.pick(Colours.palette.m3base04, Colours.palette.m3onSurfaceVariant);
    }

    implicitWidth: implicitHeight
    implicitHeight: {
        // Ensure even size so icon is centered properly
        const h = label.implicitHeight + padding * 2;
        if (h % 2 !== 0)
            return h + 1;
        return h;
    }

    MaterialIcon {
        id: label

        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1 // AHHHHHHH material symbols whyyyy
        color: root.onColour
        fontStyle: root.font
        fill: !root.isToggle || root.internalChecked ? 1 : 0

        Behavior on fill {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
