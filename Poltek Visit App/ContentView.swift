//
//  ContentView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 27/6/25.
//


import SwiftUI

enum Page {
    case teamEntry, clueGrid, scanner
    case puzzleSelect
    case puzzleWords, puzzleHolidays, puzzleDailyLife, puzzleDailyFood, puzzlePlaces
    case codeReveal
}

struct ContentView: View {
    @State private var currentPage: Page = .teamEntry
    @State private var teamNumber: String = ""
    @State private var usageLeft: [ScanTech: Int] =
        Dictionary(uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) })
    @State private var unlockedLetters: [String] = []
    @State private var combinationUnlocked: Bool = false
    private let allLetters = ["A","B","C","D","E"]

    var body: some View {
        switch currentPage {
        case .teamEntry:
            TeamInputView(teamNumber: $teamNumber) {
                currentPage = .clueGrid
            }

        case .clueGrid:
            ClueListView(
                teamNumber: teamNumber,
                unlockedLetters: Set(unlockedLetters),
                combinationUnlocked: combinationUnlocked
            ) {
                currentPage = .scanner
            }

        case .scanner:
            ScannerContainerView(
                usageLeft: usageLeft,
                onBack: { currentPage = .clueGrid },
                onNext: { tech in
                    // consume one use
                    usageLeft[tech] = max((usageLeft[tech] ?? 0) - 1, 0)
                    currentPage = .puzzleSelect
                }
            )
            .ignoresSafeArea()

        case .puzzleSelect:
            // immediately choose a random puzzle
            Color.clear
                .onAppear {
                    let puzzles: [Page] = [
                        .puzzleWords,
                        .puzzleHolidays,
                        .puzzleDailyLife,
                        .puzzleDailyFood,
                        .puzzlePlaces
                    ]
                    currentPage = puzzles.randomElement()!
                }

        // MARK: — All five puzzle cases —
        case .puzzleWords:
            MatchingPuzzleView(
                onComplete: {
                    puzzleFinished()
                    currentPage = .codeReveal
                },
                onBack: { currentPage = .clueGrid }
            )

        case .puzzleHolidays:
            HolidayPuzzleView(
                onComplete: {
                    puzzleFinished()
                    currentPage = .codeReveal
                },
                onBack: { currentPage = .clueGrid }
            )

        case .puzzleDailyLife:
            DailyLifePuzzleView(
                onComplete: {
                    puzzleFinished()
                    currentPage = .codeReveal
                },
                onBack: { currentPage = .clueGrid }
            )

        case .puzzleDailyFood:
            DailyFoodPuzzleView(
                onComplete: {
                    puzzleFinished()
                    currentPage = .codeReveal
                },
                onBack: { currentPage = .clueGrid }
            )

        case .puzzlePlaces:
            PlacesPuzzleView(
                onComplete: {
                    puzzleFinished()
                    currentPage = .codeReveal
                },
                onBack: { currentPage = .clueGrid }
            )

        case .codeReveal:
            if combinationUnlocked {
                // show final combination unlocked (CDAB)
                CodeView(code: letterCombination(), codeLabel: "All Codes") {
                    currentPage = .clueGrid
                }
            } else if let last = unlockedLetters.last {
                // per-clue reveal
                CodeView(
                    code: "\(unlockedLetters.count)",
                    codeLabel: "Code \(last)"
                ) {
                    currentPage = .clueGrid
                }
            } else {
                CodeView(code: "0", codeLabel: "Code") {
                    currentPage = .clueGrid
                }
            }
        }
    }

    /// Called when any puzzle completes
    private func puzzleFinished() {
        if unlockedLetters.count < 4 {
            // unlock next letter A→B→C→D
            unlockedLetters.append(allLetters[unlockedLetters.count])
        } else if unlockedLetters.count == 4 {
            // the fifth puzzle unlocks CDAB
            combinationUnlocked = true
        }
    }

    /// "CDAB" string for final CodeView
    private func letterCombination() -> String {
        "CDAB"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
