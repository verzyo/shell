pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.common
import qs.services

PanelWindow {
    id: root

    readonly property var log: Log.scoped("SessionCurtain")

    WlrLayershell.namespace: "session-curtain"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: SessionService.isExiting

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
    }

    Rectangle {
        id: blackScrim
        anchors.fill: parent
        color: "#000000"
        opacity: 0.0
        z: 2
    }

    Image {
        id: overlayWallpaper
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        retainWhileLoading: true
        cache: true
        smooth: true

        source: {
            const wall = WallpaperService.currentWallpaper;
            if (!wall || wall === "")
                return "";
            return wall.startsWith("file://") ? wall : "file://" + wall;
        }

        sourceSize.width: (root.screen?.width ?? root.width) > 0 ? Math.round((root.screen?.width ?? root.width) * Screen.devicePixelRatio) : 0
        sourceSize.height: (root.screen?.height ?? root.height) > 0 ? Math.round((root.screen?.height ?? root.height) * Screen.devicePixelRatio) : 0

        opacity: 0.0
        scale: 1.0
        transformOrigin: Item.Center
        z: 1
    }

    SequentialAnimation {
        id: exitAnimation

        NumberAnimation {
            id: windowDissolveAnimation
            target: overlayWallpaper
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: Appearance.animationCurves.expressiveFastSpatialDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }

        ParallelAnimation {
            NumberAnimation {
                target: blackScrim
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 400
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
            }

            NumberAnimation {
                target: overlayWallpaper
                property: "scale"
                from: 1.0
                to: 0.98
                duration: 400
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
            }
        }

        ScriptAction {
            script: SessionService.finalizeAction()
        }
    }

    Connections {
        target: SessionService

        function onStartTransition(action, skipBeat1) {
            blackScrim.z = 2;
            overlayWallpaper.z = 1;
            overlayWallpaper.opacity = 0.0;
            overlayWallpaper.scale = 1.0;
            blackScrim.opacity = 0.0;

            windowDissolveAnimation.to = skipBeat1 ? 0.0 : 1.0;
            windowDissolveAnimation.duration = skipBeat1 ? 0 : Appearance.animationCurves.expressiveFastSpatialDuration;

            root.log.info("Running exit animation for:", action, "skipBeat1:", skipBeat1);
            exitAnimation.start();
        }
    }
}
