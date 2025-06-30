//
//  ContentView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 27/6/25.
//

import SwiftUI

// MARK: – Navigation Pages
enum Page {
    case teamEntry
    case clueGrid
    case scannerMenu
    case scannerCamera, scannerNFC, scannerMicrophone, scannerAR

    // NEW: puzzle selection and puzzle instances
    case puzzleSelect
    case puzzleWords
    case puzzleHolidays

    case codeReveal
}

struct ContentView: View {
    // MARK: – App State
    @State private var currentPage: Page = .teamEntry
    @State private var teamNumber: String = ""

    // Scan‐tech usage tracking
    @State private var usageLeft: [ScanTech:Int] = .init(
        uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) }
    )

    // Unlocked letters A–E
    @State private var unlockedLetters: [String] = []
    private let allLetters = ["A","B","C","D","E"]

    // Which letter is currently selected for A–E puzzle (still used)
    @State private var selectedLetter: String = ""

    var body: some View {
        VStack {
            switch currentPage {

            //  Team Number Entry
            case .teamEntry:
                TeamInputView(teamNumber: $teamNumber) {
                    currentPage = .clueGrid
                }

            //  Clue Grid
            case .clueGrid:
                ClueListView(
                    teamNumber: teamNumber,
                    unlockedLetters: Set(unlockedLetters),
                    onScan: { currentPage = .scannerMenu },
                    onSelect: { letter in
                        selectedLetter = letter
                        currentPage = .puzzleSelect
                    }
                )

            //  Scanner Menu
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

            //  Scan placeholders
            case .scannerCamera:
                CameraFeedView { completeScan() }
            case .scannerNFC:
                NFCScanView     { completeScan() }
            case .scannerMicrophone:
                MicrophoneScanView { completeScan() }
            case .scannerAR:
                ARCameraView    { completeScan() }

            //  Puzzle-type selector
            case .puzzleSelect:
                PuzzleTypeView { choice in
                    switch choice {
                    case .words:    currentPage = .puzzleWords
                    case .holidays: currentPage = .puzzleHolidays
                    }
                }

            //  Words matching‐pairs
            case .puzzleWords:
                MatchingPuzzleView {
                    currentPage = .codeReveal
                }

            //  Holidays matching‐pairs
            case .puzzleHolidays:
                HolidayPuzzleView {
                    currentPage = .codeReveal
                }

            //  Reveal Code
            case .codeReveal:
                CodeView {
                    // After reveal, go back to grid
                    currentPage = .clueGrid
                }
            }

        }
        .animation(.default, value: currentPage)
        .padding()
    }

    // MARK: – Shared scan completion
    private func completeScan() {
        let tech: ScanTech
        switch currentPage {
        case .scannerCamera:      tech = .camera
        case .scannerNFC:         tech = .nfc
        case .scannerMicrophone:  tech = .microphone
        case .scannerAR:          tech = .ar
        default: return
        }

        if let left = usageLeft[tech], left > 0 {
            usageLeft[tech] = left - 1
        }

        if unlockedLetters.count < allLetters.count {
            let next = allLetters[unlockedLetters.count]
            unlockedLetters.append(next)
            selectedLetter = next
        }

        currentPage = .puzzleSelect
    }
}
