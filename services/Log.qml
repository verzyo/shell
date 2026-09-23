pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    enum Level {
        Debug,
        Info,
        Warn,
        Error,
        Fatal
    }

    readonly property int level: _parseLevel(Quickshell.env("SHELL_LOG_LEVEL") || (Quickshell.env("SHELL_DEBUG") === "1" ? "debug" : "info"))
    readonly property bool useColor: !Quickshell.env("NO_COLOR") && Quickshell.env("SHELL_LOG_NO_COLOR") !== "1"

    function scoped(tag: string): var {
        return {
            debug: function (...args) {
                root._emit(Log.Level.Debug, tag, args);
            },
            info: function (...args) {
                root._emit(Log.Level.Info, tag, args);
            },
            warn: function (...args) {
                root._emit(Log.Level.Warn, tag, args);
            },
            error: function (...args) {
                root._emit(Log.Level.Error, tag, args);
            },
            fatal: function (...args) {
                root._emit(Log.Level.Fatal, tag, args);
            }
        };
    }

    function debug(...args): void {
        _emit(Log.Level.Debug, "", args);
    }

    function info(...args): void {
        _emit(Log.Level.Info, "", args);
    }

    function warn(...args): void {
        _emit(Log.Level.Warn, "", args);
    }

    function error(...args): void {
        _emit(Log.Level.Error, "", args);
    }

    function fatal(...args): void {
        _emit(Log.Level.Fatal, "", args);
    }

    function _parseLevel(name: string): int {
        switch ((name || "").toLowerCase()) {
        case "debug":
        case "trace":
            return Log.Level.Debug;
        case "warn":
        case "warning":
            return Log.Level.Warn;
        case "error":
            return Log.Level.Error;
        case "fatal":
            return Log.Level.Fatal;
        case "info":
        default:
            return Log.Level.Info;
        }
    }

    function _stringify(v: var): string {
        if (v === null)
            return "null";
        if (v === undefined)
            return "undefined";
        if (typeof v === "string")
            return v;
        if (v instanceof Error)
            return v.stack ? v.stack : v.toString();
        try {
            return JSON.stringify(v);
        } catch (_) {
            return String(v);
        }
    }

    function _levelBadge(lvl: int): string {
        if (!root.useColor) {
            switch (lvl) {
            case Log.Level.Debug:
                return "[DEBUG]";
            case Log.Level.Info:
                return "[INFO]";
            case Log.Level.Warn:
                return "[WARN]";
            case Log.Level.Error:
                return "[ERROR]";
            case Log.Level.Fatal:
                return "[FATAL]";
            default:
                return "[INFO]";
            }
        }

        switch (lvl) {
        case Log.Level.Debug:
            return "\x1b[34m[DEBUG]\x1b[0m";
        case Log.Level.Info:
            return "\x1b[32m[INFO]\x1b[0m";
        case Log.Level.Warn:
            return "\x1b[33m[WARN]\x1b[0m";
        case Log.Level.Error:
            return "\x1b[91m[ERROR]\x1b[0m";
        case Log.Level.Fatal:
            return "\x1b[1;31m[FATAL]\x1b[0m";
        default:
            return "\x1b[32m[INFO]\x1b[0m";
        }
    }

    function _tagBadge(tag: string): string {
        if (!tag)
            return "";
        if (!root.useColor)
            return `[${tag}]`;
        return `\x1b[36m[${tag}]\x1b[0m`;
    }

    function _emit(lvl: int, tag: string, args: var): void {
        if (lvl < root.level)
            return;

        const badge = _levelBadge(lvl);
        const tagFormatted = _tagBadge(tag);
        const msg = args.map(_stringify).join(" ");

        let prefix = badge;
        if (tagFormatted !== "") {
            prefix += " " + tagFormatted;
        }

        const formattedLine = prefix + " " + msg;

        switch (lvl) {
        case Log.Level.Debug:
            console.debug(formattedLine);
            break;
        case Log.Level.Info:
            console.info(formattedLine);
            break;
        case Log.Level.Warn:
            console.warn(formattedLine);
            break;
        case Log.Level.Error:
        case Log.Level.Fatal:
            console.error(formattedLine);
            break;
        }

        if (lvl === Log.Level.Fatal) {
            Qt.callLater(() => Qt.exit(1));
        }
    }
}
