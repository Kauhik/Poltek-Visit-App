//
//  ClueListView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI

struct ClueListView: View {
    let teamNumber: String
    let unlockedLetters: Set<String>
    var onScan: () -> Void
    var onSelect: (String) -> Void

    // A–D in a 2×2 grid, then E full‑width
    private let allLetters = ["A", "B", "C", "D"]
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    
    var body: some View {
        ZStack {
            // full‑screen background image
            Image("Background")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    
                    Spacer()
                                            .frame(height: 80)
                    // header
                    Text("Work together to unlock all codes and open the locker")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // 2×2 grid of A–D
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(allLetters, id: \.self) { letter in
                            CodeTile(letter: letter,
                                     unlocked: unlockedLetters.contains(letter))
                                .onTapGesture {
                                    if unlockedLetters.contains(letter) {
                                        onSelect(letter)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 24)

                    // full‑width tile E
                    CodeTile(letter: "E",
                             unlocked: unlockedLetters.contains("E"))
                        .frame(height: 100)
                        .padding(.horizontal, 24)
                        .onTapGesture {
                            if unlockedLetters.contains("E") {
                                onSelect("E")
                            }
                        }

                    // locker number badge
                    VStack(spacing: 8) {
                        Text("Your locker number")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text(teamNumber)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AccentOrange").opacity(0.3))
                    .cornerRadius(20)
                    .padding(.horizontal, 24)

                    // scan clue button
                    Button(action: onScan) {
                        Text("Scan Clue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("AccentTeal"))
                            .foregroundColor(.white)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 32)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
            // hide the white ScrollView background
            .scrollContentBackground(.hidden)
        }
    }
}

private struct CodeTile: View {
    let letter: String
    let unlocked: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.3))

            VStack(spacing: 8) {
                Image(systemName: unlocked ? "lock.open" : "lock")
                    .font(.title)
                    .foregroundColor(.gray)
                Text("Code \(letter)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(height: 100)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ClueListView_Previews: PreviewProvider {
    static var previews: some View {
        ClueListView(
            teamNumber: "30",
            unlockedLetters: ["A", "C"],
            onScan: {},
            onSelect: { _ in }
        )
    }
}
