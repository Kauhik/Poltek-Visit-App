// File: VideoCapture.swift
// See LICENSE folder for this sample’s licensing information.
// Abstract:
// Convenience class that configures the video capture session and
// publishes frames at a capped 30 fps.

import UIKit
import Combine
import AVFoundation

@MainActor
protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ videoCapture: VideoCapture,
                      didCreate framePublisher: FramePublisher)
}

typealias Frame = CMSampleBuffer
typealias FramePublisher = AnyPublisher<Frame, Never>

@MainActor
class VideoCapture: NSObject {
    weak var delegate: VideoCaptureDelegate! {
        didSet { createVideoFramePublisher() }
    }

    var isEnabled = true {
        didSet {
            if isEnabled { enableCaptureSession() }
            else        { disableCaptureSession() }
        }
    }

    private var cameraPosition = AVCaptureDevice.Position.front {
        didSet { createVideoFramePublisher() }
    }

    private var orientation = AVCaptureVideoOrientation.portrait {
        didSet { createVideoFramePublisher() }
    }

    private let captureSession = AVCaptureSession()
    private var framePublisher: PassthroughSubject<Frame, Never>?
    private let videoCaptureQueue = DispatchQueue(
        label: "VideoCapture.Queue", qos: .userInitiated
    )

    // MARK: – Public API

    /// Flip front/back
    func toggleCameraSelection() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
    }

    /// Update orientation from UIDevice
    func updateDeviceOrientation() {
        switch UIDevice.current.orientation {
        case .portrait, .faceUp, .faceDown, .unknown:
            orientation = .portrait
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        case .landscapeLeft:
            orientation = .landscapeLeft
        case .landscapeRight:
            orientation = .landscapeRight
        @unknown default:
            orientation = .portrait
        }
    }

    // MARK: – Capture Start/Stop

    private func enableCaptureSession() {
        videoCaptureQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    private func disableCaptureSession() {
        videoCaptureQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}

// MARK: – AVCapture Output Delegate

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput frame: Frame,
                       from connection: AVCaptureConnection) {
        framePublisher?.send(frame)
    }
}

// MARK: – Configuration

extension VideoCapture {
    private func createVideoFramePublisher() {
        guard let output = configureCaptureSession() else { return }
        let passthrough = PassthroughSubject<Frame, Never>()
        framePublisher = passthrough
        output.setSampleBufferDelegate(self, queue: videoCaptureQueue)
        delegate.videoCapture(self, didCreate: passthrough.eraseToAnyPublisher())
    }

    private func configureCaptureSession() -> AVCaptureVideoDataOutput? {
        disableCaptureSession()
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
            enableCaptureSession()
        }

        // Cap at 30 fps
        let desiredFPS: Double = 30.0
        let input = AVCaptureDeviceInput.createCameraInput(
            position: cameraPosition,
            frameRate: desiredFPS
        )
        let output = AVCaptureVideoDataOutput.withPixelFormatType(
            kCVPixelFormatType_32BGRA
        )

        guard configureCaptureConnection(input: input, output: output) else {
            return nil
        }
        return output
    }

    private func configureCaptureConnection(
        input: AVCaptureDeviceInput?,
        output: AVCaptureVideoDataOutput?
    ) -> Bool {
        guard let inp = input, let out = output else { return false }

        captureSession.inputs.forEach  { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }

        guard captureSession.canAddInput(inp),
              captureSession.canAddOutput(out) else {
            print("Capture session not compatible")
            return false
        }

        captureSession.addInput(inp)
        captureSession.addOutput(out)

        guard let connection = out.connection(with: .video) else {
            print("No video connection found")
            return false
        }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = orientation
        }
        connection.isVideoMirrored = false  // no flip

        out.alwaysDiscardsLateVideoFrames = true
        return true
    }
}
