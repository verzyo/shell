pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.components
import qs.services
import "../utils/KdlParser.js" as KdlParser

Singleton {
    id: root

    readonly property var log: Log.scoped("NiriService")
    readonly property string socketPath: Quickshell.env("NIRI_SOCKET") || ""
    readonly property string configPath: Quickshell.env("XDG_CONFIG_HOME") ? (Quickshell.env("XDG_CONFIG_HOME") + "/niri/config.kdl") : (Quickshell.env("HOME") + "/.config/niri/config.kdl")
    readonly property string cacheDir: Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")
    readonly property string cachedConfigPath: cacheDir + "/shell/niri_config.json"

    property var config: ({})
    property bool overviewOpened: false

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.cacheDir + "/shell"]);
        root.reloadConfig();

        query("OverviewState", res => {
            if (!res || !res.Ok)
                return;
            const state = res.Ok.OverviewState;
            root.overviewOpened = typeof state === "boolean" ? state : (state?.is_open ?? false);
            root.log.debug("Initial overview state loaded:", root.overviewOpened);
        });
    }

    FileView {
        id: cachedConfigFile
        path: root.cachedConfigPath
        atomicWrites: true
        printErrors: false
    }

    FileView {
        id: configFileView
        path: root.configPath
        watchChanges: true
        printErrors: false

        onFileChanged: {
            configFileView.reload();
        }

        onTextChanged: {
            root.reloadConfig();
        }
    }

    IpcHandler {
        target: "niri"

        function config(): string {
            return JSON.stringify(root.config, null, 2);
        }

        function reload(): string {
            root.reloadConfig();
            return "Niri config reloaded";
        }
    }

    function reloadConfig(): void {
        const text = configFileView.text();
        if (!text || text.trim() === "")
            return;

        try {
            root.config = KdlParser.parse(text, root.configPath);
            root.saveConfig();
            root.log.info("Niri config successfully parsed");
        } catch (e) {
            root.log.error("Failed to parse Niri KDL config:", e);
        }
    }

    function saveConfig(): void {
        try {
            cachedConfigFile.setText(JSON.stringify(root.config, null, 2));
            root.log.debug("Saved parsed Niri config to:", root.cachedConfigPath);
        } catch (e) {
            root.log.error("Failed to save parsed Niri config to cache:", e);
        }
    }

    ReconnectSocket {
        id: eventStreamSocket
        path: root.socketPath
        connected: root.socketPath !== ""

        onConnectionStateChanged: {
            if (linkUp) {
                send('"EventStream"');
            }
        }

        parser: SplitParser {
            onRead: line => {
                if (!line || line.trim() === "")
                    return;

                try {
                    const event = JSON.parse(line);
                    if (event.ConfigLoaded) {
                        if (!event.ConfigLoaded.failed) {
                            root.log.info("Niri reported config reloaded; refreshing config object");
                            root.reloadConfig();
                        } else {
                            root.log.warn("Niri reported config error; skipping reload");
                        }
                    } else if (event.OverviewOpenedOrClosed) {
                        root.overviewOpened = !!event.OverviewOpenedOrClosed.is_open;
                        root.log.debug("Overview state changed via event:", root.overviewOpened);
                    }
                } catch (e) {
                    root.log.error("Failed to parse Niri IPC event:", e);
                }
            }
        }
    }

    function query(requestPayload: var, callback: var): void {
        if (!root.socketPath) {
            root.log.warn("NIRI_SOCKET environment variable not set; cannot query Niri");
            if (callback)
                callback(null);
            return;
        }

        const sock = socketComponent.createObject(root, {
            "requestPayload": requestPayload,
            "callback": callback
        });

        if (sock) {
            sock.connected = true;
        } else {
            root.log.error("Failed to create socket object for Niri query");
            if (callback)
                callback(null);
        }
    }

    Component {
        id: socketComponent

        ReconnectSocket {
            id: socket
            path: root.socketPath

            property var requestPayload: null
            property var callback: null

            onConnectionStateChanged: {
                if (linkUp) {
                    let json = "";
                    if (typeof requestPayload === "string") {
                        json = requestPayload.startsWith('"') ? requestPayload : JSON.stringify(requestPayload);
                    } else {
                        json = JSON.stringify(requestPayload);
                    }

                    socket.send(json);
                }
            }

            parser: SplitParser {
                onRead: line => {
                    if (!line || line.trim() === "")
                        return;

                    try {
                        const parsed = JSON.parse(line);
                        root.log.debug("Niri query response:", JSON.stringify(parsed));
                        if (socket.callback) {
                            socket.callback(parsed);
                        }
                    } catch (e) {
                        root.log.error("Failed to parse Niri response:", e, "raw line:", line);
                        if (socket.callback) {
                            socket.callback(null);
                        }
                    } finally {
                        socket.connected = false;
                        socket.destroy();
                    }
                }
            }
        }
    }
}
