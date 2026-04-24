# IVFToday Development Blueprint

## 1. Product Definition

### 1.1 Product Positioning

`IVFToday` is a local-first iPhone app for IVF patients during the highest-risk execution windows of treatment.

It does not try to manage the entire fertility journey.

It focuses on one narrow, expensive problem:

> Turn changing clinic instructions into a clear daily action list, show what changed since yesterday, and warn before medications run out.

### 1.2 MVP Promise

Within a few seconds, the user should be able to:

1. import a clinic screenshot, PDF, or photo
2. see what changed since the last instruction
3. see exactly what to do today
4. know whether a medication will run out soon

### 1.3 Product Constraints

- iPhone-first
- local-only data processing
- no backend
- no cloud dependency
- no clinic integration in MVP
- no AI server calls in MVP
- private by default

### 1.4 Technical Stack

- UI: `SwiftUI`
- Persistence: `SwiftData`
- OCR: `Vision`
- PDF parsing: `PDFKit`
- Notifications: `UserNotifications`
- File import: `PhotosPicker`, `FileImporter`
- Local search/indexing: app-managed only
- Export/share: `ShareLink`, local PDF/text export

## 2. Project Structure Tree

```text
IVFToday/
├── DEVELOPMENT_BLUEPRINT.md
├── IVFToday.xcodeproj
├── IVFToday/
│   ├── App/
│   │   ├── IVFTodayApp.swift
│   │   ├── AppEnvironment.swift
│   │   ├── AppRouter.swift
│   │   └── AppAppearance.swift
│   ├── Domain/
│   │   ├── Models/
│   │   │   ├── IVFCase.swift
│   │   │   ├── ProtocolDocument.swift
│   │   │   ├── ParsedInstruction.swift
│   │   │   ├── MedicationPlan.swift
│   │   │   ├── MedicationDose.swift
│   │   │   ├── AppointmentItem.swift
│   │   │   ├── InventoryItem.swift
│   │   │   ├── TodayTask.swift
│   │   │   ├── ChangeSet.swift
│   │   │   ├── CompletionLog.swift
│   │   │   └── AlertRule.swift
│   │   ├── Enums/
│   │   │   ├── DocumentSourceType.swift
│   │   │   ├── InstructionKind.swift
│   │   │   ├── ChangeType.swift
│   │   │   ├── MedicationUnit.swift
│   │   │   ├── TaskRiskLevel.swift
│   │   │   └── CycleStage.swift
│   │   └── ValueObjects/
│   │       ├── DoseAmount.swift
│   │       ├── ParsedTimeWindow.swift
│   │       └── InventoryForecast.swift
│   ├── Services/
│   │   ├── Import/
│   │   │   ├── DocumentImportService.swift
│   │   │   ├── ImagePreprocessService.swift
│   │   │   └── PDFTextExtractService.swift
│   │   ├── OCR/
│   │   │   ├── OCRService.swift
│   │   │   └── OCRTextNormalizer.swift
│   │   ├── Parsing/
│   │   │   ├── InstructionParser.swift
│   │   │   ├── MedicationParser.swift
│   │   │   ├── AppointmentParser.swift
│   │   │   ├── TriggerRuleParser.swift
│   │   │   └── ParserHeuristics.swift
│   │   ├── Diff/
│   │   │   ├── ProtocolDiffService.swift
│   │   │   └── ChangeClassifier.swift
│   │   ├── Tasking/
│   │   │   ├── TodayTaskBuilder.swift
│   │   │   ├── RiskFlagService.swift
│   │   │   └── CompletionService.swift
│   │   ├── Inventory/
│   │   │   ├── InventoryForecastService.swift
│   │   │   └── RefillAlertService.swift
│   │   ├── Notifications/
│   │   │   ├── NotificationPermissionService.swift
│   │   │   └── NotificationScheduler.swift
│   │   └── Export/
│   │       └── DailySummaryExportService.swift
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   ├── OnboardingView.swift
│   │   │   └── OnboardingViewModel.swift
│   │   ├── HomeToday/
│   │   │   ├── TodayHomeView.swift
│   │   │   ├── TodayHomeViewModel.swift
│   │   │   ├── TodayTaskCard.swift
│   │   │   └── CriticalBanner.swift
│   │   ├── ImportFlow/
│   │   │   ├── ImportSourceView.swift
│   │   │   ├── ImportPreviewView.swift
│   │   │   ├── ParsedProtocolView.swift
│   │   │   └── ImportFlowViewModel.swift
│   │   ├── ChangeReview/
│   │   │   ├── ChangeReviewView.swift
│   │   │   ├── ChangeRow.swift
│   │   │   └── ChangeReviewViewModel.swift
│   │   ├── Inventory/
│   │   │   ├── InventoryView.swift
│   │   │   ├── InventoryEditView.swift
│   │   │   └── InventoryViewModel.swift
│   │   ├── Timeline/
│   │   │   ├── TimelineView.swift
│   │   │   └── TimelineViewModel.swift
│   │   ├── History/
│   │   │   ├── DocumentHistoryView.swift
│   │   │   └── HistoryViewModel.swift
│   │   └── Settings/
│   │       ├── SettingsView.swift
│   │       └── SettingsViewModel.swift
│   ├── Shared/
│   │   ├── Components/
│   │   │   ├── SectionCard.swift
│   │   │   ├── StatusPill.swift
│   │   │   ├── EmptyStateView.swift
│   │   │   ├── PrimaryButton.swift
│   │   │   └── ImportBadge.swift
│   │   ├── Theme/
│   │   │   ├── ColorTokens.swift
│   │   │   ├── Typography.swift
│   │   │   └── Spacing.swift
│   │   └── Utils/
│   │       ├── DateFormatterFactory.swift
│   │       ├── StringSanitizer.swift
│   │       └── DemoDataFactory.swift
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Preview Content/
│   │   └── SampleFiles/
│   │       ├── sample_protocol_1.pdf
│   │       ├── sample_protocol_2.png
│   │       └── sample_sms_capture.png
│   └── Tests/
│       ├── ParsingTests/
│       │   ├── MedicationParserTests.swift
│       │   ├── AppointmentParserTests.swift
│       │   └── TriggerRuleParserTests.swift
│       ├── DiffTests/
│       │   └── ProtocolDiffServiceTests.swift
│       ├── InventoryTests/
│       │   └── InventoryForecastServiceTests.swift
│       └── UITests/
│           └── ImportToTodayFlowUITests.swift
└── docs/
    ├── APP_STORE_COPY.md
    ├── PRIVACY_POSITIONING.md
    └── OCR_PARSING_RULES.md
```

