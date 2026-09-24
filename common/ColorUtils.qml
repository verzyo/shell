pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    function colorWithHueOf(color1: var, color2: var): color {
        const c1 = Qt.color(color1);
        const c2 = Qt.color(color2);
        return Qt.hsva(c2.hsvHue, c1.hsvSaturation, c1.hsvValue, c1.a);
    }

    function colorWithSaturationOf(color1: var, color2: var): color {
        const c1 = Qt.color(color1);
        const c2 = Qt.color(color2);
        return Qt.hsva(c1.hsvHue, c2.hsvSaturation, c1.hsvValue, c1.a);
    }

    function colorWithLightness(color: var, lightness: real): color {
        const c = Qt.color(color);
        return Qt.hsla(c.hslHue, c.hslSaturation, lightness, c.a);
    }

    function colorWithLightnessOf(color1: var, color2: var): color {
        const c2 = Qt.color(color2);
        return colorWithLightness(color1, c2.hslLightness);
    }

    function adaptToAccent(color1: var, color2: var): color {
        const c1 = Qt.color(color1);
        const c2 = Qt.color(color2);
        return Qt.hsla(c2.hslHue, c2.hslSaturation, c1.hslLightness, c1.a);
    }

    function mix(color1: var, color2: var, percentage: real): color {
        const p = percentage !== undefined ? percentage : 0.5;
        const c1 = Qt.color(color1);
        const c2 = Qt.color(color2);
        return Qt.rgba(p * c1.r + (1.0 - p) * c2.r, p * c1.g + (1.0 - p) * c2.g, p * c1.b + (1.0 - p) * c2.b, p * c1.a + (1.0 - p) * c2.a);
    }

    function transparentize(color: var, percentage: real): color {
        const p = percentage !== undefined ? percentage : 1.0;
        const c = Qt.color(color);
        return Qt.rgba(c.r, c.g, c.b, c.a * (1.0 - p));
    }

    function applyAlpha(color: var, alpha: real): color {
        const c = Qt.color(color);
        const a = Math.max(0.0, Math.min(1.0, alpha));
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function isDark(color: var): bool {
        const c = Qt.color(color);
        return c.hslLightness < 0.5;
    }

    function clamp01(x: real): real {
        return Math.min(1.0, Math.max(0.0, x));
    }

    function solveOverlayColor(baseColor: var, targetColor: var, overlayOpacity: real): color {
        if (overlayOpacity <= 0.0) {
            return Qt.rgba(0, 0, 0, 0);
        }
        if (overlayOpacity >= 1.0) {
            return Qt.color(targetColor);
        }

        const bc = Qt.color(baseColor);
        const tc = Qt.color(targetColor);
        const invA = 1.0 - overlayOpacity;

        const r = (tc.r - bc.r * invA) / overlayOpacity;
        const g = (tc.g - bc.g * invA) / overlayOpacity;
        const b = (tc.b - bc.b * invA) / overlayOpacity;

        return Qt.rgba(clamp01(r), clamp01(g), clamp01(b), overlayOpacity);
    }
}
