//
//  ScannerContainerView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 5/7/25.
//

import SwiftUI

struct ScannerContainerView: View {
    let usageLeft: [ScanTech:Int]
    var onBack: () -> Void
    var onNext: (ScanTech) -> Void

    @State private var selectedTab: Tab = .qr

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                        }
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .padding(.top, proxy.safeAreaInsets.top + 80)
                        .padding(.leading, 24)

                        Spacer()
                    }

                    Spacer()

                    Group {
                        switch selectedTab {
                        case .qr:
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 80))
                            Text("Scan QR Code")
                        case .scan:
                            Image(systemName: "camera")
                                .font(.system(size: 80))
                            Text("Visual clue")
                        case .listen:
                            Image(systemName: "mic.fill")
                                .font(.system(size: 80))
                            Text("Listening to audio")
                        case .move:
                            Image(systemName: "figure.walk")
                                .font(.system(size: 80))
                            Text("AR Action Clue")
                        case .nfc:
                            Image(systemName: "nfc")
                                .font(.system(size: 80))
                            Text("Hold near NFC tag")
                        }
                    }
                    .foregroundColor(.white)
                    .font(.title2)
                    .multilineTextAlignment(.center)

                    Spacer()

                    // Development-only Next button
                    Button("Next") {
                        onNext(selectedTab.tech)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled((usageLeft[selectedTab.tech] ?? 0) <= 0)

                    Spacer(minLength: 16)

                    Divider().background(Color.gray)

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
                    .frame(height: 100)
                    .padding(.bottom, proxy.safeAreaInsets.bottom > 0
                             ? proxy.safeAreaInsets.bottom
                             : 16)
                    .background(Color(.systemGray5))
                }
            }
        }
    }

    private enum Tab: CaseIterable {
        case qr, scan, listen, move, nfc

        var label: String {
            switch self {
            case .qr:      return "QR Code"
            case .scan:    return "Scan"
            case .listen:  return "Listen"
            case .move:    return "Move"
            case .nfc:     return "NFC"
            }
        }

        var iconName: String {
            switch self {
            case .qr:      return "qrcode"
            case .scan:    return "camera"
            case .listen:  return "mic.fill"
            case .move:    return "figure.walk"
            case .nfc:     return "wave.3.right"
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
