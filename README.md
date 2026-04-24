# IVFToday

Local-first iPhone app for IVF patients during the highest-risk execution windows of treatment.

## Project Status

This repository now includes a Phase 7 local-first prototype for the app:
- ✅ Basic project structure following the development blueprint
- ✅ iOS app shell with SwiftUI tab navigation
- ✅ Manual demo flow for `Today`, `Edit`, `Changes`, and `Inventory`
- ✅ Image and PDF import entry flow
- ✅ Local Vision OCR for screenshots / photos
- ✅ Local PDF text extraction for text-based PDFs
- ✅ Editable extracted-text review with structured apply summary
- ✅ Rule-based protocol parsing for common IVF medication lines
- ✅ Rule-based appointment parsing for common monitoring/lab/retrieval lines
- ✅ SwiftData-backed local persistence for workflow state
- ✅ Appointment-aware semantic diff for medications and appointments
- ✅ Protocol/document history browsing with persisted local revisions
- ✅ Daily task engine combining active medications + appointments
- ✅ Task ordering by urgency/risk + scheduled time
- ✅ High-risk task emphasis and double-confirm completion in Today UI
- ✅ Local completion logging persisted in app state snapshot
- ✅ Explicit inventory days-left estimation in Inventory UI
- ✅ Low-stock local notification scheduling service (permission + schedule path)
- ✅ Improved empty states for Today / Import / Inventory
- ✅ First-run walkthrough (one-time local presentation)
- ✅ Visible safety/disclaimer copy in key workflows
- ✅ Import extraction cache to avoid repeated OCR/PDF work on same source
- ✅ App icon assets bundled for simulator/device builds
- ✅ App Store metadata draft (`docs/APP_STORE_COPY.md`)
- ✅ XcodeGen configuration for reproducible project generation
- ✅ In-memory demo state and sample data for immediate demonstration
- ✅ Unit tests for parsing, diff, and inventory alert logic
- ✅ Formalized `Settings` tab with onboarding replay, appearance controls, and demo reset
- ✅ UI tests covering import entry, compare-with-yesterday, critical completion confirm flow, and low-inventory warning flow
- ✅ Expanded parsing coverage for IVF shorthand (`ET`/`ER`/`U/S`, `QHS`, `EOD`, `CD12`)
- ✅ Extended inventory forecast to conservative 7-day projected low-stock detection
- ✅ Hardened low-stock notifications with severity-aware title and schedule delay strategy

Current scope:
- Manual protocol editing remains available as a fallback workflow
- Imported text can be reviewed and partially mapped into structured medications
- Imported text can be reviewed and partially mapped into structured medications and appointments
- Change review now includes medication and appointment changes from persisted protocol revisions
- Inventory alerts are computed from the current workflow state
- OCR / PDF extraction are local-only and rule-based parsing is intentionally limited
- Legacy JSON snapshot is retained only as a migration source into SwiftData

Current target: 1.0 candidate complete (awaiting product-owner sign-off).

## Getting Started

### Prerequisites
- **Full Xcode** (required to open the project, build, and run in iOS Simulator)
- **XcodeGen** (installed via Homebrew; only needed to generate the Xcode project file)

### Generate Xcode Project
```bash
# Install XcodeGen if not already installed
brew install xcodegen

# Generate the Xcode project
xcodegen generate
```

### Build and Run
1. Open `IVFToday.xcodeproj` in Xcode
2. Select an iOS Simulator (iOS 17.0+ required)
3. Build and run the app

The app will display a manual demo flow with:
- `Today` screen showing the current cycle, today's tasks, and protocol snapshot
- `Import Instructions` flow for screenshot/PDF import, extraction review, and apply
- `Edit` screen for manual protocol edits
- `Changes` screen for protocol diffs
- `Inventory` screen for on-hand medication tracking and alerts

This is a local-first prototype. OCR and PDF extraction work locally, parsing is still rule-based, and state is now persisted locally through a SwiftData-backed snapshot store.

### Run Tests
```bash
xcodegen generate
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project IVFToday.xcodeproj \
  -scheme IVFToday \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug \
  test
```

## Project Structure

Following the blueprint defined in DEVELOPMENT_BLUEPRINT.md:

- **App**: Application entry point
- **Domain**: Core data models (`IVFCase`, `ProtocolDocument`) and enums
- **Features**: Screen-level components (`TodayHomeView`)
- **Shared**: Reusable utilities (`DemoDataFactory`)

## Development Phases

### Phase 7: Polish for First Paid Release (Current)
- Today / Edit / Changes / Inventory are available as a manual demonstration flow
- Import / Preview / Extracted Text Review flow is available for screenshots and PDFs
- Today tasks are generated from both active medications and appointments
- Task completion is logged locally with high-risk double confirmation
- State is persisted with a SwiftData-backed local snapshot
- First-run walkthrough and safety notices are integrated in-app
- Empty states and import/inventory UX polish are included for demo readiness

### Mainline Milestone Status (2026-04-16)
- ✅ SwiftData persistence
- ✅ Complete diff/history
- ✅ Settings/Onboarding formalization
- ✅ UI tests

### Release Hardening Status (2026-04-16)
- ✅ Expand parsing coverage for more IVF protocol text formats
- ✅ Expand inventory forecasting to longer shortage timeline
- ✅ Harden notification strategy for high-risk and low-stock reminders

### Next: 1.0 Candidate Closure
- Execute full manual QA checklist scenarios on simulator/device
- Fix any high-severity findings from manual runs
- Freeze release notes and App Store submission checklist

### 1.0 Candidate Closure
- ✅ Development scope complete for local-first 1.0 candidate
- ✅ Build + unit/UI automated verification passing
- ✅ Closure checklist and evidence recorded in `docs/RELEASE_1_0_CLOSURE.md`

## Fresh Checkout Verification

To verify this repository works from a fresh checkout:

```bash
git clone <repository-url> IVFToday-fresh
cd IVFToday-fresh
brew install xcodegen
xcodegen generate
```

> **Note**: `xcodegen generate` only creates the `.xcodeproj` file. To **open, build, and run the app in iOS Simulator**, you must have **Full Xcode** installed. Xcode Command Line Tools alone are **not sufficient** for running the simulator.

To verify the current prototype more fully from a fresh checkout:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project IVFToday.xcodeproj \
  -scheme IVFToday \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug \
  test
```

## App Store URLs

This repo now includes a minimal static site for `Marketing URL` and `Support URL`
submission fields under [docs/site/README.md](/Users/yys/Documents/projects/LittleGoals/IVFToday/docs/site/README.md).
It is intended for a free GitHub Pages deployment path.
