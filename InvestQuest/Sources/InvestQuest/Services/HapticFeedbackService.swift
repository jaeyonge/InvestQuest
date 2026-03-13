import UIKit

/// Wraps UIKit feedback generators to provide haptic feedback at key gameplay moments.
///
/// Feedback is fired on:
///   - Crash events (impact — heavy, conveys consequence)
///   - Milestones  (notification success — celebratory)
///   - Achievements / phase completion (notification success — celebratory)
final class HapticFeedbackService {

    static let shared = HapticFeedbackService()

    private let impactHeavy    = UIImpactFeedbackGenerator(style: .heavy)
    private let impactMedium   = UIImpactFeedbackGenerator(style: .medium)
    private let notification   = UINotificationFeedbackGenerator()

    private init() {
        // Pre-prepare generators to reduce latency on first use
        impactHeavy.prepare()
        impactMedium.prepare()
        notification.prepare()
    }

    /// Fire heavy impact — used when an asset crashes / significant loss occurs.
    func fireCrashEvent() {
        impactHeavy.impactOccurred()
    }

    /// Fire medium impact — used when a simulation milestone is reached (e.g. new period, 50%).
    func fireMilestone() {
        impactMedium.impactOccurred()
    }

    /// Fire notification success — used when an achievement or phase badge is awarded.
    func fireAchievement() {
        notification.notificationOccurred(.success)
    }

    /// Fire notification warning — used for a significant loss that doesn't crash completely.
    func fireLossWarning() {
        notification.notificationOccurred(.warning)
    }
}
