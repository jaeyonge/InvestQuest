import SwiftUI

struct InsightCardView: View {
    let insightText: String
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                QuestSectionHeader(
                    eyebrow: "Takeaway",
                    title: "Key Insight",
                    subtitle: "Lock in the lesson before you move on."
                )

                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.highlight.opacity(0.14))
                            .frame(width: 90, height: 90)
                        Image(systemName: "lightbulb.max.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(AppTheme.highlight)
                    }

                    Text(insightText)
                        .font(.system(.body, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.textSecondary)

                    Text("Carry this forward into the next stage.")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .questCard()

                Button(action: onDismiss) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuestPrimaryButtonStyle())
                .accessibilityIdentifier("continue-from-insight")
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .foregroundStyle(AppTheme.textPrimary)
        .accessibilityElement(children: .contain)
    }
}
