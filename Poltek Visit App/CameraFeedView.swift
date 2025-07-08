//
//  CameraFeedView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI
import AVFoundation
import Vision

struct CameraFeedView: View {
    var onAllDetected: () -> Void
    /// Manual override
    var onNext: () -> Void

    @State private var discovered: [String: Bool] = [
        "Ezlink": false,
        "Mangkok ayam": false,
        "Merlion": false,
        "Tukang parkir pink": false,
        "Welcome to Batam": false
    ]
    @State private var detectionCounters: [String: Int] = [
        "Ezlink": 0,
        "Mangkok ayam": 0,
        "Merlion": 0,
        "Tukang parkir pink": 0,
        "Welcome to Batam": 0
    ]
    @State private var session = AVCaptureSession()
    @State private var classificationRequest: VNCoreMLRequest?
    @StateObject private var bufferExchange = BufferExchange()

    private let baseThreshold: VNConfidence = 0.8
    private let specialThreshold: VNConfidence = 0.9
    private let requiredConsecutiveFrames = 3

    var body: some View {
        ZStack {
            // full-screen camera preview
            CameraPreviewView(session: $session)
                .ignoresSafeArea()

            // labels overlay
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(discovered.keys.sorted(), id: \.self) { label in
                        Text(label)
                            .font(.caption)
                            .foregroundColor(discovered[label]! ? .white : .gray)
                            .padding(6)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .onAppear    { configureSession() }
        .onDisappear { session.stopRunning() }
        .onReceive(bufferExchange.$pixelBuffer.compactMap { $0 }) { classify(buffer: $0) }
    }

    private func configureSession() {
        // 1) Enumerate all back-facing video devices
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInDualCamera,
                .builtInTripleCamera,
                .builtInTelephotoCamera,
                .builtInWideAngleCamera,
                .builtInUltraWideCamera
            ],
            mediaType: .video,
            position: .back
        )
        print("Available back cameras:")
        discovery.devices.forEach { dev in
            print("• \(dev.localizedName) — type: \(dev.deviceType.rawValue)")
        }

        // 2) Pick the first available in our preferred order
        let preferredOrder: [AVCaptureDevice.DeviceType] = [
            .builtInDualCamera,
            .builtInTripleCamera,
            .builtInTelephotoCamera,
            .builtInWideAngleCamera,
            .builtInUltraWideCamera
        ]
        let chosenDevice = preferredOrder.compactMap { type in
            discovery.devices.first(where: { $0.deviceType == type })
        }.first ?? discovery.devices.first

        guard let device = chosenDevice else {
            print("No back camera found!")
            return
        }

        // 3) Print which one we’re using
        print(" Using camera: \(device.localizedName) — type: \(device.deviceType.rawValue)")

        // 4) Enable continuous autofocus & auto-exposure
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            print(" Failed to configure focus/exposure: \(error)")
        }

        // 5) Build session with high-res photo preset
        session.beginConfiguration()
        session.sessionPreset = .photo

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print(" Failed to add camera input: \(error)")
        }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(
            bufferExchange,
            queue: DispatchQueue(label: "VideoBuffer")
        )
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()

        // 6) Prepare Vision model
        if let model = try? VNCoreMLModel(for: PoltekImagesClassification_1().model) {
            classificationRequest = VNCoreMLRequest(model: model) { request, _ in
                guard
                    let results = request.results as? [VNClassificationObservation],
                    let best    = results.first
                else { return }

                let label      = best.identifier
                let confidence = best.confidence
                let threshold: VNConfidence =
                    (label == "Ezlink" || label == "Tukang parkir pink")
                    ? specialThreshold
                    : baseThreshold

                if confidence >= threshold {
                    detectionCounters[label, default: 0] += 1
                    if detectionCounters[label]! >= requiredConsecutiveFrames,
                       discovered[label] == false {
                        discovered[label] = true
                        checkCompletion()
                    }
                } else {
                    detectionCounters[label] = 0
                }
            }
            classificationRequest?.imageCropAndScaleOption = .centerCrop
        }

        session.startRunning()
    }

    private func classify(buffer: CVPixelBuffer) {
        guard let request = classificationRequest else { return }
        let handler = VNImageRequestHandler(
            cvPixelBuffer: buffer,
            orientation: .up,
            options: [:]
        )
        try? handler.perform([request])
    }

    private func checkCompletion() {
        if discovered.values.allSatisfy({ $0 }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                onAllDetected()
            }
        }
    }
}

// Helper to bridge sample buffers
private class BufferExchange: NSObject,
                               ObservableObject,
                               AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var pixelBuffer: CVPixelBuffer?

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    }
}

// SwiftUI wrapper for AVCaptureVideoPreviewLayer
struct CameraPreviewView: UIViewRepresentable {
    @Binding var session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoLayer.session      = session
        view.videoLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.videoLayer.session = session
    }

    class PreviewUIView: UIView {
        let videoLayer = AVCaptureVideoPreviewLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.addSublayer(videoLayer)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            videoLayer.frame = bounds
        }
    }
}
