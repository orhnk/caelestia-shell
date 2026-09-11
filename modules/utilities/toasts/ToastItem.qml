import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.effects
import qs.services
import qs.utils

StyledRect {
    id: root

    required property Toast modelData

    readonly property bool isSalat: root.modelData.icon.startsWith("salat:")
    readonly property int salatIndex: isSalat ? Number(root.modelData.icon.slice(6)) : -1
    readonly property color salatColor: root.salatIndex >= 0 ? Accents.prayerColor(root.salatIndex) : Accents.base0D

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: layout.implicitHeight + Tokens.padding.large

    radius: Tokens.rounding.large
    color: {
        if (root.isSalat)
            return Accents.opaque(root.salatColor, 0.85);
        if (root.modelData.type === Toast.Success)
            return Colours.pick(Colours.palette.m3base02, Colours.palette.m3successContainer);
        if (root.modelData.type === Toast.Warning)
            return Colours.pick(Colours.palette.m3base0C, Colours.palette.m3secondary);
        if (root.modelData.type === Toast.Error)
            return Colours.pick(Colours.palette.m3base03, Colours.palette.m3errorContainer);
        return Colours.pick(Colours.palette.m3base00, Colours.palette.m3surface);
    }

    border.width: 1
    border.color: {
        if (root.isSalat)
            return root.salatColor;
        let colour = Colours.pick(Colours.palette.m3base02, Colours.palette.m3outlineVariant);
        if (root.modelData.type === Toast.Success)
            colour = Colours.pick(Colours.palette.m3base0B, Colours.palette.m3success);
        if (root.modelData.type === Toast.Warning)
            colour = Colours.pick(Colours.palette.m3base02, Colours.palette.m3secondaryContainer);
        if (root.modelData.type === Toast.Error)
            colour = Colours.pick(Colours.palette.m3base08, Colours.palette.m3error);
        return Qt.alpha(colour, 0.3);
    }

    Elevation {
        anchors.fill: parent
        radius: parent.radius
        opacity: parent.opacity
        z: -1
        level: 3
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        StyledRect {
            radius: Tokens.rounding.large
            color: {
                if (root.isSalat)
                    return root.salatColor;
                if (root.modelData.type === Toast.Success)
                    return Colours.pick(Colours.palette.m3base0B, Colours.palette.m3success);
                if (root.modelData.type === Toast.Warning)
                    return Colours.pick(Colours.palette.m3base02, Colours.palette.m3secondaryContainer);
                if (root.modelData.type === Toast.Error)
                    return Colours.pick(Colours.palette.m3base08, Colours.palette.m3error);
                return Colours.pick(Colours.palette.m3base03, Colours.palette.m3surfaceContainerHigh);
            }

            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + Tokens.padding.large

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: root.isSalat ? "mosque" : root.modelData.icon
                color: {
                    if (root.isSalat)
                        return Colours.on(root.salatColor);
                    if (root.modelData.type === Toast.Success)
                        return Colours.pick(Colours.palette.m3base00, Colours.palette.m3onSuccess);
                    if (root.modelData.type === Toast.Warning)
                        return Colours.pick(Colours.palette.m3base0C, Colours.palette.m3onSecondaryContainer);
                    if (root.modelData.type === Toast.Error)
                        return Colours.pick(Colours.palette.m3base00, Colours.palette.m3onError);
                    return Colours.pick(Colours.palette.m3base04, Colours.palette.m3onSurfaceVariant);
                }
                fontStyle: Tokens.font.icon.builders.large.scale(1.2).build()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: title

                Layout.fillWidth: true
                text: Tr.trMarked(root.modelData.title)
                color: {
                    if (root.isSalat)
                        return Colours.on(root.salatColor);
                    if (root.modelData.type === Toast.Success)
                        return Colours.pick(Colours.palette.m3base0B, Colours.palette.m3onSuccessContainer);
                    if (root.modelData.type === Toast.Warning)
                        return Colours.pick(Colours.palette.m3base00, Colours.palette.m3onSecondary);
                    if (root.modelData.type === Toast.Error)
                        return Colours.pick(Colours.palette.m3base08, Colours.palette.m3onErrorContainer);
                    return Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface);
                }
                font: Tokens.font.title.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                text: Tr.trMarked(root.modelData.message)
                color: {
                    if (root.isSalat)
                        return Colours.on(root.salatColor);
                    if (root.modelData.type === Toast.Success)
                        return Colours.pick(Colours.palette.m3base0B, Colours.palette.m3onSuccessContainer);
                    if (root.modelData.type === Toast.Warning)
                        return Colours.pick(Colours.palette.m3base00, Colours.palette.m3onSecondary);
                    if (root.modelData.type === Toast.Error)
                        return Colours.pick(Colours.palette.m3base08, Colours.palette.m3onErrorContainer);
                    return Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface);
                }
                opacity: 0.8
                elide: Text.ElideRight
            }
        }
    }

    Behavior on border.color {
        CAnim {}
    }
}
