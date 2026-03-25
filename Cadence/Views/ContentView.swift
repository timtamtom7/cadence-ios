import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .focus

    enum Tab: String, CaseIterable {
        case focus = "Focus"
        case leaderboard = "Board"
        case team = "Team"
        case achievements = "Badges"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .focus: return "timer"
            case .leaderboard: return "chart.bar.fill"
            case .team: return "person.3.fill"
            case .achievements: return "medal.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                FocusTimerView()
                    .tag(Tab.focus)
                    .toolbar(.hidden, for: .tabBar)

                LeaderboardView()
                    .tag(Tab.leaderboard)
                    .toolbar(.hidden, for: .tabBar)

                TeamView()
                    .tag(Tab.team)
                    .toolbar(.hidden, for: .tabBar)

                AchievementsView()
                    .tag(Tab.achievements)
                    .toolbar(.hidden, for: .tabBar)

                SettingsView()
                    .tag(Tab.settings)
                    .toolbar(.hidden, for: .tabBar)
            }

            GlassTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            configureTabBarAppearance()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
