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
    @State private var usageLeft: [ScanTech:Int] = Dictionary(
        uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) }
    )
    @State private var unlockedLetters: [String] = []
    @State private var combinationUnlocked: Bool = false
    @State private var letterIndices: [String: Int] = [:]

    /// Which tab the scanner was on
    @State private var scannerSelectedTab: ScannerContainerView.Tab = .qr

    /// Puzzle flow state (unchanged from before)
    @State private var remainingPuzzles: [Page] = []
    @State private var currentPuzzle: Page?

    private var teamInfo: TeamInfo? {
        guard let n = Int(teamNumber) else { return nil }
        return TeamCodes.shared.info(for: n)
    }

    var body: some View {
        switch currentPage {
        case .teamEntry:
            TeamInputView(teamNumber: $teamNumber) {
                resetSession()
                currentPage = .clueGrid
            }

        case .clueGrid:
            ClueListView(
                teamNumber:          teamNumber,
                unlockedLetters:     Set(unlockedLetters),
                pin:                 teamInfo?.pin ?? "",
                letterIndices:       letterIndices,
                combinationUnlocked: combinationUnlocked
            ) {
                currentPage = .scanner
            }

        case .scanner:
            ScannerContainerView(
                selectedTab: $scannerSelectedTab,
                usageLeft:   usageLeft,
                onBack:      { currentPage = .clueGrid },
                onNext:      { tech in
                    usageLeft[tech] = max((usageLeft[tech] ?? 0) - 1, 0)
                    currentPuzzle = nil
                    currentPage = .puzzleSelect
                }
            )
            .ignoresSafeArea()

        case .puzzleSelect:
            Color.clear.onAppear {
                if currentPuzzle == nil {
                    guard !remainingPuzzles.isEmpty else {
                        currentPage = .clueGrid
                        return
                    }
                    let choice = remainingPuzzles.randomElement()!
                    remainingPuzzles.removeAll { $0 == choice }
                    currentPuzzle = choice
                }
                currentPage = currentPuzzle!
            }

        case .puzzleWords:
            MatchingPuzzleView(
                onComplete: {
                    advanceUnlock()
                    currentPuzzle = nil
                    currentPage = .codeReveal
                },
                onBack: { currentPage = .scanner }
            )

        case .puzzleHolidays:
            HolidayPuzzleView(
                onComplete: {
                    advanceUnlock()
                    currentPuzzle = nil
                    currentPage = .codeReveal
                },
                onBack: { currentPage = .scanner }
            )

        case .puzzleDailyLife:
            DailyLifePuzzleView(
                onComplete: {
                    advanceUnlock()
                    currentPuzzle = nil
                    currentPage = .codeReveal
                },
                onBack: { currentPage = .scanner }
            )

        case .puzzleDailyFood:
            DailyFoodPuzzleView(
                onComplete: {
                    advanceUnlock()
                    currentPuzzle = nil
                    currentPage = .codeReveal
                },
                onBack: { currentPage = .scanner }
            )

        case .puzzlePlaces:
            PlacesPuzzleView(
                onComplete: {
                    advanceUnlock()
                    currentPuzzle = nil
                    currentPage = .codeReveal
                },
                onBack: { currentPage = .scanner }
            )

        case .codeReveal:
            let pin = teamInfo?.pin ?? ""
            if combinationUnlocked {
                CodeView(code: "", codeLabel: "Click Done") {
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
        }
    }

    private func resetSession() {
        unlockedLetters = []
        combinationUnlocked = false
        usageLeft = Dictionary(uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) })
        letterIndices = Dictionary(uniqueKeysWithValues: zip(["A","B","C","D"], (0..<4).shuffled()))
        remainingPuzzles = [.puzzleWords, .puzzleHolidays, .puzzleDailyLife, .puzzleDailyFood, .puzzlePlaces]
        currentPuzzle = nil
        scannerSelectedTab = .qr
    }

    private func advanceUnlock() {
        let all = ["A","B","C","D"]
        if unlockedLetters.count < 4 {
            unlockedLetters.append(all[unlockedLetters.count])
        } else {
            combinationUnlocked = true
        }
    }
}
