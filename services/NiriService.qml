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
                        console.log("Niri response (" + JSON.stringify(socket.requestPayload) + "):", JSON.stringify(parsed));
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
