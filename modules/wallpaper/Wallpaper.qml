import QtQuick
import Quickshell
import Quickshell.Wayland

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

        onStatusChanged: {
            if (status === Image.Error) {
                root.log.warn("Failed to load wallpaper image:", source);
            }
        }
    }
}
