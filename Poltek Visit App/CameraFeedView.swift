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
    @Namespace private var detectionAnimation

    private let baseThreshold: VNConfidence = 0.8
    private let specialThreshold: VNConfidence = 0.9
    private let requiredConsecutiveFrames = 3

    var body: some View {
        ZStack {
            CameraPreviewView(session: $session)
                .ignoresSafeArea()

            VStack {
                Spacer()
                detectionLabelsView()
            }
        }
        .onAppear    { configureSession() }
        .onDisappear { session.stopRunning() }
        .onReceive(bufferExchange.$pixelBuffer.compactMap { $0 }) { classify(buffer: $0) }
    }

    private func detectionLabelsView() -> some View {
        let sortedKeys = discovered.keys.sorted()

        return VStack(spacing: 10) {
            HStack(spacing: 16) {
                ForEach(sortedKeys.prefix(3), id: \.self) { label in
                    let index = sortedKeys.firstIndex(of: label)! + 1
                    detectionItem(label: label, number: index)
                }
            }

            HStack(spacing: 16) {
                ForEach(sortedKeys.dropFirst(3), id: \.self) { label in
                    let index = sortedKeys.firstIndex(of: label)! + 1
                    detectionItem(label: label, number: index)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.bottom, 12)
    }

    private func detectionItem(label: String, number: Int) -> some View {
        let isDiscovered = discovered[label] ?? false

        return VStack(spacing: 4) {
            Text("\(number)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(
                            isDiscovered
                                ? LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                                : LinearGradient(
                                    colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isDiscovered
                                        ? Color.white.opacity(0.3)
                                        : Color.gray.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
                .scaleEffect(isDiscovered ? 1.2 : 1.0)
                .rotationEffect(.degrees(isDiscovered ? 360 : 0))
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.7)
                        .delay(Double(number) * 0.05),
                    value: isDiscovered
                )
                .shadow(
                    color: isDiscovered ? Color.blue.opacity(0.6) : .clear,
                    radius: isDiscovered ? 6 : 0,
                    x: 0,
                    y: 0
                )

            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 52)
        .matchedGeometryEffect(id: label, in: detectionAnimation)
    }

    private func configureSession() {
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

        guard let device = chosenDevice else { return }

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
            print("Failed to configure focus/exposure: \(error)")
        }

        session.beginConfiguration()
        session.sessionPreset = .photo

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Failed to add camera input: \(error)")
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
                        DispatchQueue.main.async {
                            withAnimation {
                                discovered[label] = true
                            }
                            checkCompletion()
                        }
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
