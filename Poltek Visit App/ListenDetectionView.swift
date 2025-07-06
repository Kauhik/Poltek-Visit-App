//
//  ListenDetectionView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 6/7/25.
//

import SwiftUI
import SoundAnalysis
import CoreML

/// The four sound labels in your PoltekAudio model.
public enum SoundIdentifier: String, CaseIterable {
    case iceCream         = "Campina Ice Cream song"
    case doorsClosing     = "SMRT Doors Closing"
    case pedestrianButton = "Singapore Pedestrian Crossing Button"
    case wallKeliling     = "Suara Es Krim Wall's Keliling"

    public var displayName: String { rawValue }
}

/// Tracks a single sound’s “found/not found” as 0→1 progress.
public struct DetectionState {
    public var currentConfidence: Double = 0
}

/// Drives the 1×4 grid of bars by listening for high-confidence hits.
public class ListenDetectionManager: ObservableObject {
    @Published public var detectionStates: [(SoundIdentifier, DetectionState)]

    private var classifier: SystemAudioClassifier?
    private let detectionThreshold: Double = 0.8

    public init() {
        // start all four at zero
        detectionStates = SoundIdentifier.allCases.map { ($0, DetectionState()) }
        restart()
    }

    /// Reset all bars → 0 and restart the classifier.
    public func restart() {
        detectionStates = SoundIdentifier.allCases.map { ($0, DetectionState()) }
        classifier?.stop()
        classifier = nil

        let new = SystemAudioClassifier()
        new.delegate = self
        classifier = new
        new.start()
    }
}

extension ListenDetectionManager: AudioClassificationDelegate {
    public func classificationDidUpdate(label: String, confidence: Double) {
        // ignore low-confidence guesses
        guard
            confidence >= detectionThreshold,
            let id = SoundIdentifier(rawValue: label),
            let idx = detectionStates.firstIndex(where: { $0.0 == id })
        else { return }

        DispatchQueue.main.async {
            // mark that bar fully “found”
            self.detectionStates[idx].1.currentConfidence = 1.0
        }
    }
}

/// The SwiftUI view showing mic icon, 4 bars, and “Next” button.
public struct ListenDetectionView: View {
    @StateObject private var manager = ListenDetectionManager()
    public var onAllDetected: () -> Void
    public var onNext: () -> Void

    public init(
        onAllDetected: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.onAllDetected = onAllDetected
        self.onNext = onNext
    }

    public var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.fill")
                .font(.system(size: 80))
            Text("Listening to audio")
                .foregroundColor(.white)

            HStack(spacing: 16) {
                ForEach(manager.detectionStates, id: \.0) { id, state in
                    VStack(spacing: 8) {
                        ProgressView(value: state.currentConfidence)
                            .progressViewStyle(.linear)
                            .frame(height: 6)
                            .tint(.white)
                        Text(id.displayName)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                    }
                    .frame(width: 70)
                }
            }

            Button("Next") { onNext() }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
        }
        .padding(.horizontal, 16)
        // Auto-advance when all four are “found”
        .onReceive(manager.$detectionStates) { states in
            if states.allSatisfy({ $0.1.currentConfidence >= 1.0 }) {
                onAllDetected()
            }
        }
        // Reset + kick off listening each time this view appears
        .onAppear {
            manager.restart()
        }
    }
}
