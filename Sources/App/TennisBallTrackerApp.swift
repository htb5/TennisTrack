import SwiftUI

@main
struct TennisBallTrackerApp: App {
    @StateObject private var viewModel = TrackingViewModel()

    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
        }
    }
}

