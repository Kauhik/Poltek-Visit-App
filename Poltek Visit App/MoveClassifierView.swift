
import SwiftUI

struct MoveClassifierView: View {
    @StateObject private var vm = ActionClassifierViewModel()

    /// Tracks whether SG and ID have been detected
    @State private var detectedSG = false
    @State private var detectedID = false

    /// Called when both SG and ID are detected (or “Done” tapped)
    var onDone: () -> Void
    var onBack: () -> Void

    var body: some View {
        ZStack {
            // Camera preview full‑screen
            if let uiImage = vm.previewImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    // Front‑camera upright rotation
                    .rotationEffect(vm.isUsingFrontCamera ? .degrees(180) : .degrees(0))
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack {
                Spacer()

                // MARK: Action labels
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.actionLabel)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(vm.confidenceLabel)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)

                    Spacer()
                }
                .padding(.horizontal)

                // MARK: Controls + SG/ID
                HStack(spacing: 16) {
                    // Back button
                    Button(action: {
                        vm.stop()
                        onBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }

                    // Flip camera
                    Button("Flip") {
                        vm.toggleCamera()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    // SG / ID indicators
                    HStack(spacing: 12) {
                        Text("SG")
                            .font(.subheadline).bold()
                            .foregroundColor(detectedSG ? .white : .gray)
                            .padding(6)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(6)
                        Text("ID")
                            .font(.subheadline).bold()
                            .foregroundColor(detectedID ? .white : .gray)
                            .padding(6)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(6)
                    }

                    Spacer()

                    // Manual Done
                    Button("Done") {
                        vm.stop()
                        onDone()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding([.horizontal, .bottom])
            }
        }
        .onAppear {
            detectedSG = false
            detectedID = false
            vm.start()
        }
        .onReceive(vm.$actionLabel) { label in
            if label == "SG"  { detectedSG = true }
            if label == "ID"  { detectedID = true }
            if detectedSG && detectedID {
                vm.stop()
                onDone()
            }
        }
    }
}

struct MoveClassifierView_Previews: PreviewProvider {
    static var previews: some View {
        MoveClassifierView(
            onDone: {},
            onBack: {}
        )
    }
}
