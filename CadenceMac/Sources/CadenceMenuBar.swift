import SwiftUI
import AppKit

// MARK: - Menu Bar Controller

@MainActor
class CadenceMenuBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Cadence")
            button.image?.isTemplate = true
        }

        let menu = buildMenu()
        menu.delegate = self
        statusItem?.menu = menu
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        // Title
        let titleItem = NSMenuItem(title: "Cadence", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        // Quick start session
        let focusItem = NSMenuItem(title: "Start 25 min Focus", action: #selector(quickStartFocus), keyEquivalent: "f")
        focusItem.target = self
        menu.addItem(focusItem)

        menu.addItem(NSMenuItem.separator())

        // Open main window
        let openItem = NSMenuItem(title: "Open Cadence", action: #selector(openMainWindow), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func quickStartFocus() {
        let service = FocusService()
        service.start(durationMinutes: 25)
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
