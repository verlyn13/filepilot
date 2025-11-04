//
//  TelemetryServiceTests.swift
//  FilePilotTests
//
//  Test suite for TelemetryService
//

import XCTest
@testable import FilePilot

final class TelemetryServiceTests: XCTestCase {
    var telemetryService: TelemetryService!
    
    override func setUp() {
        telemetryService = TelemetryService.shared
    }
    
    override func tearDown() {
        telemetryService = nil
    }
    
    // MARK: - Singleton Tests
    
    func testSingletonInstance() {
        let instance1 = TelemetryService.shared
        let instance2 = TelemetryService.shared
        XCTAssertTrue(instance1 === instance2, "Should return same singleton instance")
    }
    
    // MARK: - Event Recording Tests
    
    func testRecordAppLaunch() {
        XCTAssertNoThrow(telemetryService.recordAppLaunch())
    }
    
    func testRecordAction() {
        XCTAssertNoThrow(telemetryService.recordAction("test_action"))
    }
    
    func testRecordActionWithMetadata() {
        let metadata: [String: Any] = [
            "key1": "value1",
            "key2": 42,
            "key3": true
        ]
        XCTAssertNoThrow(telemetryService.recordAction("test_action", metadata: metadata))
    }
    
    func testRecordNavigation() {
        let testURL = URL(fileURLWithPath: "/Users/test/Desktop")
        XCTAssertNoThrow(telemetryService.recordNavigation(to: testURL))
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentRecording() {
        let expectation = XCTestExpectation(description: "Concurrent telemetry recording")
        expectation.expectedFulfillmentCount = 10
        
        DispatchQueue.concurrentPerform(iterations: 10) { index in
            telemetryService.recordAction("concurrent_test_\(index)")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
