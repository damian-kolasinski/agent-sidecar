import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    override init() {
        super.init()
        registerURLHandler()
    }

    var onOpenURL: ((URL) -> Void)? {
        didSet {
            guard let onOpenURL, let pendingURL else { return }
            self.pendingURL = nil
            onOpenURL(pendingURL)
        }
    }

    private var pendingURL: URL?

    func applicationWillFinishLaunching(_ notification: Notification) {
        registerURLHandler()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerURLHandler()
    }

    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else {
            return
        }
        handleIncomingURL(url)
    }

    func handleIncomingURL(_ url: URL) {
        if let onOpenURL {
            onOpenURL(url)
        } else {
            pendingURL = url
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func registerURLHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
}
