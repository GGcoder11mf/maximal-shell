pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property string sinkName: sink?.description || sink?.nickname || sink?.name || "No output"
    readonly property string sourceName: source?.description || source?.nickname || source?.name || "No input"
    readonly property bool ready: sink?.ready ?? false

    readonly property string icon: muted ? "volume_off" : volume < 0.01 ? "volume_mute" : volume < 0.45 ? "volume_down" : "volume_up"
    readonly property string micIcon: micMuted ? "mic_off" : "mic"

    function setVolume(v: real): void {
        if (sink?.audio) { sink.audio.muted = false; sink.audio.volume = Math.max(0, Math.min(1.5, v)); }
    }
    function setMic(v: real): void {
        if (source?.audio) { source.audio.muted = false; source.audio.volume = Math.max(0, Math.min(1.5, v)); }
    }
    function toggleMute(): void { if (sink?.audio) sink.audio.muted = !sink.audio.muted; }
    function toggleMic(): void { if (source?.audio) source.audio.muted = !source.audio.muted; }

    PwObjectTracker { objects: [root.sink, root.source] }

    // qs -p <shell> ipc call audio step 5   (percent, may be negative) · ipc call audio volume
    IpcHandler {
        target: "audio"
        function step(pct: int): void { root.setVolume(Math.round((root.volume + pct / 100) * 20) / 20); }
        function volume(): string { return Math.round(root.volume * 100) + (root.muted ? " (muted)" : "") + " ready=" + root.ready; }
    }
}
