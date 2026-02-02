import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // 先设置窗口样式
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.isMovableByWindowBackground = true
    self.styleMask.insert(.fullSizeContentView)

    // 延迟隐藏按钮，确保窗口已完全初始化
    DispatchQueue.main.async {
      self.standardWindowButton(.closeButton)?.isHidden = true
      self.standardWindowButton(.miniaturizeButton)?.isHidden = true
      self.standardWindowButton(.zoomButton)?.isHidden = true
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
