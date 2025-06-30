//
//  ContentView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 27/6/25.
//


import SwiftUI

/// Drive which “page” we’re on
enum Page {
    case teamEntry
    case clueGrid
    case scannerMenu
    case scannerCamera, scannerNFC, scannerMicrophone, scannerAR
    case puzzle
    case codeReveal
}

struct ContentView: View {
    @State private var currentPage: Page = .teamEntry
    @State private var teamNumber: String = ""
    
    // Usage left for each technology
    @State private var usageLeft: [ScanTech:Int] = .init(
        uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) }
    )
    
    // Which letters have been unlocked so far
    @State private var unlockedLetters: [String] = []
    private let allLetters = ["A","B","C","D","E"]
    
    // Which letter the puzzle screen is showing
    @State private var selectedLetter: String = ""
    
    var body: some View {
        VStack {
            switch currentPage {
            
            // Team number entry
            case .teamEntry:
                TeamInputView(teamNumber: $teamNumber) {
                    currentPage = .clueGrid
                }

            // Clue grid
            case .clueGrid:
                ClueListView(
                  teamNumber: teamNumber,
                  unlockedLetters: Set(unlockedLetters),
                  onScan: { currentPage = .scannerMenu },
                  onSelect: { letter in
                    selectedLetter = letter
                    currentPage = .puzzle
                  }
                )

            // Scanner menu
            case .scannerMenu:
                ScannerMenuView(
                  usageLeft: usageLeft,
                  unlockedCount: unlockedLetters.count
                ) { tech in
                    // only proceed if uses remain AND this tech still has clues
                    let uses = usageLeft[tech] ?? 0
                    let cluesUsed = unlockedLetters.count
                    let techCluesUsed = unlockedLetters.filter { _ in false }.count
                    // we unlock in global order, so just check uses>0
                    guard uses > 0 else { return }
                    // go to that tech’s scan page
                    switch tech {
                    case .camera:      currentPage = .scannerCamera
                    case .nfc:         currentPage = .scannerNFC
                    case .microphone:  currentPage = .scannerMicrophone
                    case .ar:          currentPage = .scannerAR
                    }
                }

            // Individual scan placeholders
            case .scannerCamera:
                CameraFeedView { completeScan() }
            case .scannerNFC:
                NFCScanView { completeScan() }
            case .scannerMicrophone:
                MicrophoneScanView { completeScan() }
            case .scannerAR:
                ARCameraView { completeScan() }

            //  Puzzle
            case .puzzle:
                PuzzleView(letter: selectedLetter) {
                    currentPage = .codeReveal
                }

            //  Code reveal
            case .codeReveal:
                CodeView {
                    currentPage = .clueGrid
                }
            }
        }
        .animation(.default, value: currentPage)
        .padding()
    }

    /// Finalize a scan: decrement usage, unlock next letter, jump to puzzle
    private func completeScan() {
        // find which tech we came from
        let tech: ScanTech
        switch currentPage {
        case .scannerCamera:      tech = .camera
        case .scannerNFC:         tech = .nfc
        case .scannerMicrophone:  tech = .microphone
        case .scannerAR:          tech = .ar
        default: return
        }
        // decrement usage
        if let left = usageLeft[tech], left > 0 {
            usageLeft[tech] = left - 1
        }
        // unlock next letter
        if unlockedLetters.count < allLetters.count {
            let next = allLetters[unlockedLetters.count]
            unlockedLetters.append(next)
            selectedLetter = next
        }
        // go to puzzle screen
        currentPage = .puzzle
    }
}
