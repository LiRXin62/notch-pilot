import AppKit
import Foundation

if ProcessInfo.processInfo.environment["NOTCH_PILOT_RENDER_PREVIEW"] == "1" {
    PreviewRenderer.run()
    exit(0)
} else if ProcessInfo.processInfo.environment["NOTCH_PILOT_SMOKE_TEST"] == "1" {
    InteractionSmokeTest.run()
    exit(0)
} else {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
