# IVFToday 1.0 Candidate Closure

Date: 2026-04-16

## Scope Completion

Mainline milestones:
- SwiftData persistence: done
- Complete diff/history: done
- Settings/Onboarding formalization: done
- UI tests: done

Release hardening slice:
- Parser coverage expanded for IVF shorthand (`ET`, `ER`, `U/S`, `QHS`, `EOD`, `CD12`): done
- Inventory forecast expanded with conservative 7-day projected low-stock detection: done
- Notification strategy hardened with severity-aware titles and delay policy: done

## Validation Commands

Build:
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project IVFToday.xcodeproj -scheme IVFToday -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build

Test (stable environment flags):
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project IVFToday.xcodeproj -scheme IVFToday -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -collect-test-diagnostics never -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 test

Latest observed result:
- Build succeeded
- Unit tests passed (48)
- UI tests passed (4)

## Manual QA Checklist Mapping

Blueprint checklist item -> Evidence:
- blurry screenshot import -> OCR regression coverage in `OCRServiceTests.testBlurredScreenshotStillExtractsMedicationName`
- long PDF import -> large local PDF import deterministic test (`testLargePdfImportRemainsDeterministic`)
- same medication with changed dose -> diff coverage in `ProtocolDiffAndInventoryTests`
- newly added medication -> diff/add coverage in `ProtocolDiffAndInventoryTests`
- stop order -> medication parser + mapper coverage in `MedicationLineParserTests`
- late-night trigger shot -> task engine coverage in `testLateNightTriggerShotIsHighRiskAndKeepsLateSchedule`
- transfer-day appointment -> parser + task-risk coverage in `AppointmentLineParserTests` and `testTransferDayAppointmentDefaultsToHighRisk`
- medication inventory falling below threshold -> inventory forecast and UI flow tests
- app relaunch after import -> persistence reload coverage in `AppStatePersistenceTests`
- no-network behavior -> import and workflow services are local-only; no network client usage in app sources

## Release Readiness Notes

- The app is now at development-complete 1.0 candidate level for local-first scope.
- Remaining non-code step: product-owner sign-off of manual exploratory run on a target device before store submission.
