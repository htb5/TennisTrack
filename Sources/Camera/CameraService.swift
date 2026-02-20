import AVFoundation
import Foundation

final class CameraService: NSObject {
    let session = AVCaptureSession()

    var frameHandler: ((CMSampleBuffer) -> Void)?

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let outputQueue = DispatchQueue(label: "camera.output.queue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isConfigured = false

    func start() {
        ensureAuthorization { [weak self] granted in
            guard let self, granted else {
                return
            }

            self.sessionQueue.async {
                if !self.isConfigured {
                    self.configureSession()
                }
                guard !self.session.isRunning else {
                    return
                }
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async {
            guard self.session.isRunning else {
                return
            }
            self.session.stopRunning()
        }
    }

    private func ensureAuthorization(_ completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }

        session.sessionPreset = .hd1280x720

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: camera),
            session.canAddInput(input)
        else {
            return
        }
        session.addInput(input)

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)

        guard session.canAddOutput(videoOutput) else {
            return
        }
        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video),
           connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        isConfigured = true
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        frameHandler?(sampleBuffer)
    }
}

