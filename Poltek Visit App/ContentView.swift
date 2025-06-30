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
    case puzzle
    case codeReveal
}

struct ContentView: View {
    // MARK: – App State
    @State private var currentPage: Page = .teamEntry
    @State private var teamNumber: String = ""
    
    // How many uses remain per tech
    @State private var usageLeft: [ScanTech:Int] = .init(
        uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) }
    )
    
    // Which letters have been unlocked (in A→E order)
    @State private var unlockedLetters: [String] = []
    private let allLetters = ["A","B","C","D","E"]
    
    // Which letter is currently selected for the puzzle
    @State private var selectedLetter: String = ""

    var body: some View {
        VStack {
            switch currentPage {
            
            //  Team Number Entry
            case .teamEntry:
                TeamInputView(teamNumber: $teamNumber) {
                    currentPage = .clueGrid
                }

            //  Clue Grid (A–E + Scan Clue)
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

            //  Scanner Menu (choose tech)
            case .scannerMenu:
                ScannerMenuView(
                    usageLeft: usageLeft,
                    unlockedCount: unlockedLetters.count
                ) { tech in
                    // only proceed if uses remain
                    guard (usageLeft[tech] ?? 0) > 0 else { return }
                    switch tech {
                    case .camera: currentPage = .scannerCamera
                    case .nfc: currentPage = .scannerNFC
                    case .microphone: currentPage = .scannerMicrophone
                    case .ar: currentPage = .scannerAR
                    }
                }

            //  Individual Scan Placeholders
            case .scannerCamera:
                CameraFeedView { completeScan() }
            case .scannerNFC:
                NFCScanView     { completeScan() }
            case .scannerMicrophone:
                MicrophoneScanView { completeScan() }
            case .scannerAR:
                ARCameraView    { completeScan() }

            //  Matching-Pairs Puzzle
            case .puzzle:
                MatchingPuzzleView {
                    currentPage = .codeReveal
                }

            //  Code Reveal
            case .codeReveal:
                CodeView {
                    currentPage = .clueGrid
                }
            }
        }
        .animation(.default, value: currentPage)
        .padding()
    }

    // MARK: – Shared Scan Completion Logic
    private func completeScan() {
        // figure out which tech we just used
        let tech: ScanTech
        switch currentPage {
        case .scannerCamera:      tech = .camera
        case .scannerNFC:         tech = .nfc
        case .scannerMicrophone:  tech = .microphone
        case .scannerAR:          tech = .ar
        default: return
        }

        // decrement uses
        if let left = usageLeft[tech], left > 0 {
            usageLeft[tech] = left - 1
        }

        // unlock the next letter A→E
        if unlockedLetters.count < allLetters.count {
            let next = allLetters[unlockedLetters.count]
            unlockedLetters.append(next)
            selectedLetter = next
        }

        // jump straight to puzzle
        currentPage = .puzzle
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
