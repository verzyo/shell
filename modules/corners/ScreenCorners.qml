pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.components
import qs.services

Scope {
    id: root

    readonly property var log: Log.scoped("ScreenCorners")

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "screen-corners"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"

            mask: Region {}

            readonly property real gaps: {
                const n = Number(NiriService.config?.layout?.gaps);
                return isFinite(n) ? Math.max(0, n) : 0;
            }

            property real t: 2. / 3.

            readonly property list<real> radii: {
                const radii = [0, 0, 0, 0];
                const rules = NiriService.config?.["window-rule"];
                const list = Array.isArray(rules) ? rules : (rules ? [rules] : []);
                for (const rule of list) {
                    const v = rule?.["geometry-corner-radius"];
                    const vals = Array.isArray(v) ? v : (typeof v === "number" ? [v] : []);
                    for (let i = 0; i < 4; i++) {
                        const n = Number(vals.length === 1 ? vals[0] : vals[i]);
                        if (isFinite(n) && n > radii[i])
                            radii[i] = n;
                    }
                }
                return radii;
            }

            visible: radii[0] > 0 || radii[1] > 0 || radii[2] > 0 || radii[3] > 0

            RoundCorner {
                anchors {
                    top: parent.top
                    left: parent.left
                }

                visible: radii[0] > 0
                implicitSize: Math.round(radii[0] + t * gaps)
                color: "#000000"
                corner: RoundCorner.Corner.TopLeft
            }

            RoundCorner {
                anchors {
                    top: parent.top
                    right: parent.right
                }

                visible: radii[1] > 0
                implicitSize: Math.round(radii[1] + t * gaps)
                color: "#000000"
                corner: RoundCorner.Corner.TopRight
            }

            RoundCorner {
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                }

                visible: radii[2] > 0
                implicitSize: Math.round(radii[2] + t * gaps)
                color: "#000000"
                corner: RoundCorner.Corner.BottomRight
            }

            RoundCorner {
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                }

                visible: radii[3] > 0
                implicitSize: Math.round(radii[3] + t * gaps)
                color: "#000000"
                corner: RoundCorner.Corner.BottomLeft
            }
        }
    }
}
