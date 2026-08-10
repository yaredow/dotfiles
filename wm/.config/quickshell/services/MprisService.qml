pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property list<MprisPlayer> players: Mpris.players.values
    property MprisPlayer activePlayer: null

    readonly property bool hasPlayer: activePlayer !== null

    readonly property string title: activePlayer?.trackTitle ?? "Unknown"
    readonly property string artist: activePlayer?.trackArtist ?? "Unknown"
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property string identity: activePlayer?.identity ?? ""

    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property bool anyPlaying: players.some(p => p.isPlaying)

    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 0
    readonly property bool positionSupported: activePlayer?.positionSupported ?? false
    readonly property bool canSeek: activePlayer?.canSeek ?? false

    readonly property bool canNext: activePlayer?.canGoNext ?? false
    readonly property bool canPrevious: activePlayer?.canGoPrevious ?? false
    readonly property bool canToggle: activePlayer?.canTogglePlaying ?? false

    readonly property var loopState: activePlayer?.loopState ?? MprisLoopState.None
    readonly property bool loopSupported: activePlayer?.loopSupported ?? false
    readonly property bool shuffle: activePlayer?.shuffle ?? false
    readonly property bool shuffleSupported: activePlayer?.shuffleSupported ?? false

    readonly property real volume: activePlayer?.volume ?? 0

    Timer {
        running: root.hasPlayer && root.isPlaying && root.positionSupported
        interval: 500
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.activePlayer && Mpris.players.values.includes(root.activePlayer))
                root.activePlayer.positionChanged();
        }
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.updateActivePlayer() }
    }

    Instantiator {
        model: Mpris.players.values
        delegate: QtObject {
            required property MprisPlayer modelData
            property bool isPlaying: modelData.isPlaying ?? false
            onIsPlayingChanged: root.updateActivePlayer()
        }
        onObjectAdded: root.updateActivePlayer()
        onObjectRemoved: root.updateActivePlayer()
    }

    function updateActivePlayer() {
        const rawList = Mpris.players.values;
        if (rawList.length === 0) { root.activePlayer = null; return; }
        const playing = rawList.find(p => p.isPlaying);
        root.activePlayer = playing || (rawList.includes(root.activePlayer) ? root.activePlayer : rawList[0]);
    }

    function playPause() { activePlayer?.canTogglePlaying && activePlayer.togglePlaying() }
    function next() { activePlayer?.canGoNext && activePlayer.next() }
    function previous() { activePlayer?.canGoPrevious && activePlayer.previous() }
    function setPosition(pos) { if (activePlayer?.canSeek) activePlayer.position = pos }
    function toggleShuffle() { if (activePlayer?.shuffleSupported) activePlayer.shuffle = !activePlayer.shuffle }
    function setVolume(vol) { if (activePlayer) activePlayer.volume = Math.max(0, Math.min(1, vol)) }

    function cycleLoop() {
        if (!activePlayer?.loopSupported) return;
        if (activePlayer.loopState === MprisLoopState.None) activePlayer.loopState = MprisLoopState.Track;
        else if (activePlayer.loopState === MprisLoopState.Track) activePlayer.loopState = MprisLoopState.Playlist;
        else activePlayer.loopState = MprisLoopState.None;
    }
}
