//
//  HolidayPuzzleView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI

fileprivate struct CardItem: Identifiable {
    let id: Int
    let text: String
    let matchId: Int
}

struct HolidayPuzzleView: View {
    var onComplete: () -> Void
    var onBack: () -> Void

    @StateObject private var data = HolidayData()
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
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Holiday Puzzle")
                        .font(.title2).bold()
                    Text("Tap the matching pairs")
                        .font(.subheadline)
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(0..<wordCards.count, id: \.self) { row in
                        HStack(spacing: 12) {
                            cardViewLeft(row)
                            cardViewRight(row)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .onReceive(data.$pairs) { all in
                let filtered = all.filter { ["Singapore","Indonesia"].contains($0.origin) }
                let origins = Set(filtered.map(\.origin))
                let needMix = origins.contains("Singapore") && origins.contains("Indonesia")

                let chosen: [HolidayPair]
                if needMix && filtered.count >= 5 {
                    var tmp: [HolidayPair]
                    repeat {
                        tmp = Array(filtered.shuffled().prefix(5))
                    } while !(
                        tmp.contains(where:{ $0.origin=="Singapore" }) &&
                        tmp.contains(where:{ $0.origin=="Indonesia" })
                    )
                    chosen = tmp
                } else {
                    chosen = Array(filtered.shuffled().prefix(5))
                }

                wordCards = chosen
                    .map { CardItem(id: $0.id * 2, text: $0.word, matchId: $0.id) }
                    .shuffled()
                meaningCards = chosen
                    .map { CardItem(id: $0.id * 2 + 1, text: $0.meaning, matchId: $0.id) }
                    .shuffled()

                selectedWord = nil
                selectedMeaning = nil
                wrongWords.removeAll()
                wrongMeanings.removeAll()
                correctWords.removeAll()
                correctMeanings.removeAll()
                matchedWords.removeAll()
                matchedMeanings.removeAll()
            }
            .navigationTitle("Holidays Puzzle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back", action: onBack)
                }
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
            correctWords.insert(w)
            correctMeanings.insert(m)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                matchedWords.insert(w)
                matchedMeanings.insert(m)
                correctWords.remove(w)
                correctMeanings.remove(m)
                selectedWord = nil
                selectedMeaning = nil
                if matchedWords.count == wordCards.count {
                    onComplete()
                }
            }
        } else {
            wrongWords.insert(w)
            wrongMeanings.insert(m)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wrongWords.remove(w)
                wrongMeanings.remove(m)
                selectedWord = nil
                selectedMeaning = nil
            }
        }
    }
}

fileprivate struct CardView: View {
    enum CardState { case normal, selected, wrong, correct }
    let text: String
    let state: CardState

    var body: some View {
        Text(text)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(background)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 1))
    }

    private var background: Color {
        switch state {
        case .normal:   return .white
        case .selected: return Color.orange.opacity(0.3)
        case .wrong:    return Color.red.opacity(0.5)
        case .correct:  return Color.green.opacity(0.5)
        }
    }
}
