//
//  MatchingPuzzleView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI

fileprivate struct Card: Identifiable {
    let id: Int
    let text: String
    let matchId: Int
}

struct MatchingPuzzleView: View {
    var onComplete: () -> Void

        //SAMPLE
    private let pairs = [
        ("Blur like sotong",         "Expression of surprise"),
        ("Walao",                     "Very confused"),
        ("Cocoklogi",                 "Making patterns from coincidences")
    ]

    // flat cards in row-major order: [Q1, A1, Q2, A2, Q3, A3]
    @State private var cards: [Card] = []
    @State private var selected: [Int] = []
    @State private var wrongSet: Set<Int> = []
    @State private var correctSet: Set<Int> = []
    @State private var matchedSet: Set<Int> = []

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        var tmp: [Card] = []
        for (i, pair) in pairs.enumerated() {
            tmp.append(.init(id: i*2,   text: pair.0, matchId: i))
            tmp.append(.init(id: i*2+1, text: pair.1, matchId: i))
        }
        _cards = State(initialValue: tmp)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cultural Expression")
                        .font(.title2).bold()
                    Text("Tap the matching pairs")
                        .font(.subheadline)
                }
                Spacer()
                Button(action: { /* close */ }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                }
            }

            // 3 rows × 2 cols
            let columns = [ GridItem(.flexible()), GridItem(.flexible()) ]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(cards.enumerated()), id: \.1.id) { idx, card in
                    CardView(
                        text: card.text,
                        state: cardState(at: idx)
                    ) {
                        guard !matchedSet.contains(idx) else { return }
                        tapCard(at: idx)
                    }
                    .opacity(matchedSet.contains(idx) ? 0.3 : 1)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: .init(colors: [Color.yellow.opacity(0.2),
                                         Color.orange.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private func cardState(at idx: Int) -> CardView.State {
        if wrongSet.contains(idx)      { return .wrong }
        if correctSet.contains(idx)    { return .correct }
        if selected.contains(idx)      { return .selected }
        return .normal
    }

    private func tapCard(at idx: Int) {
        guard selected.count < 2, !selected.contains(idx) else { return }
        selected.append(idx)

        if selected.count == 2 {
            // show both as selected
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                evaluatePair()
            }
        }
    }

    private func evaluatePair() {
        let a = selected[0], b = selected[1]
        if cards[a].matchId == cards[b].matchId {
            // correct pair
            correctSet.formUnion([a,b])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                matchedSet.formUnion([a,b])
                correctSet.subtract([a,b])
                selected.removeAll()
                if matchedSet.count == cards.count {
                    onComplete()
                }
            }
        } else {
            // wrong pair
            wrongSet.formUnion([a,b])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wrongSet.subtract([a,b])
                selected.removeAll()
            }
        }
    }
}

fileprivate struct CardView: View {
    enum State { case normal, selected, wrong, correct }

    let text: String
    let state: State
    let action: () -> Void

    var body: some View {
        Text(text)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange, lineWidth: 1)
            )
            .onTapGesture(perform: action)
    }

    private var backgroundColor: Color {
        switch state {
        case .normal:   return .white
        case .selected: return Color.orange.opacity(0.3)
        case .wrong:    return Color.red.opacity(0.5)
        case .correct:  return Color.green.opacity(0.5)
        }
    }
}
