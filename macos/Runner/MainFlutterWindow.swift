import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    configureDesktopLayout()
  }

  func configureDesktopLayout() {
    // Windowed desktop play uses a 4:3 content area (excluding title bar).
    let workArea = (screen ?? NSScreen.main)?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1024, height: 800)
    let titleHeight = frame.height - contentRect(forFrameRect: frame).height
    let availableWidth = min(workArea.width, (workArea.height - titleHeight) * 4 / 3)
    let initialWidth = min(1024, availableWidth)
    let minimumWidth = min(960, initialWidth)
    contentMinSize = NSSize(width: minimumWidth, height: minimumWidth * 3 / 4)
    contentAspectRatio = NSSize(width: 4, height: 3)
    setContentSize(NSSize(width: initialWidth, height: initialWidth * 3 / 4))
    center()
  }
}
