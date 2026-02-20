import AudioToolbox
import Foundation
import UIKit
import UserNotifications

final class OutCallNotifier {
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifyOutCall() {
        DispatchQueue.main.async {
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.error)
            AudioServicesPlaySystemSound(1113)
        }

        let content = UNMutableNotificationContent()
        content.title = "OUT"
        content.body = "Ball landed out of bounds."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

