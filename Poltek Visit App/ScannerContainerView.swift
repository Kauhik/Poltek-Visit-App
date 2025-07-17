//
//  ScannerContainerView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 5/7/25.
//

import SwiftUI
import AVFoundation
import CoreNFC

struct ScannerContainerView: View {
    let usageLeft: [ScanTech: Int]
    var onBack: () -> Void
    var onNext: (ScanTech) -> Void

    @State private var selectedTab: Tab = .qr
    @State private var discoveredClues: Set<Int> = []
    @State private var didScheduleCompletion = false

    @StateObject private var tagScanner = TagScanner()
    @State private var discoveredTagClues: Set<Int> = []
    @State private var lastTagData: String = ""

    private let qrClueURLs = [
        "https://qrs.ly/bkgtv1h",
        "https://qrs.ly/ntgtv2j",
        "https://qrs.ly/5rgtv2r",
        "https://qrs.ly/tvgtv30",
        "https://qrs.ly/njgtv34"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                // contentBody now fills safe area for .qr, .scan, .move, etc.
                contentBody()
                    .ignoresSafeArea(edges: selectedTab == .qr || selectedTab == .scan ? .all : [])

                overlayBackButton()
            }
            .navigationBarHidden(true)

            bottomTabBar
        }
    }

    @ViewBuilder
    private func contentBody() -> some View {
        switch selectedTab {
        case .qr:
            // full‑screen QR preview
            ZStack {
                QRScannerView { code in
                    if let idx = qrClueURLs.firstIndex(of: code) {
                        discoveredClues.insert(idx + 1)
                    }
                }

                VStack {
                    Spacer()
                    clueLabels(count: qrClueURLs.count, lit: discoveredClues)
                }
            }
            .onChange(of: discoveredClues) { new in
                guard new.count == qrClueURLs.count, !didScheduleCompletion else { return }
                didScheduleCompletion = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    onNext(.camera)
                }
            }

        case .scan:
            CameraFeedView(onAllDetected: { onNext(.camera) },
                           onNext:       { onNext(.camera) })

        case .listen:
            ListenDetectionView(onAllDetected: { onNext(.microphone) },
                                onNext:       { onNext(.microphone) })

        case .move:
            MoveClassifierView(onDone: { onNext(.ar) },
                               onBack: onBack)

        case .nfc:
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    Text("Hold near NFC tag")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Scan NFC") {
                        lastTagData = ""
                        tagScanner.scannedData.removeAll()
                        tagScanner.beginScanning()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                    .padding(.horizontal, 60)

                    if !lastTagData.isEmpty {
                        Text("Last scanned: \(lastTagData)")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }

                    Spacer()
                    clueLabels(count: 4, lit: discoveredTagClues)
                }
            }
            .onReceive(tagScanner.$scannedData) { messages in
                guard let raw = messages.last else { return }
                let clean = raw.trimmingCharacters(in: .controlCharacters)
                lastTagData = clean
                switch clean {
                case "enClue1": discoveredTagClues.insert(1)
                case "enClue2": discoveredTagClues.insert(2)
                case "enClue3": discoveredTagClues.insert(3)
                case "enClue4": discoveredTagClues.insert(4)
                default: break
                }
                if discoveredTagClues.count == 4 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        onNext(.nfc)
                    }
                }
            }
        }
    }

    private func overlayBackButton() -> some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Color.clear.frame(height: geo.safeAreaInsets.top)
                HStack {
                    Button(action: onBack) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                                .shadow(radius: 4)
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
        }
    }

    private var bottomTabBar: some View {
        HStack {
            ForEach(Tab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20))
                        Text(tab.label)
                            .font(.caption2)
                    }
                }
                .foregroundColor(selectedTab == tab ? .teal : .gray)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 80)
    }

    private func clueLabels(count: Int, lit: Set<Int>) -> some View {
        HStack(spacing: 12) {
            ForEach(1...count, id: \.self) { idx in
                Text("Clue \(idx)")
                    .font(.caption)
                    .foregroundColor(lit.contains(idx) ? .white : .gray)
                    .padding(6)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private enum Tab: String, CaseIterable, Identifiable {
        case qr, scan, listen, move, nfc
        var id: String { rawValue }
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
