//
//  PlacesPuzzleView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 1/7/25.
//


import SwiftUI

struct PlacesPuzzleView: View {
    var onComplete: () -> Void
    var onBack: () -> Void

    @StateObject private var data = PlacesData()
    @State private var items: [PlacePair] = []
    @State private var currentIndex = 0
    @State private var selection: String? = nil
    @State private var correctCount = 0

    private func flagEmoji(for country: String) -> String {
        switch country {
        case "Singapore": return "🇸🇬"
        case "Indonesia": return "🇮🇩"
        default:          return "❓"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // full‑bleed gradient
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
                    // Header
                    VStack(spacing: 8) {
                        Text("Travel Destination")
                            .font(.largeTitle)
                            .bold()
                            .multilineTextAlignment(.center)
                        Text("Match destination with the country")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal)

                    if currentIndex < items.count {
                        // Landmark image
                        Image(items[currentIndex].name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 350, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding()

                        // Flag buttons
                        HStack(spacing: 24) {
                            ForEach(["Singapore", "Indonesia"], id: \.self) { country in
                                Button {
                                    guard selection == nil else { return }
                                    selection = country
                                    if items[currentIndex].origin == country {
                                        correctCount += 1
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        currentIndex += 1
                                        if correctCount >= 5 {
                                            onComplete()
                                        }
                                        selection = nil
                                    }
                                } label: {
                                    Text(flagEmoji(for: country))
                                        .font(.system(size: 50))
                                        .frame(width: 80, height: 80)
                                        .background(backgroundColor(for: country))
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.orange, lineWidth: 1)
                                        )
                                }
                                .disabled(selection != nil)
                            }
                        }
                    } else {
                        // Retry state
                        Text("You got \(correctCount) / 5 correct.\nTry again!")
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Restart") {
                            resetQuiz()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back", action: onBack)
                }
            }
        }
        .onReceive(data.$pairs) { all in
            guard all.count >= 5 else { return }
            startQuiz(with: all)
        }
    }

    private func backgroundColor(for country: String) -> Color {
        guard let sel = selection, sel == country else {
            return .white
        }
        return sel == items[currentIndex].origin
            ? Color.green.opacity(0.5)
            : Color.red.opacity(0.5)
    }

    private func startQuiz(with all: [PlacePair]) {
        items = all.shuffled()
        currentIndex = 0
        selection = nil
        correctCount = 0
    }

    private func resetQuiz() {
        startQuiz(with: data.pairs)
    }
}
