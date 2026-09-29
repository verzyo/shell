pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.common
import qs.services

Singleton {
    id: root

    readonly property var log: Log.scoped("SessionService")

    property bool isExiting: false
    property string targetAction: ""
    property bool skipBeat1: false

    signal startTransition(string action, bool skipBeat1)

    IpcHandler {
        target: "action"

        function shutdown(): string {
            return root.requestAction("shutdown");
        }

        function reboot(): string {
            return root.requestAction("reboot");
        }

        function logout(): string {
            return root.requestAction("logout");
        }
    }

    function requestAction(action: string): string {
        if (action !== "shutdown" && action !== "reboot" && action !== "logout") {
            return "Unknown action: " + action + " (supported: shutdown, reboot, logout)";
        }

        if (root.isExiting) {
            return "Session transition already active for action: " + root.targetAction;
        }

        root.targetAction = action;
        root.log.info("Session action requested:", action, "overviewOpened:", NiriService.overviewOpened);

        const queryPayload = NiriService.overviewOpened ? "Windows" : "FocusedWindow";
        NiriService.query(queryPayload, res => {
            const hasWindows = NiriService.overviewOpened ? (Array.isArray(res?.Ok?.Windows) && res.Ok.Windows.length > 0) : (res?.Ok?.FocusedWindow != null);
            root._beginTransition(action, !hasWindows);
        });

        return "Initiating " + action + " transition...";
    }

    function _beginTransition(action: string, skipBeat1: bool): void {
        root.skipBeat1 = skipBeat1;
        root.isExiting = true;
        root.log.info("Beginning transition for:", action, "skipBeat1 (empty workspace):", skipBeat1);
        root.startTransition(action, skipBeat1);
    }

    function finalizeAction(): void {
        root.log.info("Transition reached 100% black; executing action:", root.targetAction);

        switch (root.targetAction) {
        case "shutdown":
            Quickshell.execDetached(["systemctl", "poweroff"]);
            break;
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"]);
            break;
        case "logout":
            Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"]);
            break;
        default:
            root.log.warn("Unrecognized action in finalizeAction:", root.targetAction);
            root.isExiting = false;
            break;
        }
    }
}
