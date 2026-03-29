import SwiftUI

@main
struct CadenceMacApp: App {
    init() {
        // Request notification permission on first launch
        Task {
            let granted = await MacNotificationService.shared.requestAuthorization()
            if granted {
                let profile = await DatabaseService.shared.loadUserProfile()
                await MacNotificationService.shared.scheduleStreakReminderIfNeeded(username: profile.username)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MacContentView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
