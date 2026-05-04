import Cocoa

// EN: Application entry point — minimal lifecycle hooks for a SpriteKit macOS app.
// RU: Точка входа приложения — минимальные хуки жизненного цикла для macOS-приложения на SpriteKit.

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // EN: Follow system light/dark (avoid inheriting a stale fixed appearance at launch).
        // RU: Следовать системной светлой/тёмной теме (не застывать на фиксированной appearance при запуске).
        NSApp.appearance = nil
    }

    func applicationWillTerminate(_ aNotification: Notification) {}
}
