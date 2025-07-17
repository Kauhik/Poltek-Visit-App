// File: VideoProcessingChain.swift
// Builds a chain of Combine publisher‑subscribers upon the video capture session’s
// frame publisher, but throttles to ~15 fps to avoid overloading Vision & UI.

import Vision
import Combine
import CoreImage

@MainActor
protocol VideoProcessingChainDelegate: AnyObject {
    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didDetect poses: [Pose]?,
                              in frame: CGImage)
    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didPredict actionPrediction: ActionPrediction,
                              for frames: Int)
}

class VideoProcessingChain {
    weak var delegate: VideoProcessingChainDelegate?

    var upstreamFramePublisher: AnyPublisher<Frame, Never>? {
        didSet { buildProcessingChain() }
    }

    private var frameProcessingChain: AnyCancellable?
    private let actionClassifier = PoltekActionClassifierORGINAL.shared
    private let predictionWindowSize: Int
    private let windowStride = 10

    private let ciContext = CIContext(options: nil)
    private let visionQueue = DispatchQueue(
        label: "VideoProcessingChain.VisionQueue", qos: .userInitiated
    )
    private var performanceReporter = PerformanceReporter()

    init() {
        predictionWindowSize = actionClassifier.calculatePredictionWindowSize()
    }

    private func buildProcessingChain() {
        guard let publisher = upstreamFramePublisher else { return }

        frameProcessingChain = publisher
            // run on our Vision queue
            .receive(on: visionQueue)
            // throttle down to ~15 fps
            .throttle(for: .milliseconds(66),
                      scheduler: visionQueue,
                      latest: true)
            // convert buffer → CGImage
            .compactMap { buffer -> CGImage? in
                guard let imageBuffer = buffer.imageBuffer else { return nil }
                let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                return self.ciContext.createCGImage(ciImage,
                                               from: ciImage.extent)
            }
            // detect poses
            .compactMap { [weak self] frame -> [Pose]? in
                guard let self = self else { return nil }
                return self.detectPoses(in: frame)
            }
            // ML windowing & prediction
            .map(isolateLargestPose)
            .map(multiArrayFromPose)
            .scan([MLMultiArray?](), gatherWindow)
            .filter(gateWindow)
            .map(predictActionWithWindow)
            .sink(receiveValue: sendPrediction)
    }

    private func detectPoses(in frame: CGImage) -> [Pose]? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: frame,
                                            orientation: .up,
                                            options: [:])
        do { try handler.perform([request]) }
        catch {
            assertionFailure("Pose request failed: \(error)")
            return nil
        }
        let observations = request.results as? [VNHumanBodyPoseObservation]
        let poses = Pose.fromObservations(observations)
        DispatchQueue.main.async {
            self.delegate?.videoProcessingChain(self,
                                                didDetect: poses,
                                                in: frame)
        }
        return poses
    }

    private func isolateLargestPose(_ poses: [Pose]?) -> Pose? {
        poses?.max(by: { $0.area < $1.area })
    }

    private func multiArrayFromPose(_ item: Pose?) -> MLMultiArray? {
        item?.multiArray
    }

    private func gatherWindow(previousWindow: [MLMultiArray?],
                              multiArray: MLMultiArray?) -> [MLMultiArray?] {
        var window = previousWindow
        if window.count == predictionWindowSize {
            window.removeFirst(windowStride)
        }
        window.append(multiArray)
        return window
    }

    private func gateWindow(_ window: [MLMultiArray?]) -> Bool {
        window.count == predictionWindowSize
    }

    private func predictActionWithWindow(_ window: [MLMultiArray?]) -> ActionPrediction {
        var count = 0
        let filled = window.map { arr -> MLMultiArray in
            if let arr = arr { count += 1; return arr }
            else { return Pose.emptyPoseMultiArray }
        }
        let minSamples = predictionWindowSize * 60 / 100
        guard count >= minSamples else {
            return ActionPrediction.noPersonPrediction
        }
        let merged = MLMultiArray(concatenating: filled,
                                  axis: 0,
                                  dataType: .float)
        let prediction = actionClassifier.predictActionFromWindow(merged)
        return prediction.confidence < 0.6
            ? ActionPrediction.lowConfidencePrediction
            : prediction
    }

    private func sendPrediction(_ prediction: ActionPrediction) {
        DispatchQueue.main.async {
            self.delegate?.videoProcessingChain(self,
                                                didPredict: prediction,
                                                for: self.windowStride)
        }
        performanceReporter?.incrementPrediction()
    }
}
