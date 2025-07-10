//
//  QRScannerView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 10/7/25.
//

import SwiftUI
import AVFoundation

class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

struct QRScannerView: UIViewRepresentable {
    /// Called with the decoded QR string whenever a code is found
    var completion: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PreviewView {
        let preview = PreviewView()
        preview.backgroundColor = .black
        context.coordinator.previewView = preview
        context.coordinator.checkPermissionsAndSetup()
        return preview
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        context.coordinator.previewView?.videoPreviewLayer.frame = uiView.bounds
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: QRScannerView
        weak var previewView: PreviewView?
        var session: AVCaptureSession?
        let bracketLayer = CAShapeLayer()

        init(parent: QRScannerView) {
            self.parent = parent
            super.init()
            bracketLayer.strokeColor = UIColor.yellow.cgColor
            bracketLayer.lineWidth = 4
            bracketLayer.fillColor = UIColor.clear.cgColor
            bracketLayer.lineJoin = .round
            bracketLayer.lineCap = .round
            bracketLayer.allowsEdgeAntialiasing = true
        }

        func checkPermissionsAndSetup() {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                setupSession()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted { self.setupSession() }
                }
            default:
                break
            }
        }

        func setupSession() {
            let session = AVCaptureSession()
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                session.canAddInput(input)
            else { return }

            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]

            DispatchQueue.main.async {
                guard let preview = self.previewView else { return }
                preview.videoPreviewLayer.session = session
                preview.videoPreviewLayer.videoGravity = .resizeAspectFill
                preview.layer.addSublayer(self.bracketLayer)
                session.startRunning()
                self.session = session
            }
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard
                let qrObject = metadataObjects
                    .compactMap({ $0 as? AVMetadataMachineReadableCodeObject })
                    .first,
                qrObject.type == .qr,
                let string = qrObject.stringValue,
                let preview = previewView,
                let transformed = preview.videoPreviewLayer
                    .transformedMetadataObject(for: qrObject)
            else {
                bracketLayer.path = nil
                return
            }

            let rect = transformed.bounds
            let length = min(rect.width, rect.height) * 0.2
            let path = UIBezierPath()

            // top-left
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))

            // top-right
            path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))

            // bottom-right
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))

            // bottom-left
            path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))

            CATransaction.begin()
            CATransaction.setAnimationDuration(0.1)
            bracketLayer.frame = preview.bounds
            bracketLayer.path = path.cgPath
            CATransaction.commit()

            parent.completion(string)
        }
    }
}
