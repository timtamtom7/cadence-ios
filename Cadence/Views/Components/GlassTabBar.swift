import SwiftUI

struct GlassTabBar: View {
    @Binding var selectedTab: ContentView.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.appPrimary.opacity(0.1), lineWidth: 1)
                )
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    private func tabButton(for tab: ContentView.Tab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.appTextSecondary)

                Text(tab.rawValue)
                    .font(.appCaption2)
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack {
            Spacer()
            GlassTabBar(selectedTab: .constant(.focus))
        }
    }
    .preferredColorScheme(.dark)
}