## 3. Core Data Model

The core data model should be optimized for:

- versioned clinic instructions
- daily task generation
- change detection
- medication inventory forecast

### 3.1 IVFCase

Represents one treatment journey.

Fields:

- `id: UUID`
- `title: String`
- `stage: CycleStage`
- `startDate: Date?`
- `clinicName: String?`
- `notes: String?`
- `createdAt: Date`
- `updatedAt: Date`

Purpose:

- allows multiple cycles in the future
- keeps the MVP extensible without overcomplicating the current scope

### 3.2 ProtocolDocument

Represents one imported instruction source.

Fields:

- `id: UUID`
- `caseID: UUID`
- `sourceType: DocumentSourceType`
- `sourceFilename: String?`
- `capturedAt: Date`
- `rawText: String`
- `normalizedText: String`
- `isActiveBaseline: Bool`
- `createdAt: Date`

Purpose:

- preserves source history
- enables compare-with-yesterday behavior

### 3.3 ParsedInstruction

Represents any structured item extracted from a document.

Fields:

- `id: UUID`
- `documentID: UUID`
- `kind: InstructionKind`
- `title: String`
- `detailText: String`
- `effectiveDate: Date?`
- `effectiveTimeText: String?`
- `isCritical: Bool`
- `confidence: Double`

Kinds:

- medication
- appointment
- stop-order
- trigger
- transfer
- lab
- note

Purpose:

- acts as a normalized layer between OCR text and product UI

### 3.4 MedicationPlan

Represents the active medication order abstracted from parsed instructions.

Fields:

- `id: UUID`
- `caseID: UUID`
- `medicationName: String`
- `genericKey: String`
- `doseValue: Double?`
- `doseUnit: MedicationUnit?`
- `route: String?`
- `frequencyText: String?`
- `timeText: String?`
- `startDate: Date?`
- `endDate: Date?`
- `status: String`
- `sourceDocumentID: UUID`
- `isHighRisk: Bool`

Purpose:

- powers Today screen
- powers diff
- powers inventory forecast

