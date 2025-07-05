//
//  ScannerContainerView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 5/7/25.
//

import Foundation
import SwiftUI

/// A single view that lets the user swipe between
/// Camera, NFC, Microphone, and AR scan modes,
/// with a bottom icon bar and a Back button.
struct ScannerContainerView: View {
    @State private var selectedTech: ScanTech = .camera
    let usageLeft: [ScanTech:Int]
    var onBack: () -> Void
    /// Called when the user taps Done; passes the tech that was used
    var onDone: (ScanTech) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Swipeable pages
                TabView(selection: $selectedTech) {
                    cameraPage.tag(ScanTech.camera)
                    nfcPage.tag(ScanTech.nfc)
                    microphonePage.tag(ScanTech.microphone)
                    arPage.tag(ScanTech.ar)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                Divider()

                // Bottom icon bar
                HStack {
                    ForEach(ScanTech.allCases) { tech in
                        Button(action: { selectedTech = tech }) {
                            VStack(spacing: 4) {
                                Image(systemName: tech.icon)
                                    .font(.title2)
                                Text(tech.name)
                                    .font(.caption)
                            }
                            .foregroundColor(selectedTech == tech ? .blue : .gray)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
            }
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pages

    private var cameraPage: some View {
        VStack {
            Spacer()
            Text("Use the camera to scan")
                .font(.title2)
            Spacer()
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .cornerRadius(12)
                .overlay(Text("Camera Feed Placeholder"))
                .frame(height: 300)
            Spacer()
            Button("Done") {
                onDone(.camera)
            }
            .buttonStyle(.borderedProminent)
            .disabled((usageLeft[.camera] ?? 0) <= 0)
            Spacer()
        }
        .padding()
    }

    private var nfcPage: some View {
        VStack {
            Spacer()
            Text("Hold near NFC tag")
                .font(.title2)
            Spacer()
            Image(systemName: "nfc")
                .font(.system(size: 100))
            Spacer()
            Button("Done") {
                onDone(.nfc)
            }
            .buttonStyle(.borderedProminent)
            .disabled((usageLeft[.nfc] ?? 0) <= 0)
            Spacer()
        }
        .padding()
    }

    private var microphonePage: some View {
        VStack {
            Spacer()
            Text("Listening to audio")
                .font(.title2)
            Spacer()
            Image(systemName: "mic.fill")
                .font(.system(size: 100))
            Spacer()
            Button("Done") {
                onDone(.microphone)
            }
            .buttonStyle(.borderedProminent)
            .disabled((usageLeft[.microphone] ?? 0) <= 0)
            Spacer()
        }
        .padding()
    }

    private var arPage: some View {
        VStack {
            Spacer()
            Text("AR Camera")
                .font(.title2)
            Spacer()
            Rectangle()
                .fill(Color.blue.opacity(0.2))
                .cornerRadius(12)
                .overlay(Text("AR Camera Placeholder"))
                .frame(height: 300)
            Spacer()
            Button("Done") {
                onDone(.ar)
            }
            .buttonStyle(.borderedProminent)
            .disabled((usageLeft[.ar] ?? 0) <= 0)
            Spacer()
        }
        .padding()
    }
}

struct ScannerContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerContainerView(
            usageLeft: Dictionary(uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) }),
            onBack: {},
            onDone: { _ in }
        )
    }
}
