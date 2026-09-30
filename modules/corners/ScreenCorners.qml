pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.common
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

            visible: Corners.radii[0] > 0 || Corners.radii[1] > 0 || Corners.radii[2] > 0 || Corners.radii[3] > 0

            RoundCorner {
                anchors {
                    top: parent.top
                    left: parent.left
                }

                visible: Corners.radii[0] > 0
                implicitSize: Corners.sizeFor(0)
                color: "#000000"
                corner: RoundCorner.Corner.TopLeft
            }

            RoundCorner {
                anchors {
                    top: parent.top
                    right: parent.right
                }

                visible: Corners.radii[1] > 0
                implicitSize: Corners.sizeFor(1)
                color: "#000000"
                corner: RoundCorner.Corner.TopRight
            }

            RoundCorner {
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                }

                visible: Corners.radii[2] > 0
                implicitSize: Corners.sizeFor(2)
                color: "#000000"
                corner: RoundCorner.Corner.BottomRight
            }

            RoundCorner {
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                }

                visible: Corners.radii[3] > 0
                implicitSize: Corners.sizeFor(3)
                color: "#000000"
                corner: RoundCorner.Corner.BottomLeft
            }
        }
    }
}
