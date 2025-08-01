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
    @Environment(\.colorScheme) private var colorScheme

    /// Number of correct answers required to finish
    private let requiredCorrect = 5

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveBackground()
                    .overlay(
                        Color(.systemBackground)
                            .opacity(0.25)
                            .blendMode(.overlay)
                    )
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 8) {
                        Text("Daily Food")
                            .font(.largeTitle)
                            .bold()
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .allowsTightening(true)
                            .foregroundColor(.primary)
                        Text("Select the country of origin")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    .padding(.horizontal)

                    Spacer()

                    if correctCount >= requiredCorrect {
                        Color.clear
                    } else if currentIndex < items.count {
                        let pair = items[currentIndex]
                        let isWrong = selection != nil && selection != pair.origin
                        let isCorrect = selection != nil && selection == pair.origin

                        Image(pair.word)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 350, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 8)
                                    .opacity(isWrong ? 1 : 0)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: 8)
                                    .opacity(isCorrect ? 1 : 0)
                            )
                            .animation(.easeInOut(duration: 0.3), value: isWrong || isCorrect)
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
                                    ZStack {
                                        Circle()
                                            .fill(baseCircleBackground())
                                            .frame(width: 80, height: 80)
                                        if let sel = selection, sel == country {
                                            Circle()
                                                .fill(sel == pair.origin
                                                      ? Color.green.opacity(0.5)
                                                      : Color.red.opacity(0.5))
                                                .frame(width: 80, height: 80)
                                        }
                                        Text(flagEmoji(for: country))
                                            .font(.system(size: 50))
                                    }
                                    .overlay(
                                        Circle()
                                            .stroke(strokeColor, lineWidth: 1)
                                    )
                                }
                                .disabled(selection != nil)
                            }
                        }

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
                    ToolbarItem(placement: .navigationBarLeading) { }
                }
                .onReceive(data.$pairs) { all in
                    startQuiz(with: all)
                }
            }
        }
    }

    // MARK: - Helpers

    private var strokeColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.2)
        } else {
            return Color(.systemGray5)
        }
    }

    private func baseCircleBackground() -> Color {
        if colorScheme == .dark {
            return Color(.systemGray6).opacity(0.2)
        } else {
            return .white
        }
    }

    private func flagEmoji(for country: String) -> String {
        switch country {
        case "Singapore": return "🇸🇬"
        case "Indonesia":  return "🇮🇩"
        default:           return "?"
        }
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
        Group {
            DailyFoodPuzzleView(onComplete: {}, onBack: {})
                .preferredColorScheme(.light)
            DailyFoodPuzzleView(onComplete: {}, onBack: {})
                .preferredColorScheme(.dark)
        }
        .previewDevice("iPhone 14")
    }
}
