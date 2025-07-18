//
//  DailyFoodPuzzleView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 1/7/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DailyFoodPuzzleView: View {
    /// Called once all 5 pairs are placed correctly
    var onComplete: () -> Void
    /// Called when the Back button is tapped
    var onBack: () -> Void

    @StateObject private var data = DailyFoodData()
    @State private var items: [DailyFoodPair] = []
    @State private var results: [Int: Bool] = [:]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.95, blue: 0.8),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Title & subtitle
                    VStack(spacing: 8) {
                        Text("Daily Food")
                            .font(.largeTitle)
                            .bold()
                            .multilineTextAlignment(.center)
                        Text("Drag each food onto its origin")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal)

                    // Draggable items container
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            VStack(spacing: 12) {
                                ForEach(items) { pair in
                                    Text(pair.word)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(backgroundColor(for: pair.id))
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.orange, lineWidth: 1))
                                        .opacity(results[pair.id] == true ? 0.5 : 1)
                                        .disabled(results[pair.id] == true)
                                        .onDrag {
                                            NSItemProvider(object: "\(pair.id)" as NSString)
                                        }
                                }
                            }

                            VStack(spacing: 24) {
                                dropZone(country: "Singapore")
                                dropZone(country: "Indonesia")
                            }
                            .frame(maxWidth: 150)
                        }
                        .padding()
                        .frame(minHeight: 300)
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Back", action: onBack)
                }
            }
            .onReceive(data.$pairs) { all in
                let filtered = all.filter { ["Singapore","Indonesia"].contains($0.origin) }
                guard filtered.count >= 5 else {
                    items = filtered
                    return
                }
                var chosen: [DailyFoodPair]
                repeat {
                    chosen = Array(filtered.shuffled().prefix(5))
                } while !(
                    chosen.contains(where: { $0.origin == "Singapore" }) &&
                    chosen.contains(where: { $0.origin == "Indonesia" })
                )
                items = chosen
                results = [:]
            }
            .onChange(of: results) { new in
                if results.count == items.count,
                   results.values.allSatisfy({ $0 }) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onComplete()
                    }
                }
            }
        }
    }

    private func backgroundColor(for id: Int) -> Color {
        if let ok = results[id] {
            return ok
                ? Color.green.opacity(0.5)
                : Color.red.opacity(0.5)
        }
        return Color.white
    }

    @ViewBuilder
    private func dropZone(country: String) -> some View {
        VStack {
            Text(country)
                .font(.headline)
            Rectangle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 100, height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 1)
                )
                .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
                    handleDrop(providers, onto: country)
                }
        }
    }

    private func handleDrop(
        _ providers: [NSItemProvider],
        onto country: String
    ) -> Bool {
        guard let prov = providers.first else { return false }
        prov.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, _ in
            guard
                let d = data as? Data,
                let str = String(data: d, encoding: .utf8),
                let id = Int(str),
                let pair = items.first(where: { $0.id == id })
            else { return }
            let correct = (pair.origin == country)
            DispatchQueue.main.async {
                if correct {
                    results[id] = true
                } else {
                    results[id] = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        results.removeValue(forKey: id)
                    }
                }
            }
        }
        return true
    }
}