### 3.5 MedicationDose

Represents one actionable scheduled dose generated for a day.

Fields:

- `id: UUID`
- `caseID: UUID`
- `medicationPlanID: UUID`
- `scheduledDate: Date`
- `scheduledTimeText: String?`
- `doseValue: Double?`
- `doseUnit: MedicationUnit?`
- `status: String`
- `riskLevel: TaskRiskLevel`

Purpose:

- converts plan into execution

### 3.6 AppointmentItem

Represents clinic visits or timed events.

Fields:

- `id: UUID`
- `caseID: UUID`
- `title: String`
- `scheduledDate: Date?`
- `scheduledTimeText: String?`
- `locationText: String?`
- `kind: String`
- `sourceDocumentID: UUID`
- `isCritical: Bool`

Examples:

- monitoring appointment
- retrieval
- transfer
- beta blood test

### 3.7 InventoryItem

Represents medication stock on hand.

Fields:

- `id: UUID`
- `caseID: UUID`
- `medicationKey: String`
- `displayName: String`
- `remainingAmount: Double`
- `unit: MedicationUnit`
- `packageCount: Int?`
- `lowThresholdAmount: Double?`
- `lastUpdatedAt: Date`

Purpose:

- warns before a cycle-disrupting shortage

### 3.8 ChangeSet

Represents the diff between two protocol snapshots.

Fields:

- `id: UUID`
- `caseID: UUID`
- `previousDocumentID: UUID`
- `currentDocumentID: UUID`
- `generatedAt: Date`
- `summaryText: String`

Child change items:

- `changeType: ChangeType`
- `entityKey: String`
- `oldValue: String?`
- `newValue: String?`
- `isCritical: Bool`

Change types:

- new-med
- dose-updated
- stopped
- time-updated
- appointment-added
- appointment-updated
- note-added

### 3.9 TodayTask

Represents what the user should actually do today.

Fields:

- `id: UUID`
- `caseID: UUID`
- `taskDate: Date`
- `sortIndex: Int`
- `kind: String`
- `title: String`
- `subtitle: String`
- `scheduledTimeText: String?`
- `riskLevel: TaskRiskLevel`
- `sourceDocumentID: UUID`
- `completionState: String`

Purpose:

- this is the product's highest-value view model persisted for quick loading

### 3.10 CompletionLog

Fields:

- `id: UUID`
- `taskID: UUID`
- `completedAt: Date`
- `confirmedByUser: Bool`
- `secondaryConfirmation: Bool`
- `note: String?`

Purpose:

- provides safety trail without making medical claims

## 4. Data Relationships

```text
IVFCase
├── ProtocolDocument (1..n)
│   └── ParsedInstruction (1..n)
├── MedicationPlan (1..n)
│   └── MedicationDose (1..n)
├── AppointmentItem (1..n)
├── InventoryItem (1..n)
├── ChangeSet (1..n)
└── TodayTask (1..n)
    └── CompletionLog (0..n)
```

## 5. Core User Flows

### 5.1 First-Time Import Flow

1. user opens app
2. onboarding explains value in one screen
3. user imports screenshot or PDF
4. OCR extracts raw text
5. parser creates structured instructions
6. user reviews extracted content
7. app generates Today tasks
8. app asks for medication inventory setup
9. app lands on Today

### 5.2 Daily Update Flow

1. user imports new clinic instruction
2. app parses current instruction
3. app compares it with the latest active baseline
4. app shows Change Review
5. user confirms
6. app rebuilds Today tasks
7. app updates inventory forecast
8. app schedules reminders

### 5.3 Completion Flow

1. user opens Today
2. taps a task
3. sees details and source summary
4. confirms completion
5. if critical, second confirmation appears
6. completion is logged

### 5.4 Refill Alert Flow

1. user records remaining stock
2. app subtracts projected use from current plan
3. if stock drops below threshold, show warning banner
4. optionally schedule local notification

## 6. View Breakdown

### 6.1 OnboardingView

Purpose:

- explain what the app does in under 15 seconds

Core content:

- headline: `See dose changes before you miss a med`
- proof points:
  - import clinic screenshots and PDFs
  - compare with yesterday
  - know what to do today

Primary CTA:

- `Import Today's Instructions`

### 6.2 ImportSourceView

Purpose:

- let the user choose source input fast

Actions:

- import image
- import PDF
- take photo
- paste text manually

