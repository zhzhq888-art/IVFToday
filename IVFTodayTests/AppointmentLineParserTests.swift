import XCTest
@testable import IVFToday

final class AppointmentLineParserTests: XCTestCase {
    private let parser = AppointmentLineParser()

    func testUltrasoundLineParsesTimeAndKind() {
        let result = parser.parseLine("Ultrasound monitoring tomorrow 7:30 AM at Main Clinic")

        XCTAssertEqual(result.state, .parsed)
        XCTAssertEqual(result.kind, "monitoring")
        XCTAssertEqual(result.scheduledTimeText, "tomorrow")
        XCTAssertEqual(result.locationText, "Main Clinic")
        XCTAssertEqual(result.isCritical, false)
        XCTAssertEqual(result.title, "Ultrasound monitoring")
    }

    func testRetrievalLineIsCriticalAndParsesClockTime() {
        let result = parser.parseLine("Egg retrieval at 06:45 AM in OR Suite 2")

        XCTAssertEqual(result.state, .parsed)
        XCTAssertEqual(result.kind, "retrieval")
        XCTAssertEqual(result.scheduledTimeText, "06:45 AM")
        XCTAssertEqual(result.locationText, "OR Suite 2")
        XCTAssertEqual(result.isCritical, true)
    }

    func testNonAppointmentMedicationLineStaysUnparsed() {
        let result = parser.parseLine("Inject Gonal-F 150 IU at 8:00 PM")

        XCTAssertEqual(result.state, .unparsed)
        XCTAssertNil(result.kind)
        XCTAssertNil(result.title)
    }

    func testMapToAppointmentsCreatesStructuredItems() {
        let results = parser.parseLines([
            "Monitoring appointment tomorrow 8 AM at North Clinic",
            "Beta blood test 9:00 AM",
            "Take Cetrotide 0.25 mg 7:00 AM"
        ])
        let appointments = parser.mapToAppointments(from: results)

        XCTAssertEqual(appointments.count, 2)
        XCTAssertEqual(appointments[0].kind, "monitoring")
        XCTAssertEqual(appointments[0].scheduledTimeText, "tomorrow")
        XCTAssertEqual(appointments[1].kind, "lab")
        XCTAssertEqual(appointments[1].isCritical, true)
    }

    func testAbbreviationLinesParseIntoCriticalTransferAndRetrieval() {
        let transferResult = parser.parseLine("ET tomorrow 11:00 AM @ Transfer Suite")
        let retrievalResult = parser.parseLine("ER check-in 06:45 AM @ OR Suite 2")

        XCTAssertEqual(transferResult.state, .parsed)
        XCTAssertEqual(transferResult.kind, "transfer")
        XCTAssertEqual(transferResult.title, "Embryo transfer")
        XCTAssertEqual(transferResult.locationText, "Transfer Suite")
        XCTAssertTrue(transferResult.isCritical)

        XCTAssertEqual(retrievalResult.state, .parsed)
        XCTAssertEqual(retrievalResult.kind, "retrieval")
        XCTAssertEqual(retrievalResult.title, "Egg retrieval")
        XCTAssertEqual(retrievalResult.locationText, "OR Suite 2")
        XCTAssertTrue(retrievalResult.isCritical)
    }

    func testUltrasoundAbbreviationParsesAsMonitoring() {
        let result = parser.parseLine("U/S 7:15 AM @ Main Clinic")

        XCTAssertEqual(result.state, .parsed)
        XCTAssertEqual(result.kind, "monitoring")
        XCTAssertEqual(result.title, "Ultrasound monitoring")
        XCTAssertEqual(result.locationText, "Main Clinic")
    }
}
