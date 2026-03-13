import SwiftUI

struct StageBriefingView: View {
    let definition: StageDefinition
    let onStart: () -> Void
    @ObservedObject var viewModel: StageViewModel

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Phase \(definition.phase) · Stage \(definition.stage)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(definition.scenarioTitle)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
            }

            ScrollView {
                Text(definition.scenarioDescription)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }

            if let hint = viewModel.hintForCurrentFailures {
                HStack {
                    Image(systemName: viewModel.failureCount >= 5 ? "lightbulb.fill" : "lightbulb")
                        .foregroundStyle(.yellow)
                    Text(hint)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }

            Spacer()

            Button(action: onStart) {
                Text("Start Stage")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
        }
        .padding()
    }
}
