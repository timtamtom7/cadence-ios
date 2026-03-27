import SwiftUI

// MARK: - Theme.swift
// iOS 26 Liquid Glass Design System for Cadence

// MARK: - Corner Radius Tokens

enum CornerRadius {
    /// 8pt — tight elements, chips, small badges
    static let small: CGFloat = 8
    /// 12pt — cards, list items, buttons
    static let medium: CGFloat = 12
    /// 16pt — large cards, section containers
    static let large: CGFloat = 16
    /// 20pt — major containers, sheet backgrounds
    static let xl: CGFloat = 20
    /// 24pt — pill shapes, floating elements
    static let pill: CGFloat = 24
}

// MARK: - Haptic Feedback

enum Theme {
    /// Trigger a light haptic for selection/choice changes
    static func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Trigger a medium haptic for significant interactions
    static func hapticMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Trigger a soft haptic for gentle confirmations
    static func hapticSoft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    /// Trigger notification feedback for success/warning/error
    static func hapticNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    /// Trigger selection changed feedback
    static func hapticSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Button Styles

struct AxiomPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appHeading2)
            .foregroundStyle(Color.appBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                Group {
                    if isEnabled {
                        Color.appPrimary
                    } else {
                        Color.appTextTertiary
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct AxiomSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBody)
            .foregroundStyle(isEnabled ? Color.appPrimary : Color.appTextTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(isEnabled ? Color.appPrimary.opacity(0.3) : Color.appTextTertiary.opacity(0.2), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct AxiomDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBody)
            .foregroundStyle(Color.appError)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(Color.appError.opacity(0.3), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct AxiomGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBody)
            .foregroundStyle(Color.appTextSecondary)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Text Tertiary/Quaternary

extension Color {
    /// Primary text — highest contrast, main content
    static let textPrimary = Color.appTextPrimary
    /// Secondary text — supporting content
    static let textSecondary = Color.appTextSecondary
    /// Tertiary text — hints, timestamps, metadata (45% white equivalent)
    static let textTertiary = Color.appTextTertiary
    /// Quaternary text — disabled, placeholder (30% white equivalent)
    static let textQuaternary = Color(hex: "2A5A58")
}

// MARK: - Background Depth Levels

extension Color {
    /// Depth 0 — Base background, true dark (#0D1B1E)
    static let backgroundBase = Color.appBackground
    /// Depth 1 — Elevated surfaces, cards (#142328)
    static let backgroundElevated = Color.appSurface
    /// Depth 2 — Higher elevated surfaces, modals (#1A2E33)
    static let backgroundElevated2 = Color.appSurfaceElevated
    /// Depth 3 — Floating elements, tab bar, sheets
    static let backgroundFloating = Color(hex: "1E353B")
}

// MARK: - Separator Color

extension Color {
    /// Separator — thin lines between content (Light: 29% black, Dark: 20% white)
    static let separator = Color(hex: "2A3538")
    static let separatorLight = Color(hex: "000000").opacity(0.29)
}

// MARK: - Glass Material

extension View {
    /// Liquid Glass background — translucent with blur
    func glassBackground() -> some View {
        self
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .stroke(Color.appPrimary.opacity(0.1), lineWidth: 1)
            )
    }

    /// Glass surface for cards
    func glassCard() -> some View {
        self
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(Color.appPrimary.opacity(0.08), lineWidth: 1)
            )
    }
}