### 6.3 ImportPreviewView

Purpose:

- show the imported asset before parsing

Needed UI:

- document thumbnail
- capture timestamp
- button: `Extract Instructions`

### 6.4 ParsedProtocolView

Purpose:

- let user sanity-check extracted structure

Sections:

- medications
- appointments
- critical notes
- start/stop changes

Actions:

- edit obvious OCR mistakes
- confirm import

### 6.5 ChangeReviewView

Purpose:

- this is the app's main differentiator

Sections:

- `New Today`
- `Dose Changed`
- `Stopped`
- `Time Changed`
- `Appointments`

UX rules:

- critical changes must be at top
- changed values should be visually contrasted
- do not bury high-risk items in long lists

### 6.6 TodayHomeView

Purpose:

- answer one question: what do I do today

Layout:

- top critical banner
- current day header
- chronological task cards
- medication shortage warning
- next appointment summary

Task card content:

- medication name or task title
- dose/time
- source tag
- risk marker
- completion toggle

### 6.7 Task Detail Sheet

Purpose:

- confirm the exact action

Content:

- what to do
- when to do it
- why it is critical
- source snippet from imported instruction
- complete action

### 6.8 InventoryView

Purpose:

- track remaining meds and detect risk

Sections:

- on-hand now
- projected days left
- low stock alerts

Actions:

- update remaining amount
- adjust threshold

### 6.9 TimelineView

Purpose:

- provide light orientation without becoming a full journaling product

Timeline items:

- stimulation
- monitoring
- trigger
- retrieval
- transfer
- beta

### 6.10 DocumentHistoryView

Purpose:

- show instruction history and let user reopen old imports

Content:

- import date/time
- source type
- change summary

### 6.11 SettingsView

Purpose:

- keep privacy, reminders, and support simple

Sections:

- notification permissions
- passcode / local privacy option if added later
- sample data reset
- disclaimers

## 7. Architecture Notes

### 7.1 App Architecture

Use a simple layered architecture:

- `Domain`: persistent models and business types
- `Services`: OCR, parsing, diffing, inventory forecasting
- `Features`: screen-level state and UI
- `Shared`: reusable UI and formatting helpers

Avoid premature complexity:

- no coordinator-heavy architecture
- no feature modules split into packages in MVP
- no dependency injection framework in MVP

Use lightweight injection via environment objects and service protocols.

### 7.2 Parsing Strategy

The parser should use deterministic heuristics first.

Why:

- there is no backend
- the app must work offline
- deterministic parsing is testable

Recommended parsing pipeline:

1. OCR extracts raw text
2. normalizer fixes spacing, line breaks, common OCR mistakes
3. medication parser identifies medication-like lines
4. appointment parser identifies date/time visit instructions
5. stop/start parser identifies directive changes
6. risk flagger marks trigger shots, progesterone, stop orders

Do not start with ML.
Use well-defined heuristics and editable review UI.

### 7.3 Diff Strategy

Diff should compare semantic entities, not raw lines.

Examples:

- `Gonal-F 225 IU` to `Gonal-F 150 IU` => `dose-updated`
- `Cetrotide` absent before and present now => `new-med`
- `stop estrace` => `stopped`
- `arrive at 7:15 AM` replacing `8:00 AM` => `time-updated`

### 7.4 Inventory Strategy

Inventory forecast should be simple and conservative.

Formula:

- current remaining amount
- minus active scheduled doses
- projected through next 3 to 7 days

If uncertain, warn early rather than late.

## 8. Development Implementation Path

Build in vertical slices. Do not build all models first and all UI later.

### Phase 0: Project Bootstrap

Goal:

- get the app compiling with navigation shell and sample data

Tasks:

1. create Xcode project
2. configure SwiftData container
3. set up app router
4. create color and typography tokens
5. add demo data and preview support

Done when:

- app launches
- tab or stack navigation works
- sample Today screen renders with fake data

### Phase 1: Manual-Only Core Flow

Goal:

- prove the core value before OCR complexity

Tasks:

1. build `TodayHomeView`
2. build `ChangeReviewView`
3. build `InventoryView`
4. create manual entry for medications and appointments
5. generate Today tasks from manual protocol objects

Done when:

- a manually entered protocol can produce a Today list
- a changed protocol can produce a clear diff
- inventory warning appears

Reason:

- this validates product shape without parser risk

