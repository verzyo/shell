pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string cacheDir: Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")
    readonly property string stateFilePath: cacheDir + "/shell/state.json"

    property string currentWallpaper: ""

    function setWallpaper(path: string): string {
        if (!path || path.trim() === "") {
            return "Error: No path provided";
        }

        let cleanPath = path.trim();
        if (cleanPath.startsWith("file://")) {
            cleanPath = cleanPath.substring(7);
        }
        if (cleanPath.startsWith("~/")) {
            cleanPath = Quickshell.env("HOME") + cleanPath.substring(1);
        } else if (cleanPath === "~") {
            cleanPath = Quickshell.env("HOME");
        }

        root.currentWallpaper = cleanPath;
        root.saveState();
        return "Wallpaper set to: " + cleanPath;
    }

    function saveState(): void {
        try {
            let state = {};
            let raw = "";
            try {
                raw = stateFile.text();
            } catch (_) {}
            if (raw && raw.trim() !== "") {
                try {
                    state = JSON.parse(raw);
                } catch (_) {
                    state = {};
                }
            }
            state.wallpaper = root.currentWallpaper;
            stateFile.setText(JSON.stringify(state, null, 2));
        } catch (e) {
            console.error("[WallpaperService] Failed to save state:", e);
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.cacheDir + "/shell"]);
    }

    FileView {
        id: stateFile
        path: root.stateFilePath
        watchChanges: true
        atomicWrites: true
        printErrors: false

        onFileChanged: {
            stateFile.reload();
        }

        onLoaded: {
            try {
                const content = stateFile.text();
                if (content && content.trim() !== "") {
                    const data = JSON.parse(content);
                    if (data.wallpaper && typeof data.wallpaper === "string") {
                        root.currentWallpaper = data.wallpaper;
                    }
                }
            } catch (e) {
                console.error("[WallpaperService] Failed to parse state.json:", e);
            }
        }

        onLoadFailed: error => {
        // First run or missing state file: silently wait until first wallpaper is set
        }
    }

    IpcHandler {
        target: "wallpaper"

        function set(path: string): string {
            return root.setWallpaper(path);
        }

        function get(): string {
            return root.currentWallpaper;
        }
    }
}
