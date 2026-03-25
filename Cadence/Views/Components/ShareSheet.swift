import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?

    init(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SessionShareButton: View {
    let session: Session
    let streak: Int
    @State private var showingShare = false

    var body: some View {
        Button {
            showingShare = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.title3)
                .foregroundStyle(Color.appPrimary)
        }
        .sheet(isPresented: $showingShare) {
            ShareSheet(items: [ExportService.shared.shareText(session: session, streak: streak)])
        }
    }
}

struct WeeklyShareButton: View {
    let summary: WeeklySummary
    @State private var showingShare = false

    var body: some View {
        Button {
            showingShare = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.title3)
                .foregroundStyle(Color.appPrimary)
        }
        .sheet(isPresented: $showingShare) {
            ShareSheet(items: [ExportService.shared.shareText(weeklySummary: summary)])
        }
    }
}

#Preview {
    ShareSheet(items: ["Test share text"])
        .preferredColorScheme(.dark)
}
