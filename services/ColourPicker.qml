pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.I18n
import qs.services

Singleton {
    id: root

    property bool probed: false
    property bool hasHyprpicker: false
    property bool hasFallback: false
    property bool pendingPick: false

    function pick(): void {
        if (pickProc.running || slurpProc.running || grimProc.running)
            return;
        if (!root.probed) {
            if (!probeProc.running) {
                root.pendingPick = true;
                probeProc.running = true;
            }
            return;
        }
        root.startPick();
    }

    function startPick(): void {
        if (root.hasHyprpicker)
            pickProc.running = true;
        else if (root.hasFallback)
            slurpProc.running = true;
        else
            Toaster.toast(Tr.tr("Color picker unavailable"), Tr.tr("Install hyprpicker, or grim, slurp and python3"), "colorize");
    }

    function finish(hex: string): void {
        if (/^#[0-9a-fA-F]{6}$/.test(hex)) {
            Quickshell.clipboardText = hex;
            Toaster.toast(Tr.tr("Color copied"), hex, "colorize");
        }
    }

    Process {
        id: probeProc

        command: ["sh", "-c", "for b in hyprpicker slurp grim python3; do command -v $b >/dev/null && echo $b; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const have = new Set(text.trim().split("\n").filter(s => s !== ""));
                root.hasHyprpicker = have.has("hyprpicker");
                root.hasFallback = have.has("slurp") && have.has("grim") && have.has("python3");
                root.probed = true;
                if (root.pendingPick) {
                    root.pendingPick = false;
                    root.startPick();
                }
            }
        }
    }

    Process {
        id: pickProc

        command: ["hyprpicker", "-a", "-f", "hex"]
        stdout: StdioCollector {
            onStreamFinished: root.finish(text.trim())
        }
    }

    Process {
        id: slurpProc

        command: ["slurp", "-p", "-f", "%x,%y"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.trim().match(/^(-?\d+),(-?\d+)$/);
                if (m)
                    grimProc.startFor(m[1], m[2]);
            }
        }
    }

    Process {
        id: grimProc

        stdout: StdioCollector {
            onStreamFinished: root.finish(text.trim())
        }

        function startFor(x: string, y: string): void {
            // x/y come from slurp's own %x,%y format and are digits-only (see regex above).
            command = ["sh", "-c", `grim -g '${x},${y} 1x1' -t png - 2>/dev/null | python3 '${Quickshell.shellDir}/assets/pick-pixel.py'`];
            running = true;
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.colourpicker"
        defaultLogLevel: LoggingCategory.Info
    }
}
