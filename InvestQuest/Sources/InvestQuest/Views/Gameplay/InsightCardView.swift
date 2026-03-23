import SwiftUI

struct InsightCardView: View {
    let insightText: String
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding = AppTheme.contentHorizontalPadding(for: geometry.size.width)
            let topPadding = AppTheme.contentTopPadding(for: geometry.size.width)
            let bottomPadding = AppTheme.contentBottomPadding(for: geometry.size.width)

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

                        Text(insightText.ko)
                            .font(.system(.body, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppTheme.textSecondary)

                        Text("Carry this forward into the next stage.".ko)
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .questCard()

                    Button(action: onDismiss) {
                        Text("Continue".ko)
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(QuestPrimaryButtonStyle())
                    .accessibilityIdentifier("continue-from-insight")
                }
                .questReadableContentFrame(in: geometry.size.width)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
            }
            .scrollClipDisabled()
        }
        .foregroundStyle(AppTheme.textPrimary)
        .accessibilityElement(children: .contain)
    }
}
