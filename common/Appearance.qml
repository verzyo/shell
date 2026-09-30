pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.common
import qs.services

Singleton {
    id: root

    readonly property var log: Log.scoped("Appearance")
    readonly property string themeCachePath: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell/theme.json"

    property real backgroundTransparency: 0.0
    property real contentTransparency: 0.9
    property bool skipTransition: true

    // ==========================================
    // M3 Colors (Base Palette Roles)
    // ==========================================
    property QtObject m3colors: QtObject {
        property bool darkmode: true
        property bool transparent: false

        property color m3background: "#141313"
        property color m3onBackground: "#e6e1e1"
        property color m3surface: "#141313"
        property color m3surfaceDim: "#141313"
        property color m3surfaceBright: "#3a3939"
        property color m3surfaceContainerLowest: "#0f0e0e"
        property color m3surfaceContainerLow: "#1c1b1c"
        property color m3surfaceContainer: "#201f20"
        property color m3surfaceContainerHigh: "#2b2a2a"
        property color m3surfaceContainerHighest: "#363435"
        property color m3onSurface: "#e6e1e1"
        property color m3surfaceVariant: "#49464a"
        property color m3onSurfaceVariant: "#cbc5ca"
        property color m3inverseSurface: "#e6e1e1"
        property color m3inverseOnSurface: "#313030"
        property color m3outline: "#948f94"
        property color m3outlineVariant: "#49464a"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#cbc4cb"
        property color m3primary: "#cbc4cb"
        property color m3onPrimary: "#322f34"
        property color m3primaryContainer: "#2d2a2f"
        property color m3onPrimaryContainer: "#bcb6bc"
        property color m3inversePrimary: "#615d63"
        property color m3secondary: "#cac5c8"
        property color m3onSecondary: "#323032"
        property color m3secondaryContainer: "#4d4b4d"
        property color m3onSecondaryContainer: "#ece6e9"
        property color m3tertiary: "#d1c3c6"
        property color m3onTertiary: "#372e30"
        property color m3tertiaryContainer: "#31292b"
        property color m3onTertiaryContainer: "#c1b4b7"
        property color m3error: "#ffb4ab"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000a"
        property color m3onErrorContainer: "#ffdad6"
        property color m3primaryFixed: "#e7e0e7"
        property color m3primaryFixedDim: "#cbc4cb"
        property color m3onPrimaryFixed: "#1d1b1f"
        property color m3onPrimaryFixedVariant: "#49454b"
        property color m3secondaryFixed: "#e6e1e4"
        property color m3secondaryFixedDim: "#cac5c8"
        property color m3onSecondaryFixed: "#1d1b1d"
        property color m3onSecondaryFixedVariant: "#484648"
        property color m3tertiaryFixed: "#eddfe1"
        property color m3tertiaryFixedDim: "#d1c3c6"
        property color m3onTertiaryFixed: "#211a1c"
        property color m3onTertiaryFixedVariant: "#4e4447"
        property color m3success: "#b5ccba"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374b3e"
        property color m3onSuccessContainer: "#d1e9d6"
    }

    // ==========================================
    // Interactive Layered Colors (Surface + States)
    // ==========================================
    property QtObject colors: QtObject {
        property color colSubtext: m3colors.m3outline

        // Layer 0: Desktop base directly above wallpaper
        property color colLayer0Base: ColorUtils.mix(m3colors.m3background, m3colors.m3primary, 1.0)
        property color colLayer0: ColorUtils.transparentize(colLayer0Base, root.backgroundTransparency)
        property color colOnLayer0: m3colors.m3onBackground
        property color colLayer0Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer0, colOnLayer0, 0.9), root.contentTransparency)
        property color colLayer0Active: ColorUtils.transparentize(ColorUtils.mix(colLayer0, colOnLayer0, 0.8), root.contentTransparency)
        property color colLayer0Border: ColorUtils.mix(m3colors.m3outlineVariant, colLayer0, 0.4)

        // Layer 1: Structural panels (Bar, Dock)
        property color colLayer1Base: m3colors.m3surfaceContainerLow
        property color colLayer1: ColorUtils.solveOverlayColor(colLayer0Base, colLayer1Base, 1.0 - root.contentTransparency)
        property color colOnLayer1: m3colors.m3onSurfaceVariant
        property color colOnLayer1Inactive: ColorUtils.mix(colOnLayer1, colLayer1, 0.45)
        property color colLayer1Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.92), root.contentTransparency)
        property color colLayer1Active: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.85), root.contentTransparency)

        // Layer 2: Interactive pills & widgets
        property color colLayer2Base: m3colors.m3surfaceContainer
        property color colLayer2: ColorUtils.solveOverlayColor(colLayer1Base, colLayer2Base, 1.0 - root.contentTransparency)
        property color colLayer2Hover: ColorUtils.solveOverlayColor(colLayer1Base, ColorUtils.mix(colLayer2Base, colOnLayer2, 0.90), 1.0 - root.contentTransparency)
        property color colLayer2Active: ColorUtils.solveOverlayColor(colLayer1Base, ColorUtils.mix(colLayer2Base, colOnLayer2, 0.80), 1.0 - root.contentTransparency)
        property color colLayer2Disabled: ColorUtils.solveOverlayColor(colLayer1Base, ColorUtils.mix(colLayer2Base, m3colors.m3background, 0.80), 1.0 - root.contentTransparency)
        property color colOnLayer2: m3colors.m3onSurface
        property color colOnLayer2Disabled: ColorUtils.mix(colOnLayer2, m3colors.m3background, 0.40)

        // Layer 3: Elevated cards & popups
        property color colLayer3Base: m3colors.m3surfaceContainerHigh
        property color colLayer3: ColorUtils.solveOverlayColor(colLayer2Base, colLayer3Base, 1.0 - root.contentTransparency)
        property color colLayer3Hover: ColorUtils.solveOverlayColor(colLayer2Base, ColorUtils.mix(colLayer3Base, colOnLayer3, 0.90), 1.0 - root.contentTransparency)
        property color colLayer3Active: ColorUtils.solveOverlayColor(colLayer2Base, ColorUtils.mix(colLayer3Base, colOnLayer3, 0.80), 1.0 - root.contentTransparency)
        property color colOnLayer3: m3colors.m3onSurface

        // Layer 4: Highest elevation dialogs & modals
        property color colLayer4Base: m3colors.m3surfaceContainerHighest
        property color colLayer4: ColorUtils.solveOverlayColor(colLayer3Base, colLayer4Base, 1.0 - root.contentTransparency)
        property color colLayer4Hover: ColorUtils.solveOverlayColor(colLayer3Base, ColorUtils.mix(colLayer4Base, colOnLayer4, 0.90), 1.0 - root.contentTransparency)
        property color colLayer4Active: ColorUtils.solveOverlayColor(colLayer3Base, ColorUtils.mix(colLayer4Base, colOnLayer4, 0.80), 1.0 - root.contentTransparency)
        property color colOnLayer4: m3colors.m3onSurface

        // Primary Accents
        property color colPrimary: m3colors.m3primary
        property color colOnPrimary: m3colors.m3onPrimary
        property color colPrimaryHover: ColorUtils.mix(colPrimary, colLayer1Hover, 0.87)
        property color colPrimaryActive: ColorUtils.mix(colPrimary, colLayer1Active, 0.70)
        property color colPrimaryContainer: m3colors.m3primaryContainer
        property color colPrimaryContainerHover: ColorUtils.mix(colPrimaryContainer, colOnPrimaryContainer, 0.90)
        property color colPrimaryContainerActive: ColorUtils.mix(colPrimaryContainer, colOnPrimaryContainer, 0.80)
        property color colOnPrimaryContainer: m3colors.m3onPrimaryContainer

        // Secondary Accents
        property color colSecondary: m3colors.m3secondary
        property color colSecondaryHover: ColorUtils.mix(colSecondary, colLayer1Hover, 0.85)
        property color colSecondaryActive: ColorUtils.mix(colSecondary, colLayer1Active, 0.40)
        property color colOnSecondary: m3colors.m3onSecondary
        property color colSecondaryContainer: m3colors.m3secondaryContainer
        property color colSecondaryContainerHover: ColorUtils.mix(colSecondaryContainer, colOnSecondaryContainer, 0.90)
        property color colSecondaryContainerActive: ColorUtils.mix(colSecondaryContainer, colOnSecondaryContainer, 0.54)
        property color colOnSecondaryContainer: m3colors.m3onSecondaryContainer

        // Tertiary Accents
        property color colTertiary: m3colors.m3tertiary
        property color colTertiaryHover: ColorUtils.mix(colTertiary, colLayer1Hover, 0.85)
        property color colTertiaryActive: ColorUtils.mix(colTertiary, colLayer1Active, 0.40)
        property color colOnTertiary: m3colors.m3onTertiary
        property color colTertiaryContainer: m3colors.m3tertiaryContainer
        property color colTertiaryContainerHover: ColorUtils.mix(colTertiaryContainer, colOnTertiaryContainer, 0.90)
        property color colTertiaryContainerActive: ColorUtils.mix(colTertiaryContainer, colLayer1Active, 0.54)
        property color colOnTertiaryContainer: m3colors.m3onTertiaryContainer

        // Direct Surface Mappings
        property color colBackgroundSurfaceContainer: ColorUtils.transparentize(m3colors.m3surfaceContainer, root.backgroundTransparency)
        property color colSurfaceContainerLow: ColorUtils.solveOverlayColor(m3colors.m3background, m3colors.m3surfaceContainerLow, 1.0 - root.contentTransparency)
        property color colSurfaceContainer: ColorUtils.solveOverlayColor(m3colors.m3surfaceContainerLow, m3colors.m3surfaceContainer, 1.0 - root.contentTransparency)
        property color colSurfaceContainerHigh: ColorUtils.solveOverlayColor(m3colors.m3surfaceContainer, m3colors.m3surfaceContainerHigh, 1.0 - root.contentTransparency)
        property color colSurfaceContainerHighest: ColorUtils.solveOverlayColor(m3colors.m3surfaceContainerHigh, m3colors.m3surfaceContainerHighest, 1.0 - root.contentTransparency)
        property color colSurfaceContainerHighestHover: ColorUtils.mix(m3colors.m3surfaceContainerHighest, m3colors.m3onSurface, 0.95)
        property color colSurfaceContainerHighestActive: ColorUtils.mix(m3colors.m3surfaceContainerHighest, m3colors.m3onSurface, 0.85)
        property color colOnSurface: m3colors.m3onSurface
        property color colOnSurfaceVariant: m3colors.m3onSurfaceVariant

        // Scrim, Shadow & Outline
        property color colTooltip: m3colors.m3inverseSurface
        property color colOnTooltip: m3colors.m3inverseOnSurface
        property color colScrim: ColorUtils.transparentize(m3colors.m3scrim, 0.5)
        property color colShadow: ColorUtils.transparentize(m3colors.m3shadow, 0.7)
        property color colOutline: m3colors.m3outline
        property color colOutlineVariant: m3colors.m3outlineVariant

        // Error Feedback
        property color colError: m3colors.m3error
        property color colErrorHover: ColorUtils.mix(m3colors.m3error, colLayer1Hover, 0.85)
        property color colErrorActive: ColorUtils.mix(m3colors.m3error, colLayer1Active, 0.70)
        property color colOnError: m3colors.m3onError
        property color colErrorContainer: m3colors.m3errorContainer
        property color colErrorContainerHover: ColorUtils.mix(m3colors.m3errorContainer, m3colors.m3onErrorContainer, 0.90)
        property color colErrorContainerActive: ColorUtils.mix(m3colors.m3errorContainer, m3colors.m3onErrorContainer, 0.70)
        property color colOnErrorContainer: m3colors.m3onErrorContainer
    }

    // ==========================================
    // Semantic Rounding Tokens (end4 Organic Radii)
    // ==========================================
    property QtObject rounding: QtObject {
        property int unsharpen: 2
        property int unsharpenmore: 6
        property int verysmall: 8
        property int small: 12
        property int normal: 17
        property int large: 23
        property int verylarge: 30
        property int full: 9999
        property int screenRounding: large
        property int windowRounding: 18
    }

    // ==========================================
    // Typography Scale & Fonts
    // ==========================================
    property QtObject font: QtObject {
        property QtObject family: QtObject {
            property string main: "Roboto Flex"
            property string numbers: "Roboto Flex"
            property string title: "Roboto Flex"
            property string iconMaterial: "Material Symbols Rounded"
            property string iconNerd: "Symbols Nerd Font"
            property string monospace: "monospace"
            property string reading: "Roboto Flex"
            property string expressive: "Roboto Flex"
        }

        property QtObject variableAxes: QtObject {
            property var main: ({
                    "wght": 450,
                    "wdth": 100
                })
            property var numbers: ({
                    "wght": 450
                })
            property var title: ({
                    "wght": 550
                })
        }

        property QtObject pixelSize: QtObject {
            property int smallest: 10
            property int smaller: 12
            property int smallie: 13
            property int small: 15
            property int normal: 16
            property int large: 17
            property int larger: 19
            property int huge: 22
            property int hugeass: 23
            property int title: huge
        }
    }

    // ==========================================
    // Animation Curves & Tokens (end4 M3 Expressive)
    // ==========================================
    property QtObject animationCurves: QtObject {
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1] // 350ms
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1] // 500ms
        readonly property list<real> expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1] // 650ms
        readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1] // 200ms

        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedFirstHalf: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82]
        readonly property list<real> emphasizedLastHalf: [5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]

        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]

        readonly property real expressiveFastSpatialDuration: 350
        readonly property real expressiveDefaultSpatialDuration: 500
        readonly property real expressiveSlowSpatialDuration: 650
        readonly property real expressiveEffectsDuration: 200
    }

    // ==========================================
    // Pre-built Reusable Animation Components
    // ==========================================
    property QtObject animation: QtObject {
        property QtObject elementMove: QtObject {
            property int duration: animationCurves.expressiveDefaultSpatialDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveDefaultSpatial
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMove.duration
                    easing.type: root.animation.elementMove.type
                    easing.bezierCurve: root.animation.elementMove.bezierCurve
                }
            }
        }

        property QtObject elementMoveSmall: QtObject {
            property int duration: animationCurves.expressiveFastSpatialDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveFastSpatial
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveSmall.duration
                    easing.type: root.animation.elementMoveSmall.type
                    easing.bezierCurve: root.animation.elementMoveSmall.bezierCurve
                }
            }
        }

        property QtObject elementMoveEnter: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedDecel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveEnter.duration
                    easing.type: root.animation.elementMoveEnter.type
                    easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        property QtObject elementMoveExit: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedAccel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveExit.duration
                    easing.type: root.animation.elementMoveExit.type
                    easing.bezierCurve: root.animation.elementMoveExit.bezierCurve
                }
            }
        }

        property QtObject elementMoveFast: QtObject {
            property int duration: animationCurves.expressiveEffectsDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveEffects
            property int velocity: 850
            property Component colorAnimation: Component {
                ColorAnimation {
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
                }
            }
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
                }
            }
        }

        property QtObject elementResize: QtObject {
            property int duration: 300
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.standard
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementResize.duration
                    easing.type: root.animation.elementResize.type
                    easing.bezierCurve: root.animation.elementResize.bezierCurve
                }
            }
        }
    }

    // ==========================================
    // Dynamic Theme Ingestion & Persistence
    // ==========================================
    FileView {
        id: themeFileView
        path: root.themeCachePath
        watchChanges: true
        printErrors: false

        onFileChanged: {
            themeFileView.reload();
        }

        onTextChanged: {
            root.applyTheme(themeFileView.text());
        }

        onLoadFailed: error => {
            root.log.debug("No cached theme.json found on startup; using default Material 3 palette");
        }
    }

    Component.onCompleted: {
        root.applyTheme(themeFileView.text());
        root.skipTransition = false;
    }

    function applyTheme(fileContent: string): void {
        if (!fileContent || typeof fileContent !== "string" || fileContent.trim() === "") {
            return;
        }

        try {
            const parsed = JSON.parse(fileContent);

            // 1. Nested Matugen format (e.g. from `matugen -j hex`)
            if (parsed.colors) {
                const isDark = parsed.is_dark_mode !== undefined ? parsed.is_dark_mode : true;
                const modeKey = isDark ? "dark" : "light";

                for (const key in parsed.colors) {
                    const entry = parsed.colors[key];
                    const hex = (entry[modeKey] && entry[modeKey].color) || (entry.default && entry.default.color);
                    if (hex) {
                        const camelCaseKey = key.replace(/_([a-z])/g, g => g[1].toUpperCase());
                        const m3Key = `m3${camelCaseKey}`;
                        if (root.m3colors.hasOwnProperty(m3Key)) {
                            root.m3colors[m3Key] = hex;
                        }
                    }
                }
            }

            // 2. Flat JSON format (e.g. from template or direct map)
            for (const key in parsed) {
                if (typeof parsed[key] === "string" && parsed[key].startsWith("#")) {
                    const camelCaseKey = key.replace(/_([a-z])/g, g => g[1].toUpperCase());
                    const m3Key = `m3${camelCaseKey}`;
                    if (root.m3colors.hasOwnProperty(m3Key)) {
                        root.m3colors[m3Key] = parsed[key];
                    }
                }
            }

            root.m3colors.darkmode = (root.m3colors.m3background.hslLightness < 0.5);
            root.log.info("Material 3 palette applied from theme.json");
        } catch (err) {
            root.log.error("Failed to parse theme.json:", err);
        }
    }
}
