import XCTest
@testable import IVFToday

final class MedicationDraftValidationServiceTests: XCTestCase {
    private let service = MedicationDraftValidationService()

    func testActiveNonInstructionRequiresPositiveDoseAndScheduledTime() {
        let issues = service.validate(
            .init(
                medicationName: "Gonal-F",
                doseAmount: "0",
                scheduledTime: "   ",
                route: "Subcutaneous",
                instructions: "Night dose",
                isActive: true
            )
        )

        XCTAssertTrue(issues.contains("Active medication dose must be a number greater than 0."))
        XCTAssertTrue(issues.contains("Active medication needs a scheduled time."))
    }

    func testActiveInstructionRouteDoesNotRequireDoseOrTime() {
        let issues = service.validate(
            .init(
                medicationName: "Aspirin",
                doseAmount: "",
                scheduledTime: "",
                route: "Instruction",
                instructions: "Continue after dinner",
                isActive: true
            )
        )

        XCTAssertFalse(issues.contains("Active medication dose must be a number greater than 0."))
        XCTAssertFalse(issues.contains("Active medication needs a scheduled time."))
    }

    func testInactiveRequiresInstructionGuidanceText() {
        let issues = service.validate(
            .init(
                medicationName: "Aspirin",
                doseAmount: "",
                scheduledTime: "",
                route: "Instruction",
                instructions: "  ",
                isActive: false
            )
        )

        XCTAssertTrue(issues.contains("Inactive instruction should include guidance text."))
    }

    func testEmptyNameAndRouteProduceIssues() {
        let issues = service.validate(
            .init(
                medicationName: "  ",
                doseAmount: "150",
                scheduledTime: "8:00 PM",
                route: " ",
                instructions: "Take tonight",
                isActive: true
            )
        )

        XCTAssertTrue(issues.contains("Medication name cannot be empty."))
        XCTAssertTrue(issues.contains("Route cannot be empty."))
    }
}
