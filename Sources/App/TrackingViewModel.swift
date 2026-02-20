import AVFoundation
import Foundation
import SwiftUI

final class TrackingViewModel: ObservableObject {
    enum CallState {
        case searching
        case inCall
        case outCall

        var label: String {
            switch self {
            case .searching:
                return "Searching For Ball"
            case .inCall:
                return "IN"
            case .outCall:
                return "OUT"
            }
        }

        var color: Color {
            switch self {
            case .searching:
                return .blue
            case .inCall:
                return .green
            case .outCall:
                return .red
            }
        }
    }

    @Published var ballPoint: CGPoint?
    @Published var callState: CallState = .searching
    @Published var replayFrames: [CGImage] = []
    @Published var isReplayPresented = false
    @Published var isRunning = false

    let courtModel = CourtModel.defaultSingles

    var session: AVCaptureSession {
        cameraService.session
    }

    private let cameraService = CameraService()
    private let detector = TennisBallDetector()
    private let bounceDetector = BounceDetector()
    private let replayBuffer = ReplayBuffer(maxDurationSeconds: 8.0)
    private let notifier = OutCallNotifier()
    private let replayWindowSeconds = 5.0
    private var lastOutTimestamp = -Double.infinity

    init() {
        cameraService.frameHandler = { [weak self] sampleBuffer in
            self?.handle(sampleBuffer: sampleBuffer)
        }
        notifier.requestPermission()
    }

    func start() {
        isRunning = true
        cameraService.start()
    }

    func stop() {
        isRunning = false
        cameraService.stop()
    }

    func presentReplay() {
        let frames = replayBuffer.frames(lastSeconds: replayWindowSeconds).map(\.image)
        DispatchQueue.main.async {
            self.replayFrames = frames
            self.isReplayPresented = !frames.isEmpty
        }
    }

    private func handle(sampleBuffer: CMSampleBuffer) {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        if let image = ReplayBuffer.makeCGImage(from: sampleBuffer) {
            replayBuffer.append(image: image, timestamp: timestamp)
        }

        guard let detection = detector.detect(in: sampleBuffer) else {
            return
        }

        DispatchQueue.main.async {
            self.ballPoint = detection.point
            if self.callState == .searching {
                self.callState = .inCall
            }
        }

        if let bounce = bounceDetector.consume(point: detection.point, time: timestamp.seconds) {
            evaluateBounce(bounce)
        }
    }

    private func evaluateBounce(_ bounce: BounceEvent) {
        let isIn = courtModel.contains(point: bounce.point)
        DispatchQueue.main.async {
            self.callState = isIn ? .inCall : .outCall
        }

        guard !isIn else {
            return
        }

        guard bounce.timestamp - lastOutTimestamp > 0.8 else {
            return
        }
        lastOutTimestamp = bounce.timestamp

        notifier.notifyOutCall()
        let frames = replayBuffer.frames(lastSeconds: replayWindowSeconds).map(\.image)
        DispatchQueue.main.async {
            self.replayFrames = frames
            self.isReplayPresented = !frames.isEmpty
        }
    }
}

