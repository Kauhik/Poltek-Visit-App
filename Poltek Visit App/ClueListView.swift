//
//  ClueListView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI

struct ClueListView: View {
    let teamNumber:          String
    let unlockedLetters:     Set<String>
    let pin:                 String
    let letterIndices:       [String: Int]
    let combinationUnlocked: Bool
    var onScan:              () -> Void

    private let allLetters = ["A","B","C","D"]
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            Image("Background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 80)

                    Text("Work together to unlock all codes")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(allLetters, id: \.self) { letter in
                            CodeTile(
                                letter:   letter,
                                unlocked: unlockedLetters.contains(letter),
                                digit:    codeMap[letter] ?? "?"
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    CodeTile(
                        letter:   combinationUnlocked ? "ABCD" : nil,
                        unlocked: combinationUnlocked,
                        digit:    combinationUnlocked ? combinationString : ""
                    )
                    .frame(height: 100)
                    .padding(.horizontal, 24)

                    VStack(spacing: 8) {
                        Text("Your locker number")
                            .font(.subheadline)
                        Text(teamNumber)
                            .font(.largeTitle).bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AccentOrange").opacity(0.3))
                    .cornerRadius(20)
                    .padding(.horizontal, 24)

                    Button {
                        onScan()
                    } label: {
                        Text("Scan Clue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("AccentTeal"))
                            .foregroundColor(.white)
                            .cornerRadius(30)
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 32)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var codeMap: [String:String] {
        var m = [String:String]()
        for letter in allLetters {
            if let idx = letterIndices[letter], idx < pin.count {
                let c = pin[pin.index(pin.startIndex, offsetBy: idx)]
                m[letter] = String(c)
            }
        }
        return m
    }

    private var combinationString: String {
        allLetters
            .sorted { letterIndices[$0]! < letterIndices[$1]! }
            .joined()
    }
}

/// A single “code” tile (A, B, C, D, or full‑width for the combination)
struct CodeTile: View {
    /// "A" / "B" / "C" / "D" or nil for the full‑width combination tile
    let letter:   String?
    let unlocked: Bool
    let digit:    String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    unlocked
                        ? AnyShapeStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.pink]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : AnyShapeStyle(Color.gray.opacity(0.3))
                )

            VStack(spacing: 8) {
                if let d = digit, unlocked {
                    Text(d)
                        .font(.largeTitle).bold()
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "lock")
                        .font(.title)
                        .foregroundColor(.gray)
                }

                // Only show "Code X" for single-letter tiles
                if let letter = letter, letter.count == 1 {
                    Text("Code \(letter)")
                        .font(.subheadline)
                        .foregroundColor(unlocked ? .white : .gray)
                }
            }
        }
        .frame(height: 100)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
