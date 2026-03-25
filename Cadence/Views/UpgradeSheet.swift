import SwiftUI

/// R9: Subscription upgrade sheet
struct UpgradeSheet: View {
    @Binding var isPresented: Bool
    @State private var selectedTier: FreemiumService.SubscriptionTier = .pro
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.appAccent)

                            Text("Upgrade Your Focus")
                                .font(.appHeading1)
                                .foregroundStyle(Color.appTextPrimary)

                            Text("Unlock unlimited sessions and advanced features")
                                .font(.appBody)
                                .foregroundStyle(Color.appTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)

                        // Tier selector
                        VStack(spacing: 12) {
                            ForEach(FreemiumService.SubscriptionTier.allCases, id: \.self) { tier in
                                TierCard(
                                    tier: tier,
                                    isSelected: selectedTier == tier,
                                    onSelect: { selectedTier = tier }
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Features comparison
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What's Included")
                                .font(.appHeading2)
                                .foregroundStyle(Color.appTextPrimary)

                            FeatureRow(feature: "Focus sessions", free: "2/day", pro: "Unlimited", team: "Unlimited")
                            FeatureRow(feature: "Ambient sounds", free: "5", pro: "15+", team: "15+")
                            FeatureRow(feature: "AI insights", free: "—", pro: "Yes", team: "Yes")
                            FeatureRow(feature: "Calendar sync", free: "—", pro: "Yes", team: "Yes")
                            FeatureRow(feature: "Data export", free: "—", pro: "Yes", team: "Yes")
                            FeatureRow(feature: "Team sessions", free: "—", pro: "—", team: "Yes")
                            FeatureRow(feature: "Team goals", free: "—", pro: "—", team: "Yes")
                        }
                        .padding()
                        .background(Color.appSurface)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // CTA Button
                        Button {
                            purchaseSelectedTier()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(Color.appBackground)
                                } else {
                                    Text("Start \(selectedTier.rawValue)")
                                        .fontWeight(.semibold)
                                    Text(selectedTier.price)
                                        .fontWeight(.regular)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appPrimary)
                            .foregroundStyle(Color.appBackground)
                            .cornerRadius(16)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal)

                        Text("Cancel anytime. Auto-renews monthly.")
                            .font(.caption)
                            .foregroundStyle(Color.appTextTertiary)

                        Spacer(minLength: 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                    .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
    }

    private func purchaseSelectedTier() {
        isLoading = true
        // Simulate purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            FreemiumService.shared.upgrade(to: selectedTier)
            isLoading = false
            isPresented = false
        }
    }
}

struct TierCard: View {
    let tier: FreemiumService.SubscriptionTier
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tier.rawValue)
                            .font(.appHeading2)
                            .foregroundStyle(Color.appTextPrimary)

                        if tier == .pro {
                            Text("Popular")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.appAccent.opacity(0.2))
                                .foregroundStyle(Color.appAccent)
                                .cornerRadius(4)
                        }
                    }

                    Text(tier.price)
                        .font(.appBody)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.appTextTertiary)
            }
            .padding()
            .background(isSelected ? Color.appPrimary.opacity(0.1) : Color.appSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct FeatureRow: View {
    let feature: String
    let free: String
    let pro: String
    let team: String

    var body: some View {
        HStack {
            Text(feature)
                .font(.appBody)
                .foregroundStyle(Color.appTextPrimary)
                .frame(width: 120, alignment: .leading)

            Spacer()

            Text(free)
                .font(.appCaption)
                .foregroundStyle(Color.appTextTertiary)
                .frame(width: 70)

            Text(pro)
                .font(.appCaption)
                .foregroundStyle(pro == "—" ? Color.appTextTertiary : Color.appPrimary)
                .frame(width: 70)

            Text(team)
                .font(.appCaption)
                .foregroundStyle(Color.appAccent)
                .frame(width: 70)
        }
    }
}

#Preview {
    UpgradeSheet(isPresented: .constant(true))
}
