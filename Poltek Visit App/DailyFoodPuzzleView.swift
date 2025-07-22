//
//  DailyFoodPuzzleView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 1/7/25.
//

import SwiftUI

struct DailyFoodPuzzleView: View {
    /// Called once the user has 5 correct answers
    var onComplete: () -> Void
    /// Called when the Back button is tapped
    var onBack: () -> Void

    @StateObject private var data = DailyFoodData()
    @State private var items: [DailyFoodPair] = []
    @State private var currentIndex = 0
    @State private var selection: String? = nil
    @State private var correctCount = 0

    // Number of correct answers required to finish
    private let requiredCorrect = 5

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
                    // Title
                    VStack(spacing: 8) {
                        Text("Daily Food")
                            .font(.largeTitle)
                            .bold()
                            .multilineTextAlignment(.center)
                        Text("Select the country of origin")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal)

                    Spacer()

                    // Once enough correct answers → complete
                    if correctCount >= requiredCorrect {
                        Color.clear

                    // Show next food image
                    } else if currentIndex < items.count {
                        let pair = items[currentIndex]

                        Image(pair.word)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 350, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding()

                        HStack(spacing: 40) {
                            ForEach(["Singapore", "Indonesia"], id: \.self) { country in
                                Button {
                                    guard selection == nil else { return }
                                    selection = country
                                    if country == pair.origin {
                                        correctCount += 1
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        if correctCount >= requiredCorrect {
                                            onComplete()
                                        } else {
                                            currentIndex += 1
                                            selection = nil
                                        }
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

                    // Out of items & not enough correct → retry
                    } else {
                        VStack(spacing: 16) {
                            Text("You got \(correctCount) / \(items.count) correct.\nTry again!")
                                .multilineTextAlignment(.center)
                            Button("Restart") { resetQuiz() }
                                .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }

                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back", action: onBack)
                    }
                }
                .onReceive(data.$pairs) { all in
                    startQuiz(with: all)
                }
            }
        }
    }

    // MARK: - Helpers

    private func flagEmoji(for country: String) -> String {
        switch country {
        case "Singapore": return "🇸🇬"
        case "Indonesia": return "🇮🇩"
        default:          return "?"
        }
    }

    private func backgroundColor(for country: String) -> Color {
        guard let sel = selection else { return .white }
        if sel == country {
            return sel == items[currentIndex].origin
                ? Color.green.opacity(0.5)
                : Color.red.opacity(0.5)
        }
        return .white
    }

    private func startQuiz(with all: [DailyFoodPair]) {
        let filtered = all.filter { ["Singapore", "Indonesia"].contains($0.origin) }
        guard filtered.count >= 8 else {
            items = filtered
            return
        }
        var chosen: [DailyFoodPair]
        repeat {
            chosen = Array(filtered.shuffled().prefix(8))
        } while !(
            chosen.contains(where: { $0.origin == "Singapore" }) &&
            chosen.contains(where: { $0.origin == "Indonesia" })
        )
        items = chosen
        currentIndex = 0
        selection = nil
        correctCount = 0
    }

    private func resetQuiz() {
        startQuiz(with: data.pairs)
    }
}

struct DailyFoodPuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        DailyFoodPuzzleView(onComplete: {}, onBack: {})
    }
}
