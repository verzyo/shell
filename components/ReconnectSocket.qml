/*
MIT License

Copyright (c) 2025-2026 Avenge Media LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string path: ""
    property var parser: null
    property bool connected: false
    property bool linkUp: false

    property int reconnectBaseMs: 400
    property int reconnectMaxMs: 15000

    property int _reconnectAttempt: 0
    property var _socket: null

    signal connectionStateChanged

    onConnectedChanged: {
        if (connected) {
            _restartSocket();
        } else {
            _reconnectTimer.stop();
            _teardown();
        }
    }

    // Quickshell's Socket cannot redial after a failed attempt: its dead
    // QLocalSocket is only cleared when a *successful* connection closes, and
    // setting connected back to true is a no-op while the object exists. Every
    // attempt therefore gets a fresh Socket instance.
    function _restartSocket() {
        _teardown();
        _socket = _socketFactory.createObject(root);
        if (_socket) {
            _socket.connected = true;
        }
    }

    function _teardown() {
        if (_socket) {
            _socket.connected = false;
            _socket.destroy();
            _socket = null;
        }
        if (linkUp) {
            linkUp = false;
            connectionStateChanged();
        }
    }

    function send(data) {
        if (!_socket)
            return;
        const json = typeof data === "string" ? data : JSON.stringify(data);
        const message = json.endsWith("\n") ? json : json + "\n";
        _socket.write(message);
        _socket.flush();
    }

    function _scheduleReconnect() {
        const pow = Math.min(_reconnectAttempt, 10);
        const base = Math.min(reconnectBaseMs * Math.pow(2, pow), reconnectMaxMs);
        const jitter = Math.floor(Math.random() * Math.floor(base / 4));
        _reconnectTimer.interval = base + jitter;
        _reconnectTimer.restart();
        _reconnectAttempt++;
    }

    property Component _socketFactory: Component {
        Socket {
            path: root.path
            parser: root.parser

            onConnectionStateChanged: {
                root.linkUp = connected;
                root.connectionStateChanged();
                if (connected) {
                    root._reconnectAttempt = 0;
                    return;
                }
                if (root.connected)
                    root._scheduleReconnect();
            }

            // A failed dial emits only the error signal, never a connection
            // state transition, so the retry loop must also start from here.
            onError: err => {
                if (root.connected && !root.linkUp)
                    root._scheduleReconnect();
            }
        }
    }

    property Timer _reconnectTimer: Timer {
        repeat: false
        onTriggered: {
            if (root.connected && !root.linkUp)
                root._restartSocket();
        }
    }
}
