pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.components
import qs.services

Singleton {
    id: root

    readonly property var log: Log.scoped("NiriService")
    readonly property string socketPath: Quickshell.env("NIRI_SOCKET") || ""

    property bool overviewOpened: false

    Component.onCompleted: {
        query("OverviewState", res => {
            if (!res || !res.Ok)
                return;
            const state = res.Ok.OverviewState;
            root.overviewOpened = typeof state === "boolean" ? state : (state?.is_open ?? false);
            root.log.debug("Initial overview state loaded:", root.overviewOpened);
        });
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
                    if (event.OverviewOpenedOrClosed) {
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
