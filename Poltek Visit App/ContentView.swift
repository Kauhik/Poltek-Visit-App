//
//  ContentView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 27/6/25.
//

import SwiftUI

enum Page {
    case teamEntry, clueGrid, scannerMenu
    case scannerCamera, scannerNFC, scannerMicrophone, scannerAR
    case puzzleSelect, puzzleWords, puzzleHolidays, puzzleDailyLife, puzzleDailyFood, puzzlePlaces
    case codeReveal
}

struct ContentView: View {
    @State private var currentPage: Page = .teamEntry
    @State private var teamNumber: String = ""
    @State private var usageLeft: [ScanTech:Int] = .init(
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
                    onScan: { currentPage = .scannerMenu },
                    onSelect: { _ in currentPage = .puzzleSelect }
                )

            case .scannerMenu:
                ScannerMenuView(
                    usageLeft: usageLeft,
                    unlockedCount: unlockedLetters.count
                ) { tech in
                    guard (usageLeft[tech] ?? 0) > 0 else { return }
                    switch tech {
                    case .camera:      currentPage = .scannerCamera
                    case .nfc:         currentPage = .scannerNFC
                    case .microphone:  currentPage = .scannerMicrophone
                    case .ar:          currentPage = .scannerAR
                    }
                }

            case .scannerCamera:
                CameraFeedView { completeScan() }
            case .scannerNFC:
                NFCScanView { completeScan() }
            case .scannerMicrophone:
                MicrophoneScanView { completeScan() }
            case .scannerAR:
                ARCameraView { completeScan() }

            case .puzzleSelect:
                PuzzleTypeView { choice in
                    switch choice {
                    case .words:      currentPage = .puzzleWords
                    case .holidays:   currentPage = .puzzleHolidays
                    case .dailyLife:  currentPage = .puzzleDailyLife
                    case .dailyFood:  currentPage = .puzzleDailyFood
                    case .places:     currentPage = .puzzlePlaces
                    }
                }

            case .puzzleWords:
                MatchingPuzzleView {
                    currentPage = .codeReveal
                }
            case .puzzleHolidays:
                HolidayPuzzleView {
                    currentPage = .codeReveal
                }
            case .puzzleDailyLife:
                DailyLifePuzzleView {
                    currentPage = .codeReveal
                }
            case .puzzleDailyFood:
                DailyFoodPuzzleView {
                    currentPage = .codeReveal
                }
            case .puzzlePlaces:
                PlacesPuzzleView {
                    currentPage = .codeReveal
                }

            case .codeReveal:
                CodeView {
                    currentPage = .clueGrid
                }
            }
        }
        .animation(.default, value: currentPage)
        .padding()
    }

    private func completeScan() {
        let tech: ScanTech
        switch currentPage {
        case .scannerCamera:      tech = .camera
        case .scannerNFC:         tech = .nfc
        case .scannerMicrophone:  tech = .microphone
        case .scannerAR:          tech = .ar
        default: return
        }
        usageLeft[tech] = max((usageLeft[tech] ?? 0) - 1, 0)
        if unlockedLetters.count < allLetters.count {
            unlockedLetters.append(allLetters[unlockedLetters.count])
        }
        currentPage = .puzzleSelect
    }
}
