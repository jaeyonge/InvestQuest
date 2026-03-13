import SwiftUI

struct InsightCardView: View {
    let insightText: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text("Key Insight")
                .font(.title2.bold())

            Text(insightText)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

            Spacer()

            Button(action: onDismiss) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
    }
}
