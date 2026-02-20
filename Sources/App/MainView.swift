import AVFoundation
import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: TrackingViewModel

    var body: some View {
        GeometryReader { _ in
            ZStack {
                CameraPreviewView(session: viewModel.session)
                    .ignoresSafeArea()

                CourtBoundsOverlay(boundary: viewModel.courtModel.boundary)

                if let point = viewModel.ballPoint {
                    BallMarker(point: point)
                }

                VStack(spacing: 12) {
                    StatusChip(label: viewModel.callState.label, color: viewModel.callState.color)
                    Spacer()
                    HStack(spacing: 12) {
                        Button(viewModel.isRunning ? "Stop" : "Start") {
                            viewModel.isRunning ? viewModel.stop() : viewModel.start()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Replay Last Shot") {
                            viewModel.presentReplay()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .overlay(alignment: .topLeading) {
                Text("MVP Assistive Line Call")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
            }
            .onAppear {
                viewModel.start()
            }
            .onDisappear {
                viewModel.stop()
            }
            .sheet(isPresented: $viewModel.isReplayPresented) {
                ReplayPlayerView(frames: viewModel.replayFrames)
            }
        }
    }
}

private struct BallMarker: View {
    let point: CGPoint

    var body: some View {
        GeometryReader { geometry in
            Circle()
                .stroke(Color.yellow, lineWidth: 3)
                .frame(width: 26, height: 26)
                .position(
                    x: point.x * geometry.size.width,
                    y: point.y * geometry.size.height
                )
        }
        .allowsHitTesting(false)
    }
}

private struct CourtBoundsOverlay: View {
    let boundary: [CGPoint]

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard let first = boundary.first else {
                    return
                }
                path.move(to: scaled(first, in: geometry.size))
                for point in boundary.dropFirst() {
                    path.addLine(to: scaled(point, in: geometry.size))
                }
                path.closeSubpath()
            }
            .stroke(Color.white.opacity(0.8), lineWidth: 2)
            .shadow(radius: 3)
        }
        .allowsHitTesting(false)
    }

    private func scaled(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
}

private struct StatusChip: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(color.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
