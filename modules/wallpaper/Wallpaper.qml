import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.common
import qs.services

PanelWindow {
    id: root

    readonly property var log: Log.scoped("Wallpaper")

    WlrLayershell.namespace: "wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    property bool entranceDone: false
    property bool isHandingOff: false

    function formatUrl(path: string): string {
        if (!path || path === "")
            return "";
        return path.startsWith("file://") ? path : "file://" + path;
    }

    function loadWallpaper(path: string): void {
        const url = formatUrl(path);
        if (url === "")
            return;

        if (!root.entranceDone) {
            currentWallpaper.source = url;
            return;
        }

        if (currentWallpaper.source.toString() === url)
            return;

        nextWallpaper.source = url;
    }

    Connections {
        target: WallpaperService

        function onCurrentWallpaperChanged() {
            root.loadWallpaper(WallpaperService.currentWallpaper);
        }
    }

    Component.onCompleted: {
        if (WallpaperService.currentWallpaper !== "") {
            root.loadWallpaper(WallpaperService.currentWallpaper);
        }
    }

    Image {
        id: currentWallpaper
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        retainWhileLoading: true
        cache: true
        smooth: true

        sourceSize.width: root.width > 0 ? Math.round(root.width * Screen.devicePixelRatio) : 0
        sourceSize.height: root.height > 0 ? Math.round(root.height * Screen.devicePixelRatio) : 0

        opacity: 0.0
        scale: 1.05
        transformOrigin: Item.Center

        ParallelAnimation {
            id: entranceAnimation

            NumberAnimation {
                target: currentWallpaper
                property: "opacity"
                to: 1.0
                duration: Appearance.animationCurves.expressiveSlowSpatialDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }

            NumberAnimation {
                target: currentWallpaper
                property: "scale"
                to: 1.0
                duration: Appearance.animationCurves.expressiveSlowSpatialDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }
        }

        onStatusChanged: {
            if (status === Image.Ready) {
                if (root.isHandingOff) {
                    root.isHandingOff = false;
                    nextWallpaper.visible = false;
                    nextWallpaper.source = "";
                    WallpaperService.saveState();
                } else if (!root.entranceDone) {
                    root.entranceDone = true;
                    entranceAnimation.start();
                    WallpaperService.saveState();
                } else {
                    opacity = 1.0;
                    scale = 1.0;
                }
            } else if (status === Image.Error) {
                root.log.warn("Failed to load current wallpaper:", source);
            }
        }

        Component.onCompleted: {
            if (status === Image.Ready && !root.entranceDone) {
                root.entranceDone = true;
                entranceAnimation.start();
            }
        }
    }

    Image {
        id: nextWallpaper
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        retainWhileLoading: true
        cache: true
        smooth: true
        visible: false

        sourceSize.width: root.width > 0 ? Math.round(root.width * Screen.devicePixelRatio) : 0
        sourceSize.height: root.height > 0 ? Math.round(root.height * Screen.devicePixelRatio) : 0

        onStatusChanged: {
            if (status === Image.Ready) {
                visible = true;
                root.isHandingOff = true;
                currentWallpaper.source = source;
                if (currentWallpaper.status === Image.Ready) {
                    root.isHandingOff = false;
                    nextWallpaper.visible = false;
                    nextWallpaper.source = "";
                    WallpaperService.saveState();
                }
            } else if (status === Image.Error) {
                root.log.warn("Failed to load next wallpaper:", source);
                source = "";
                visible = false;
                root.isHandingOff = false;
            }
        }
    }
}
