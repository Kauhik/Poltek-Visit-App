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

    // NFC scanning state
    @StateObject private var nfcScanner = NFCScanner()
    @State private var discoveredNfcClues: Set<Int> = []
    @State private var lastNfcData: String = ""

    // The five valid QR URLs in order
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
                contentBody()
                    .ignoresSafeArea(edges: selectedTab == .scan ? .all : [])
                if selectedTab == .scan {
                    nextButtonOverlay()
                }
            }
            .overlay(backButtonOverlay())
            .navigationBarHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            bottomTabBar
        }
    }

    @ViewBuilder
    private func contentBody() -> some View {
        switch selectedTab {
        case .qr:
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
            .onChange(of: discoveredClues) { newSet in
                if newSet.count == qrClueURLs.count && !didScheduleCompletion {
                    didScheduleCompletion = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        onNext(.camera)
                    }
                }
            }

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
                        // clear previous data but keep discovered clues
                        lastNfcData = ""
                        nfcScanner.scannedMessages.removeAll()
                        nfcScanner.beginScanning()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                    .padding(.horizontal, 60)

                    if !lastNfcData.isEmpty {
                        Text("Last scanned: \(lastNfcData)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.top, 8)
                    }

                    Spacer()
                    clueLabels(count: 4, lit: discoveredNfcClues)
                }
            }
            .onReceive(nfcScanner.$scannedMessages) { messages in
                guard let raw = messages.last else { return }
                // strip control characters
                let clean = raw.trimmingCharacters(in: .controlCharacters)
                lastNfcData = clean
                switch clean {
                case "enClue1": discoveredNfcClues.insert(1)
                case "enClue2": discoveredNfcClues.insert(2)
                case "enClue3": discoveredNfcClues.insert(3)
                case "enClue4": discoveredNfcClues.insert(4)
                default: break
                }
                if discoveredNfcClues.count == 4 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        onNext(.nfc)
                    }
                }
            }
        }
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

    private func backButtonOverlay() -> some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Color.clear.frame(height: proxy.safeAreaInsets.top)
                HStack {
                    Button(action: onBack) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.2), radius: 4)
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
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20))
                        Text(tab.label).font(.caption2)
                    }
                }
                .foregroundColor(selectedTab == tab ? .teal : .gray)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 80)
    }

    private func nextButtonOverlay() -> some View {
        GeometryReader { proxy in
            let bottom = proxy.safeAreaInsets.bottom
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button("Next") { onNext(.camera) }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .disabled((usageLeft[.camera] ?? 0) <= 0)
                }
                .padding(.horizontal)
                .padding(.bottom, bottom + 60)
            }
        }
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

struct ScannerContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerContainerView(
            usageLeft: Dictionary(uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) }),
            onBack: {},
            onNext: { _ in }
        )
    }
}
