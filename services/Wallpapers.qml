pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    // A mistyped directory and a directory without images both give an empty
    // model but need different messages, so ask the filesystem. Starts true so
    // nothing claims a missing directory before the check has run.
    property bool dirExists: true

    function checkDir(): void {
        if (!Paths.wallsdir)
            return;
        dirCheckProc.command = ["sh", "-c", `test -d '${Paths.wallsdir}'`];
        dirCheckProc.running = true;
    }

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        // Pick from the recursive model so wallpapers in subdirs are included
        // (the cli picker only looks at the top level), and so a broken file can
        // never be picked: the model lists only the images Qt can actually read,
        // while the cli scans suffixes and then opens each candidate to size it.
        if (wallpapers.entries.length > 0) {
            const entry = wallpapers.entries[Math.floor(Math.random() * wallpapers.entries.length)];
            console.log(lc, `random pick ${entry.path} (${wallpapers.entries.length} candidates)`);
            setWallpaper(entry.path);
            return;
        }

        // Nothing to pick from. The cli would fail on the same directory, so say
        // what is wrong rather than doing nothing at all.
        if (!dirExists) {
            console.warn(lc, `random: no such wallpaper directory: ${Paths.wallsdir}`);
            Toaster.toast(Tr.tr("Wallpaper directory not found"), Tr.tr("Check paths.wallpaperDir in the caelestia config: %1").arg(Paths.shortenHome(Paths.wallsdir)), "folder_off");
            return;
        }

        // The directory exists, so the model may just still be scanning: keep the
        // cli picker as the fallback for that.
        console.warn(lc, `random: model empty, falling back to the cli picker (${Paths.wallsdir})`);
        Quickshell.execDetached(["caelestia", "wallpaper", "-r", ...smartArg]);
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        function random(): string {
            root.setRandom();
            return `random: ${root.actualCurrent}`;
        }

        target: "wallpaper"
    }

    Component.onCompleted: root.checkDir()

    Connections {
        target: Paths

        function onWallsdirChanged(): void {
            root.checkDir();
        }
    }

    // Checks whether the configured directory is there at all, and says so when
    // it is not: an empty switcher is otherwise indistinguishable from a path
    // that no longer exists (a renamed theme dir, a stale env var, a typo).
    Process {
        id: dirCheckProc

        onExited: code => { // qmllint disable signal-handler-parameters
            root.dirExists = code === 0;
            if (!root.dirExists)
                console.warn(lc, `wallpaper directory does not exist: ${Paths.wallsdir} - set paths.wallpaperDir in the caelestia config`);
        }
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
    }

    LoggingCategory {
        id: lc
        name: "caelestia.qml.services.wallpapers"
        defaultLogLevel: LoggingCategory.Info
    }

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }
}
