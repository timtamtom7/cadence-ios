import SwiftUI

struct PartnerRadarView: View {
    @State private var partners: [Partner] = []
    @State private var isSearching = false
    @State private var radarRotation: Double = 0
    @State private var showingInvite = false
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Radar visualization
                radarView
                
                // Status
                if isSearching {
                    searchingView
                } else if partners.isEmpty {
                    emptyStateView
                } else {
                    partnersList
                }
                
                Spacer()
                
                // Action button
                Button {
                    isSearching = true
                    simulateSearch()
                } label: {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text(partners.isEmpty ? "Find Focus Partners" : "Search for More")
                    }
                    .font(.headline)
                    .foregroundColor(.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .disabled(isSearching)
            }
            .padding(.top, 24)
        }
        .navigationTitle("Find Partners")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingInvite) {
            InvitePartnerSheet()
        }
    }
    
    private var radarView: some View {
        ZStack {
            // Radar circles
            ForEach(0..<4, id: \.self) { ring in
                Circle()
                    .stroke(Color.appPrimary.opacity(0.2), lineWidth: 1)
                    .frame(width: CGFloat(60 + ring * 50), height: CGFloat(60 + ring * 50))
            }
            
            // Radar sweep
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(Color.appPrimary.opacity(0.5), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(radarRotation))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: radarRotation)
            
            // Center dot
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 16, height: 16)
            
            // Blips for nearby partners
            ForEach(Array(partners.prefix(3).enumerated()), id: \.element.id) { index, partner in
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 12, height: 12)
                    .offset(partnerBlipOffset(index: index))
            }
        }
        .frame(width: 220, height: 220)
        .onAppear {
            radarRotation = 360
        }
    }
    
    private func partnerBlipOffset(index: Int) -> CGSize {
        let angle = Double(index) * 120.0 + radarRotation
        let radius = CGFloat(60 + index * 30)
        let x = radius * cos(angle * .pi / 180)
        let y = radius * sin(angle * .pi / 180)
        return CGSize(width: x, height: y)
    }
    
    private var searchingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.appPrimary)
            
            Text("Searching for nearby focus partners...")
                .font(.subheadline)
                .foregroundColor(Color.appTextSecondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.wave.2")
                .font(.system(size: 48))
                .foregroundColor(Color.appTextTertiary)
            
            Text("No partners yet")
                .font(.headline)
                .foregroundColor(Color.appTextPrimary)
            
            Text("Find someone to focus with.\nStay accountable together.")
                .font(.subheadline)
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var partnersList: some View {
        VStack(spacing: 12) {
            Text("\(partners.count) partner\(partners.count == 1 ? "" : "s") found")
                .font(.caption)
                .foregroundColor(Color.appTextSecondary)
            
            ForEach(partners) { partner in
                PartnerRow(partner: partner) {
                    // Focus with this partner
                }
            }
        }
    }
    
    private func simulateSearch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            partners = Partner.mockPartners
            isSearching = false
        }
    }
}

struct PartnerRow: View {
    let partner: Partner
    let onFocusWith: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.appSurface)
                    .frame(width: 48, height: 48)
                
                Text(partner.avatarInitials)
                    .font(.headline)
                    .foregroundColor(Color.appPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(partner.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appTextPrimary)
                
                HStack(spacing: 8) {
                    Label("\(partner.currentStreak) day streak", systemImage: "flame.fill")
                    Label("\(partner.totalSessions) sessions", systemImage: "timer")
                }
                .font(.caption)
                .foregroundColor(Color.appTextSecondary)
            }
            
            Spacer()
            
            Button(action: onFocusWith) {
                Text("Focus")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.appPrimary.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InvitePartnerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "link")
                        .font(.system(size: 48))
                        .foregroundColor(Color.appPrimary)
                    
                    Text("Share your code")
                        .font(.headline)
                        .foregroundColor(Color.appTextPrimary)
                    
                    Text("Or enter a friend's code below")
                        .font(.subheadline)
                        .foregroundColor(Color.appTextSecondary)
                    
                    TextField("Enter invite code", text: $inviteCode)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .padding(16)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Connect")
                            .font(.headline)
                            .foregroundColor(Color.appBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(inviteCode.isEmpty ? Color.appTextTertiary : Color.appPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(inviteCode.isEmpty)
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Add Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PartnerRadarView()
    }
}
