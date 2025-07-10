//
//  ScannerContainerView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 5/7/25.
//

import SwiftUI
import AVFoundation

struct ScannerContainerView: View {
    let usageLeft: [ScanTech: Int]
    var onBack: () -> Void
    var onNext: (ScanTech) -> Void

    @State private var selectedTab: Tab = .qr
    @State private var scannedCode: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                contentBody()
                    .ignoresSafeArea(edges: selectedTab == .scan ? .all : [])

                if selectedTab == .scan {
                    nextButtonOverlay()
                }
            }
            .overlay(
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: proxy.safeAreaInsets.top)
                        HStack {
                            Button(action: onBack) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .frame(height: 80)
                        .offset(y: -30)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            )
            .navigationBarHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomTabBar
        }
    }

    @ViewBuilder
    private func contentBody() -> some View {
        switch selectedTab {
        case .qr:
            QRScannerView { code in
                scannedCode = code
            }
            .ignoresSafeArea()
            .overlay(
                Group {
                    if let code = scannedCode {
                        VStack {
                            Spacer()
                            VStack(spacing: 6) {
                                Text("Scanned QR Code:")
                                    .font(.headline)
                                Text(code)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(8)
                            .padding(.bottom, 60)
                        }
                    }
                }
            )

        case .scan:
            CameraFeedView(
                onAllDetected: { onNext(.camera) },
                onNext:       { onNext(.camera) }
            )

        case .listen:
            ListenDetectionView(
                onAllDetected: { onNext(.microphone) },
                onNext:       { onNext(.microphone) }
            )

        case .move:
            ARCameraView(
                onDone: { onNext(.ar) },
                onBack: onBack
            )

        case .nfc:
            NFCScanView(
                onDone: { onNext(.nfc) },
                onBack: onBack
            )
        }
    }

    private var bottomTabBar: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20))
                        Text(tab.label)
                            .font(.caption2)
                    }
                }
                .foregroundColor(
                    selectedTab == tab
                        ? Color(.systemTeal)
                        : Color.gray
                )
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 80)
        .background(Color.clear)
    }

    private func nextButtonOverlay() -> some View {
        GeometryReader { proxy in
            let bottom = proxy.safeAreaInsets.bottom
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button("Next") {
                        onNext(.camera)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled((usageLeft[.camera] ?? 0) <= 0)
                }
                .padding(.horizontal)
                .padding(.bottom, bottom + 60)
            }
        }
    }

    private enum Tab: CaseIterable {
        case qr, scan, listen, move, nfc

        var label: String {
            switch self {
            case .qr:     return "QR Code"
            case .scan:   return "Scan"
            case .listen: return "Listen"
            case .move:   return "Move"
            case .nfc:    return "NFC"
            }
        }

        var iconName: String {
            switch self {
            case .qr:     return "qrcode"
            case .scan:   return "camera"
            case .listen: return "mic.fill"
            case .move:   return "figure.walk"
            case .nfc:    return "wave.3.right"
            }
        }
    }
}


struct ScannerContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerContainerView(
            usageLeft: Dictionary(
                uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) }
            ),
            onBack: {},
            onNext: { _ in }
        )
    }
}
