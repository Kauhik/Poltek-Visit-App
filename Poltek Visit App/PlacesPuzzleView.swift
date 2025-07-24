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

    private func flagEmoji(for country: String) -> String {
        switch country {
        case "Singapore": return "🇸🇬"
        case "Indonesia":  return "🇮🇩"
        default:           return "?"
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

struct PlacesPuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        PlacesPuzzleView(onComplete: {}, onBack: {})
    }
}
