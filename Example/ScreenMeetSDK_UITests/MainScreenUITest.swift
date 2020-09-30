//
//  MainScreenUITest.swift
//  ScreenMeetSDK_UITests
//
//  Created by Vasyl Morarash on 22.06.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest

class MainScreenUITest: XCTestCase {
    
    func testUIExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        app.buttons["start_session"].tap()
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
