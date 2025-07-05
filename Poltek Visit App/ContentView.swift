//
//  ContentView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 27/6/25.
//

import SwiftUI

enum Page {
    case teamEntry
    case clueGrid
    case scanner
    case puzzleSelect
    case puzzleWords, puzzleHolidays, puzzleDailyLife, puzzleDailyFood, puzzlePlaces
    case codeReveal
}

struct ContentView: View {
    @State private var currentPage: Page = .teamEntry
    @State private var teamNumber: String = ""
    
    /// How many scans remain per tech
    @State private var usageLeft: [ScanTech:Int] = Dictionary(
        uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) }
    )
    
    @State private var unlockedLetters: [String] = []
    private let allLetters = ["A","B","C","D","E"]
    
    var body: some View {
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
                
            case .scanner:
                ScannerContainerView(
                    usageLeft: usageLeft,
                    onBack: { currentPage = .clueGrid },
                    onDone: { tech in completeScan(with: tech) }
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
                    // Back from puzzle‐select goes to the scanner nav-bar
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
                CodeView(
                    // Only when user taps “Back to Clues” here do we unlock the next letter
                    onDone: { completePuzzle() }
                )
            }
        }
        .animation(.default, value: currentPage)
        .padding()
    }
    
    /// Called when the user finishes a scan.
    /// Decrements usage but does NOT unlock a letter yet.
    private func completeScan(with tech: ScanTech) {
        usageLeft[tech] = max((usageLeft[tech] ?? 0) - 1, 0)
        currentPage = .puzzleSelect
    }
    
    /// Called when the user actually finishes a puzzle (in CodeView).
    /// Unlocks the next letter and returns to the clues grid.
    private func completePuzzle() {
        if unlockedLetters.count < allLetters.count {
            unlockedLetters.append(allLetters[unlockedLetters.count])
        }
        currentPage = .clueGrid
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
