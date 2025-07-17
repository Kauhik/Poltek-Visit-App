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
    let combinationUnlocked: Bool
    var onScan: () -> Void

    private let allLetters = ["A", "B", "C", "D"]
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    private let codeNumbers = ["A": "1", "B": "5", "C": "6", "D": "8"]

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
                                letter: letter,
                                unlocked: unlockedLetters.contains(letter),
                                codeNumber: codeNumbers[letter]!
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Combination bar
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            (combinationUnlocked && unlockedLetters.count == 4)
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.orange, Color.pink]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                  )
                                : AnyShapeStyle(Color.gray.opacity(0.3))
                        )
                        .frame(height: 100)
                        .overlay(
                            // only show text when fully unlocked
                            Group {
                                if combinationUnlocked && unlockedLetters.count == 4 {
                                    Text("CDAB")
                                        .font(.title)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                            }
                        )
                        .padding(.horizontal, 24)

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
            .scrollContentBackground(.hidden)
        }
    }
}

private struct CodeTile: View {
    let letter: String
    let unlocked: Bool
    let codeNumber: String

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
                if unlocked {
                    Text(codeNumber)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "lock")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                Text("Code \(letter)")
                    .font(.subheadline)
                    .foregroundColor(unlocked ? .white : .gray)
            }
        }
        .frame(height: 100)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ClueListView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // still locked
            ClueListView(
                teamNumber: "30",
                unlockedLetters: ["A","B","C","D"],
                combinationUnlocked: false
            ) {}

            // now unlocked!
            ClueListView(
                teamNumber: "30",
                unlockedLetters: ["A","B","C","D"],
                combinationUnlocked: true
            ) {}
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
