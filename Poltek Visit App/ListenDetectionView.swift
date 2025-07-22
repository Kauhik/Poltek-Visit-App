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

/// Manages the classifier + raw results → binary “found” states.
public class ListenDetectionManager: ObservableObject {
    @Published public var detectionStates: [(SoundIdentifier, DetectionState)]
    private var classifier: SystemAudioClassifier?
    private let detectionThreshold: Double = 0.8

    public init() {
        detectionStates = SoundIdentifier.allCases.map { ($0, DetectionState()) }
    }

    /// Only start listening once; call this explicitly.
    public func startListening() {
        // reset states if you really need a fresh start:
        detectionStates = SoundIdentifier.allCases.map { ($0, DetectionState()) }
        classifier?.stop()
        classifier = nil
        let newClassifier = SystemAudioClassifier()
        newClassifier.delegate = self
        classifier = newClassifier
        newClassifier.start()
    }
}

extension ListenDetectionManager: AudioClassificationDelegate {
    public func classificationDidUpdate(label: String, confidence: Double) {
        guard confidence >= detectionThreshold,
              let id = SoundIdentifier(rawValue: label),
              let idx = detectionStates.firstIndex(where: { $0.0 == id })
        else { return }

        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                self.detectionStates[idx].1.currentConfidence = 1.0
            }
        }
    }
}

/// The SwiftUI view showing mic icon, 4 items, and auto-advance after detection.
public struct ListenDetectionView: View {
    @Binding var detectedClues: Set<Int>
    @StateObject private var manager = ListenDetectionManager()
    @Namespace private var audioAnimation

    /// Called after the 1 second buffer once all detect.
    public var onAllDetected: () -> Void
    /// Manual override
    public var onNext: () -> Void

    @State private var didScheduleAdvance = false
    @State private var didSetup = false

    public init(
        detectedClues: Binding<Set<Int>>,
        onAllDetected: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self._detectedClues = detectedClues
        self.onAllDetected = onAllDetected
        self.onNext = onNext
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "waveform.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 80))
                    .scaleEffect(
                        manager.detectionStates.contains { $0.1.currentConfidence >= 1.0 }
                        ? 1.1 : 1.0
                    )
                    .animation(
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: manager.detectionStates.map { $0.1.currentConfidence }
                    )

                Text("Listening for sounds")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Spacer()

                animatedAudioLabels()

                Spacer()
            }
        }
        .onAppear {
            // only set up once
            guard !didSetup else { return }
            didSetup = true
            manager.startListening()
            // replay any previously detected clues into the UI
            for idx in detectedClues {
                let pos = idx - 1
                if manager.detectionStates.indices.contains(pos) {
                    manager.detectionStates[pos].1.currentConfidence = 1.0
                }
            }
            didScheduleAdvance = false
        }
        .onReceive(manager.$detectionStates) { states in
            // mark each newly detected sound
            for (idx, item) in states.enumerated() {
                if item.1.currentConfidence >= 1.0 {
                    detectedClues.insert(idx + 1)
                }
            }
            // once all four have fired
            guard !didScheduleAdvance,
                  states.allSatisfy({ $0.1.currentConfidence >= 1.0 })
            else { return }

            didScheduleAdvance = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                onAllDetected()
            }
        }
    }

    private func animatedAudioLabels() -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                ForEach(Array(manager.detectionStates.prefix(2).enumerated()), id: \.element.0) { index, pair in
                    audioDetectionItem(identifier: index,
                                       state: pair.1,
                                       number: index + 1)
                }
            }
            HStack(spacing: 20) {
                ForEach(Array(manager.detectionStates.dropFirst(2).enumerated()), id: \.element.0) { index, pair in
                    audioDetectionItem(identifier: index + 2,
                                       state: pair.1,
                                       number: index + 3)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    private func audioDetectionItem(
        identifier: Int,
        state: DetectionState,
        number: Int
    ) -> some View {
        let isDetected  = state.currentConfidence >= 1.0
        let isListening = state.currentConfidence > 0 && state.currentConfidence < 1.0

        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        isDetected
                        ? LinearGradient(colors: [Color.purple, Color.pink],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing)
                        : isListening
                        ? LinearGradient(colors: [Color.orange.opacity(0.7), Color.yellow.opacity(0.7)],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing)
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                isDetected ? Color.white.opacity(0.3)
                                : isListening ? Color.orange.opacity(0.5)
                                : Color.gray.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    .frame(width: 44, height: 44)

                if isListening {
                    Circle()
                        .stroke(Color.orange, lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .scaleEffect(1.2)
                        .opacity(0.6)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true),
                                   value: isListening)
                }

                Text("\(number)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(isDetected ? .black : .white)
            }
            .frame(width: 80)

            Text(SoundIdentifier.allCases[identifier].displayName)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            if !isDetected {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isListening ? Color.orange.opacity(0.3) : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isListening ? Color.orange : .clear)
                            .frame(width: 60 * state.currentConfidence, height: 3),
                        alignment: .leading
                    )
            }
        }
        .matchedGeometryEffect(id: identifier, in: audioAnimation)
        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(Double(number) * 0.1),
                   value: isDetected)
        .animation(.easeInOut(duration: 0.3), value: isListening)
    }
}
