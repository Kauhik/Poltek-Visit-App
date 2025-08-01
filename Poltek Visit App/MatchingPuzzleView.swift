//
//  MatchingPuzzleView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI

struct MatchingPuzzleView: View {
    /// Called once all 5 pairs are matched
    var onComplete: () -> Void
    /// Called when the Back button is tapped
    var onBack: () -> Void

    @StateObject private var data = PuzzleData()
    @State private var wordCards: [CardItem]    = []
    @State private var meaningCards: [CardItem] = []
    @State private var selectedWord: Int?       = nil
    @State private var selectedMeaning: Int?    = nil
    @State private var wrongWords: Set<Int>     = []
    @State private var wrongMeanings: Set<Int>  = []
    @State private var correctWords: Set<Int>   = []
    @State private var correctMeanings: Set<Int> = []
    @State private var matchedWords: Set<Int>    = []
    @State private var matchedMeanings: Set<Int> = []

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
                    VStack(spacing: 8) {
                        Text("Cultural Expression Quest")
                            .font(.title)
                            .bold()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)                            .allowsTightening(true)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        Text("Tap the matching pairs")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60) // extra top padding so it’s clear of the notch
                    .padding(.horizontal)

                    // Cards container
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(0..<wordCards.count, id: \.self) { row in
                                HStack(spacing: 16) {
                                    cardViewLeft(row)
                                    cardViewRight(row)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 300)
                    }
//                    .background(.ultraThinMaterial)
//                    .cornerRadius(20)
//                    .padding(.horizontal)

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Uncomment if needed:
                    // Button("Back", action: onBack)
                }
            }
            .onReceive(data.$pairs) { all in
                let filtered = all.filter { ["Singapore","Indonesia"].contains($0.origin) }
                let origins = Set(filtered.map(\.origin))
                let needMix = origins.contains("Singapore") && origins.contains("Indonesia")
                let chosen: [PuzzlePair]
                if needMix && filtered.count >= 5 {
                    var tmp: [PuzzlePair]
                    repeat {
                        tmp = Array(filtered.shuffled().prefix(5))
                    } while !(
                        tmp.contains(where: { $0.origin == "Singapore" }) &&
                        tmp.contains(where: { $0.origin == "Indonesia" })
                    )
                    chosen = tmp
                } else {
                    chosen = Array(filtered.shuffled().prefix(5))
                }
                wordCards = chosen.map {
                    CardItem(id: $0.id * 2, text: $0.word, matchId: $0.id)
                }.shuffled()
                meaningCards = chosen.map {
                    CardItem(id: $0.id * 2 + 1, text: $0.meaning, matchId: $0.id)
                }.shuffled()
                selectedWord = nil
                selectedMeaning = nil
                wrongWords.removeAll()
                wrongMeanings.removeAll()
                correctWords.removeAll()
                correctMeanings.removeAll()
                matchedWords.removeAll()
                matchedMeanings.removeAll()
            }
        }
    }

    private func cardViewLeft(_ row: Int) -> some View {
        CardView(text: wordCards[row].text, state: wordState(row))
            .onTapGesture { tapWord(row) }
            .disabled(matchedWords.contains(row))
            .opacity(matchedWords.contains(row) ? 0.3 : 1)
    }

    private func cardViewRight(_ row: Int) -> some View {
        CardView(text: meaningCards[row].text, state: meaningState(row))
            .onTapGesture { tapMeaning(row) }
            .disabled(matchedMeanings.contains(row))
            .opacity(matchedMeanings.contains(row) ? 0.3 : 1)
    }

    private func wordState(_ row: Int) -> CardView.CardState {
        if wrongWords.contains(row)   { return .wrong }
        if correctWords.contains(row) { return .correct }
        if selectedWord == row        { return .selected }
        return .normal
    }

    private func meaningState(_ row: Int) -> CardView.CardState {
        if wrongMeanings.contains(row)    { return .wrong }
        if correctMeanings.contains(row)  { return .correct }
        if selectedMeaning == row         { return .selected }
        return .normal
    }

    private func tapWord(_ row: Int) {
        guard selectedWord == nil else { return }
        selectedWord = row
    }

    private func tapMeaning(_ row: Int) {
        guard selectedMeaning == nil, selectedWord != nil else { return }
        selectedMeaning = row
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            evaluatePair()
        }
    }

    private func evaluatePair() {
        guard let w = selectedWord, let m = selectedMeaning else { return }
        if wordCards[w].matchId == meaningCards[m].matchId {
            correctWords.insert(w); correctMeanings.insert(m)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                matchedWords.insert(w); matchedMeanings.insert(m)
                correctWords.remove(w); correctMeanings.remove(m)
                selectedWord = nil; selectedMeaning = nil
                if matchedWords.count == wordCards.count {
                    onComplete()
                }
            }
        } else {
            wrongWords.insert(w); wrongMeanings.insert(m)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wrongWords.remove(w); wrongMeanings.remove(m)
                selectedWord = nil; selectedMeaning = nil
            }
        }
    }
}

fileprivate struct CardItem: Identifiable {
    let id: Int
    let text: String
    let matchId: Int
}

fileprivate struct CardView: View {
    enum CardState { case normal, selected, wrong, correct }
    let text: String
    let state: CardState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(background)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray, lineWidth: 1))
            .foregroundColor(.primary) // adapts to light/dark
    }

    private var background: Color {
        switch state {
        case .normal:
            // card base adapts so it’s distinguishable in dark mode
            return colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : .white
        case .selected:
            return Color.orange.opacity(0.3)
        case .wrong:
            return Color.red.opacity(0.5)
        case .correct:
            return Color.green.opacity(0.5)
        }
    }
}

//struct MatchingPuzzleView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            MatchingPuzzleView(onComplete: {}, onBack: {})
//                .previewDevice("iPhone 14")
//                .preferredColorScheme(.light)
//            MatchingPuzzleView(onComplete: {}, onBack: {})
//                .previewDevice("iPhone 14")
//                .preferredColorScheme(.dark)
//        }
//    }
//}

struct MatchingPuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        MatchingPuzzleView(onComplete: {}, onBack: {})
            .previewDevice("iPhone 14")
    }
}
