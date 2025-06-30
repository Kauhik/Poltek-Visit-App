//
//  MatchingPuzzleView.swift
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

struct MatchingPuzzleView: View {
    /// Called once all 5 pairs are matched
    var onComplete: () -> Void

    @StateObject private var data = PuzzleData()

    // Left‐column words & right‐column meanings
    @State private var wordCards: [CardItem]    = []
    @State private var meaningCards: [CardItem] = []

    // Selections
    @State private var selectedWord: Int?       = nil
    @State private var selectedMeaning: Int?    = nil

    // Feedback sets
    @State private var wrongWords: Set<Int>     = []
    @State private var wrongMeanings: Set<Int>  = []
    @State private var correctWords: Set<Int>   = []
    @State private var correctMeanings: Set<Int> = []

    // Matched sets (faded)
    @State private var matchedWords: Set<Int>    = []
    @State private var matchedMeanings: Set<Int> = []

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Cultural Expression")
                    .font(.title2).bold()
                Text("Tap the matching pairs")
                    .font(.subheadline)
            }
            .padding(.horizontal)

            // 5 rows x 2 columns
            VStack(spacing: 12) {
                ForEach(0..<wordCards.count, id: \.self) { row in
                    HStack(spacing: 12) {
                        leftCard(row)
                        rightCard(row)
                    }
                }
            }
            .padding(.horizontal)
        }
        .onReceive(data.$pairs) { all in
            // 1) Filter only SG/ID
            let filtered = all.filter { ["Singapore","Indonesia"].contains($0.origin) }
            // 2) Ensure at least one of each if possible
            let origins = Set(filtered.map(\.origin))
            let needMix = origins.contains("Singapore") && origins.contains("Indonesia")

            // 3) Pick 5
            let chosen: [PuzzlePair]
            if needMix && filtered.count >= 5 {
                var tmp: [PuzzlePair]
                repeat {
                    tmp = Array(filtered.shuffled().prefix(5))
                } while !(
                    tmp.contains(where:{ $0.origin=="Singapore" })
                    && tmp.contains(where:{ $0.origin=="Indonesia" })
                )
                chosen = tmp
            } else {
                chosen = Array(filtered.shuffled().prefix(5))
            }

            // 4) Build independent shuffles
            wordCards = chosen
                .map { CardItem(id:$0.id*2, text:$0.word, matchId:$0.id) }
                .shuffled()
            meaningCards = chosen
                .map { CardItem(id:$0.id*2+1, text:$0.meaning, matchId:$0.id) }
                .shuffled()

            // 5) Reset all selection/feedback
            selectedWord     = nil
            selectedMeaning  = nil
            wrongWords.removeAll()
            wrongMeanings.removeAll()
            correctWords.removeAll()
            correctMeanings.removeAll()
            matchedWords.removeAll()
            matchedMeanings.removeAll()
        }
    }

    // MARK: – Card builders

    private func leftCard(_ row: Int) -> some View {
        CardView(text: wordCards[row].text, state: wordState(row))
            .onTapGesture { tapWord(row) }
            .disabled(matchedWords.contains(row))
            .opacity(matchedWords.contains(row) ? 0.3 : 1)
    }

    private func rightCard(_ row: Int) -> some View {
        CardView(text: meaningCards[row].text, state: meaningState(row))
            .onTapGesture { tapMeaning(row) }
            .disabled(matchedMeanings.contains(row))
            .opacity(matchedMeanings.contains(row) ? 0.3 : 1)
    }

    // MARK: – States

    private func wordState(_ row: Int) -> CardView.CardState {
        if wrongWords.contains(row)    { return .wrong }
        if correctWords.contains(row)  { return .correct }
        if selectedWord == row         { return .selected }
        return .normal
    }

    private func meaningState(_ row: Int) -> CardView.CardState {
        if wrongMeanings.contains(row)   { return .wrong }
        if correctMeanings.contains(row) { return .correct }
        if selectedMeaning == row        { return .selected }
        return .normal
    }

    // MARK: – Tap handlers

    private func tapWord(_ row: Int) {
        // only if none selected yet
        guard selectedWord == nil else { return }
        selectedWord = row
    }

    private func tapMeaning(_ row: Int) {
        // only after a word is selected
        guard selectedMeaning == nil, selectedWord != nil else { return }
        selectedMeaning = row
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            evaluatePair()
        }
    }

    private func evaluatePair() {
        guard let w = selectedWord, let m = selectedMeaning else { return }
        if wordCards[w].matchId == meaningCards[m].matchId {
            // correct
            correctWords.insert(w)
            correctMeanings.insert(m)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                matchedWords.insert(w)
                matchedMeanings.insert(m)
                correctWords.remove(w)
                correctMeanings.remove(m)
                selectedWord    = nil
                selectedMeaning = nil
                // done?
                if matchedWords.count == wordCards.count {
                    onComplete()
                }
            }
        } else {
            // wrong
            wrongWords.insert(w)
            wrongMeanings.insert(m)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wrongWords.remove(w)
                wrongMeanings.remove(m)
                selectedWord    = nil
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
