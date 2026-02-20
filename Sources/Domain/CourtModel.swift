import CoreGraphics
import Foundation

struct CourtModel {
    let boundary: [CGPoint]

    func contains(point: CGPoint) -> Bool {
        guard boundary.count >= 3 else {
            return false
        }
        return pointInPolygon(point: point, polygon: boundary)
    }

    // Default normalized singles court polygon for a fixed camera view.
    static let defaultSingles = CourtModel(
        boundary: [
            CGPoint(x: 0.16, y: 0.20),
            CGPoint(x: 0.84, y: 0.20),
            CGPoint(x: 0.92, y: 0.88),
            CGPoint(x: 0.08, y: 0.88)
        ]
    )

    private func pointInPolygon(point: CGPoint, polygon: [CGPoint]) -> Bool {
        var isInside = false
        var j = polygon.count - 1

        for i in 0..<polygon.count {
            let pi = polygon[i]
            let pj = polygon[j]

            let intersects = ((pi.y > point.y) != (pj.y > point.y)) &&
                (point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y + 0.000001) + pi.x)

            if intersects {
                isInside.toggle()
            }
            j = i
        }

        return isInside
    }
}

