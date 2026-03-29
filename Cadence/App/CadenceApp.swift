import SwiftUI

@main
struct CadenceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .task {
                    await initializeNotifications()
                }
        }
    }

    private func initializeNotifications() async {
        let service = NotificationService.shared

        // Register notification categories
        service.registerCategories()

        // Check authorization
        await service.checkAuthorizationStatus()

        // Request authorization if needed
        if service.authorizationStatus == .notDetermined {
            _ = await service.requestAuthorization()
        }

        // Schedule weekly digest if enabled
        if service.isAuthorized {
            let profile = await DatabaseService.shared.loadUserProfile()
            let stats = await DatabaseService.shared.loadStats()
            await service.scheduleWeeklyDigest(profile: profile, stats: stats)
        }
    }
}
