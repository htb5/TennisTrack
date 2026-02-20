import CoreGraphics
import XCTest
@testable import TennisBallTracker

final class CourtModelTests: XCTestCase {
    func testContainsPointInsideBoundary() {
        let court = CourtModel.defaultSingles
        XCTAssertTrue(court.contains(point: CGPoint(x: 0.5, y: 0.5)))
    }

    func testDoesNotContainPointOutsideBoundary() {
        let court = CourtModel.defaultSingles
        XCTAssertFalse(court.contains(point: CGPoint(x: 0.02, y: 0.5)))
    }
}

