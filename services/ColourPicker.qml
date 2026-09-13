pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.I18n
import qs.services

Singleton {
    id: root

    function pick(): void {
        if (!pickProc.running)
            pickProc.running = true;
    }

    Process {
        id: pickProc

        command: ["hyprpicker", "-a", "-f", "hex"]
        stdout: StdioCollector {
            onStreamFinished: {
                const hex = text.trim();
                if (/^#[0-9a-fA-F]{6}$/.test(hex)) {
                    Quickshell.clipboardText = hex;
                    Toaster.toast(Tr.tr("Color copied"), hex, "colorize");
                }
            }
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.colourpicker"
        defaultLogLevel: LoggingCategory.Info
    }
}
