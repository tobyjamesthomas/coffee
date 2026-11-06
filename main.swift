import AppKit
import IOKit.pwr_mgt

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    // Power management assertions held while caffeinated. macOS releases them
    // automatically if this app quits or crashes.
    private var assertionIDs: [IOPMAssertionID] = []

    private var isAwake: Bool { !assertionIDs.isEmpty }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updateIcon()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopStayingAwake()
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let isRightClick = NSApp.currentEvent?.type == .rightMouseUp
            || NSApp.currentEvent?.modifierFlags.contains(.control) == true
        if isRightClick {
            showMenu()
        } else {
            toggle()
        }
    }

    private func toggle() {
        if isAwake {
            stopStayingAwake()
        } else {
            startStayingAwake()
        }
        updateIcon()
    }

    private func startStayingAwake() {
        let reason = "Coffee is keeping your Mac awake" as CFString
        // Equivalent to `caffeinate -d -i`: keep the display awake and prevent idle sleep.
        let types = [kIOPMAssertionTypePreventUserIdleDisplaySleep, kIOPMAssertionTypePreventUserIdleSystemSleep]
        for type in types {
            var id = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithName(type as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), reason, &id)
            if result == kIOReturnSuccess {
                assertionIDs.append(id)
            } else {
                NSLog("Failed to create \(type) assertion: \(result)")
            }
        }
    }

    private func stopStayingAwake() {
        assertionIDs.forEach { IOPMAssertionRelease($0) }
        assertionIDs.removeAll()
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let symbolName = isAwake ? "cup.and.saucer.fill" : "cup.and.saucer"
        let description = isAwake ? "Stay Awake is on" : "Stay Awake is off"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)
        image?.isTemplate = true
        button.image = image
        button.toolTip = description
    }

    private func showMenu() {
        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: "Stay Awake", action: #selector(menuToggle), keyEquivalent: "")
        toggleItem.state = isAwake ? .on : .off
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Coffee", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Detach so the next left-click toggles instead of opening the menu.
        statusItem.menu = nil
    }

    @objc private func menuToggle() {
        toggle()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
