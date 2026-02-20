import CoreGraphics
import Foundation

struct BounceEvent {
    let point: CGPoint
    let timestamp: Double
}

final class BounceDetector {
    private struct TimedPoint {
        let point: CGPoint
        let time: Double
    }

    private var history: [TimedPoint] = []
    private var lastBounceTime = -Double.infinity

    private let minDownVelocity: CGFloat
    private let minUpVelocity: CGFloat
    private let minBounceInterval: Double
    private let minReboundDistance: CGFloat

    init(
        minDownVelocity: CGFloat = 0.10,
        minUpVelocity: CGFloat = 0.10,
        minBounceInterval: Double = 0.35,
        minReboundDistance: CGFloat = 0.008
    ) {
        self.minDownVelocity = minDownVelocity
        self.minUpVelocity = minUpVelocity
        self.minBounceInterval = minBounceInterval
        self.minReboundDistance = minReboundDistance
    }

    func consume(point: CGPoint, time: Double) -> BounceEvent? {
        history.append(TimedPoint(point: point, time: time))
        if history.count > 6 {
            history.removeFirst(history.count - 6)
        }

        guard history.count >= 3 else {
            return nil
        }

        let a = history[history.count - 3]
        let b = history[history.count - 2]
        let c = history[history.count - 1]

        let dt1 = max(0.001, b.time - a.time)
        let dt2 = max(0.001, c.time - b.time)
        let v1 = (b.point.y - a.point.y) / CGFloat(dt1)
        let v2 = (c.point.y - b.point.y) / CGFloat(dt2)
        let rebound = abs(c.point.y - b.point.y)

        guard v1 > minDownVelocity else {
            return nil
        }
        guard v2 < -minUpVelocity else {
            return nil
        }
        guard rebound >= minReboundDistance else {
            return nil
        }
        guard (b.time - lastBounceTime) >= minBounceInterval else {
            return nil
        }

        lastBounceTime = b.time
        return BounceEvent(point: b.point, timestamp: b.time)
    }
}

