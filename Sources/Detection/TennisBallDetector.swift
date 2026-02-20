import AVFoundation
import CoreGraphics
import Foundation

struct BallDetection {
    let point: CGPoint
    let confidence: Double
    let boundingBox: CGRect
}

final class TennisBallDetector {
    private let samplingStep = 2
    private let minimumMatches = 24

    func detect(in sampleBuffer: CMSampleBuffer) -> BallDetection? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let bytePointer = baseAddress.assumingMemoryBound(to: UInt8.self)

        var matchedCount = 0
        var sumX = 0.0
        var sumY = 0.0
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0

        for y in stride(from: 0, to: height, by: samplingStep) {
            let row = bytePointer.advanced(by: y * bytesPerRow)
            for x in stride(from: 0, to: width, by: samplingStep) {
                let offset = x * 4
                let b = Int(row[offset])
                let g = Int(row[offset + 1])
                let r = Int(row[offset + 2])

                guard isLikelyBallPixel(r: r, g: g, b: b) else {
                    continue
                }

                matchedCount += 1
                sumX += Double(x)
                sumY += Double(y)
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }

        guard matchedCount >= minimumMatches else {
            return nil
        }

        let centerX = sumX / Double(matchedCount)
        let centerY = sumY / Double(matchedCount)
        let normalizedPoint = CGPoint(
            x: CGFloat(centerX / Double(width)),
            y: CGFloat(centerY / Double(height))
        )

        let boxWidth = max(1, maxX - minX)
        let boxHeight = max(1, maxY - minY)
        let area = max(1, boxWidth * boxHeight)
        let effectiveMatches = matchedCount * samplingStep * samplingStep
        let fillRatio = Double(effectiveMatches) / Double(area)

        guard fillRatio > 0.12, fillRatio < 0.9 else {
            return nil
        }

        let confidence = min(1.0, Double(matchedCount) / 600.0)
        let boundingBox = CGRect(
            x: CGFloat(minX) / CGFloat(width),
            y: CGFloat(minY) / CGFloat(height),
            width: CGFloat(boxWidth) / CGFloat(width),
            height: CGFloat(boxHeight) / CGFloat(height)
        )

        return BallDetection(point: normalizedPoint, confidence: confidence, boundingBox: boundingBox)
    }

    private func isLikelyBallPixel(r: Int, g: Int, b: Int) -> Bool {
        let isBright = r > 110 && g > 110
        let greenYellowBand = b < 150 && abs(r - g) < 55
        let highContrast = (r + g) - b > 170
        return isBright && greenYellowBand && highContrast
    }
}

