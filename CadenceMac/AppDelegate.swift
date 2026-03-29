import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Cadence")
            button.image?.isTemplate = true
        }

        statusItem?.menu = createMenu()
    }

    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Cadence", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let focusItem = NSMenuItem(title: "Start Focus Session", action: #selector(startFocusSession), keyEquivalent: "f")
        focusItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(focusItem)

        let stopItem = NSMenuItem(title: "Stop Session", action: #selector(stopFocusSession), keyEquivalent: "s")
        stopItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(stopItem)

        menu.addItem(NSMenuItem.separator())

        let statusItem = NSMenuItem(title: "Status: Ready", action: nil, keyEquivalent: "")
        statusItem.tag = 100
        menu.addItem(statusItem)

        menu.addItem(NSMenuItem.separator())

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Cadence", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        return menu
    }

    @objc private func startFocusSession() {
        NotificationCenter.default.post(name: .startFocusSession, object: nil)
    }

    @objc private func stopFocusSession() {
        NotificationCenter.default.post(name: .stopFocusSession, object: nil)
    }

    @objc private func showPreferences() {
        NSApp.sendAction(Selector(("showPreferencesWindow")), to: nil, from: nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