### Phase 2: Import and OCR

Goal:

- make import work for screenshots, photos, PDFs

Tasks:

1. add `PhotosPicker`
2. add `FileImporter`
3. build document preview
4. implement image OCR with Vision
5. implement PDF text extraction
6. persist raw and normalized text

Done when:

- user can import a clinic screenshot or PDF and see extracted text

### Phase 3: Parsing Layer

Goal:

- turn imported text into structured instructions

Tasks:

1. build text normalizer
2. build medication parser
3. build appointment parser
4. build stop/start detection
5. build risk flagging
6. allow user correction in parsed review screen

Done when:

- imported text consistently becomes editable structured items

Current implementation status (2026-04-16):

- SwiftData-backed snapshot persistence is now the default local storage path
- legacy JSON snapshot loading is retained only as a migration source
- medication parser: implemented with deterministic line rules
- appointment parser: implemented with deterministic line rules
- parsed review: include/exclude and inline edit for medications and appointments
- apply flow: writes parsed medications and appointments into app state
- daily task engine: generates TodayTask from active medications + appointments
- task ordering: urgency/risk first, then scheduled time
- high-risk UX: explicit high-risk markers + double confirmation on completion
- completion logging: local logs and completed-state persistence in app snapshot
- inventory projections: explicit days-left estimates in Inventory UI
- low-stock alerts: warning banner retained with structured low/critical alert output
- local notifications: low-stock permission request + local scheduling service integrated (local-first)
- semantic diff: appointment-aware semantic diff is now implemented for medications + appointments
- change review UI: critical changes remain pinned first and appointment changes render in-app
- protocol history: persisted local revision history is browseable from a dedicated History tab

### Phase 4: Diff Engine

Goal:

- make the core differentiator real

Tasks:

1. define stable comparison keys per medication and appointment
2. compare previous and current protocol states
3. classify semantic changes
4. render grouped diff UI
5. store `ChangeSet`

Done when:

- app can reliably tell the user what changed today

### Phase 5: Daily Task Engine

Goal:

- convert protocol into an execution plan

Tasks:

1. generate `TodayTask` from active medication and appointment items
2. sort by urgency and time
3. mark critical tasks
4. add completion logging
5. add double-confirmation for high-risk items

Done when:

- user can use the app as the source of truth for today's actions

### Phase 6: Inventory Forecast and Alerts

Goal:

- warn before medication shortages

Tasks:

1. create inventory editing UI
2. subtract projected active doses
3. display days-left estimate
4. trigger warning banner
5. schedule local notifications for low stock if enabled

Done when:

- shortage risk is visible before the next critical usage

### Phase 7: Polish for First Paid Release

Goal:

- make the app sellable, not just functional

Tasks:

1. improve empty states
2. improve first-run sample walkthrough
3. add disclaimers and safety copy
4. optimize import speed
5. add app icon and screenshot-ready UI polish
6. write App Store metadata

Done when:

- the app can be demoed in under 30 seconds
- value is obvious without explanation

Current implementation status (2026-04-16):

- empty states: improved for Today, Import, and Inventory key workflows
- first-run walkthrough: one-time local walkthrough sheet is implemented
- safety copy: visible clinic-first disclaimers are added in Today/Import/Inventory
- import speed: repeat OCR/PDF extraction now uses local cache by source fingerprint
- app icon: AppIcon asset set now includes required icon files and mapping
- app store metadata: initial draft published in `docs/APP_STORE_COPY.md`

### Mainline Milestone Status (2026-04-16)

- done: SwiftData persistence
- done: complete diff/history
- done: Settings/Onboarding formalization
- done: UI tests

### Release Hardening Status (2026-04-16)

- done: parser coverage expanded for IVF shorthand lines (`ET`/`ER`/`U/S`, `QHS`, `EOD`, `CD` prefixes)
- done: inventory forecasting expanded to conservative projected low-stock detection within 7 days
- done: notification strategy hardened with severity-aware titles and schedule delay policy

### 1.0 Candidate Closure Status (2026-04-16)

- done: automated release-readiness checklist coverage is documented in `docs/RELEASE_1_0_CLOSURE.md`
- done: simulator build and full unit/UI verification are passing for candidate scope
- done: app is development-complete for local-first 1.0 candidate

## 9. Testing Strategy

### 9.1 Unit Tests

Must cover:

