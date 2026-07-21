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

    property var entries: []

    readonly property var filteredEntries: {
        if (query === "")
            return entries.slice(0, entries.length);

        const q = query.toLowerCase();
        return entries.filter(entry => {
            return entry.text.toLowerCase().includes(q);
        }).slice(0, entries.length);
    }

    function show() {
        refresh();
        query = "";
        selectedIndex = 0;
        visible = true;
    }

    function hide() {
        visible = false;
        query = "";
        selectedIndex = 0;
    }

    function toggle() {
        if (visible) hide();
        else show();
    }

    function selectItem(index) {
        if (index < 0 || index >= filteredEntries.length) return;

        const entry = filteredEntries[index];
        selectProc.command = ["sh", "-c", "echo " + shellEscape(entry.line) + " | cliphist decode | wl-copy && sleep 0.3 && wtype -M ctrl v -m ctrl"];
        selectProc.running = true;
    }

    function selectCurrent() {
        selectItem(selectedIndex);
    }

    function deleteItem(index) {
        if (index < 0 || index >= filteredEntries.length) return;

        const entry = filteredEntries[index];
        deleteProc.command = ["sh", "-c", "echo " + shellEscape(entry.line) + " | cliphist delete"];
        deleteProc.running = true;
    }

    function clearAll() {
        clearProc.running = true;
    }

    function refresh() {
        listProc.running = true;
    }

    function navigateUp() {
        if (selectedIndex > 0) selectedIndex--;
    }

    function navigateDown() {
        if (selectedIndex < filteredEntries.length - 1) selectedIndex++;
    }

    onQueryChanged: {
        selectedIndex = 0;
    }

    function shellEscape(str) {
        return "'" + str.replace(/'/g, "'\\''") + "'";
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                var items = [];

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (!line) continue;

                    const tabIndex = line.indexOf("\t");
                    if (tabIndex === -1) continue;

                    items.push({
                        id: line.substring(0, tabIndex),
                        text: line.substring(tabIndex + 1),
                        line: line
                    });
                }

                root.entries = items;
            }
        }

        stderr: SplitParser {
            onRead: data => console.error("[Clipboard] " + data)
        }
    }

    Process {
        id: selectProc

        onExited: code => {
            if (code !== 0) {
                console.error("[Clipboard] Failed to copy entry, exit code:", code);
            }
        }

        stderr: SplitParser {
            onRead: data => console.error("[Clipboard] " + data)
        }
    }

    Process {
        id: deleteProc

        onExited: code => {
            if (code === 0) {
                root.refresh();
            } else {
                console.error("[Clipboard] Failed to delete entry, exit code:", code);
            }
        }

        stderr: SplitParser {
            onRead: data => console.error("[Clipboard] " + data)
        }
    }

    Process {
        id: clearProc
        command: ["cliphist", "wipe"]

        onExited: code => {
            if (code === 0) {
                root.entries = [];
            } else {
                console.error("[Clipboard] Failed to clear entries, exit code:", code);
            }
        }

        stderr: SplitParser {
            onRead: data => console.error("[Clipboard] " + data)
        }
    }
}
