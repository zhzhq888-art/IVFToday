import XCTest

final class IVFTodayUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFirstImportFlowShowsSourceOptionsAndSafetyCopy() {
        let app = launchApp()

        openTab(named: "Import Instructions", in: app)

        XCTAssertTrue(app.navigationBars["Import Instructions"].waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, identifier: "import.source.screenshot").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, identifier: "import.source.pdf").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["OCR and PDF extraction happen locally on device"].exists)
    }

    func testCompareWithYesterdayFlowShowsChangeSections() {
        let app = launchApp()

        openTab(named: "Changes", in: app)

        XCTAssertTrue(app.navigationBars["Changes"].waitForExistence(timeout: 5))
        let hasExpectedSection = app.staticTexts["Critical"].waitForExistence(timeout: 2)
            || app.staticTexts["Medication Changes"].waitForExistence(timeout: 2)
            || app.staticTexts["Appointment Changes"].waitForExistence(timeout: 2)
        XCTAssertTrue(hasExpectedSection)
    }

    func testCompleteCriticalTaskFlowRequiresDoubleConfirmation() {
        let app = launchApp()

        let triggerButton = element(in: app, identifier: "today.ui-test.trigger-high-risk")
        XCTAssertTrue(waitForElementWithScrolling(triggerButton, in: app, timeout: 5))
        triggerButton.tap()

        let highRiskAlert = app.alerts["High-Risk Task"]
        XCTAssertTrue(highRiskAlert.waitForExistence(timeout: 5))
        highRiskAlert.buttons["Continue"].tap()

        let finalConfirmation = app.alerts["Final Confirmation"]
        XCTAssertTrue(finalConfirmation.waitForExistence(timeout: 5))
        finalConfirmation.buttons["Mark Completed"].tap()

        let completionRows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "today.completion.row.")
        )
        let completionRow = completionRows.firstMatch
        XCTAssertTrue(waitForElementWithScrolling(completionRow, in: app, timeout: 5))
    }

    func testLowInventoryWarningFlowAfterReducingStock() {
        let app = launchApp()

        openTab(named: "Inventory", in: app)

        let remainingField = element(in: app, identifier: "inventory.remaining.gonal-f")
        XCTAssertTrue(waitForElementWithScrolling(remainingField, in: app, timeout: 5))
        replaceText(in: remainingField, with: "0")

        let saveButton = element(in: app, identifier: "inventory.save.gonal-f")
        XCTAssertTrue(waitForElementWithScrolling(saveButton, in: app, timeout: 5))
        saveButton.tap()

        let warningBanner = element(in: app, identifier: "inventory.alert.banner")
        XCTAssertTrue(warningBanner.waitForExistence(timeout: 5))
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-ui-testing-reset-demo-data",
            "-ui-testing-skip-onboarding",
            "-ui-testing-enable-hooks"
        ]
        app.launch()
        return app
    }

    private func element(in app: XCUIApplication, identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func openTab(named name: String, in app: XCUIApplication) {
        let directTabButton = app.tabBars.buttons[name]
        if directTabButton.waitForExistence(timeout: 2) {
            directTabButton.tap()
            return
        }

        let moreButton = app.tabBars.buttons["More"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 5))
        moreButton.tap()

        let destinationCell = app.tables.cells.containing(.staticText, identifier: name).firstMatch
        if destinationCell.waitForExistence(timeout: 5) {
            destinationCell.tap()
            return
        }

        let destinationText = app.tables.staticTexts[name].firstMatch
        XCTAssertTrue(destinationText.waitForExistence(timeout: 5))
        destinationText.tap()
    }

    private func waitForElementWithScrolling(_ element: XCUIElement, in app: XCUIApplication, timeout: TimeInterval) -> Bool {
        if element.waitForExistence(timeout: timeout) {
            return true
        }

        for _ in 0..<6 {
            app.swipeUp()
            if element.waitForExistence(timeout: 0.8) {
                return true
            }
        }

        for _ in 0..<6 {
            app.swipeDown()
            if element.waitForExistence(timeout: 0.8) {
                return true
            }
        }

        return false
    }

    private func replaceText(in textField: XCUIElement, with text: String) {
        textField.tap()

        let currentValue = (textField.value as? String) ?? ""
        if !currentValue.isEmpty {
            let deleteSequence = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            textField.typeText(deleteSequence)
        }

        textField.typeText(text)
    }
}
