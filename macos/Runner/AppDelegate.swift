import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    // Apply after AppKit restores any frame saved by an earlier app version.
    DispatchQueue.main.async { [weak self] in
      (self?.mainFlutterWindow as? MainFlutterWindow)?.configureDesktopLayout()
    }

    // Load the bundled icon directly so the Dock does not keep an older
    // Launch Services icon when flutter run rebuilds the same app bundle.
    if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
       let icon = NSImage(contentsOf: iconURL) {
      NSApp.applicationIconImage = icon
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
