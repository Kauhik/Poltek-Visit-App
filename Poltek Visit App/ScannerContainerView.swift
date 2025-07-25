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
    @Binding var selectedTab: Tab
    @Binding var completedTabs: Set<Tab>
    @Binding var qrScannedClues: Set<Int>
    @Binding var nfcScannedClues: Set<Int>
    @Binding var listenScannedClues: Set<Int>
    let usageLeft: [ScanTech: Int]
    var onBack: () -> Void
    var onNext: (ScanTech) -> Void

    @State private var lastTagData: String = ""
    @State private var didFinishCurrent = false

    @State private var showScannedToast = false
    @State private var showWrongToast   = false

    @StateObject private var tagScanner = TagScanner()
    @Namespace private var clueAnimation

    private static let nfcCluesKey = "ScannerContainerView.nfcScannedClues"
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
                contentBody().ignoresSafeArea(edges: .all)

                if showScannedToast {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20, weight: .semibold))
                        Text("Clue scanned!")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8),
                               value: showScannedToast)
                    .padding(.top, 60)
                }

                if showWrongToast {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 20, weight: .semibold))
                        Text("Wrong QR code")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
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
                    .animation(.spring(response: 0.5, dampingFraction: 0.8),
                               value: showWrongToast)
                    .padding(.top, 60)
                }

                overlayBackButton()
            }
            .navigationBarHidden(true)
            bottomTabBar
        }
        .onAppear {
            didFinishCurrent = false
            if let data = UserDefaults.standard.data(forKey: Self.nfcCluesKey),
               let arr = try? JSONDecoder().decode([Int].self, from: data) {
                nfcScannedClues = Set(arr)
            }
        }
        .onChange(of: nfcScannedClues) { new in
            if let data = try? JSONEncoder().encode(Array(new)) {
                UserDefaults.standard.set(data, forKey: Self.nfcCluesKey)
            }
        }
    }

    @ViewBuilder
    private func contentBody() -> some View {
        switch selectedTab {
        case .qr:     qrView
        case .scan:   scanView
        case .listen: listenView
        case .move:   moveView
        case .nfc:    nfcView
        }
    }

    private var qrView: some View {
        ZStack {
            QRScannerView { code in
                // ignore while finishing
                guard !didFinishCurrent else { return }

                if let idx = qrClueURLs.firstIndex(of: code) {
                    // ── valid QR ───────────────────────────────────────────────
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        qrScannedClues.insert(idx + 1)
                        showScannedToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showScannedToast = false
                    }
                    if qrScannedClues.count == qrClueURLs.count {
                        finish(.camera)
                    }
                } else {
                    // ── wrong QR ───────────────────────────────────────────────
                    withAnimation {
                        showWrongToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showWrongToast = false
                    }
                }
            }
            VStack {
                Spacer()
                // Clue box (scaled to match camera sizing)
                animatedClueLabels(count: qrClueURLs.count, lit: qrScannedClues)
                    .scaleEffect(0.85)
            }
        }
    }

    private var scanView: some View {
        CameraFeedView(onAllDetected: { finish(.camera) },
                       onNext:        { finish(.camera) })
    }

    private var listenView: some View {
        ListenDetectionView(detectedClues: $listenScannedClues,
                            onAllDetected: { finish(.microphone) },
                            onNext:        { finish(.microphone) })
    }

    private var moveView: some View {
        MoveClassifierView(onDone: { finish(.ar) },
                           onBack: onBack)
    }

    private var nfcView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "wave.3.right")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                Text("Hold near a NFC Card")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: { tagScanner.beginScanning() }) {
                    Text("Scan Card")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: 250)
                        .padding(.vertical, 18)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(20)
                }
                .padding(.horizontal, 20)
                if !lastTagData.isEmpty {
                    Text("Last scanned: \(lastTagData)")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                Spacer()
                animatedClueLabels(count: 4, lit: nfcScannedClues)
            }
        }
        .onReceive(tagScanner.$scannedData) { messages in
            guard !didFinishCurrent, let raw = messages.last else { return }
            let clean = raw.trimmingCharacters(in: .controlCharacters)
            lastTagData = clean
            switch clean {
            case "enClue1": animateNFC(1)
            case "enClue2": animateNFC(2)
            case "enClue3": animateNFC(3)
            case "enClue4": animateNFC(4)
            default: break
            }
            if nfcScannedClues.count == 4 {
                finish(.nfc)
            }
        }
    }

    private func animatedClueLabels(count: Int, lit: Set<Int>) -> some View {
        HStack(spacing: 16) {
            ForEach(1...count, id: \.self) { idx in
                VStack(spacing: 4) {
                    Text("\(idx)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(lit.contains(idx) ? .black : .white)
                        .frame(width: 40, height: 40)
                        .background(Circle()
                            .fill(
                                lit.contains(idx)
                                    ? LinearGradient(colors: [.green, .mint],
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [.gray.opacity(0.3),
                                                              .gray.opacity(0.1)],
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing)
                            )
                            .overlay(Circle().stroke(
                                lit.contains(idx)
                                    ? .white.opacity(0.3)
                                    : .gray.opacity(0.2),
                                lineWidth: 1
                            ))
                        )
                        .shadow(color: lit.contains(idx) ? .green.opacity(0.6) : .clear,
                                radius: lit.contains(idx) ? 8 : 0)
                    Text("Clue")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(lit.contains(idx) ? .green : .gray)
                        .opacity(lit.contains(idx) ? 1.0 : 0.6)
                }
                .matchedGeometryEffect(id: idx, in: clueAnimation)
                .animation(.spring(response: 0.8, dampingFraction: 0.6)
                            .delay(Double(idx) * 0.1),
                           value: lit.contains(idx))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
        .padding(.bottom, 20)
    }

    private func animateNFC(_ idx: Int) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            nfcScannedClues.insert(idx)
        }
    }

    private func finish(_ tech: ScanTech) {
        guard !didFinishCurrent else { return }
        didFinishCurrent = true
        DispatchQueue.main.async {
            onNext(tech)
            completedTabs.insert(selectedTab)
        }
    }

    private func overlayBackButton() -> some View {
        GeometryReader { geo in
            VStack {
                Color.clear.frame(height: geo.safeAreaInsets.top)
                HStack {
                    Button(action: onBack) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .overlay(Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black))
                            .shadow(radius: 4)
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
                Button { selectedTab = tab } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(
                                completedTabs.contains(tab)
                                    ? .green
                                    : (selectedTab == tab ? .orange : .gray)
                            )
                        Text(tab.label)
                            .font(.caption2)
                            .foregroundColor(
                                completedTabs.contains(tab)
                                    ? .green
                                    : (selectedTab == tab ? .orange : .gray)
                            )
                    }
                }
                .disabled(completedTabs.contains(tab))
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 80)
    }

    enum Tab: String, CaseIterable, Identifiable {
        case qr, scan, listen, move, nfc
        var id: String { rawValue }
        var label: String {
            switch self {
            case .qr:     return "QR Code"
            case .scan:   return "Camera"
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
