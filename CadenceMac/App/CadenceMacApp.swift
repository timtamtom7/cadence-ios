import SwiftUI

@main
struct CadenceMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 320, idealWidth: 400, minHeight: 300, idealHeight: 400)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandMenu("Focus") {
                Button("Start Focus Session") {
                    NotificationCenter.default.post(name: .startFocusSession, object: nil)
                }
                .keyboardShortcut("F", modifiers: [.command, .shift])

                Button("Stop Session") {
                    NotificationCenter.default.post(name: .stopFocusSession, object: nil)
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])

                Divider()

                Button("Preferences...") {
                    NSApp.sendAction(Selector(("showPreferencesWindow")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandMenu("Window") {
                Button("Minimize") {
                    NSApp.keyWindow?.miniaturize(nil)
                }
                .keyboardShortcut("m", modifiers: .command)

                Button("Close") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut("w", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let startFocusSession = Notification.Name("startFocusSession")
    static let stopFocusSession = Notification.Name("stopFocusSession")
}
