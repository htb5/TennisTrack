import CoreGraphics
import XCTest
@testable import TennisBallTracker

final class BounceDetectorTests: XCTestCase {
    func testDetectsBounceWhenDirectionReverses() {
        let detector = BounceDetector(
            minDownVelocity: 0.05,
            minUpVelocity: 0.05,
            minBounceInterval: 0.0,
            minReboundDistance: 0.001
        )

        XCTAssertNil(detector.consume(point: CGPoint(x: 0.5, y: 0.20), time: 0.00))
        XCTAssertNil(detector.consume(point: CGPoint(x: 0.5, y: 0.34), time: 0.05))
        let bounce = detector.consume(point: CGPoint(x: 0.5, y: 0.24), time: 0.10)

        XCTAssertNotNil(bounce)
        XCTAssertEqual(bounce?.point.y, 0.34, accuracy: 0.0001)
    }
}

