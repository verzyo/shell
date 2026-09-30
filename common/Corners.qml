pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.services

Singleton {
    id: root

    property real t: 2. / 3.

    readonly property real gaps: {
        const n = Number(NiriService.config?.layout?.gaps);
        return isFinite(n) ? Math.max(0, n) : 0;
    }

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

    function sizeFor(i: int): int {
        return Math.round(radii[i] + t * gaps);
    }
}
