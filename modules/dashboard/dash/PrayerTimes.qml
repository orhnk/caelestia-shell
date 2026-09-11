import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    readonly property list<color> nameColors: [Accents.base08, Accents.base09, Accents.base0A, Accents.base0B, Accents.base0C]

    implicitWidth: layout.implicitWidth + Tokens.padding.large * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    Component.onCompleted: Salat.reload()

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Salat.nextIndex >= 0 ? `${Salat.label(Salat.prayers[Salat.nextIndex]?.name ?? "")} · ${Tr.tr("in %1").arg(Salat.nextIn)}` : Tr.tr("Prayer times")
            color: Accents.base0D
            font: Tokens.font.title.small
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: text.length > 0
            text: Salat.hijri
            color: Colours.pick(Colours.palette.m3base04, Colours.palette.m3onSurfaceVariant)
            font: Tokens.font.body.small
            elide: Text.ElideRight
        }

        Repeater {
            model: Salat.prayers

            RowLayout {
                id: row

                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: Tokens.spacing.medium
                opacity: modelData.passed && index !== Salat.nextIndex ? 0.45 : 1

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Salat.label(modelData.name)
                    color: root.nameColors[index] ?? Accents.base05
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    text: modelData.display
                    color: index === Salat.nextIndex ? Accents.base0D : Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface)
                    font: Tokens.font.body.medium
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Remind before")
                color: Colours.pick(Colours.palette.m3base04, Colours.palette.m3onSurfaceVariant)
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledSpinBox {
                from: 0
                to: 60
                stepSize: 1
                value: Salat.reminderMins
                onValueModified: Salat.reminderMins = Math.round(value)
            }

            StyledText {
                text: Tr.tr("min")
                color: Colours.pick(Colours.palette.m3base04, Colours.palette.m3onSurfaceVariant)
                font: Tokens.font.body.small
            }
        }
    }
}
