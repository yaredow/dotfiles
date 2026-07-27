pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool recording: false

    Process {
        id: recordProc
        running: false

        onExited: {
            root.recording = false;
        }
    }

    function startRecording(geometry: string) {
        if (root.recording)
            return;

        const videosDir = Quickshell.env("XDG_VIDEOS_DIR") || (Quickshell.env("HOME") + "/Videos/Screenrecordings");
        const timestamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
        const outputPath = `${videosDir}/recording-${timestamp}.mp4`;
        const cmd = `mkdir -p "${videosDir}" && wf-recorder -g "${geometry}" -f "${outputPath}"`;

        root.recording = true;
        recordProc.command = ["sh", "-c", cmd];
        recordProc.running = true;
    }

    function stopRecording() {
        if (!root.recording)
            return;
        root.recording = false;
        Quickshell.execDetached(["sh", "-c", "killall -2 wf-recorder && notify-send -a Screenshot 'Recording saved' 'Screen recording has been saved.'"]);
    }
}
