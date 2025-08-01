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
    @Environment(\.colorScheme) private var colorScheme

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
                    // Header
                    VStack(spacing: 8) {
                        Text("Travel Destination")
                            .font(.largeTitle)
                            .bold()
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .allowsTightening(true)
                            .foregroundColor(.primary)
                        Text("Match destination with the country")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    .padding(.horizontal)

                    if currentIndex < items.count {
                        let place = items[currentIndex]
                        let isWrong = selection != nil && selection != place.origin
                        let isCorrect = selection != nil && selection == place.origin

                        Image(place.name)
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

                        HStack(spacing: 24) {
                            ForEach(["Singapore", "Indonesia"], id: \.self) { country in
                                Button {
                                    guard selection == nil else { return }
                                    selection = country
                                    if place.origin == country {
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
                                    ZStack {
                                        Circle()
                                            .fill(baseCircleBackground())
                                            .frame(width: 80, height: 80)
                                        if let sel = selection, sel == country {
                                            Circle()
                                                .fill(selection == place.origin
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
                ToolbarItem(placement: .navigationBarLeading) { }
            }
        }
        .onReceive(data.$pairs) { all in
            guard all.count >= 5 else { return }
            startQuiz(with: all)
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

struct PlacesPuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PlacesPuzzleView(onComplete: {}, onBack: {})
                .preferredColorScheme(.light)
            PlacesPuzzleView(onComplete: {}, onBack: {})
                .preferredColorScheme(.dark)
        }
        .previewDevice("iPhone 14")
    }
}
