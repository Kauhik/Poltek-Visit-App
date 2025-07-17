import SwiftUI

struct SummaryView: View {
    let actionFrameCounts: [String: Int]
    @Environment(\.dismiss) private var dismiss

    private var sortedActions: [(String, Int)] {
        actionFrameCounts.sorted { $0.value > $1.value }
    }

    var body: some View {
        NavigationView {
            List(sortedActions, id: \.0) { action, frames in
                HStack {
                    Text(action)
                    Spacer()
                    Text(String(
                        format: "%0.1fs",
                        Double(frames) / PoltekActionClassifierORGINAL.frameRate
                    ))
                }
            }
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
