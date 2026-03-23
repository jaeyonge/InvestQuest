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
    private let selection      = UISelectionFeedbackGenerator()
    private let notification   = UINotificationFeedbackGenerator()

    private init() {
        // Pre-prepare generators to reduce latency on first use
        impactHeavy.prepare()
        impactMedium.prepare()
        selection.prepare()
        notification.prepare()
    }

    /// Fire heavy impact — used when an asset crashes / significant loss occurs.
    func fireCrashEvent() {
        impactHeavy.impactOccurred()
        impactHeavy.prepare()
    }

    /// Fire medium impact — used when a simulation milestone is reached (e.g. new period, 50%).
    func fireMilestone() {
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }

    /// Fire a light selection pulse for each discrete chart advance step.
    func fireStep() {
        selection.selectionChanged()
        selection.prepare()
    }

    /// Fire notification success — used when an achievement or phase badge is awarded.
    func fireAchievement() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    /// Fire notification warning — used for a significant loss that doesn't crash completely.
    func fireLossWarning() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }
}
