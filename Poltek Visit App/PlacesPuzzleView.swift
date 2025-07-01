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
            VStack(spacing: 16) {
                Text("Places Puzzle")
                    .font(.title2)
                    .bold()

                Text("Tap the country code for the landmark")
                    .font(.subheadline)

                Spacer()

                if currentIndex < items.count {
                    Image(items[currentIndex].name)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 350, height: 300)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()

                    HStack(spacing: 24) {
                        countryButton(code: "SG", country: "Singapore")
                        countryButton(code: "ID", country: "Indonesia")
                    }
                    .disabled(selection != nil)
                } else {
                    Text("You got \(correctCount) / 5 correct.\nTry again to get all 5 right!")
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Restart") {
                        resetQuiz()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
            }
            .padding()
            .onReceive(data.$pairs) { all in
                guard all.count >= 5 else { return }
                startQuiz(with: all)
            }
            .navigationTitle("Places")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back", action: onBack)
                }
            }
        }
    }

    private func countryButton(code: String, country: String) -> some View {
        Button(action: {
            guard selection == nil else { return }
            selection = country
            let correct = (items[currentIndex].origin == country)
            if correct {
                correctCount += 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentIndex += 1
                if correctCount >= 5 {
                    onComplete()
                }
                selection = nil
            }
        }) {
            Text(code)
                .font(.title)
                .frame(width: 60, height: 60)
                .background(backgroundColor(for: country))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.orange, lineWidth: 1)
                )
        }
    }

    private func backgroundColor(for country: String) -> Color {
        guard let sel = selection, sel == country else {
            return Color.white
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
        if !data.pairs.isEmpty {
            startQuiz(with: data.pairs)
        }
    }
}
