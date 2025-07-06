//
//  SystemAudioClassifier.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 6/7/25.
//


import Foundation
import AVFoundation
import SoundAnalysis
import CoreML

/// Protocol for audio updates.  Declared here once.
public protocol AudioClassificationDelegate: AnyObject {
    /// Called whenever the model produces a new label + confidence.
    func classificationDidUpdate(label: String, confidence: Double)
}

/// A thin wrapper around your Core ML “PoltekAudio” model,
/// driven by SoundAnalysis for live audio classification.
public class SystemAudioClassifier: NSObject, SNResultsObserving {
    public weak var delegate: AudioClassificationDelegate?

    private let engine = AVAudioEngine()
    private var streamAnalyzer: SNAudioStreamAnalyzer!
    private var request: SNClassifySoundRequest!

    /// Designated initializer.  Crashes early if setup fails.
    public override init() {
        super.init()

        // 1) Load the compiled CoreML model bundle
        guard let modelURL = Bundle.main.url(forResource: "PoltekAudio", withExtension: "mlmodelc") else {
            fatalError(" SystemAudioClassifier: PoltekAudio.mlmodelc not found")
        }

        let mlModel: MLModel
        do {
            mlModel = try MLModel(contentsOf: modelURL)
        } catch {
            fatalError(" SystemAudioClassifier: Failed to load MLModel: \(error)")
        }

        // 2) Create a SoundAnalysis request
        do {
            let req = try SNClassifySoundRequest(mlModel: mlModel)
            req.overlapFactor = 0.5
            self.request = req
        } catch {
            fatalError(" SystemAudioClassifier: Could not create SNClassifySoundRequest: \(error)")
        }

        // 3) Hook it up to an SNAudioStreamAnalyzer
        let format = engine.inputNode.outputFormat(forBus: 0)
        streamAnalyzer = SNAudioStreamAnalyzer(format: format)
        do {
            try streamAnalyzer.add(self.request, withObserver: self)
        } catch {
            fatalError(" SystemAudioClassifier: Failed to add request to stream analyzer: \(error)")
        }

        // 4) Install tap on the engine’s input node
        engine.inputNode.installTap(
            onBus: 0,
            bufferSize: 4096,
            format: format
        ) { buffer, when in
            self.streamAnalyzer.analyze(buffer, atAudioFramePosition: when.sampleTime)
        }

        engine.prepare()
    }

    /// Start capturing audio & classifying.
    public func start() {
        do {
            try engine.start()
        } catch {
            print(" SystemAudioClassifier: Failed to start engine:", error)
        }
    }

    /// Stop everything.
    public func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }

    // MARK: – SNResultsObserving

    public func request(_ request: SNRequest, didProduce result: SNResult) {
        guard
            let res = result as? SNClassificationResult,
            let best = res.classifications.first
        else { return }

        delegate?.classificationDidUpdate(
            label: best.identifier,
            confidence: Double(best.confidence)
        )
    }

    public func request(_ request: SNRequest, didFailWithError error: Error) {
        print("Audio analysis failed:", error)
    }

    public func requestDidComplete(_ request: SNRequest) {
        // nothing to do
    }
}
