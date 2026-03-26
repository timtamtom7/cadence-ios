import SwiftUI

/// Sheet for adding notes and tags to a completed focus session
struct SessionNoteSheet: View {
    let session: Session
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var notes: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var isSaving = false
    @State private var hasSaved = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Session summary header
                        sessionSummaryHeader

                        // Notes text field
                        notesSection

                        // Tags section
                        tagsSection

                        // Save button
                        saveButton
                    }
                    .padding(Spacing.md)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.appPrimary)
                }
            }
            .onAppear {
                loadExistingNote()
            }
        }
    }

    // MARK: - Session Summary

    private var sessionSummaryHeader: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 56, height: 56)
                VStack(spacing: 0) {
                    Text("\(session.durationMinutes)")
                        .font(.appHeading2)
                        .foregroundStyle(Color.appPrimary)
                    Text("min")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appPrimary)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Focus Session")
                    .font(.appHeading2)
                    .foregroundStyle(Color.appTextPrimary)

                Text(session.completedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)

                HStack(spacing: Spacing.xs) {
                    scoreBadge
                    if !session.soundIds.isEmpty {
                        soundBadge
                    }
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var scoreBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
            Text("\(session.focusScore)")
                .font(.system(size: 11))
        }
        .foregroundStyle(scoreColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(scoreColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var soundBadge: some View {
        HStack(spacing: 2) {
            if let firstSound = session.soundIds.first,
               let sound = Sound.allSounds.first(where: { $0.id == firstSound }) {
                Image(systemName: sound.icon)
                    .font(.system(size: 10))
                Text(sound.name)
                    .font(.system(size: 11))
            }
        }
        .foregroundStyle(Color.appTextSecondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.appSurfaceElevated)
        .clipShape(Capsule())
    }

    private var scoreColor: Color {
        switch session.focusScore {
        case 80...100: return Color.appAccent
        case 60..<80: return Color.appPrimary
        default: return Color.appWarning
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("What did you work on?")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            TextEditor(text: $notes)
                .font(.appBody)
                .foregroundStyle(Color.appTextPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(Spacing.sm)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    Group {
                        if notes.isEmpty {
                            Text("e.g. Worked on the quarterly report, reviewed design mockups...")
                                .font(.appBody)
                                .foregroundStyle(Color.appTextTertiary)
                                .padding(.leading, Spacing.md)
                                .padding(.top, Spacing.md)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
                .accessibilityLabel("Session notes")
                .accessibilityHint("Describe what you worked on during this focus session")

            Text("\(notes.count) characters")
                .font(.system(size: 11))
                .foregroundStyle(Color.appTextTertiary)
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Tags")
                .font(.appHeading2)
                .foregroundStyle(Color.appTextPrimary)

            Text("Categorize this session to find it later")
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)

            FlowLayout(spacing: Spacing.xs) {
                ForEach(SessionTag.allCases) { tag in
                    tagChip(tag)
                }
            }
        }
    }

    private func tagChip(_ tag: SessionTag) -> some View {
        let isSelected = selectedTags.contains(tag.rawValue)
        return Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                if isSelected {
                    selectedTags.remove(tag.rawValue)
                } else {
                    selectedTags.insert(tag.rawValue)
                }
            }
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: tag.icon)
                    .font(.system(size: 11))
                Text(tag.rawValue)
                    .font(.appCaption)
            }
            .foregroundStyle(isSelected ? Color.appBackground : Color.appTextSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? Color.appPrimary : Color.appSurface)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.appSurfaceElevated, lineWidth: 1)
            )
        }
        .accessibilityLabel("\(tag.rawValue), \(isSelected ? "selected" : "not selected")")
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveNote()
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(Color.appBackground)
                } else if hasSaved {
                    Image(systemName: "checkmark")
                } else {
                    Text("Save Note")
                }
            }
            .font(.appHeading2)
            .foregroundStyle(hasSaved ? Color.appBackground : Color.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(hasSaved ? Color.appSuccess : Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isSaving || hasSaved)
    }

    // MARK: - Helpers

    private func loadExistingNote() {
        Task {
            if let existing = await DatabaseService.shared.loadSessionNote(for: session.id) {
                await MainActor.run {
                    notes = existing.notes
                    selectedTags = Set(existing.tags)
                }
            }
        }
    }

    private func saveNote() {
        isSaving = true
        Task {
            let note = SessionNote(
                sessionId: session.id,
                notes: notes,
                tags: Array(selectedTags)
            )
            await DatabaseService.shared.saveSessionNote(note)
            await MainActor.run {
                isSaving = false
                hasSaved = true
            }
            try? await Task.sleep(nanoseconds: 600_000_000)
            onSave()
            dismiss()
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    SessionNoteSheet(
        session: Session(duration: 25 * 60, focusScore: 85),
        onSave: {}
    )
    .preferredColorScheme(.dark)
}
