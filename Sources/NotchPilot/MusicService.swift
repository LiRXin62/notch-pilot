import AppKit
import Foundation

struct NowPlayingInfo: Equatable {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var isPlaying: Bool = false
    var appName: String = ""

    var isEmpty: Bool { title.isEmpty }
}

@MainActor
final class MusicService: ObservableObject {
    @Published var nowPlaying = NowPlayingInfo()
    @Published var isSupported = false

    private var timer: Timer?

    func startMonitoring() {
        checkNowPlaying()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkNowPlaying()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func togglePlayPause() {
        sendMediaKey(key: NX_KEYTYPE_PLAY)
    }

    func nextTrack() {
        sendMediaKey(key: NX_NEXT)
    }

    func previousTrack() {
        sendMediaKey(key: NX_PREVIOUS)
    }

    private func checkNowPlaying() {
        // Use scripting bridge to check common music players
        let players = [
            ("com.apple.Music", "Music"),
            ("com.apple.iTunes", "iTunes"),
            ("com.spotify.client", "Spotify")
        ]

        for (bundleId, appName) in players {
            if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first {
                isSupported = true
                // Use AppleScript to get current track info
                if let info = getTrackInfoViaAppleScript(bundleId: bundleId) {
                    nowPlaying = info
                    return
                }
            }
        }

        // Check for any app using MediaPlayer framework (via NowPlaying)
        if let info = getNowPlayingFromSystem() {
            nowPlaying = info
            isSupported = true
            return
        }

        isSupported = false
    }

    private func getTrackInfoViaAppleScript(bundleId: String) -> NowPlayingInfo? {
        let script: String
        switch bundleId {
        case "com.spotify.client":
            script = """
            tell application "Spotify"
                if player state is playing then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set albumName to album of current track
                    return trackName & "|||" & artistName & "|||" & albumName & "|||playing"
                else if player state is paused then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set albumName to album of current track
                    return trackName & "|||" & artistName & "|||" & albumName & "|||paused"
                end if
            end tell
            """
        default:
            script = """
            tell application "Music"
                if player state is playing then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set albumName to album of current track
                    return trackName & "|||" & artistName & "|||" & albumName & "|||playing"
                else if player state is paused then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set albumName to album of current track
                    return trackName & "|||" & artistName & "|||" & albumName & "|||paused"
                end if
            end tell
            """
        }

        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)

        guard error == nil else { return nil }

        let parts = result.stringValue?.components(separatedBy: "|||") ?? []
        guard parts.count >= 4 else { return nil }

        return NowPlayingInfo(
            title: parts[0],
            artist: parts[1],
            album: parts[2],
            isPlaying: parts[3] == "playing",
            appName: bundleId == "com.spotify.client" ? "Spotify" : "Music"
        )
    }

    private func getNowPlayingFromSystem() -> NowPlayingInfo? {
        // Fallback: check if any media player is active via workspace
        return nil
    }

    private func sendMediaKey(key: Int32) {
        let eventSource = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(key), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(key), keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

private let NX_KEYTYPE_PLAY: Int32 = 16
private let NX_NEXT: Int32 = 17
private let NX_PREVIOUS: Int32 = 18
