import SwiftUI

struct MacContentView: View {
    @State private var selectedTab: MacTab = .focus

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                MacTopBar()

                Divider()
                    .background(Color.appSurfaceElevated)

                // Content
                TabView(selection: $selectedTab) {
                    MacFocusSessionView()
                        .tag(MacTab.focus)

                    MacStreakView()
                        .tag(MacTab.streak)

                    MacSettingsView()
                        .tag(MacTab.settings)
                }
                .tabViewStyle(.automatic)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

enum MacTab: String, CaseIterable {
    case focus = "Focus"
    case streak = "Streaks"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .streak: return "flame.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MacTopBar: View {
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Logo
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: 8, height: 8)
                Text("Cadence")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appTextPrimary)
            }

            Spacer()

            // Tab buttons
            HStack(spacing: Spacing.xs) {
                ForEach(MacTab.allCases, id: \.self) { tab in
                    MacTabButton(tab: tab)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Color.appSurface)
    }
}

struct MacTabButton: View {
    let tab: MacTab
    @State private var selectedTab: MacTab = .focus

    var body: some View {
        Button {
            // handled via binding in parent
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13))
                Text(tab.rawValue)
                    .font(.appCaption)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.clear)
            .foregroundStyle(Color.appTextSecondary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MacContentView()
}
