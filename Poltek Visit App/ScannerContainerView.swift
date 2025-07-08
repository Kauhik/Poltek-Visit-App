//
//  ScannerContainerView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 5/7/25.
//

import SwiftUI

struct ScannerContainerView: View {
    let usageLeft: [ScanTech: Int]
    var onBack:   () -> Void
    var onNext:   (ScanTech) -> Void

    @State private var selectedTab: Tab = .qr

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
                        // status-bar spacer
                        Color.clear
                            .frame(height: proxy.safeAreaInsets.top)
                        // back button row, shifted up
                        HStack {
                            Button(action: onBack) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: Color.black.opacity(0.2),
                                                radius: 4, x: 0, y: 2)
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
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity,
                           alignment: .top)
                }
            )
            .navigationBarHidden(true)
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity)

            // bottom tab bar, transparent
            bottomTabBar
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
                    .foregroundColor(
                        selectedTab == tab
                            ? Color(.systemTeal)
                            : Color.gray
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 80)
        .background(Color.clear)
    }

    @ViewBuilder
    private func contentBody() -> some View {
        switch selectedTab {
        case .qr:
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.white)

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

    // MARK: Tabs

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

        var tech: ScanTech {
            switch self {
            case .qr, .scan: return .camera
            case .listen:    return .microphone
            case .move:      return .ar
            case .nfc:       return .nfc
            }
        }

        var title: String {
            switch self {
            case .qr:     return "Scan QR Code"
            case .scan:   return "Camera Scan"
            case .listen: return "Audio Scan"
            case .move:   return "AR Scan"
            case .nfc:    return "NFC Scan"
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
