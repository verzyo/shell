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

    Image {
        id: wallpaperImage
        anchors.fill: parent

        source: WallpaperService.currentWallpaper !== "" ? (WallpaperService.currentWallpaper.startsWith("file://") ? WallpaperService.currentWallpaper : "file://" + WallpaperService.currentWallpaper) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
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
                target: wallpaperImage
                property: "opacity"
                to: 1.0
                duration: Appearance.animationCurves.expressiveSlowSpatialDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }

            NumberAnimation {
                target: wallpaperImage
                property: "scale"
                to: 1.0
                duration: Appearance.animationCurves.expressiveSlowSpatialDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }
        }

        onStatusChanged: {
            if (status === Image.Ready) {
                WallpaperService.saveState();
                if (!root.entranceDone) {
                    root.entranceDone = true;
                    entranceAnimation.start();
                } else {
                    opacity = 1.0;
                    scale = 1.0;
                }
            } else if (status === Image.Error) {
                root.log.warn("Failed to load wallpaper image:", source);
            }
        }

        Component.onCompleted: {
            if (status === Image.Ready && !root.entranceDone) {
                root.entranceDone = true;
                entranceAnimation.start();
            }
        }
    }
}
