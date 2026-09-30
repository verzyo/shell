pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.common
import qs.components
import qs.services

Scope {
    id: root

    readonly property var log: Log.scoped("Bar")

    property int barWidth: 40

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            readonly property int hugWidth: Math.max(Corners.sizeFor(0), Corners.sizeFor(3))

            WlrLayershell.namespace: "bar"
            WlrLayershell.layer: WlrLayer.Top
            exclusionMode: ExclusionMode.Auto
            exclusiveZone: root.barWidth

            anchors {
                top: true
                bottom: true
                left: true
            }

            implicitWidth: root.barWidth + hugWidth
            color: "transparent"

            mask: Region {
                item: barBody
            }

            Rectangle {
                id: barBody

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }

                implicitWidth: root.barWidth
                color: Appearance.colors.colLayer0
            }

            Item {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: barBody.right
                }

                implicitWidth: hugWidth

                RoundCorner {
                    anchors.top: parent.top
                    implicitSize: Corners.sizeFor(0)
                    color: Appearance.colors.colLayer0
                    corner: RoundCorner.Corner.TopLeft
                }

                RoundCorner {
                    anchors.bottom: parent.bottom
                    implicitSize: Corners.sizeFor(3)
                    color: Appearance.colors.colLayer0
                    corner: RoundCorner.Corner.BottomLeft
                }
            }
        }
    }
}
