pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property list<MprisPlayer> players: Mpris.players.values
    property MprisPlayer manual: null
    readonly property MprisPlayer player: (manual && players.includes(manual)) ? manual
        : (players.find(p => p.isPlaying) ?? players[0] ?? null)

    readonly property bool active: player !== null && (player.trackTitle ?? "") !== ""
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle || "Nothing playing"
    readonly property string artist: player?.trackArtist || player?.identity || ""
    readonly property string album: player?.trackAlbum || ""
    readonly property string art: player?.trackArtUrl || ""
    readonly property real length: player?.length ?? 0
    readonly property real position: player?.position ?? 0
    readonly property real progress: length > 0 ? Math.min(1, position / length) : 0

    function toggle(): void { player?.togglePlaying(); }
    function next(): void { if (player?.canGoNext) player.next(); }
    function previous(): void { if (player?.canGoPrevious) player.previous(); }
    function seek(frac: real): void { if (player?.canSeek && length > 0) player.position = frac * length; }
    function cycle(): void {
        if (players.length < 2) return;
        const i = players.indexOf(player);
        manual = players[(i + 1) % players.length];
    }

    function fmt(s: real): string {
        s = Math.max(0, Math.floor(s));
        const m = Math.floor(s / 60), r = s % 60;
        return `${m}:${r < 10 ? "0" : ""}${r}`;
    }

    // MPRIS position isn't pushed; poke it while playing
    Timer {
        interval: 1000; repeat: true
        running: root.playing
        onTriggered: root.player?.positionChanged()
    }
}
