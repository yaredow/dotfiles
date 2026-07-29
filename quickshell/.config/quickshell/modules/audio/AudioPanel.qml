pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.config
import qs.services
import "../../components/"

QsPopupWindow {
    id: root

    popupWidth: 380
    popupMaxHeight: 560
    anchorSide: "right"
    moduleName: "AudioPanel"
    contentImplicitHeight: mainColumn.implicitHeight

    // ---- Pipewire data ----
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []

    property var displaySinks: []
    property var displaySources: []
    property var displayStreams: []

    // ---- Derived (use AudioService for live volume — pactl polling, reliable) ----
    readonly property real outputVolume: AudioService.volume
    readonly property bool outputMuted: AudioService.muted
    readonly property real inputVolume: (source && source.audio) ? source.audio.volume : 0
    readonly property bool inputMuted: (source && source.audio) ? source.audio.muted : false

    readonly property bool hasOutput: true
    readonly property bool hasInput: !!(source && source.audio)
    readonly property bool anyAudible: !outputMuted || (hasInput && !inputMuted)

    // ---- Device/stream construction ----
    readonly property var allSinks: {
        var l = []
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (n && n.isSink && !n.isStream) l.push(n)
        }
        return l
    }
    readonly property var allSources: {
        var l = []
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (!n || !n.audio) continue
            if (n.isSink || n.isStream) continue
            l.push(n)
        }
        return l
    }
    readonly property var allStreams: {
        var l = []
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (!n || !n.audio) continue
            if (!n.isStream) continue
            l.push(n)
        }
        return l
    }

    function snapshotModels() {
        displaySinks = allSinks.slice()
        displaySources = allSources.slice()
        displayStreams = allStreams.slice()
    }

    onVisibleChanged: {
        if (visible) { snapshotModels(); modelTimer.start() }
        else { displaySinks = []; displaySources = []; displayStreams = []; modelTimer.stop() }
    }

    Timer {
        id: modelTimer
        interval: 2000
        repeat: true
        onTriggered: root.snapshotModels()
    }

    Connections {
        target: Pipewire
        function onNodesChanged() { if (root.visible) root.snapshotModels() }
    }

    // ---- Helpers ----
    function outputIcon() {
        if (!sink || !sink.audio) return ""
        if (outputMuted) return ""
        var v = outputVolume
        if (v >= 0.67) return ""
        if (v >= 0.34) return ""
        if (v > 0) return ""
        return ""
    }

    function outputVolumeName(volume, muted) {
        if (muted) return "Muted"
        var p = Math.round(volume * 100)
        if (p === 0) return "Silent"
        if (p >= 100) return "Max volume"
        if (p >= 85) return "Loud"
        if (p >= 70) return "High"
        if (p >= 50) return "Medium"
        if (p >= 30) return "Low"
        if (p >= 15) return "Quiet"
        return "Whisper"
    }

    function sinkIcon(node) {
        if (!node) return "󰓃"
        var blob = String([node.name, node.description || ""].join(" ")).toLowerCase()
        if (blob.indexOf("headphone") !== -1 || blob.indexOf("headset") !== -1) return "󰋋"
        if (blob.indexOf("bluetooth") !== -1) return "󰂯"
        if (blob.indexOf("hdmi") !== -1 || blob.indexOf("display") !== -1) return "󰍹"
        return "󰓃"
    }

    function nodeLabel(node) {
        if (!node) return ""
        var d = node.description || node.nickname || node.name || ""
        return d.replace(/\s+Output$/i, "").replace(/^Built-in Audio\s+/i, "")
    }

    function streamLabelRaw(node) {
        if (!node) return ""
        var p = node.properties || {}
        return p["application.name"] || node.description || node.name || "Unknown"
    }

    function setOutputVolume(v) { AudioService.setVolume(Math.max(0, Math.min(1, v))) }
    function toggleOutputMute() { AudioService.toggleMute() }
    function toggleInputMute() { if (source && source.audio) source.audio.muted = !source.audio.muted }
    function toggleAllMuted() {
        AudioService.toggleMute()
        if (hasInput && source && source.audio) source.audio.muted = outputMuted
    }
    function setDefaultSink(node) { AudioService.setDefaultSink(node) }
    function setDefaultSource(node) {
        if (!node) return
        Pipewire.preferredDefaultAudioSource = node
    }

    // ---- Content ----
    content: Column {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 14

        // ═══════ Hero ═══════
        Item {
            width: parent.width
            implicitHeight: Math.max(
                heroIcon.implicitHeight,
                heroLabels.implicitHeight,
                powerSwitch.implicitHeight
            )

            Text {
                id: heroIcon
                text: root.outputIcon()
                color: Config.textColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeIconLarge
                opacity: root.outputMuted ? 0.5 : 1.0
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            ToggleSwitch {
                id: powerSwitch
                checked: root.anyAudible
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onToggled: root.toggleAllMuted()
                tooltipText: root.anyAudible ? "Mute" : "Unmute"
            }

            Column {
                id: heroLabels
                anchors.left: heroIcon.right
                anchors.leftMargin: 14
                anchors.right: powerSwitch.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: "Audio"
                    color: Config.textColor
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeLarge
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: root.outputVolumeName(root.outputVolume, root.outputMuted).toUpperCase()
                    color: Qt.darker(Config.textColor, 1.4)
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }

        // ═══════ Separator ═══════
        Rectangle { width: parent.width; height: 1; color: Qt.alpha(Config.textColor, 0.15) }

        // ═══════ Output section ═══════
        Column {
            width: parent.width
            spacing: 6

            // Header: label + percentage
            Item {
                width: parent.width
                implicitHeight: Math.max(outHeader.implicitHeight, outPct.implicitHeight)

                Text {
                    id: outHeader
                    text: "OUTPUT"
                    color: Config.textColor
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: outPct
                    text: Math.round(root.outputVolume * 100) + "%"
                    color: Qt.darker(Config.textColor, 1.4)
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.weight: Font.Bold
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: root.outputMuted ? 0.5 : 1.0
                }
            }

            // Slider
            Item {
                width: parent.width
                height: 28

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    height: 4; radius: 2
                    color: Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.12)

                    Rectangle {
                        height: parent.height; radius: parent.radius
                        color: Config.accentColor
                        width: Math.round(parent.width * root.outputVolume)
                        opacity: root.outputMuted ? 0.35 : 1.0
                        Behavior on width { NumberAnimation { duration: 80 } }
                        Behavior on opacity { NumberAnimation { duration: Config.animDurationShort } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onPressed: function(mouse) {
                        if (mouse.button === Qt.RightButton) { root.toggleOutputMute(); return }
                        root.setOutputVolume(Math.max(0, Math.min(1, mouse.x / width)))
                    }
                    onPositionChanged: function(mouse) {
                        if (pressed && mouse.button === Qt.LeftButton)
                            root.setOutputVolume(Math.max(0, Math.min(1, mouse.x / width)))
                    }
                    onWheel: function(event) {
                        if (event.angleDelta.y > 0) root.setOutputVolume(root.outputVolume + 0.05)
                        else root.setOutputVolume(root.outputVolume - 0.05)
                    }
                }
            }

            // Device list
            Repeater {
                model: root.displaySinks

                delegate: SinkRow {
                    required property var modelData
                    required property int index
                    width: mainColumn.width
                    node: modelData
                }
            }
        }

        // ═══════ Input section ═══════
        Rectangle {
            width: parent.width; height: 1
            color: Qt.alpha(Config.textColor, 0.15)
            visible: root.displaySources.length > 0 || !!root.source
        }

        Column {
            width: parent.width
            spacing: 6
            visible: root.displaySources.length > 0 || !!root.source

            Item {
                width: parent.width
                implicitHeight: Math.max(inHeader.implicitHeight, inPct.implicitHeight)

                Text {
                    id: inHeader
                    text: "INPUT"
                    color: Config.textColor
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: inPct
                    text: Math.round(root.inputVolume * 100) + "%"
                    color: Qt.darker(Config.textColor, 1.4)
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.weight: Font.Bold
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: root.inputMuted ? 0.5 : 1.0
                }
            }

            Item {
                width: parent.width
                height: 18

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    height: 3; radius: 1
                    color: Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.12)

                    Rectangle {
                        height: parent.height; radius: parent.radius
                        color: Config.accentColor
                        width: Math.round(parent.width * root.inputVolume)
                        opacity: root.inputMuted ? 0.35 : 1.0
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onPressed: function(mouse) {
                        if (mouse.button === Qt.RightButton) { root.toggleInputMute(); return }
                        if (source && source.audio) source.audio.volume = Math.max(0, Math.min(1, mouse.x / width))
                    }
                    onPositionChanged: function(mouse) {
                        if (pressed && mouse.button === Qt.LeftButton && source && source.audio)
                            source.audio.volume = Math.max(0, Math.min(1, mouse.x / width))
                    }
                }
            }

            Repeater {
                model: root.displaySources

                delegate: SourceRow {
                    required property var modelData
                    required property int index
                    width: mainColumn.width
                    node: modelData
                }
            }
        }

        // ═══════ Per-app streams ═══════
        Rectangle {
            width: parent.width; height: 1
            color: Qt.alpha(Config.textColor, 0.15)
            visible: root.displayStreams.length > 0
        }

        Column {
            width: parent.width
            spacing: 10
            visible: root.displayStreams.length > 0

            Text {
                text: "SOURCES"
                color: Config.textColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                font.weight: Font.Bold
                font.letterSpacing: 1.2
            }

            Repeater {
                model: root.displayStreams

                delegate: StreamRow {
                    required property var modelData
                    required property int index
                    width: mainColumn.width
                    node: modelData
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Components
    // ═══════════════════════════════════════════════════

    component ToggleSwitch: Item {
        property bool checked: false
        property string tooltipText: ""
        signal toggled

        width: 42; height: 24

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: parent.checked ? Config.accentColor : Config.surface2Color
            Behavior on color { ColorAnimation { duration: Config.animDuration } }

            Rectangle {
                x: parent.checked ? parent.width - 20 : 4
                y: 4
                width: 16; height: 16; radius: 8
                color: "white"
                Behavior on x { NumberAnimation { duration: Config.animDurationShort; easing.type: Easing.OutQuad } }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.toggled()
        }
    }

    component SinkRow: Rectangle {
        required property var node
        required property int index
        width: parent.width; height: 34; radius: Config.radiusSmall
        color: mouse.containsMouse ? Qt.alpha(Config.textColor, 0.05) : "transparent"

        readonly property bool isActive: root.sink && node && root.sink.id === node.id

        Row {
            anchors.left: parent.left; anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: root.sinkIcon(node)
                color: Config.textColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeLarge
                width: 22; horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.nodeLabel(node)
                color: Config.textColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                font.weight: isActive ? Font.Bold : Font.Normal
                elide: Text.ElideRight
                width: parent.width - 30 - 8
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: !isActive ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: { if (!isActive) root.setDefaultSink(node) }
        }
    }

    component SourceRow: Rectangle {
        required property var node
        required property int index
        width: parent.width; height: 34; radius: Config.radiusSmall
        color: mouse.containsMouse ? Qt.alpha(Config.textColor, 0.05) : "transparent"

        readonly property bool isActive: root.source && node && root.source.id === node.id

        Row {
            anchors.left: parent.left; anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: "󰍬"
                color: Config.textColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeLarge
                width: 22; horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.nodeLabel(node)
                color: Config.textColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                font.weight: isActive ? Font.Bold : Font.Normal
                elide: Text.ElideRight
                width: parent.width - 30 - 8
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: !isActive ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: { if (!isActive) root.setDefaultSource(node) }
        }
    }

    component StreamRow: Item {
        required property var node
        required property int index
        width: parent.width; height: 48

        readonly property real sVol: (node && node.audio) ? node.audio.volume : 0
        readonly property bool sMuted: (node && node.audio) ? node.audio.muted : false

        Column {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 6; anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Row {
                width: parent.width
                spacing: 8

                Text {
                    text: sMuted ? "󰝟" : "󰕾"
                    color: Config.textColor
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeLarge
                    width: 22; horizontalAlignment: Text.AlignHCenter
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: sMuted ? 0.5 : 1.0

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (node && node.audio) node.audio.muted = !node.audio.muted }
                    }
                }

                Text {
                    text: root.streamLabelRaw(node)
                    color: Config.textColor
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    elide: Text.ElideRight
                    width: parent.width - 22 - 36 - 16
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: Math.round(sVol * 100) + "%"
                    color: Qt.darker(Config.textColor, 1.5)
                    font.family: Config.font
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    width: 36; horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: sMuted ? 0.5 : 1.0
                }
            }

            Rectangle {
                width: parent.width
                height: 3; radius: 1
                color: Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.12)
                opacity: sMuted ? 0.35 : 1.0

                Rectangle {
                    height: parent.height; radius: parent.radius
                    color: Config.accentColor
                    width: Math.round(parent.width * sVol)
                    Behavior on width { NumberAnimation { duration: 80 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onPressed: function(mouse) {
                        if (mouse.button === Qt.RightButton) { if (node && node.audio) node.audio.muted = !node.audio.muted; return }
                        if (node && node.audio) node.audio.volume = Math.max(0, Math.min(1.5, mouse.x / width))
                    }
                    onPositionChanged: function(mouse) {
                        if (pressed && mouse.button === Qt.LeftButton && node && node.audio)
                            node.audio.volume = Math.max(0, Math.min(1.5, mouse.x / width))
                    }
                }
            }
        }
    }
}
