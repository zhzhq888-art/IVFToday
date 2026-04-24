import XCTest
@testable import IVFToday

final class MedicationLineParserTests: XCTestCase {
    private let parser = MedicationLineParser()
    private let mapper = ImportedProtocolMapper()

    func testNormalDoseLineParsesMedicationDoseUnitAndTime() {
        let result = parser.parseLine("Gonal-F 150 IU 8:30pm")

        XCTAssertEqual(result.state, .parsed)
        XCTAssertEqual(result.medicationName, "Gonal-F")
        XCTAssertEqual(result.doseAmount, "150")
        XCTAssertEqual(result.unit, "IU")
        XCTAssertEqual(result.scheduledTime, "8:30pm")
        XCTAssertEqual(result.remainingText, "8:30pm")
        XCTAssertNil(result.directive)
    }

    func testNoisePrefixAndSevenPmTimeAreParsed() {
        let result = parser.parseLine("• Day 5: Inject Gonal-F 150 lU 7 pm")

        XCTAssertEqual(result.state, .parsed)
        XCTAssertEqual(result.directive, .inject)
        XCTAssertEqual(result.medicationName, "Gonal-F")
        XCTAssertEqual(result.doseAmount, "150")
        XCTAssertEqual(result.unit, "IU")
        XCTAssertEqual(result.scheduledTime, "7 pm")
        XCTAssertEqual(result.remainingText, "7 pm")
    }

    func testTomorrowMorningAndStopHoldInstructionsPreserveMedicationName() {
        let holdResult = parser.parseLine("Hold aspirin tomorrow morning")
        let stopResult = parser.parseLine("Stop Cetrotide")

        XCTAssertEqual(holdResult.state, .parsed)
        XCTAssertEqual(holdResult.directive, .hold)
        XCTAssertEqual(holdResult.medicationName, "aspirin")
        XCTAssertEqual(holdResult.doseAmount, nil)
        XCTAssertEqual(holdResult.unit, nil)
        XCTAssertEqual(holdResult.scheduledTime, "tomorrow morning")
        XCTAssertEqual(holdResult.remainingText, "tomorrow morning")

        XCTAssertEqual(stopResult.state, .parsed)
        XCTAssertEqual(stopResult.directive, .stop)
        XCTAssertEqual(stopResult.medicationName, "Cetrotide")
        XCTAssertEqual(stopResult.doseAmount, nil)
        XCTAssertEqual(stopResult.unit, nil)
        XCTAssertNil(stopResult.scheduledTime)
        XCTAssertNil(stopResult.remainingText)
    }

    func testMapperKeepsHoldInstructionInactiveAndNormalDoseActive() {
        let results = parser.parseLines([
            "Hold aspirin tonight",
            "Gonal-F 150 IU 8:30pm"
        ])

        let plans = mapper.mapToMedicationPlans(from: results)

        XCTAssertEqual(plans.count, 2)

        let holdPlan = plans.first { $0.isActive == false }
        XCTAssertNotNil(holdPlan)
        XCTAssertEqual(holdPlan?.name, "aspirin")
        XCTAssertEqual(holdPlan?.route, "Instruction")
        XCTAssertEqual(holdPlan?.instructions, "Hold tonight")
        XCTAssertEqual(holdPlan?.scheduledTime, "tonight")
        XCTAssertEqual(holdPlan?.doseAmount, 0)
        XCTAssertEqual(holdPlan?.unit, .iu)

        let activePlan = plans.first { $0.isActive == true }
        XCTAssertNotNil(activePlan)
        XCTAssertEqual(activePlan?.route, "Subcutaneous")
        XCTAssertEqual(activePlan?.instructions, "8:30pm")
        XCTAssertEqual(activePlan?.scheduledTime, "8:30pm")
        XCTAssertEqual(activePlan?.doseAmount, 150)
        XCTAssertEqual(activePlan?.unit, .iu)
    }

    func testNaturalLanguageTimeAndRouteAreMapped() {
        let result = parser.parseLine("Progesterone in oil 1 mL IM before bed")
        let plans = mapper.mapToMedicationPlans(from: [result])

        XCTAssertEqual(result.state, .parsed)
        XCTAssertEqual(result.medicationName, "Progesterone in oil")
        XCTAssertEqual(result.scheduledTime, "before bed")
        XCTAssertEqual(result.unit, "mL")

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans.first?.route, "Intramuscular")
        XCTAssertEqual(plans.first?.scheduledTime, "before bed")
        XCTAssertEqual(plans.first?.instructions, "before bed")
        XCTAssertEqual(plans.first?.unit, .ml)
    }

    func testActiveDirectiveWithoutDoseIsPreservedAsActiveInstruction() {
        let result = parser.parseLine("Continue aspirin after dinner")
        let plans = mapper.mapToMedicationPlans(from: [result])

        XCTAssertEqual(result.state, .parsed)
        XCTAssertEqual(result.directive, .continue)
        XCTAssertEqual(result.medicationName, "aspirin")
        XCTAssertEqual(result.scheduledTime, "after dinner")

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans.first?.name, "aspirin")
        XCTAssertEqual(plans.first?.route, "Instruction")
        XCTAssertEqual(plans.first?.scheduledTime, "after dinner")
        XCTAssertEqual(plans.first?.instructions, "Continue after dinner")
        XCTAssertEqual(plans.first?.isActive, true)
        XCTAssertEqual(plans.first?.doseAmount, 0)
    }

    func testCycleDayPrefixAndQhsAbbreviationAreParsed() {
        let result = parser.parseLine("CD12: Inject Progesterone 1 mL IM QHS")

        XCTAssertEqual(result.state, .parsed)
        XCTAssertEqual(result.directive, .inject)
        XCTAssertEqual(result.medicationName, "Progesterone")
        XCTAssertEqual(result.doseAmount, "1")
        XCTAssertEqual(result.unit, "mL")
        XCTAssertEqual(result.scheduledTime, "QHS")
    }

    func testEveryOtherDayExpressionIsRecognizedAsScheduleToken() {
        let result = parser.parseLine("Take Estrace 2 mg every other day")

        XCTAssertEqual(result.state, .parsed)
        XCTAssertEqual(result.directive, .take)
        XCTAssertEqual(result.medicationName, "Estrace")
        XCTAssertEqual(result.doseAmount, "2")
        XCTAssertEqual(result.unit, "mg")
        XCTAssertEqual(result.scheduledTime, "every other day")
    }
}
