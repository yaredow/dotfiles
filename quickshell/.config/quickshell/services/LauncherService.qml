pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool visible: false
    property string query: ""
    property int selectedIndex: 0
    property string mode: "apps"
    property var fileResults: []

    property int _refreshToken: 0

    readonly property var filteredApps: {
        if (root.mode === "files")
            return root.fileResults;

        void root._refreshToken;
        let apps = DesktopEntries.applications.values;

        const seen = new Set();
        apps = apps.filter(app => {
            const key = app.id || app.execString || app.name;
            if (seen.has(key))
                return false;
            seen.add(key);
            return true;
        });

        apps = apps.slice().sort((a, b) => {
            const nameA = (a.name || "").toLowerCase();
            const nameB = (b.name || "").toLowerCase();
            return nameA.localeCompare(nameB);
        });

        if (query === "") {
            return [];
        }

        const q = query.toLowerCase();

        let nameMatches = [];
        let descMatches = [];

        for (const app of apps) {
            const name = (app.name || "").toLowerCase();
            const comment = (app.comment || "").toLowerCase();
            const genericName = (app.genericName || "").toLowerCase();

            if (name.includes(q)) {
                nameMatches.push(app);
            } else if (comment.includes(q) || genericName.includes(q)) {
                descMatches.push(app);
            }
        }

        return [...nameMatches, ...descMatches].slice(0, apps.length);
    }

    readonly property string homeDir: Quickshell.env("HOME")

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
                return {
                    _type: "file",
                    name: name,
                    filePath: fullPath,
                    icon: "video-x-generic",
                    comment: parentDir
                };
            });
        }
    }

    Timer {
        id: fileSearchDebounce
        interval: 150
        onTriggered: root.runFileSearch()
    }

    function show() {
        mode = "apps";
        _refreshToken++;
        query = "";
        selectedIndex = 0;
        visible = true;
    }

    function hide() {
        visible = false;
        query = "";
        selectedIndex = 0;
    }

    function toggleFileMode() {
        mode = mode === "apps" ? "files" : "apps";
        query = "";
        fileResults = [];
        selectedIndex = 0;
    }

    function toggle() {
        if (visible)
            hide();
        else
            show();
    }

    function launch(entry) {
        if (!entry)
            return;

        console.log("[Launcher] Launching:", entry.name);

        if (entry._type === "file") {
            Quickshell.execDetached(["mpv", entry.filePath]);
            hide();
            return;
        }

        let cmd = entry.execString;
        cmd = cmd.replace(/%[uUfFdDnNickvm]/g, "").trim();
        cmd = cmd.replace(/\s+/g, " ");

        Quickshell.execDetached(["sh", "-c", cmd]);
        hide();
    }

    function launchSelected() {
        if (filteredApps.length > 0 && selectedIndex >= 0 && selectedIndex < filteredApps.length) {
            launch(filteredApps[selectedIndex]);
        }
    }

    function navigateUp() {
        if (selectedIndex > 0) {
            selectedIndex--;
        }
    }

    function navigateDown() {
        if (selectedIndex < filteredApps.length - 1) {
            selectedIndex++;
        }
    }

    function runFileSearch() {
        const q = root.query.trim();
        if (!q) {
            fileResults = [];
            return;
        }
        fileSearchProc.command = ["fd", "-t", "f",
            "-E", ".cache", "-E", "Android", "-E", ".local", "-E", ".npm", "-E", ".cargo", "-E", ".rustup",
            "-e", "mp4", "-e", "mkv", "-e", "avi", "-e", "mov", "-e", "webm", "-e", "m4v", "-e", "flv",
            "-i", "--max-results", "15", q, root.homeDir];
        fileSearchProc.running = false;
        fileSearchProc.running = true;
    }

    onQueryChanged: {
        selectedIndex = 0;
        if (root.mode === "files")
            fileSearchDebounce.restart();
    }
}
