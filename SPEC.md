# Cadence — Focus Session App

## 1. Concept & Vision

Cadence is an AI-powered focus companion that turns deep work into a shared ritual. It pairs you with a focus partner, surrounds you with ambient sounds tuned to your task, and tracks your streaks so consistency becomes identity. It feels like a calm command center for your attention — not a productivity guilt machine, but a warm invitation to be present.

---

## 2. Design Language

### Aesthetic Direction
**Deep-sea focus sanctuary.** The palette evokes a calm, dark ocean where focus blooms like bioluminescence. Teal glows pulse against deep darkness. The UI breathes slowly — no visual noise, only what matters. Glass-like surfaces float above the abyss.

### Color Palette

| Role | Hex |
|------|-----|
| Background | #0D1B1E |
| Surface | #142328 |
| Surface Elevated | #1A2E33 |
| Primary | #00D4AA |
| Accent | #00F5CC |
| Text Primary | #E8F7F3 |
| Text Secondary | #7AAEAA |
| Text Tertiary | #4A7A78 |
| Error | #FF6B6B |
| Success | #00D4AA |
| Warning | #FFD93D |

### Typography

| Role | Font | Weight | Size |
|------|------|--------|------|
| Display | SF Pro Display | Bold | 34pt |
| Heading 1 | SF Pro Display | Semibold | 28pt |
| Heading 2 | SF Pro Text | Medium | 20pt |
| Body | SF Pro Text | Regular | 17pt |
| Caption | SF Pro Text | Regular | 13pt |
| Mono | SF Mono | Regular | 15pt |

### Spacing System (8pt Grid)

| Name | Value |
|------|-------|
| xxs | 4pt |
| xs | 8pt |
| sm | 12pt |
| md | 16pt |
| lg | 24pt |
| xl | 32pt |
| xxl | 48pt |

### Motion Philosophy
- Screen transitions: 350ms easeInOut
- Card appear: 200ms spring(0.7)
- Button press: 100ms easeOut
- Sheet present: 400ms spring(0.8)
- Breathing orb (focus indicator): 4000ms easeInOut repeating
- Timer pulse: 1500ms easeInOut repeating

### Visual Assets
- SF Symbols exclusively (no custom icon imports)
- Programmatic app icon via SwiftUI shapes
- No photography or illustrations in R1

---

## 3. Layout & Structure

### Navigation
- **Tab-based** with 4 tabs: Focus, Leaderboard, Sounds, Settings
- Focus tab is the primary/home tab
- Tab bar uses glass/blur aesthetic over content

### Screen Hierarchy
```
TabView
├── Focus (FocusTimerView)
│   ├── Session Setup
│   ├── Active Session
│   └── Session Complete (sheet)
├── Leaderboard (LeaderboardView)
│   └── Partner detail (sheet)
├── Sounds (SoundPickerView)
│   └── Sound mixing controls
└── Settings (SettingsView)
    ├── Profile
    ├── Notifications
    └── About
```

### Responsive
- iPhone only for R1 (iPad TBD)
- Safe area respected on all edges
- Dynamic Type supported on all text

---

## 4. Features & Interactions

### Focus Timer
- Preset durations: 15, 25, 45, 60 minutes
- Custom duration picker
- Circular breathing orb animates during session
- Tap to pause/resume
- Cancel with confirmation dialog
- Background timer support (notification on completion)

### Session Complete
- Animated success state
- Duration + focus score
- Streak update
- Share achievement button
- "Start Next" or "Done"

### Partner Matching (Simulated in R1)
- Partner radar shows "nearby focus partners" (mock data)
- Partner status: focusing, idle, available
- Partner name + current session type
- R1: static/mock data only

### Ambient Sounds
- Sound categories: Rain, Forest, Ocean, Cafe, Fire, White Noise
- Individual volume sliders per sound (mix up to 3)
- Sounds persist across app foregrounding
- R1: bundled audio files or silent placeholders

### Leaderboard
- Weekly focus time ranking
- Mock users + current user
- Rank, name, focus minutes, streak
- Animated rank changes

### Achievements (R1 — displayed in Settings)
- First Focus (complete first session)
- Week Warrior (7-day streak)
- Night Owl (focus after 10pm)
- Marathoner (60-min session)
- Social Butterfly (5 partner sessions)

### Streaks
- Daily streak counter on Focus screen
- Streak preserved in UserDefaults
- Streak breaks reset to 0

### Settings
- Username (editable)
- Daily focus goal (minutes)
- Notification toggle
- Sound preference persistence
- App version

---

## 5. Component Inventory

### BreathingOrb
- Animated circle that pulses at ~4s interval
- Color: Primary (#00D4AA) with glow effect
- Scales between 0.85 and 1.0
- Label inside: MM:SS countdown

### SessionCard
- Surface background with rounded corners (16pt)
- Duration, partner count, sound indicator
- Tap to select/prepare

### LeaderboardRow
- Rank number, avatar circle, name, minutes, streak fire icon
- Top 3 get gold/silver/bronze accent
- Current user highlighted

### SoundTile
- Icon (SF Symbol), name, volume slider
- Active state: accent border glow
- Inactive: muted text/icon

### AchievementBadge
- Icon, title, description, earned/locked state
- Earned: full color + glow
- Locked: grayscale + opacity 0.4

### GlassTabBar
- Translucent surface (#142328 @ 70% opacity)
- Blur effect behind
- SF Symbol icons
- Selected: Primary color, unselected: Text Secondary

---

## 6. Technical Approach

### Stack
- **SwiftUI** (iOS 26 target)
- **XcodeGen** for project generation
- **UserDefaults** for R1 persistence (upgrade to SQLite later)
- **AVFoundation** for ambient sounds
- **UserNotifications** for background timer alerts

### Architecture: MVVM + Services

```
Views (SwiftUI)
    ↓ binds to
ViewModels (@Observable)
    ↓ calls
Services (DatabaseService, FocusService, SoundService)
    ↓ uses
Models (Session, Sound, Achievement, Partner, User)
```

### Models

```swift
struct Session: Identifiable, Codable {
    let id: UUID
    let duration: Int // seconds
    let completedAt: Date
    let soundIds: [String]
    let partnerId: UUID?
    let focusScore: Int // 0-100
}

struct Sound: Identifiable {
    let id: String
    let name: String
    let icon: String // SF Symbol
    let category: SoundCategory
    var volume: Double
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    var isEarned: Bool
    let earnedAt: Date?
}

struct Partner: Identifiable {
    let id: UUID
    let name: String
    let status: PartnerStatus
    let currentSession: String?
    let streak: Int
}

enum PartnerStatus: String, Codable {
    case focusing, idle, available
}

enum SoundCategory: String, Codable {
    case nature, ambient, noise
}
```

### Services

- **DatabaseService**: UserDefaults wrapper for sessions, achievements, user profile
- **FocusService**: Timer management, streak calculation, focus score algorithm
- **SoundService**: Audio playback management, volume mixing

### Data Persistence (R1)
- `UserDefaults` keys: `sessions`, `achievements`, `user`, `streak`, `dailyGoal`
- Codable conformance for all persisted models

### Error Handling
- All async operations wrapped in do-catch
- User-facing errors use Alert or inline error views
- No force unwraps anywhere

### Accessibility
- All images have accessibility labels
- Dynamic Type on all text
- Reduce motion respected for animations
- VoiceOver labels on all interactive elements
