pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    property bool visible: false
    property string query: ""
    property int selectedIndex: 0
    property var fileResults: []
    property string mathResult: ""
    property bool menuMode: false
    property var menuPath: []

    property int _refreshToken: 0
    property int _usageToken: 0
    property var usage: ({})

    readonly property int maxResults: 20
    readonly property int maxRecent: 12
    readonly property string usagePath: Quickshell.env("HOME") + "/.local/state/ydot/launcher-usage.json"
    readonly property string homeDir: Quickshell.env("HOME")

    readonly property var parsed: {
        const raw = query;
        if (raw.length > 0) {
            const ch = raw[0];
            if (ch === "=")
                return { provider: "math", text: raw.slice(1).trim() };
            if (ch === ">")
                return { provider: "command", text: raw.slice(1).trim() };
            if (ch === "?")
                return { provider: "web", text: raw.slice(1).trim() };
            if (ch === ":")
                return { provider: "clipboard", text: raw.slice(1).trim() };
            if (ch === "/")
                return { provider: "files", text: raw.slice(1).trim() };
            if (ch === ";")
                return { provider: "actions", text: raw.slice(1).trim() };
        }
        return { provider: "apps", text: raw.trim() };
    }

    readonly property string provider: parsed.provider
    readonly property string providerLabel: {
        if (root.menuMode)
            return root.menuPath.length ? root.menuPath[root.menuPath.length - 1].name : "ydot"
        switch (provider) {
        case "math": return "Math";
        case "command": return "Run";
        case "web": return "Web";
        case "clipboard": return "Clip";
        case "files": return "Files";
        case "actions": return "Actions";
        default: return "";
        }
    }

    readonly property string placeholder: {
        if (root.menuMode)
            return "Search menu…"
        switch (provider) {
        case "math": return "Calculate…";
        case "command": return "Run command…";
        case "web": return "Search the web…";
        case "clipboard": return "Search clipboard…";
        case "files": return "Search files…";
        case "actions": return "Search actions…";
        default: return "Search apps…";
        }
    }

    function actionVerb(entry) {
        if (!entry)
            return "Open";
        switch (entry._type) {
        case "math":
        case "clipboard":
            return "Copy";
        case "command":
        case "action":
            return "Run";
        case "web":
            return "Search";
        case "file":
            return "Open";
        default:
            return "Open";
        }
    }

    function escapeHtml(text) {
        return String(text ?? "")
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;");
    }

    function colorHex(c) {
        const r = Math.round(c.r * 255).toString(16).padStart(2, "0");
        const g = Math.round(c.g * 255).toString(16).padStart(2, "0");
        const b = Math.round(c.b * 255).toString(16).padStart(2, "0");
        return "#" + r + g + b;
    }

    // Contiguous substring highlight; falls back to plain escaped text for fuzzy-only hits.
    function highlightedName(name, accent) {
        const n = name || "";
        const needle = (root.parsed.text || "").trim();
        if (!needle)
            return escapeHtml(n);

        const idx = n.toLowerCase().indexOf(needle.toLowerCase());
        if (idx < 0)
            return escapeHtml(n);

        const before = escapeHtml(n.slice(0, idx));
        const match = escapeHtml(n.slice(idx, idx + needle.length));
        const after = escapeHtml(n.slice(idx + needle.length));
        const hex = colorHex(accent);
        return before + "<b><font color=\"" + hex + "\">" + match + "</font></b>" + after;
    }

    readonly property var filteredApps: {
        void root._refreshToken;
        void root._usageToken;
        void root.fileResults;
        void root.mathResult;
        void ClipboardService.entries;

        if (root.menuMode)
            return root.menuResults(root.query);

        const provider = root.parsed.provider;
        const text = root.parsed.text;

        if (provider === "math")
            return root.mathResults(text);
        if (provider === "command")
            return root.commandResults(text);
        if (provider === "web")
            return root.webResults(text);
        if (provider === "clipboard")
            return root.clipboardResults(text);
        if (provider === "files")
            return root.fileResults;
        if (provider === "actions")
            return root.actionResults(text);

        return root.appResults(text);
    }

    Component.onCompleted: {
        loadUsage();
        ThemeService.refreshThemes();
    }

    // --- Apps + frecency ---------------------------------------------------

    function appResults(q) {
        if (q === "")
            return [];

        const apps = DesktopEntries.applications.values;
        const seen = new Set();
        const scored = [];

        for (const app of apps) {
            if (app.noDisplay)
                continue;

            const key = app.id || app.name;
            if (!key || seen.has(key))
                continue;
            seen.add(key);

            const fuzzy = root.scoreApp(app, q.toLowerCase());
            if (fuzzy < 0)
                continue;

            scored.push({
                app: app,
                score: root.combineScore(fuzzy, app, q.toLowerCase())
            });
        }

        scored.sort((a, b) => {
            if (b.score !== a.score)
                return b.score - a.score;
            return (a.app.name || "").localeCompare(b.app.name || "");
        });

        const results = scored.slice(0, root.maxResults).map(s => s.app);

        // Inline calculator for numeric queries
        if (/^[\d.(]/.test(q)) {
            const value = root.evalMath(q);
            if (value !== null)
                results.unshift(root.makeMathItem(value, q));
        }

        return results;
    }

    function recentApps() {
        const apps = DesktopEntries.applications.values;
        const byId = new Map();

        for (const app of apps) {
            if (app.noDisplay)
                continue;
            const key = app.id || app.name;
            if (key && !byId.has(key))
                byId.set(key, app);
        }

        const ranked = [];
        for (const id of Object.keys(root.usage)) {
            const app = byId.get(id);
            if (!app)
                continue;
            ranked.push({ app: app, score: frecencyScore(id) });
        }

        ranked.sort((a, b) => {
            if (b.score !== a.score)
                return b.score - a.score;
            const aLast = (root.usage[a.app.id || a.app.name] || {}).lastUsed || 0;
            const bLast = (root.usage[b.app.id || b.app.name] || {}).lastUsed || 0;
            return bLast - aLast;
        });

        return ranked.slice(0, root.maxRecent).map(s => s.app);
    }

    function fuzzyScore(text, query) {
        if (!query)
            return 0;
        if (!text)
            return -1;

        const idx = text.indexOf(query);
        if (idx === 0)
            return 1000 - Math.min(text.length, 200);
        if (idx > 0)
            return 750 - idx * 2 - Math.min(text.length, 200) * 0.1;

        let ti = 0;
        let score = 0;
        let consecutive = 0;
        let firstMatch = -1;

        for (let qi = 0; qi < query.length; qi++) {
            const qc = query[qi];
            let found = false;

            while (ti < text.length) {
                if (text[ti] === qc) {
                    if (firstMatch < 0)
                        firstMatch = ti;

                    consecutive++;
                    score += 10 + consecutive * 5;

                    if (ti === 0 || /[^a-z0-9]/.test(text[ti - 1]) || (text[ti - 1] !== text[ti - 1].toLowerCase() && text[ti] === text[ti].toLowerCase()))
                        score += 20;

                    ti++;
                    found = true;
                    break;
                }
                consecutive = 0;
                ti++;
            }

            if (!found)
                return -1;
        }

        score -= firstMatch * 2;
        score -= Math.max(0, text.length - query.length);
        return score;
    }

    function scoreApp(app, query) {
        const name = (app.name || "").toLowerCase();
        const generic = (app.genericName || "").toLowerCase();
        const comment = (app.comment || "").toLowerCase();
        const keywords = Array.from(app.keywords || []).join(" ").toLowerCase();

        let best = -1;

        const nameScore = fuzzyScore(name, query);
        if (nameScore >= 0)
            best = Math.max(best, nameScore + 100);

        const genericScore = fuzzyScore(generic, query);
        if (genericScore >= 0)
            best = Math.max(best, genericScore + 40);

        const commentScore = fuzzyScore(comment, query);
        if (commentScore >= 0)
            best = Math.max(best, commentScore + 20);

        const keywordScore = fuzzyScore(keywords, query);
        if (keywordScore >= 0)
            best = Math.max(best, keywordScore + 30);

        return best;
    }

    function frecencyScore(appId) {
        const u = root.usage[appId];
        if (!u || !u.count)
            return 0;

        const ageDays = (Date.now() - (u.lastUsed || 0)) / 86400000;
        let recency = 0.2;
        if (ageDays < 1)
            recency = 4;
        else if (ageDays < 7)
            recency = 2;
        else if (ageDays < 30)
            recency = 1;
        else if (ageDays < 90)
            recency = 0.5;

        return Math.log2(1 + u.count) * 50 * recency;
    }

    function combineScore(fuzzy, app, query) {
        const frec = frecencyScore(app.id || app.name);
        const name = (app.name || "").toLowerCase();

        if (name.startsWith(query))
            return fuzzy + frec * 0.15;

        const fuzzyWeight = Math.min(0.55 + query.length * 0.06, 0.9);
        return fuzzy * fuzzyWeight + frec * (1 - fuzzyWeight) * 2;
    }

    // --- Providers ---------------------------------------------------------

    function evalMath(expr) {
        const cleaned = (expr || "").trim();
        if (!cleaned || !/^[0-9+\-*/().%\s^eE]+$/.test(cleaned))
            return null;

        const safe = cleaned.replace(/\^/g, "**");
        try {
            const result = Function('"use strict"; return (' + safe + ')')();
            if (typeof result !== "number" || !isFinite(result))
                return null;
            // Trim floating junk: 0.1+0.2
            const rounded = Math.round(result * 1e12) / 1e12;
            return String(rounded);
        } catch (e) {
            return null;
        }
    }

    function makeMathItem(value, expr) {
        return {
            _type: "math",
            name: value,
            comment: expr ? ("= " + expr) : "Copy result",
            icon: "accessories-calculator",
            value: value
        };
    }

    function mathResults(text) {
        if (!text)
            return [];
        const value = evalMath(text);
        if (value === null)
            return [];
        return [makeMathItem(value, text)];
    }

    function commandResults(text) {
        if (!text)
            return [];
        return [{
            _type: "command",
            name: text,
            comment: "Run in background",
            icon: "utilities-terminal",
            command: text
        }];
    }

    function webResults(text) {
        if (!text)
            return [];
        return [{
            _type: "web",
            name: text,
            comment: "Search DuckDuckGo",
            icon: "system-search",
            search: text
        }];
    }

    function clipboardResults(text) {
        const q = (text || "").toLowerCase();
        const entries = ClipboardService.entries || [];
        const out = [];

        for (let i = 0; i < entries.length && out.length < root.maxResults; i++) {
            const entry = entries[i];
            const preview = entry.text || "";
            if (q && preview.toLowerCase().indexOf(q) < 0)
                continue;
            out.push({
                _type: "clipboard",
                name: preview.replace(/\s+/g, " ").trim(),
                comment: "Copy to clipboard",
                icon: "edit-copy",
                line: entry.line
            });
        }
        return out;
    }

    function actionResults(text) {
        const q = (text || "").toLowerCase();
        const actions = root.allActions();
        const out = [];

        for (let i = 0; i < actions.length; i++) {
            const action = actions[i];
            const hay = (action.name + " " + (action.comment || "") + " " + (action.keywords || "")).toLowerCase();
            if (q && hay.indexOf(q) < 0 && fuzzyScore(hay, q) < 0)
                continue;
            out.push(action);
            if (out.length >= root.maxResults)
                break;
        }
        return out;
    }

    function menuEntry(name, comment, icon, id, type) {
        return {
            _type: type || "menu",
            id: id,
            name: name,
            comment: comment || "",
            icon: icon || "applications-system"
        };
    }

    function menuGlyph(entry) {
        const glyphs = {
            connect: "󰤨", audio: "󰕾", display: "󰍹", capture: "󰹑",
            style: "󰏘", session: "󰐥", settings: "󰒓", wifi: "󰤨",
            bluetooth: "󰂯", "network-editor": "󰖩", "audio-mute": "󰖁",
            "audio-mixer": "󰕾", "brightness-up": "󰃠", "brightness-down": "󰃞",
            wallpaper: "󰸉", "wallpaper-cycle": "󰸉", screenshot: "󰹑",
            recording: "󰑋", clipboard: "󰅇", lock: "󰌾", suspend: "󰒲",
            logout: "󰍃", reboot: "󰜉", shutdown: "󰐥"
        };
        return glyphs[entry?.id || ""] || "󰍉";
    }

    function menuRoot() {
        return [
            menuEntry("Connect", "Wi-Fi and Bluetooth", "network-wireless", "connect"),
            menuEntry("Audio", "Outputs, inputs, and volume", "audio-card", "audio"),
            menuEntry("Display", "Brightness and wallpaper", "video-display", "display"),
            menuEntry("Capture", "Screenshots, recording, and clipboard", "camera-photo", "capture"),
            menuEntry("Style", "Theme and typography", "preferences-desktop-theme", "style"),
            menuEntry("Session", "Lock, suspend, and power", "system-shutdown", "session"),
            menuEntry("Settings", "Open ydot settings", "preferences-system", "settings")
        ];
    }

    function menuChildren(id) {
        switch (id) {
        case "connect":
            return [
                menuEntry("Wi-Fi", "Open Impala", "network-wireless", "wifi", "action"),
                menuEntry("Bluetooth", "Open Bluetui", "bluetooth", "bluetooth", "action"),
                menuEntry("Network settings", "Open NetworkManager editor", "preferences-system-network", "network-editor", "action")
            ];
        case "audio":
            return [
                menuEntry("Mute / unmute", "Toggle default output", "audio-volume-muted", "audio-mute", "action"),
                menuEntry("Audio mixer", "Open Pavucontrol", "audio-card", "audio-mixer", "action")
            ];
        case "display":
            return [
                menuEntry("Brightness up", "Increase brightness", "display-brightness", "brightness-up", "action"),
                menuEntry("Brightness down", "Decrease brightness", "display-brightness", "brightness-down", "action"),
                menuEntry("Wallpaper", "Open wallpaper picker", "preferences-desktop-wallpaper", "wallpaper", "action"),
                menuEntry("Cycle wallpaper", "Next wallpaper", "preferences-desktop-wallpaper", "wallpaper-cycle", "action")
            ];
        case "capture":
            return [
                menuEntry("Screenshot", "Select a region", "camera-photo", "screenshot", "action"),
                menuEntry("Toggle recording", "Start or stop recording", "media-record", "recording", "action"),
                menuEntry("Clipboard history", "Search clipboard", "edit-paste", "clipboard", "action")
            ];
        case "style":
            return [
                menuEntry("Theme and font settings", "Open settings panel", "preferences-desktop-theme", "settings", "action"),
                menuEntry("Wallpaper picker", "Choose a background", "preferences-desktop-wallpaper", "wallpaper", "action")
            ];
        case "session":
            return [
                menuEntry("Lock", "Lock the session", "system-lock-screen", "lock", "action"),
                menuEntry("Suspend", "Suspend the system", "system-suspend", "suspend", "action"),
                menuEntry("Log out", "End the Hyprland session", "system-log-out", "logout", "action"),
                menuEntry("Reboot", "Restart the system", "system-reboot", "reboot", "action"),
                menuEntry("Shut down", "Power off the system", "system-shutdown", "shutdown", "action")
            ];
        default:
            return [];
        }
    }

    function menuResults(text) {
        let entries = menuPath.length ? menuChildren(menuPath[menuPath.length - 1].id) : menuRoot();
        const q = (text || "").trim().toLowerCase();
        if (q)
            entries = entries.filter(entry => (entry.name + " " + entry.comment).toLowerCase().includes(q));
        return entries;
    }

    function showMenu() {
        menuMode = true;
        menuPath = [];
        query = "";
        fileResults = [];
        selectedIndex = 0;
        visible = true;
    }

    function leaveMenu() {
        if (!menuMode)
            return false;
        if (menuPath.length) {
            menuPath = menuPath.slice(0, -1);
            query = "";
            selectedIndex = 0;
        } else {
            hide();
        }
        return true;
    }

    function allActions() {
        const list = [
            {
                _type: "action",
                id: "wallpaper-cycle",
                name: "Cycle wallpaper",
                comment: "Next wallpaper in theme",
                icon: "preferences-desktop-wallpaper",
                keywords: "wallpaper background"
            },
            {
                _type: "action",
                id: "clipboard-wipe",
                name: "Clear clipboard history",
                comment: "Wipe cliphist",
                icon: "edit-clear",
                keywords: "clipboard wipe clear"
            },
            {
                _type: "action",
                id: "lock",
                name: "Lock session",
                comment: "Action",
                icon: "system-lock-screen",
                keywords: "lock screen"
            },
            {
                _type: "action",
                id: "suspend",
                name: "Suspend",
                comment: "Action",
                icon: "system-suspend",
                keywords: "sleep suspend"
            },
            {
                _type: "action",
                id: "logout",
                name: "Log out",
                comment: "Action",
                icon: "system-log-out",
                keywords: "logout exit"
            },
            {
                _type: "action",
                id: "reboot",
                name: "Reboot",
                comment: "Action",
                icon: "system-reboot",
                keywords: "restart reboot"
            },
            {
                _type: "action",
                id: "shutdown",
                name: "Shut down",
                comment: "Action",
                icon: "system-shutdown",
                keywords: "power off shutdown"
            }
        ];

        const themes = ThemeService.availableThemes || [];
        for (let i = 0; i < themes.length; i++) {
            const theme = themes[i];
            list.push({
                _type: "action",
                id: "theme:" + theme,
                name: "Theme: " + theme,
                comment: "Apply theme",
                icon: "preferences-desktop-theme",
                keywords: "theme " + theme
            });
        }

        return list;
    }

    function runAction(action) {
        const id = action.id || "";
        if (id === "wifi") {
            Quickshell.execDetached(["kitty", "--title", "impala", "-e", "impala"]);
            return;
        }
        if (id === "bluetooth") {
            Quickshell.execDetached(["kitty", "--title", "bluetui", "-e", "bluetui"]);
            return;
        }
        if (id === "network-editor") {
            Quickshell.execDetached(["nm-connection-editor"]);
            return;
        }
        if (id === "audio-mute") {
            AudioService.toggleMute();
            return;
        }
        if (id === "audio-mixer") {
            Quickshell.execDetached(["pavucontrol"]);
            return;
        }
        if (id === "brightness-up") {
            BrightnessService.increaseBrightness();
            return;
        }
        if (id === "brightness-down") {
            BrightnessService.decreaseBrightness();
            return;
        }
        if (id === "wallpaper") {
            WallpaperService.toggle();
            return;
        }
        if (id === "screenshot") {
            Quickshell.execDetached(["qs", "ipc", "call", "screenshot", "start"]);
            return;
        }
        if (id === "recording") {
            Quickshell.execDetached(["qs", "ipc", "call", "screenshot", "recordtoggle"]);
            return;
        }
        if (id === "clipboard") {
            ClipboardService.toggle();
            return;
        }
        if (id === "settings") {
            SettingsService.toggle();
            return;
        }
        if (id === "wallpaper-cycle") {
            Quickshell.execDetached(["wallpaper-cycle.sh"]);
            return;
        }
        if (id === "clipboard-wipe") {
            ClipboardService.clearAll();
            return;
        }
        if (id === "lock") {
            PowerService.lock();
            return;
        }
        if (id === "suspend") {
            PowerService.suspend();
            return;
        }
        if (id === "logout") {
            PowerService.logout();
            return;
        }
        if (id === "reboot") {
            PowerService.reboot();
            return;
        }
        if (id === "shutdown") {
            PowerService.shutdown();
            return;
        }
        if (id.startsWith("theme:")) {
            Quickshell.execDetached(["theme-set.sh", id.slice(6)]);
            return;
        }
    }

    // --- Usage persistence -------------------------------------------------

    function recordUsage(entry) {
        const id = entry.id || entry.name;
        if (!id)
            return;

        const next = Object.assign({}, root.usage);
        const prev = next[id] || { count: 0, lastUsed: 0 };
        next[id] = {
            count: (prev.count || 0) + 1,
            lastUsed: Date.now()
        };
        root.usage = next;
        root._usageToken++;
        usageSaveDebounce.restart();
    }

    function loadUsage() {
        usageLoadProc.running = true;
    }

    function saveUsage() {
        const jsonStr = JSON.stringify(root.usage, null, 2);
        usageSaveProc.command = ["bash", "-c", "mkdir -p \"$(dirname '" + root.usagePath + "')\" && cat > '" + root.usagePath + "' << 'USAGE_EOF'\n" + jsonStr + "\nUSAGE_EOF"];
        usageSaveProc.running = true;
    }

    Process {
        id: usageLoadProc
        command: ["bash", "-c", "cat '" + root.usagePath + "' 2>/dev/null || echo '{}'"]
        property string buffer: ""

        stdout: SplitParser {
            onRead: data => usageLoadProc.buffer += data
        }

        onExited: {
            try {
                const parsed = JSON.parse(usageLoadProc.buffer.trim() || "{}");
                root.usage = parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : {};
                root._usageToken++;
            } catch (e) {
                console.error("[Launcher] usage parse error:", e);
                root.usage = {};
            }
            usageLoadProc.buffer = "";
        }
    }

    Process {
        id: usageSaveProc
    }

    Timer {
        id: usageSaveDebounce
        interval: 250
        onTriggered: root.saveUsage()
    }

    // --- File search -------------------------------------------------------

    Process {
        id: fileSearchProc
        property var _buffer: []
        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim();
                if (trimmed)
                    fileSearchProc._buffer.push(trimmed);
            }
        }
        onStarted: fileSearchProc._buffer = []
        onExited: {
            root.fileResults = fileSearchProc._buffer.map(fullPath => {
                fullPath = fullPath.replace(/\/+$/, '');
                const idx = fullPath.lastIndexOf('/');
                const name = idx >= 0 ? fullPath.slice(idx + 1) : fullPath;
                const parentDir = idx >= 0 ? fullPath.slice(0, idx) : '';
                const lower = name.toLowerCase();
                const isVideo = /\.(mp4|mkv|avi|mov|webm|m4v|flv)$/.test(lower);
                return {
                    _type: "file",
                    name: name,
                    filePath: fullPath,
                    icon: isVideo ? "video-x-generic" : "text-x-generic",
                    comment: parentDir,
                    isVideo: isVideo
                };
            });
        }
    }

    Timer {
        id: fileSearchDebounce
        interval: 150
        onTriggered: root.runFileSearch()
    }

    function runFileSearch() {
        const q = root.parsed.provider === "files" ? root.parsed.text : "";
        if (!q) {
            fileResults = [];
            return;
        }
        fileSearchProc.command = ["fd", "-t", "f",
            "-E", ".cache", "-E", "Android", "-E", ".local", "-E", ".npm", "-E", ".cargo", "-E", ".rustup",
            "-i", "--max-results", "15", q, root.homeDir];
        fileSearchProc.running = false;
        fileSearchProc.running = true;
    }

    function shellEscape(str) {
        return "'" + String(str).replace(/'/g, "'\\''") + "'";
    }

    // --- Visibility / launch -----------------------------------------------

    function show() {
        _refreshToken++;
        query = "";
        fileResults = [];
        selectedIndex = 0;
        visible = true;
    }

    function hide() {
        visible = false;
        query = "";
        fileResults = [];
        selectedIndex = 0;
        menuMode = false;
        menuPath = [];
    }

    function toggle() {
        if (visible)
            hide();
        else
            show();
    }

    // Prefill a provider prefix (used by Ctrl+F → files)
    function setProviderPrefix(prefix) {
        if (query.startsWith(prefix))
            return;
        query = prefix;
        selectedIndex = 0;
    }

    function launch(entry) {
        if (!entry)
            return;

        const type = entry._type || "app";

        if (type === "menu") {
            menuPath = menuPath.concat([entry]);
            query = "";
            selectedIndex = 0;
            return;
        }

        if (type === "file") {
            if (entry.isVideo)
                Quickshell.execDetached(["mpv", entry.filePath]);
            else
                Quickshell.execDetached(["xdg-open", entry.filePath]);
            hide();
            return;
        }

        if (type === "math") {
            Quickshell.clipboardText = entry.value || entry.name || "";
            hide();
            return;
        }

        if (type === "command") {
            Quickshell.execDetached(["bash", "-c", entry.command]);
            hide();
            return;
        }

        if (type === "web") {
            Qt.openUrlExternally("https://duckduckgo.com/?q=" + encodeURIComponent(entry.search || entry.name || ""));
            hide();
            return;
        }

        if (type === "clipboard") {
            Quickshell.execDetached(["bash", "-c", "echo " + shellEscape(entry.line) + " | cliphist decode | wl-copy"]);
            hide();
            return;
        }

        if (type === "action") {
            runAction(entry);
            hide();
            return;
        }

        // DesktopEntry app
        recordUsage(entry);

        if (entry.runInTerminal && entry.command && entry.command.length > 0) {
            Quickshell.execDetached({
                command: ["kitty", "-e"].concat(Array.from(entry.command)),
                workingDirectory: entry.workingDirectory || ""
            });
        } else if (typeof entry.execute === "function") {
            entry.execute();
        } else if (entry.command && entry.command.length > 0) {
            Quickshell.execDetached({
                command: Array.from(entry.command),
                workingDirectory: entry.workingDirectory || ""
            });
        } else {
            return;
        }

        hide();
    }

    function launchSelected() {
        if (filteredApps.length > 0 && selectedIndex >= 0 && selectedIndex < filteredApps.length)
            launch(filteredApps[selectedIndex]);
    }

    function navigateUp() {
        navigateBy(-1);
    }

    function navigateDown() {
        navigateBy(1);
    }

    function navigateBy(delta) {
        const max = filteredApps.length - 1;
        if (max < 0)
            return;
        selectedIndex = Math.max(0, Math.min(max, selectedIndex + delta));
    }

    onQueryChanged: {
        selectedIndex = 0;

        if (root.parsed.provider === "files")
            fileSearchDebounce.restart();
        else if (fileResults.length)
            fileResults = [];

        if (root.parsed.provider === "clipboard")
            ClipboardService.refresh();

        if (root.parsed.provider === "math") {
            const value = evalMath(root.parsed.text);
            mathResult = value !== null ? value : "";
        }
    }
}
