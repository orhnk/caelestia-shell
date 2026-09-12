import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

StyledRect {
    id: root

    property string lastColor: ""
    property list<string> history

    function handlePicked(raw: string): void {
        const hex = raw.trim();
        if (!/^#[0-9a-fA-F]{6}$/.test(hex))
            return;

        lastColor = hex;
        Quickshell.clipboardText = hex;

        const next = [hex, ...history.filter(c => c.toLowerCase() !== hex.toLowerCase())];
        history = next.slice(0, 8);
        colorsStorage.setText(JSON.stringify(history));
    }

    function copyColor(hex: string): void {
        Quickshell.clipboardText = hex;
        Toaster.toast(Tr.tr("Color copied"), hex, "colorize");
    }

    radius: Tokens.rounding.large
    color: Colours.pick(Colours.tPalette.m3base02, Colours.tPalette.m3surfaceContainer)
    clip: true

    implicitHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    ColumnLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: pickIcon.implicitHeight + Tokens.padding.large

                radius: Tokens.rounding.full
                color: Accents.base0D

                MaterialIcon {
                    id: pickIcon

                    anchors.centerIn: parent
                    text: "colorize"
                    color: Colours.on(Accents.base0D)
                    fontStyle: Tokens.font.icon.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.trCtx("Color picker", "color picker card")
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.lastColor || Tr.tr("Pick any pixel on screen")
                    color: root.lastColor ? Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface) : Colours.pick(Colours.palette.m3base04, Colours.palette.m3onSurfaceVariant)
                    font: Tokens.font.mono.small
                    elide: Text.ElideRight
                }
            }

            IconButton {
                shapeMorph: true
                isRound: true
                icon: "pipette"
                inactiveColour: Accents.base0D
                inactiveOnColour: Colours.on(Accents.base0D)
                font: Tokens.font.icon.medium
                onClicked: pickProc.running = true
            }
        }

        RowLayout {
            visible: root.history.length > 0
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: root.history

                StyledRect {
                    required property string modelData
                    required property int index

                    implicitWidth: 28
                    implicitHeight: 28
                    radius: Tokens.rounding.small
                    color: modelData
                    border.width: 1
                    border.color: Qt.alpha(Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface), 0.2)

                    StateLayer {
                        radius: parent.radius
                        onClicked: root.copyColor(parent.modelData)
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }

    Process {
        id: pickProc

        command: ["hyprpicker", "-a", "-f", "hex"]
        stdout: StdioCollector {
            onStreamFinished: root.handlePicked(text)
        }
    }

    FileView {
        id: colorsStorage

        printErrors: false
        path: `${Paths.state}/colors.json`
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (Array.isArray(data)) {
                    const valid = data.filter(c => typeof c === "string" && /^#[0-9a-fA-F]{6}$/.test(c));
                    root.history = valid.slice(0, 8);
                    if (root.history.length > 0)
                        root.lastColor = root.history[0];
                }
            } catch (error) {
                console.warn(lc, `Unable to parse saved colors: ${error}`);
            }
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => setText("[]"));
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.utilities.colorpicker"
        defaultLogLevel: LoggingCategory.Info
    }
}
