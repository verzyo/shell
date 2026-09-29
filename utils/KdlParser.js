.pragma library

function parse(text, basePath) {
    if (!text || typeof text !== "string") {
        return {};
    }
    const nodes = parseDocument(text, basePath || "", new Set());
    return flattenAst(nodes);
}

function readLocalFile(filePath) {
    try {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + filePath, false);
        xhr.send();
        if (xhr.status === 200 || xhr.status === 0) {
            return xhr.responseText;
        }
    } catch (_) {}
    return null;
}

function resolveIncludePath(target, base) {
    let clean = target.trim();
    if (clean.startsWith("file://")) {
        clean = clean.substring(7);
    }
    if (clean.startsWith("~/")) {
        const home = typeof Quickshell !== "undefined" ? Quickshell.env("HOME") : "";
        return (home || "") + clean.substring(1);
    }
    if (clean.startsWith("/")) {
        return clean;
    }
    const idx = base.lastIndexOf("/");
    const dir = idx >= 0 ? base.substring(0, idx) : "";
    return dir ? (dir + "/" + clean) : clean;
}

function parseDocument(text, currentPath, visitedPaths) {
    const nodes = [];
    const len = text.length;
    let i = 0;

    function skipWhitespace(allowNewline) {
        while (i < len) {
            const ch = text[i];
            if (ch === " " || ch === "\t" || ch === "\r") {
                i++;
                continue;
            }
            if (ch === "\\" && text[i + 1] === "\n") {
                i += 2;
                continue;
            }
            if (ch === "\\" && text[i + 1] === "\r" && text[i + 2] === "\n") {
                i += 3;
                continue;
            }
            if (ch === "/" && text[i + 1] === "/") {
                i += 2;
                while (i < len && text[i] !== "\n") {
                    i++;
                }
                continue;
            }
            if (ch === "/" && text[i + 1] === "*") {
                i += 2;
                let depth = 1;
                while (i < len && depth > 0) {
                    if (text[i] === "/" && text[i + 1] === "*") {
                        depth++;
                        i += 2;
                    } else if (text[i] === "*" && text[i + 1] === "/") {
                        depth--;
                        i += 2;
                    } else {
                        i++;
                    }
                }
                continue;
            }
            if (allowNewline && ch === "\n") {
                i++;
                continue;
            }
            break;
        }
    }

    function parseQuotedString() {
        i++;
        let res = "";
        while (i < len) {
            const ch = text[i];
            if (ch === "\\") {
                i++;
                if (i >= len) break;
                const esc = text[i];
                if (esc === "n") res += "\n";
                else if (esc === "r") res += "\r";
                else if (esc === "t") res += "\t";
                else if (esc === "\\") res += "\\";
                else if (esc === "\"") res += "\"";
                else if (esc === "/") res += "/";
                else if (esc === "b") res += "\b";
                else if (esc === "f") res += "\f";
                else if (esc === "u") {
                    if (text[i + 1] === "{") {
                        i += 2;
                        let hex = "";
                        while (i < len && text[i] !== "}") {
                            hex += text[i];
                            i++;
                        }
                        if (hex) {
                            try {
                                res += String.fromCodePoint(parseInt(hex, 16));
                            } catch (_) {}
                        }
                    } else {
                        const hex = text.substring(i + 1, i + 5);
                        i += 4;
                        try {
                            res += String.fromCharCode(parseInt(hex, 16));
                        } catch (_) {}
                    }
                } else {
                    res += esc;
                }
            } else if (ch === "\"") {
                i++;
                return res;
            } else {
                res += ch;
            }
            i++;
        }
        return res;
    }

    function parseRawString() {
        i++;
        let hashes = 0;
        while (i < len && text[i] === "#") {
            hashes++;
            i++;
        }
        if (i >= len || text[i] !== "\"") {
            return "";
        }
        i++;
        let start = i;
        const endPattern = "\"" + "#".repeat(hashes);
        const idx = text.indexOf(endPattern, start);
        if (idx === -1) {
            i = len;
            return text.substring(start);
        }
        const res = text.substring(start, idx);
        i = idx + endPattern.length;
        return res;
    }

    function isBareChar(ch) {
        if (ch <= " " || ch === "﻿") return false;
        if (ch === "\\" || ch === "/" || ch === "(" || ch === ")" ||
            ch === "{" || ch === "}" || ch === ";" || ch === "[" ||
            ch === "]" || ch === "=" || ch === "\"") {
            return false;
        }
        return true;
    }

    function coerceValue(raw) {
        if (raw === "true") return true;
        if (raw === "false") return false;
        if (raw === "null") return null;

        if (/^0x[0-9a-fA-F]+$/.test(raw)) {
            return parseInt(raw, 16);
        }
        if (/^0o[0-7]+$/.test(raw)) {
            return parseInt(raw.substring(2), 8);
        }
        if (/^0b[01]+$/.test(raw)) {
            return parseInt(raw.substring(2), 2);
        }
        if (/^[+-]?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?$/.test(raw)) {
            const num = Number(raw);
            if (!isNaN(num)) {
                return num;
            }
        }
        return raw;
    }

    function parseValueOrIdent() {
        if (i >= len) return null;
        if (text[i] === "\"") {
            return { "val": parseQuotedString(), "isString": true };
        }
        if (text[i] === "r" && (text[i + 1] === "\"" || text[i + 1] === "#")) {
            return { "val": parseRawString(), "isString": true };
        }
        let start = i;
        while (i < len && isBareChar(text[i])) {
            i++;
        }
        const raw = text.substring(start, i);
        return { "val": coerceValue(raw), "isString": false, "raw": raw };
    }

    function parseChildrenBlock() {
        i++;
        const blockNodes = [];
        while (i < len) {
            skipWhitespace(true);
            if (i >= len || text[i] === "}") {
                if (text[i] === "}") i++;
                break;
            }
            const childNode = parseNode();
            if (childNode) {
                blockNodes.push(childNode);
            }
        }
        return blockNodes;
    }

    function parseNode() {
        let skipThisNode = false;
        if (text[i] === "/" && text[i + 1] === "-") {
            skipThisNode = true;
            i += 2;
            skipWhitespace(false);
        }

        if (text[i] === "(") {
            while (i < len && text[i] !== ")") i++;
            if (text[i] === ")") i++;
            skipWhitespace(false);
        }

        const nameEntry = parseValueOrIdent();
        if (!nameEntry || nameEntry.val === null || nameEntry.val === undefined) {
            return null;
        }

        const name = String(nameEntry.val);
        const args = [];
        const props = {};
        let children = null;

        while (i < len) {
            skipWhitespace(false);
            if (i >= len) break;

            const ch = text[i];
            if (ch === "\n" || ch === ";") {
                i++;
                break;
            }
            if (ch === "}") {
                break;
            }

            let skipItem = false;
            if (ch === "/" && text[i + 1] === "-") {
                skipItem = true;
                i += 2;
                skipWhitespace(false);
            }

            if (text[i] === "(") {
                while (i < len && text[i] !== ")") i++;
                if (text[i] === ")") i++;
                skipWhitespace(false);
            }

            if (text[i] === "{") {
                const parsedChildren = parseChildrenBlock();
                if (!skipItem) {
                    children = parsedChildren;
                }
                break;
            }

            const item = parseValueOrIdent();
            if (!item) break;

            if (i < len && text[i] === "=") {
                i++;
                skipWhitespace(false);
                const propValEntry = parseValueOrIdent();
                const propVal = propValEntry ? propValEntry.val : null;
                if (!skipItem && !skipThisNode) {
                    props[String(item.val)] = propVal;
                }
            } else {
                if (!skipItem && !skipThisNode) {
                    args.push(item.val);
                }
            }
        }

        if (skipThisNode) {
            return null;
        }

        if (name === "include" && args.length > 0 && typeof args[0] === "string") {
            const resolved = resolveIncludePath(args[0], currentPath);
            if (resolved && !visitedPaths.has(resolved)) {
                visitedPaths.add(resolved);
                const incContent = readLocalFile(resolved);
                if (incContent) {
                    const incNodes = parseDocument(incContent, resolved, visitedPaths);
                    return { "__include": true, "nodes": incNodes };
                }
            }
            return null;
        }

        return {
            "name": name,
            "args": args,
            "props": props,
            "children": children
        };
    }

    while (i < len) {
        skipWhitespace(true);
        if (i >= len) break;
        const node = parseNode();
        if (node) {
            if (node.__include && Array.isArray(node.nodes)) {
                for (let k = 0; k < node.nodes.length; k++) {
                    nodes.push(node.nodes[k]);
                }
            } else {
                nodes.push(node);
            }
        }
    }

    return nodes;
}

function flattenAst(nodes) {
    const result = {};

    for (let i = 0; i < nodes.length; i++) {
        const node = nodes[i];
        const name = node.name;
        const args = node.args;
        const props = node.props;
        const children = node.children;

        let value;
        if (children && children.length > 0) {
            value = flattenAst(children);
            if (props && Object.keys(props).length > 0) {
                for (const propKey in props) {
                    if (value[propKey] === undefined) {
                        value[propKey] = props[propKey];
                    }
                }
            }
        } else if (args && args.length > 0) {
            value = args.length === 1 ? args[0] : args;
        } else if (props && Object.keys(props).length > 0) {
            value = props;
        } else {
            value = true;
        }

        if (children && children.length > 0 && args && args.length === 1 && typeof args[0] === "string") {
            if (!(name in result) || typeof result[name] !== "object" || Array.isArray(result[name])) {
                result[name] = {};
            }
            result[name][args[0]] = value;
        } else {
            if (name in result) {
                if (!Array.isArray(result[name])) {
                    result[name] = [result[name]];
                }
                result[name].push(value);
            } else {
                result[name] = value;
            }
        }
    }

    return result;
}
