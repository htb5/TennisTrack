import Combine
import SwiftUI

struct ReplayPlayerView: View {
    let frames: [CGImage]

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var isPlaying = true
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            if frames.isEmpty {
                Text("No replay captured yet")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                Image(decorative: frames[min(index, frames.count - 1)], scale: 1.0, orientation: .up)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topLeading) {
                        Text("Replay")
                            .padding(8)
                            .background(Color.black.opacity(0.65))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(10)
                    }
                    .onReceive(timer) { _ in
                        guard isPlaying, !frames.isEmpty else {
                            return
                        }
                        if index < frames.count - 1 {
                            index += 1
                        } else {
                            isPlaying = false
                        }
                    }
            }

            HStack(spacing: 12) {
                Button(isPlaying ? "Pause" : "Play") {
                    isPlaying.toggle()
                    if !isPlaying && index >= frames.count - 1 {
                        index = 0
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(frames.isEmpty)

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