- OCR normalization edge cases
- medication parsing
- appointment parsing
- stop/start rules
- semantic diff classification
- inventory forecast math

### 9.2 UI Tests

Must cover:

- first import flow
- compare with yesterday flow
- complete critical task flow
- low inventory warning flow

Current implementation status (2026-04-16):

- implemented in `IVFTodayUITests/IVFTodayUITests.swift` with deterministic launch arguments for stable local execution

### 9.3 Manual QA Checklist

- blurry screenshot import
- long PDF import
- same medication with changed dose
- newly added medication
- stop order
- late-night trigger shot
- transfer-day appointment
- medication inventory falling below threshold
- app relaunch after import
- no-network behavior

## 10. Safety, Messaging, and Scope Discipline

### 10.1 Messaging Rules

The app must not claim:

- improved pregnancy outcomes
- medical diagnosis
- medical advice

The app may claim:

- instruction clarity
- task organization
- local privacy
- change visibility
- refill risk visibility

### 10.2 Scope Rules

Do not add in MVP:

- community
- therapist content
- clinic messaging
- insurance tools
- analytics dashboard overload
- Apple Watch app
- iPad redesign
- partner sync through cloud

If a feature does not strengthen one of the three core promises, reject it:

1. see changes
2. know today
3. avoid running out

## 11. Release Order

### Release 0.1

- sample-data only prototype
- manual entry only
- validate screen hierarchy and emotional clarity

### Release 0.2

- import and OCR
- parsed review screen
- save documents locally

### Release 0.3

- semantic diff
- task generation
- completion confirmation

### Release 0.4

- inventory forecast
- local notifications
- polish and App Store preparation

### Release 1.0

- stable offline IVF execution assistant
- first paid launch candidate

## 12. Definition of Done for MVP

The MVP is done only when all of the following are true:

1. a user can import a real clinic screenshot or PDF
2. the app can extract structured meds and appointments with editable review
3. the app can compare today's protocol with the previous one
4. the app can generate a clean Today action list
5. the app can track medication inventory and warn about shortage risk
6. the app works offline after install
7. the app does not require any server
8. the first-time user can understand the value in under 30 seconds

## 13. System Kickoff Prompt for a Junior AI Programmer

Use the following as the system startup prompt for a junior AI implementation agent.

```text
You are a pragmatic iOS engineer working on IVFToday, an iPhone-first, local-only IVF execution app.

Your job is to build production-quality SwiftUI code inside the existing project without inventing extra scope.

Product promise:
- import clinic screenshots, photos, and PDFs
- extract IVF instructions locally
- show what changed since yesterday
- generate a clear Today action list
- warn before medications run out

Hard constraints:
- no backend
- no cloud dependency
- no network-required feature
- no medical claims
- no giant architecture rewrites
- prefer simple, testable code

Technical stack:
- SwiftUI
- SwiftData
- Vision
- PDFKit
- UserNotifications

Implementation rules:
- work in small vertical slices
- each change must move the product toward one of three promises:
  1. see changes
  2. know today
  3. avoid running out
- avoid adding features outside MVP
- prefer deterministic parsing and editable review UI over speculative AI logic
- write concise comments only where needed
- add unit tests for parsing, diffing, and inventory math

Code quality expectations:
- strong naming
- small focused types
- explicit state handling
- no dead abstractions
- no copy-pasted UI logic when a small shared component is enough

UX expectations:
- user must understand the next action immediately
- critical items must appear first
- high-risk tasks require stronger confirmation
- import flow must feel fast and reassuring

When implementing:
- explain your assumptions briefly
- say which files you will change before editing
- preserve local-first privacy positioning
- do not broaden scope into community, content, or clinic integration

Success condition:
- a real IVF patient can import instructions, see changes, know what to do today, and see refill risk without needing a server.
```

## 14. Recommended First Build Ticket List

Start execution with these tickets in order:

1. bootstrap Xcode project and SwiftData container
2. build Today home with demo data
3. build manual protocol entry and diff view
4. build inventory editor and forecast banner
5. add screenshot/PDF import
6. add OCR normalization
7. add medication and appointment parsing
8. add semantic diff engine
9. add completion logging for critical tasks
10. add local notifications and launch polish

## 15. Final Principle

If there is a product decision conflict, choose the option that makes this sentence more true:

> A patient can look at IVFToday and know exactly what changed and what to do next without panic.
