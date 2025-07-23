
import SwiftUI

struct MoveClassifierView: View {
    // MARK: – Persistence keys
    private static let keyDetectedSG = "MoveClassifierView.detectedSG"
    private static let keyDetectedID = "MoveClassifierView.detectedID"

    // MARK: – Persisted storage
    @AppStorage(keyDetectedSG) private var storedDetectedSG: Bool = false
    @AppStorage(keyDetectedID) private var storedDetectedID: Bool = false

    // MARK: – UI state
    @StateObject private var vm = ActionClassifierViewModel()
    @Namespace private var moveAnimation

    @State private var detectedSG = false
    @State private var detectedID = false

    @State private var showMultiPersonToast = false
    @State private var showWholeBodyToast = false

    var onDone: () -> Void
    var onBack: () -> Void

    var body: some View {
        ZStack {
            if let image = vm.previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .rotationEffect(vm.isUsingFrontCamera ? .degrees(180) : .degrees(0))
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(vm.actionLabel)
                            .font(.title2).bold().foregroundColor(.white)
                        Text(vm.confidenceLabel)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    Spacer()
                }
                .padding(.top, 80)

                if showMultiPersonToast {
                    Text("Ensure there’s only one person")
                        .font(.subheadline).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }

                if showWholeBodyToast {
                    Text("Whole body must be visible")
                        .font(.subheadline).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.8))
                        .cornerRadius(12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }

                Spacer()

                HStack {
                    Spacer()
                    animatedMoveLabels()
                    Spacer()
                }
                .padding(.bottom, 30)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            detectedSG = storedDetectedSG
            detectedID = storedDetectedID
            vm.start()
        }
        .onReceive(vm.$actionLabel) { label in
            if label == "SG", !detectedSG {
                detectedSG = true
                storedDetectedSG = true
            }
            if label == "ID", !detectedID {
                detectedID = true
                storedDetectedID = true
            }
            if detectedSG && detectedID {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    vm.stop()
                    onDone()
                }
            }
        }
        .onReceive(vm.$poseCount) { count in
            guard count > 1 else { return }
            withAnimation { showMultiPersonToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showMultiPersonToast = false }
            }
        }
        .onReceive(vm.$largestPoseArea) { area in
            // if the person is too small (body off-camera), warn
            if vm.poseCount == 1, area < 0.3 {
                withAnimation { showWholeBodyToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showWholeBodyToast = false }
                }
            }
        }
    }

    private func animatedMoveLabels() -> some View {
        HStack(spacing: 24) {
            moveDetectionItem(label: "SG",
                              fullName: "Singapore",
                              number: 1,
                              isDetected: detectedSG,
                              colors: [.red, .orange])
            moveDetectionItem(label: "ID",
                              fullName: "Indonesia",
                              number: 2,
                              isDetected: detectedID,
                              colors: [.blue, .cyan])
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func moveDetectionItem(
        label: String,
        fullName: String,
        number: Int,
        isDetected: Bool,
        colors: [Color]
    ) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        isDetected
                        ? LinearGradient(colors: colors,
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.gray.opacity(0.3),
                                                  .gray.opacity(0.1)],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing)
                    )
                    .frame(width: 50, height: 50)

                if vm.actionLabel == label && !isDetected {
                    Circle()
                        .stroke(colors.first!, lineWidth: 2)
                        .frame(width: 50, height: 50)
                        .scaleEffect(1.3)
                        .opacity(0.6)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true),
                                   value: vm.actionLabel)
                }

                Text("\(number)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(isDetected ? .black : .white)
            }
            .scaleEffect(isDetected
                         ? 1.2
                         : vm.actionLabel == label ? 1.1 : 1)
            .rotationEffect(.degrees(isDetected ? 360 : 0))
            .shadow(color: isDetected
                    ? colors.first!.opacity(0.6)
                    : vm.actionLabel == label
                        ? colors.first!.opacity(0.3)
                        : .clear,
                    radius: isDetected ? 10 : vm.actionLabel == label ? 5 : 0)

            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(fullName)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isDetected
                          ? colors.first!
                          : vm.actionLabel == label
                            ? .yellow.opacity(0.7)
                            : .gray.opacity(0.3))
                    .frame(width: 60, height: 4)

                Text(isDetected
                     ? "✓ Done"
                     : (vm.actionLabel == label ? "Detecting..." : "Waiting"))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 100)
        .matchedGeometryEffect(id: label, in: moveAnimation)
        .animation(.spring(response: 0.8, dampingFraction: 0.6)
                    .delay(Double(number) * 0.1),
                   value: isDetected)
        .animation(.easeInOut(duration: 0.3),
                   value: vm.actionLabel == label)
    }
}




struct MoveClassifierView_Previews: PreviewProvider {
    static var previews: some View {
        MoveClassifierView(onDone: {}, onBack: {})
    }
}
