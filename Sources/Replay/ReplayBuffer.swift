import AVFoundation
import CoreGraphics
import Foundation
import VideoToolbox

struct ReplayFrame {
    let image: CGImage
    let timestamp: CMTime
}

final class ReplayBuffer {
    private var frames: [ReplayFrame] = []
    private let maxDurationSeconds: Double
    private let lock = NSLock()

    init(maxDurationSeconds: Double) {
        self.maxDurationSeconds = maxDurationSeconds
    }

    func append(image: CGImage, timestamp: CMTime) {
        lock.lock()
        defer {
            lock.unlock()
        }

        frames.append(ReplayFrame(image: image, timestamp: timestamp))
        trimIfNeeded()
    }

    func frames(lastSeconds: Double) -> [ReplayFrame] {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard let latest = frames.last else {
            return []
        }
        let threshold = latest.timestamp.seconds - lastSeconds
        return frames.filter { $0.timestamp.seconds >= threshold }
    }

    private func trimIfNeeded() {
        guard let latest = frames.last else {
            return
        }
        let oldestAllowed = latest.timestamp.seconds - maxDurationSeconds
        while let first = frames.first, first.timestamp.seconds < oldestAllowed {
            frames.removeFirst()
        }
    }

    static func makeCGImage(from sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        return cgImage
    }
}

