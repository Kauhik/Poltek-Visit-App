//
//  MoveClassifierView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 17/7/25.
//

import Foundation
import SwiftUI

struct MoveClassifierView: View {
    @StateObject private var vm = ActionClassifierViewModel()
    @State private var showingSummary = false

    /// Called when the user taps “Done”
    var onDone: () -> Void
    /// Called when the user taps “Back”
    var onBack: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                if let uiImage = vm.previewImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Color.black.edgesIgnoringSafeArea(.all)
                }

                VStack {
                    Spacer()

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

                    HStack {
                        Button("Flip") {
                            vm.toggleCamera()
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)

                        Spacer()

                        Button("Done") {
                            vm.stop()
                            onDone()
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                    }
                    .padding([.horizontal, .bottom])
                }
            }
            .onAppear { vm.start() }
            .sheet(isPresented: $showingSummary, onDismiss: { vm.start() }) {
                SummaryView(actionFrameCounts: vm.actionFrameCounts)
            }
            .navigationTitle("Move")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        vm.stop()
                        onBack()
                    }
                }
            }
        }
    }
}
