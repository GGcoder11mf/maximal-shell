pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Caelestia.Services

// Music brain of the rice:
//  · track changes (-> toast, album-art theming)
//  · clean artist/title (YouTube "Artist - Title (Official Video)") for lyrics lookup
//  · synced lyrics via Caelestia's Lyrics service, with a smooth local position clock
//  · album-art theming: whole rice re-themes from the cover; wallpaper palette returns
//    after the music has been stopped/paused for a while
//  · Music Stage auto-opens when you're idle while music plays
Singleton {
    id: root

    // ── track identity (cleaned) ────────────────────────
    readonly property string rawTitle: Media.player?.trackTitle ?? ""
    readonly property string rawArtist: Media.player?.trackArtist ?? ""
    readonly property var clean: cleanup(rawArtist, rawTitle)
    readonly property string title: clean.title
    readonly property string artist: clean.artist
    readonly property string key: artist + "\u0001" + title
    signal trackChanged()

    function cleanup(artist, title) {
        let a = (artist || "").trim(), t = (title || "").trim();
        // strip common video/audio decorations
        t = t.replace(/\s*[\(\[]\s*(official\s*)?(music\s*)?(video|audio|lyrics?|lyric video|visualizer|hd|hq|4k|remaster(ed)?( \d{4})?|explicit|clean|live)[^\)\]]*[\)\]]/gi, "")
             .replace(/\s*\|\s*.*$/, "").trim();
        // "Artist - Title" in the title (YouTube), or a channel-ish artist (VEVO / - Topic)
        const m = t.match(/^(.+?)\s+[-–—]\s+(.+)$/);
        if (m && (!a || /vevo$|\s-\sTopic$|official/i.test(a) || a.toLowerCase().replace(/\s/g, "").includes(m[1].toLowerCase().replace(/\s/g, ""))))
            { a = m[1].trim(); t = m[2].trim(); }
        a = a.replace(/VEVO$/i, "").replace(/\s-\sTopic$/i, "").trim();
        return { artist: a, title: t };
    }

    // ── lyrics ──────────────────────────────────────────
    // derived from `lines` (that binding updates reliably; Lyrics.hasLyrics did not re-notify here)
    readonly property bool hasLyrics: lines.length > 0 && Media.active
    readonly property var lines: Lyrics.lyrics
    property real pos: 0                      // smooth playback position (s)
    property int lyricIndex: -1
    readonly property string line: lyricIndex >= 0 ? (lines[lyricIndex] ?? "") : ""
    readonly property string prevLine: lyricIndex > 0 ? (lines[lyricIndex - 1] ?? "") : ""
    readonly property string nextLine: lyricIndex >= 0 ? (lines[lyricIndex + 1] ?? "") : (lines[0] ?? "")

    property real _posBase: 0
    property real _posStamp: 0
    Connections {
        target: Media.player
        function onPositionChanged() { root._posBase = Media.player.position; root._posStamp = Date.now(); }
    }
    Timer {     // 4 Hz local clock between MPRIS updates -> lyric line changes on time
        interval: 250; repeat: true
        running: Media.playing && root.hasLyrics
        onTriggered: {
            root.pos = root._posBase + (Date.now() - root._posStamp) / 1000;
            const i = Lyrics.indexForTime(root.pos);
            if (i !== root.lyricIndex) root.lyricIndex = i;
        }
    }

    // ── track change handling ───────────────────────────
    property string _lastKey: ""
    onKeyChanged: trackDebounce.restart()
    Component.onCompleted: trackDebounce.restart()     // a track already loaded at startup counts too
    Timer {
        id: trackDebounce
        interval: 700           // metadata arrives in pieces; wait for it to settle
        onTriggered: {
            if (!root.title) { Lyrics.clearTrack(); root.lyricIndex = -1; return; }
            if (root.key === root._lastKey) return;
            root._lastKey = root.key;
            root.lyricIndex = -1;
            Lyrics.setTrack(root.artist, root.title, Media.album, Media.length);
            if (Media.playing) root.trackChanged();
            artDebounce.restart();
        }
    }

    // ── album-art theming ───────────────────────────────
    readonly property bool albumOn: Shell.albumColors
    property string _themedArt: ""
    property bool _artThemed: false
    Timer {
        id: artDebounce
        interval: 900
        onTriggered: root.applyArt()
    }
    onAlbumOnChanged: albumOn ? applyArt() : restorePalette()
    Connections {
        target: Media
        function onArtChanged() { artDebounce.restart(); }
        function onPlayingChanged() {
            if (Media.playing) { restoreTimer.stop(); artDebounce.restart(); }
            else restoreTimer.restart();
        }
    }
    function applyArt() {
        if (!Shell.albumColors || !Media.playing || !Media.art || Media.art === root._themedArt) return;
        root._themedArt = Media.art;
        root._artThemed = true;
        Quickshell.execDetached([Theme.scripts + "art-theme.sh", Media.art]);
    }
    function restorePalette() {
        if (!root._artThemed) return;
        root._artThemed = false;
        root._themedArt = "";
        Quickshell.execDetached([Theme.scripts + "art-theme.sh", "--restore"]);
    }
    Timer {     // paused/stopped for a while -> wallpaper palette comes back
        id: restoreTimer
        interval: 20000
        onTriggered: if (!Media.playing) root.restorePalette()
    }

    // ── Music Stage: auto-open when idle while music plays ──
    property bool _stageAuto: false
    IdleMonitor {
        enabled: Shell.stageAuto && Media.playing
        timeout: 150            // seconds without input
        respectInhibitors: false
        onIsIdleChanged: {
            if (isIdle && Media.playing && Shell.panel === "") { root._stageAuto = true; Shell.open("stage"); }
            else if (!isIdle && root._stageAuto) { root._stageAuto = false; if (Shell.panel === "stage") Shell.close(); }
        }
    }

    // debugging: qs -p <shell> ipc call music stats
    IpcHandler {
        target: "music"
        function stats(): string {
            return `hasLyrics(combined)=${root.hasLyrics} mediaActive=${Media.active} raw="${root.rawArtist} | ${root.rawTitle}" clean="${root.artist} | ${root.title}" lyrics=${Lyrics.hasLyrics} loading=${Lyrics.loading} n=${root.lines.length} idx=${root.lyricIndex} line="${root.line}" pos=${root.pos.toFixed(1)} albumThemed=${root._artThemed} playing=${Media.playing}`;
        }
    }
}
