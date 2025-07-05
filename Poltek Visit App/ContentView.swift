//
//  ContentView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 27/6/25.
//

import SwiftUI

enum Page {
    case teamEntry, clueGrid, scanner
    case puzzleSelect, puzzleWords, puzzleHolidays, puzzleDailyLife, puzzleDailyFood, puzzlePlaces
    case codeReveal
}

struct ContentView: View {
    @State private var currentPage: Page = .teamEntry
    @State private var teamNumber: String = ""
    @State private var usageLeft: [ScanTech:Int] = Dictionary(
        uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) }
    )
    @State private var unlockedLetters: [String] = []
    private let allLetters = ["A","B","C","D","E"]

    var body: some View {
        if currentPage == .scanner {
            ScannerContainerView(
                usageLeft: usageLeft,
                onBack: { currentPage = .clueGrid },
                onNext: { tech in
                    usageLeft[tech] = max((usageLeft[tech] ?? 0) - 1, 0)
                    currentPage = .puzzleSelect
                }
            )
            .ignoresSafeArea()

        } else {
            VStack {
                switch currentPage {
                case .teamEntry:
                    TeamInputView(teamNumber: $teamNumber) {
                        currentPage = .clueGrid
                    }

                case .clueGrid:
                    ClueListView(
                        teamNumber: teamNumber,
                        unlockedLetters: Set(unlockedLetters),
                        onScan: { currentPage = .scanner },
                        onSelect: { _ in currentPage = .puzzleSelect }
                    )

                case .puzzleSelect:
                    PuzzleTypeView(
                        onSelect: { choice in
                            switch choice {
                            case .words:      currentPage = .puzzleWords
                            case .holidays:   currentPage = .puzzleHolidays
                            case .dailyLife:  currentPage = .puzzleDailyLife
                            case .dailyFood:  currentPage = .puzzleDailyFood
                            case .places:     currentPage = .puzzlePlaces
                            }
                        },
                        onBack: { currentPage = .scanner }
                    )

                case .puzzleWords:
                    MatchingPuzzleView(
                        onComplete: { currentPage = .codeReveal },
                        onBack:     { currentPage = .puzzleSelect }
                    )

                case .puzzleHolidays:
                    HolidayPuzzleView(
                        onComplete: { currentPage = .codeReveal },
                        onBack:     { currentPage = .puzzleSelect }
                    )

                case .puzzleDailyLife:
                    DailyLifePuzzleView(
                        onComplete: { currentPage = .codeReveal },
                        onBack:     { currentPage = .puzzleSelect }
                    )

                case .puzzleDailyFood:
                    DailyFoodPuzzleView(
                        onComplete: { currentPage = .codeReveal },
                        onBack:     { currentPage = .puzzleSelect }
                    )

                case .puzzlePlaces:
                    PlacesPuzzleView(
                        onComplete: { currentPage = .codeReveal },
                        onBack:     { currentPage = .puzzleSelect }
                    )

                case .codeReveal:
                    CodeView {
                        if unlockedLetters.count < allLetters.count {
                            unlockedLetters.append(allLetters[unlockedLetters.count])
                        }
                        currentPage = .clueGrid
                    }

                // scanner handled above
                case .scanner:
                    EmptyView()
                }
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
