pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var log: Log.scoped("WallpaperService")
    readonly property string cacheDir: Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")
    readonly property string stateFilePath: cacheDir + "/shell/state.json"

    property string currentWallpaper: ""
    property bool _selfWrite: false

    readonly property var supportedExtensions: [".jpg", ".jpeg", ".png", ".webp", ".avif", ".bmp", ".svg"]

    function setWallpaper(path: string): string {
        if (!path || path.trim() === "") {
            root.log.warn("Empty path passed to setWallpaper");
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

        if (!cleanPath.startsWith("/")) {
            root.log.warn("Rejected invalid/relative wallpaper path:", path);
            return "Error: Path must be absolute or start with ~/ (e.g. ~/Pictures/wall.jpg, /path/to/wall.png)";
        }

        const lower = cleanPath.toLowerCase();
        if (!root.supportedExtensions.some(ext => lower.endsWith(ext))) {
            root.log.warn("Rejected unsupported wallpaper format:", path);
            return "Error: Unsupported format. Supported: jpg, jpeg, png, webp, avif, bmp, svg";
        }

        root.currentWallpaper = cleanPath;
        root.log.info("Wallpaper updated to:", cleanPath);
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

            if (state.wallpaper === root.currentWallpaper) {
                return;
            }

            state.wallpaper = root.currentWallpaper;
            root._selfWrite = true;
            stateFile.setText(JSON.stringify(state, null, 2));
            root.log.debug("State saved to:", root.stateFilePath);
        } catch (e) {
            root.log.error("Failed to save state:", e);
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
            if (root._selfWrite) {
                root._selfWrite = false;
                return;
            }
            stateFile.reload();
        }

        onLoaded: {
            try {
                const content = stateFile.text();
                if (content && content.trim() !== "") {
                    const data = JSON.parse(content);
                    if (data.wallpaper && typeof data.wallpaper === "string" && data.wallpaper.startsWith("/")) {
                        root.currentWallpaper = data.wallpaper;
                        root.log.info("Restored wallpaper from state:", root.currentWallpaper);
                    } else if (data.wallpaper) {
                        root.log.warn("Ignoring invalid wallpaper path in state.json:", data.wallpaper);
                    }
                }
            } catch (e) {
                root.log.error("Failed to parse state.json:", e);
            }
        }

        onLoadFailed: error => {
            root.log.debug("State file not found on initial load; waiting for initial wallpaper configuration");
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
