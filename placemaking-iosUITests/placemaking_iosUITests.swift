//
//  placemaking_iosUITests.swift
//  placemaking-iosUITests
//
//  Created by PC1 on 4/1/26.
//

import XCTest

final class placemaking_iosUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testCreateProjectAndUpdateZoneStatus() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UI_TESTING")
        app.launch()

        XCTAssertTrue(app.buttons["createProjectButton"].waitForExistence(timeout: 2))
        app.buttons["createProjectButton"].tap()

        let projectNameField = app.textFields["projectNameField"]
        XCTAssertTrue(projectNameField.waitForExistence(timeout: 2))
        projectNameField.tap()
        projectNameField.typeText("Campus North")

        app.buttons["locationChoiceArbitrary"].tap()

        let confirmBoundaryButton = app.buttons["confirmBoundaryButton"]
        XCTAssertTrue(confirmBoundaryButton.waitForExistence(timeout: 2))
        confirmBoundaryButton.tap()

        let createButton = app.buttons["createProjectSubmitButton"]
        XCTAssertTrue(createButton.isEnabled)
        createButton.tap()

        XCTAssertTrue(app.staticTexts["Project Overview"].waitForExistence(timeout: 3))

        let firstZone = app.buttons["zoneTile_A1"]
        XCTAssertTrue(firstZone.waitForExistence(timeout: 2))
        firstZone.tap()

        let progressButton = app.buttons["markZoneInProgressButton"]
        XCTAssertTrue(progressButton.waitForExistence(timeout: 2))
        progressButton.tap()

        XCTAssertTrue(app.staticTexts["In Progress"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
