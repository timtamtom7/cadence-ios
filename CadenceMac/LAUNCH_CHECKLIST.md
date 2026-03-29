# Cadence for Mac — Launch Checklist

## Pre-Launch ✅

### App Store Assets
- [ ] App icon (1024x1024 for App Store, various sizes for macOS)
- [ ] Screenshots (6 screenshots, 2560x1600 @2x for Mac)
- [ ] App Store description (uploaded to App Store Connect)
- [ ] Keywords (100 char limit)
- [ ] Privacy policy URL (required)
- [ ] Support URL
- [ ] Marketing URL (optional)

### Code & Functionality
- [x] Notification permission request on first launch
- [x] Smart notification scheduling (focus reminders, streak alerts)
- [x] Menu bar integration working
- [x] Window management (hidden title bar style)
- [x] Focus session flow end-to-end
- [x] Streak tracking and persistence
- [x] Settings panel with all toggles
- [x] Export data functionality
- [x] Build succeeds (CODE_SIGN_IDENTITY="-")

### Identity & Branding
- [x] Bundle ID: `com.cadence.macos`
- [x] App name: "Cadence" (Display name)
- [x] Category: Productivity
- [x] Age rating: 4+
- [x] Deep-sea aesthetic (teal on dark)
- [x] Tagline: "Find your flow."

---

## App Store Connect Setup

### New App Entry
- [ ] Create new app in App Store Connect
- [ ] Select platform: macOS
- [ ] Name: Cadence
- [ ] Primary language: English
- [ ] Bundle ID: com.cadence.macos
- [ ] SKU: cadence-macos

### Pricing & Availability
- [ ] Set pricing tier (Free / $4.99 USD)
- [ ] Select available territories
- [ ] Configure pre-orders (if applicable)

### App Information
- [ ] Privacy policy URL
- [ ] Category selection
- [ ] Age rating questionnaire

### Version Setup
- [ ] Create new version (1.0.0)
- [ ] Upload App Store assets
- [ ] Add localized metadata
- [ ] Set release date or manual release

---

## Pre-Submission Review

### Entitlements
- [ ] App Sandbox: Enabled
- [ ] Hardened Runtime: Enabled (for notarization)
- [ ] Network: None required (offline-first)

### Build Verification
```bash
cd /Users/mauriello/.openclaw/workspace/projects/cadence-ios-code
xcodegen generate
xcodebuild -scheme CadenceMac -configuration Release \
  -destination 'platform=macOS,arch=arm64' build \
  CODE_SIGN_IDENTITY="-" 2>&1 | grep -E "error:|BUILD"
```

### Notarization (Required for distribution)
```bash
# Create a signed dmg or zip for notarization
# Submit to Apple for notarization
xcrun notarytool submit --apple-id <email> --password <app-password> <artifact>
```

---

## Launch Day

### Marketing
- [ ] Tweet / announcement
- [ ] Product Hunt submission
- [ ] Update relevant directories (AlternativeTo, etc.)

### Monitor
- [ ] App Store Connect sales dashboard
- [ ] Any crash reports from users
- [ ] Feedback email/contact ready

---

## Post-Launch

### Week 1
- [ ] Monitor ratings and reviews
- [ ] Respond to early feedback
- [ ] Fix any reported issues quickly

### Week 2-4
- [ ] Gather user feedback
- [ ] Plan version 1.1 improvements
- [ ] Consider additional platforms (iOS companion?)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | TBD | Initial release |

---

## Contacts

- **Developer:** Tommaso Mauriello
- **Support:** (set up support email)
- **Website:** (optional)
