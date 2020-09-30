//
//  ScreenMeetTests.swift
//  ScreenMeetSDK_Tests
//
//  Created by Vasyl Morarash on 20.06.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
@testable import ScreenMeetSDK

class ScreenMeetTests: XCTestCase {

    func testVersion() throws {
        let screenMeetVersion = ScreenMeet.version()
        
        let bundle = try XCTUnwrap(Bundle(identifier: "org.cocoapods.ScreenMeetSDK"))
        let version = try XCTUnwrap(bundle.infoDictionary?["CFBundleShortVersionString"])
        let build = try XCTUnwrap(bundle.infoDictionary?["CFBundleVersion"])
        
        XCTAssertEqual(screenMeetVersion, "\(version) (\(build))")
    }
}
