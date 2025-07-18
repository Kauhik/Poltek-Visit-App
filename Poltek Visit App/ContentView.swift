//
//  ContentView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 27/6/25.
//


import SwiftUI

enum Page {
    case teamEntry, clueGrid, scanner, puzzleSelect
    case puzzleWords, puzzleHolidays, puzzleDailyLife, puzzleDailyFood, puzzlePlaces
    case codeReveal
}

struct ContentView: View {
    @State private var currentPage: Page = .teamEntry
    @State private var teamNumber: String = ""
    @State private var usageLeft: [ScanTech: Int] = Dictionary(
        uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) }
    )
    @State private var unlockedLetters: [String] = []
    @State private var combinationUnlocked: Bool = false
    @State private var letterIndices: [String: Int] = [:]

    /// Pull team info (including the 4‑digit `pin`) out of your CSV‑backed store.
    private var teamInfo: TeamInfo? {
        guard let n = Int(teamNumber) else { return nil }
        return TeamCodes.shared.info(for: n)
    }

    var body: some View {
        switch currentPage {
        case .teamEntry:
            TeamInputView(teamNumber: $teamNumber) {
                // reset state when you first hit Play
                unlockedLetters = []
                combinationUnlocked = false
                usageLeft = Dictionary(uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) })
                // shuffle A‑D into letterIndices
                let perm = Array(0..<4).shuffled()
                letterIndices = Dictionary(uniqueKeysWithValues: zip(["A","B","C","D"], perm))
                currentPage = .clueGrid
            }

        case .clueGrid:
            if let info = teamInfo {
                ClueListView(
                    teamNumber:          teamNumber,
                    unlockedLetters:     Set(unlockedLetters),
                    pin:                 info.pin,
                    letterIndices:       letterIndices,
                    combinationUnlocked: combinationUnlocked
                ) {
                    currentPage = .scanner
                }
            } else {
                EmptyView()
            }

        case .scanner:
            ScannerContainerView(
                usageLeft: usageLeft,
                onBack:    { currentPage = .clueGrid },
                onNext:    { tech in
                    usageLeft[tech] = max((usageLeft[tech] ?? 0) - 1, 0)
                    currentPage = .puzzleSelect
                }
            )
            .ignoresSafeArea()

        case .puzzleSelect:
            Color.clear
                .onAppear {
                    // pick one random puzzle
                    let puzzles: [Page] = [
                        .puzzleWords, .puzzleHolidays,
                        .puzzleDailyLife, .puzzleDailyFood,
                        .puzzlePlaces
                    ]
                    currentPage = puzzles.randomElement()!
                }

        case .puzzleWords:
            MatchingPuzzleView(
                onComplete: { advanceUnlock(); currentPage = .codeReveal },
                onBack:     { currentPage = .puzzleSelect }
            )

        case .puzzleHolidays:
            HolidayPuzzleView(
                onComplete: { advanceUnlock(); currentPage = .codeReveal },
                onBack:     { currentPage = .puzzleSelect }
            )

        case .puzzleDailyLife:
            DailyLifePuzzleView(
                onComplete: { advanceUnlock(); currentPage = .codeReveal },
                onBack:     { currentPage = .puzzleSelect }
            )

        case .puzzleDailyFood:
            DailyFoodPuzzleView(
                onComplete: { advanceUnlock(); currentPage = .codeReveal },
                onBack:     { currentPage = .puzzleSelect }
            )

        case .puzzlePlaces:
            PlacesPuzzleView(
                onComplete: { advanceUnlock(); currentPage = .codeReveal },
                onBack:     { currentPage = .puzzleSelect }
            )

        case .codeReveal:
            if let info = teamInfo {
                let pin = info.pin

                if combinationUnlocked {
                    CodeView(code: pin, codeLabel: "All Codes") {
                        currentPage = .clueGrid
                    }

                } else if
                    let last = unlockedLetters.last,
                    let idx  = letterIndices[last],
                    idx < pin.count
                {
                    let digit = String(pin[pin.index(pin.startIndex, offsetBy: idx)])
                    CodeView(code: digit, codeLabel: "Code \(last)") {
                        currentPage = .clueGrid
                    }
                } else {
                    CodeView(code: "0", codeLabel: "Code") {
                        currentPage = .clueGrid
                    }
                }
            } else {
                EmptyView()
            }
        }
    }

    private func advanceUnlock() {
        let allLetters = ["A","B","C","D","E"]
        if unlockedLetters.count < 4 {
            unlockedLetters.append(allLetters[unlockedLetters.count])
        } else {
            combinationUnlocked = true
        }
    }
}


//testing git
