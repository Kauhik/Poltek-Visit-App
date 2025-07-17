////
////  MoveClassifierView.swift
////  Poltek Visit App
////
////  Created by Kaushik Manian on 17/7/25.
////
//
//import SwiftUI
//
//struct MoveClassifierView: View {
//    @StateObject private var vm = ActionClassifierViewModel()
//    @State private var showingSummary = false
//
//    /// Called when the user taps “Done”
//    var onDone: () -> Void
//    /// Called when the user taps “Back”
//    var onBack: () -> Void
//
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                if let uiImage = vm.previewImage {
//                    Image(uiImage: uiImage)
//                        .resizable()
//                        .scaledToFill()
//                        // Flip X+Y on front camera (rotates 180° + mirrors)
//                        .scaleEffect(
//                            x: vm.isUsingFrontCamera ? -1 : 1,
//                            y: vm.isUsingFrontCamera ? -1 : 1,
//                            anchor: .center
//                        )
//                        .edgesIgnoringSafeArea(.all)
//                } else {
//                    Color.black.edgesIgnoringSafeArea(.all)
//                }
//
//                VStack {
//                    Spacer()
//
//                    HStack {
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text(vm.actionLabel)
//                                .font(.headline)
//                                .foregroundColor(.white)
//                            Text(vm.confidenceLabel)
//                                .font(.subheadline)
//                                .foregroundColor(.white)
//                        }
//                        .padding(8)
//                        .background(Color.black.opacity(0.5))
//                        .cornerRadius(10)
//
//                        Spacer()
//                    }
//                    .padding(.horizontal)
//
//                    HStack {
//                        Button("Flip") {
//                            vm.toggleCamera()
//                        }
//                        .padding()
//                        .background(Color.black.opacity(0.5))
//                        .cornerRadius(10)
//
//                        Spacer()
//
//                        Button("Done") {
//                            vm.stop()
//                            onDone()
//                        }
//                        .padding()
//                        .background(Color.black.opacity(0.5))
//                        .cornerRadius(10)
//                    }
//                    .padding([.horizontal, .bottom])
//                }
//            }
//            .onAppear { vm.start() }
//            .sheet(isPresented: $showingSummary, onDismiss: { vm.start() }) {
//                SummaryView(actionFrameCounts: vm.actionFrameCounts)
//            }
//            .navigationTitle("Move")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Back") {
//                        vm.stop()
//                        onBack()
//                    }
//                }
//            }
//        }
//    }
//}
//
//struct MoveClassifierView_Previews: PreviewProvider {
//    static var previews: some View {
//        MoveClassifierView(onDone: {}, onBack: {})
//    }
//}


//
// MoveClassifierView.swift
// Poltek Visit App
// Updated to highlight “SG” and “ID” as they’re detected and advance when both are seen.
//

import SwiftUI

struct MoveClassifierView: View {
    @StateObject private var vm = ActionClassifierViewModel()
    @State private var showingSummary = false

    /// Tracks whether SG and ID have been detected
    @State private var detectedSG = false
    @State private var detectedID = false

    /// Called when both SG and ID are detected (or “Done” tapped)
    var onDone: () -> Void
    var onBack: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: Camera preview
                if let uiImage = vm.previewImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        // Front‑camera upright rotation
                        .rotationEffect(vm.isUsingFrontCamera ? .degrees(180) : .degrees(0))
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Color.black.edgesIgnoringSafeArea(.all)
                }

                VStack {
                    Spacer()

                    // MARK: Labels overlay
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

                    // MARK: Controls + SG/ID indicators
                    HStack(spacing: 16) {
                        // Back button
                        Button(action: onBack) {
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
                // Mark SG or ID when seen
                if label == "SG"  { detectedSG = true }
                if label == "ID"  { detectedID = true }
                // If both detected, advance
                if detectedSG && detectedID {
                    vm.stop()
                    onDone()
                }
            }
            .sheet(isPresented: $showingSummary, onDismiss: { vm.start() }) {
                SummaryView(actionFrameCounts: vm.actionFrameCounts)
            }
            .navigationTitle("Move")
            .navigationBarHidden(true)
        }
    }
}

struct MoveClassifierView_Previews: PreviewProvider {
    static var previews: some View {
        MoveClassifierView(onDone: {}, onBack: {})
    }
}
