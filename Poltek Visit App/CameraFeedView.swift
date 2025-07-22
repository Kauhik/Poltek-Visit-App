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
    /// Called after all clues have been correctly detected
    var onAllDetected: () -> Void
    /// Unused in this mode; required by container
    var onNext: () -> Void

    // persist key
    private static let discoveredKey = "CameraFeedView.discoveredClues"

    /// Discovered clue labels (persisted)
    @State private var discovered: [String: Bool] = {
        // default labels
        let defaults: [String: Bool] = [
            "Ezlink": false,
            "Mangkok ayam": false,
            "Merlion": false,
            "Welcome to Batam": false
        ]
        // load saved
        if let saved = UserDefaults.standard.dictionary(forKey: discoveredKey) as? [String: Bool] {
            // merge to ensure any new keys get defaulted
            return defaults.merging(saved) { _, new in new }
        }
        return defaults
    }()

    @State private var session = AVCaptureSession()
    @State private var classificationRequest: VNCoreMLRequest?
    @StateObject private var bufferExchange = BufferExchange()
    @Namespace private var detectionAnimation
    @State private var showToast = false

    private let baseThreshold: VNConfidence = 0.8
    private let specialThreshold: VNConfidence = 0.9

    var body: some View {
        ZStack {
            CameraPreviewView(session: $session)
                .ignoresSafeArea()

            VStack {
                // Toast on failed match
                if showToast {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 20, weight: .semibold))
                        Text("Try again")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showToast)
                    .padding(.top, 60)
                }

                Spacer()

                // Capture button
                Button(action: {
                    if let buffer = bufferExchange.pixelBuffer {
                        classify(buffer: buffer)
                    }
                }) {
                    Text("Capture")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .animation(.easeInOut(duration: 0.1), value: showToast)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

                // Clue indicators in a single row of 4
                detectionLabelsView()
            }
        }
        .onAppear { configureSession() }
        .onDisappear { session.stopRunning() }
    }

    private func detectionLabelsView() -> some View {
        let keys = discovered.keys.sorted()
        return HStack(spacing: 16) {
            ForEach(keys, id: \.self) { label in
                clueItem(label: label,
                         number: keys.firstIndex(of: label)! + 1)
            }
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

    private func clueItem(label: String, number: Int) -> some View {
        let done = discovered[label] ?? false
        return VStack(spacing: 4) {
            Text("\(number)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(
                            done
                                ? LinearGradient(colors: [.blue, .cyan],
                                                 startPoint: .topLeading,
                                                 endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.gray.opacity(0.3),
                                                          .gray.opacity(0.1)],
                                                 startPoint: .topLeading,
                                                 endPoint: .bottomTrailing)
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    done
                                        ? Color.white.opacity(0.3)
                                        : Color.gray.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
                .scaleEffect(done ? 1.2 : 1.0)
                .rotationEffect(.degrees(done ? 360 : 0))
                .animation(.spring(response: 0.6, dampingFraction: 0.7)
                            .delay(Double(number) * 0.05),
                           value: done)

            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 60)
        .matchedGeometryEffect(id: label, in: detectionAnimation)
    }

    private func configureSession() {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )

        guard let device = discovery.devices.first else { return }

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
            print("Focus/exposure error: \(error)")
        }

        session.beginConfiguration()
        session.sessionPreset = .photo

        if let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(bufferExchange,
                                       queue: DispatchQueue(label: "VideoBuffer"))

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()

        if let mlModel = try? VNCoreMLModel(for: PoltekImagesClassification_1().model) {
            classificationRequest = VNCoreMLRequest(model: mlModel) { request, _ in
                guard
                    let results = request.results as? [VNClassificationObservation],
                    let top = results.first
                else { return }

                let label = top.identifier
                let conf  = top.confidence
                let thresh: VNConfidence =
                    label == "Ezlink"
                        ? specialThreshold
                        : baseThreshold

                DispatchQueue.main.async {
                    if conf >= thresh, discovered[label] == false {
                        discovered[label] = true
                        saveDiscovered()
                        if discovered.values.allSatisfy({ $0 }) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                onAllDetected()
                            }
                        }
                    } else {
                        showToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showToast = false
                        }
                    }
                }
            }
            classificationRequest?.imageCropAndScaleOption = .centerCrop
        }

        session.startRunning()
    }

    private func classify(buffer: CVPixelBuffer) {
        guard let req = classificationRequest else { return }
        let handler = VNImageRequestHandler(
            cvPixelBuffer: buffer,
            orientation: .up,
            options: [:]
        )
        try? handler.perform([req])
    }

    private func saveDiscovered() {
        UserDefaults.standard.set(discovered, forKey: Self.discoveredKey)
    }
}

// Captures the latest frame buffer
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

// SwiftUI wrapper for the preview layer
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
