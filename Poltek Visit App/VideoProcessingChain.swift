

import Vision
import Combine
import CoreImage

@MainActor
protocol VideoProcessingChainDelegate: AnyObject {
    /// Called when a set of poses has been detected in a frame.
    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didDetect poses: [Pose]?,
                              in frame: CGImage)
    /// Called when an action prediction has been made for a batch of frames.
    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didPredict actionPrediction: ActionPrediction,
                              for frames: Int)
}

class VideoProcessingChain {
    weak var delegate: VideoProcessingChainDelegate?

    /// Upstream publisher of CMSampleBuffer frames.
    var upstreamFramePublisher: AnyPublisher<Frame, Never>? {
        didSet { buildProcessingChain() }
    }

    private var frameProcessingChain: AnyCancellable?
    private let actionClassifier = PoltekActionClassifierORGINAL.shared
    private let predictionWindowSize: Int
    private let windowStride = 10

    private let ciContext = CIContext(options: nil)
    private let visionQueue = DispatchQueue(
        label: "VideoProcessingChain.VisionQueue",
        qos: .userInitiated
    )
    private var performanceReporter = PerformanceReporter()

    init() {
        predictionWindowSize = actionClassifier.calculatePredictionWindowSize()
    }

    /// Sets up the Combine chain: throttle → convert → pose detection → ML windowing → prediction.
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

    /// Runs Vision’s human‑body‑pose request on the CGImage.
    /// Guards out any zero‑sized frames and wraps the request in an autoreleasepool.
    private func detectPoses(in frame: CGImage) -> [Pose]? {
        // Skip any invalid (zero‑sized) images.
        guard frame.width > 0, frame.height > 0 else { return nil }

        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(
            cgImage: frame,
            orientation: .up,
            options: [:]
        )

        do {
            // Free internal Vision buffers immediately.
            try autoreleasepool {
                try handler.perform([request])
            }
        } catch {
            assertionFailure("Pose request failed: \(error)")
            return nil
        }

        let observations = request.results
        let poses = Pose.fromObservations(observations)

        DispatchQueue.main.async {
            self.delegate?.videoProcessingChain(self,
                                                didDetect: poses,
                                                in: frame)
        }
        return poses
    }

    /// Pick the largest pose by area (if any).
    private func isolateLargestPose(_ poses: [Pose]?) -> Pose? {
        poses?.max(by: { $0.area < $1.area })
    }

    /// Extract the MLMultiArray of keypoints from a pose.
    private func multiArrayFromPose(_ item: Pose?) -> MLMultiArray? {
        item?.multiArray
    }

    /// Maintains a sliding window of the last N arrays.
    private func gatherWindow(previousWindow: [MLMultiArray?],
                              multiArray: MLMultiArray?) -> [MLMultiArray?] {
        var window = previousWindow
        if window.count == predictionWindowSize {
            window.removeFirst(windowStride)
        }
        window.append(multiArray)
        return window
    }

    /// Only let windows of exactly the right size through.
    private func gateWindow(_ window: [MLMultiArray?]) -> Bool {
        window.count == predictionWindowSize
    }

    /// Run the classifier on each full window.
    private func predictActionWithWindow(_ window: [MLMultiArray?]) -> ActionPrediction {
        var count = 0
        let filled = window.map { arr -> MLMultiArray in
            if let arr = arr { count += 1; return arr }
            else { return Pose.emptyPoseMultiArray }
        }

        // Require at least 60% non‑empty frames.
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

    /// Relay each prediction back to the SwiftUI layer.
    private func sendPrediction(_ prediction: ActionPrediction) {
        DispatchQueue.main.async {
            self.delegate?.videoProcessingChain(self,
                                                didPredict: prediction,
                                                for: self.windowStride)
        }
        performanceReporter?.incrementPrediction()
    }
}
