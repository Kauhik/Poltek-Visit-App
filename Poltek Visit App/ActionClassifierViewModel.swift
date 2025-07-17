// File: ActionClassifierViewModel.swift
// See LICENSE folder for this sample’s licensing information.
// Abstract:
// Hosts the capture + processing chain and bridges to SwiftUI.

import SwiftUI
import Combine
import UIKit

@MainActor
class ActionClassifierViewModel: NSObject,
                                  ObservableObject,
                                  VideoCaptureDelegate,
                                  VideoProcessingChainDelegate {
    // MARK: - Published UI state
    @Published var previewImage: UIImage?
    @Published var actionLabel: String = ActionPrediction.startingPrediction.label
    @Published var confidenceLabel: String = "Observing..."
    @Published var actionFrameCounts: [String: Int] = [:]

    /// New: mirror preview when front camera
    @Published var isUsingFrontCamera: Bool

    private let videoCapture = VideoCapture()
    private var videoProcessingChain = VideoProcessingChain()
    
    override init() {
        // Initialize mirror flag
        isUsingFrontCamera = (videoCapture.currentPosition == .front)
        super.init()
        videoCapture.delegate = self
        videoProcessingChain.delegate = self
    }

    /// Start capture + processing
    func start() {
        videoCapture.updateDeviceOrientation()
        videoCapture.isEnabled = true
    }

    /// Stop capture
    func stop() {
        videoCapture.isEnabled = false
    }

    /// Flip between front/back camera
    func toggleCamera() {
        videoCapture.toggleCameraSelection()
        // Update mirroring flag
        isUsingFrontCamera = (videoCapture.currentPosition == .front)
    }

    // ... rest of your delegates & drawing code unchanged ...
    
    func videoCapture(_ videoCapture: VideoCapture,
                      didCreate framePublisher: FramePublisher) {
        // reset labels
        actionLabel = ActionPrediction.startingPrediction.label
        confidenceLabel = "Observing..."
        // feed into processing chain
        videoProcessingChain.upstreamFramePublisher = framePublisher
    }

    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didDetect poses: [Pose]?,
                              in frame: CGImage) {
        let img = drawPoses(poses, onto: frame)
        previewImage = img
    }

    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didPredict actionPrediction: ActionPrediction,
                              for frames: Int) {
        if actionPrediction.isModelLabel {
            let total = (actionFrameCounts[actionPrediction.label] ?? 0) + frames
            actionFrameCounts[actionPrediction.label] = total
        }
        actionLabel = actionPrediction.label
        confidenceLabel = actionPrediction.confidenceString ?? "Observing..."
    }

    private func drawPoses(_ poses: [Pose]?, onto frame: CGImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let size = CGSize(width: frame.width, height: frame.height)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.draw(frame, in: CGRect(origin: .zero, size: size))
            let transform = CGAffineTransform(scaleX: size.width,
                                              y: size.height)
            poses?.forEach { $0.drawWireframeToContext(cg,
                                                       applying: transform) }
        }
    }
}
