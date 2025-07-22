

//
//  ContentView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 27/6/25.
//

import SwiftUI
import SwiftData

enum Page {
    case teamEntry, clueGrid, scanner
    case puzzleSelect, puzzleWords, puzzleHolidays, puzzleDailyLife, puzzleDailyFood, puzzlePlaces
    case codeReveal
}

struct ContentView: View {
    // MARK: — SwiftData bindings
    @Query private var settings: [TeamSetting]
    @Environment(\.modelContext) private var modelContext

    private var teamSetting: TeamSetting {
        if let existing = settings.first {
            return existing
        } else {
            let new = TeamSetting()
            modelContext.insert(new)
            return new
        }
    }

    // MARK: — Navigation
    @State private var currentPage: Page = .teamEntry

    // MARK: — Persistent state
    @State private var qrScannedClues: Set<Int> = []
    @State private var completedScanTabs: Set<ScannerContainerView.Tab> = []

    // MARK: — Ephemeral state
    @State private var usageLeft: [ScanTech: Int] = Dictionary(
        uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) }
    )
    @State private var unlockedLetters: [String] = []
    @State private var combinationUnlocked: Bool = false
    @State private var letterIndices: [String: Int] = [:]

    @State private var scannerSelectedTab: ScannerContainerView.Tab = .qr
    @State private var nfcScannedClues: Set<Int> = []

    @State private var remainingPuzzles: [Page] = []
    @State private var currentPuzzle: Page?

    private var teamInfo: TeamInfo? {
        guard let n = Int(teamSetting.teamNumber) else { return nil }
        return TeamCodes.shared.info(for: n)
    }

    var body: some View {
        Group {
            switch currentPage {
            case .teamEntry:
                TeamInputView(
                    teamNumber: Binding(
                        get: { teamSetting.teamNumber },
                        set: { teamSetting.teamNumber = $0 }
                    )
                ) {
                    resetSession()
                    currentPage = .clueGrid
                }

            case .clueGrid:
                ClueListView(
                    teamNumber:          teamSetting.teamNumber,
                    unlockedLetters:     Set(unlockedLetters),
                    pin:                 teamInfo?.pin ?? "",
                    letterIndices:       letterIndices,
                    combinationUnlocked: combinationUnlocked
                ) {
                    // pick next unused tab
                    scannerSelectedTab = ScannerContainerView.Tab.allCases.first {
                        !completedScanTabs.contains($0)
                    } ?? .qr
                    currentPage = .scanner
                }

            case .scanner:
                ScannerContainerView(
                    selectedTab:     $scannerSelectedTab,
                    completedTabs:   $completedScanTabs,
                    qrScannedClues:  $qrScannedClues,
                    nfcScannedClues: $nfcScannedClues,
                    usageLeft:       usageLeft,
                    onBack:          { currentPage = .clueGrid },
                    onNext:          { tech in
                        usageLeft[tech] = max((usageLeft[tech] ?? 0) - 1, 0)
                        completedScanTabs.insert(scannerSelectedTab)
                        currentPuzzle = nil
                        currentPage = .puzzleSelect
                    }
                )
                .ignoresSafeArea()
                .onAppear {
                    // restore persisted QR progress
                    if qrScannedClues.isEmpty, !teamSetting.qrClues.isEmpty {
                        qrScannedClues = Set(teamSetting.qrClues)
                    }
                    // restore which tabs are done
                    if completedScanTabs.isEmpty, !teamSetting.completedTabs.isEmpty {
                        completedScanTabs = Set(
                            teamSetting.completedTabs.compactMap {
                                ScannerContainerView.Tab(rawValue: $0)
                            }
                        )
                    }
                    // skip any already‑done tab
                    if completedScanTabs.contains(scannerSelectedTab) {
                        scannerSelectedTab = ScannerContainerView.Tab.allCases.first {
                            !completedScanTabs.contains($0)
                        } ?? .qr
                    }
                }

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
        .onAppear {
            // if reopening with a saved team, reset and jump to clue grid
            if !teamSetting.teamNumber.isEmpty && currentPage == .teamEntry {
                resetSession()
                currentPage = .clueGrid
            }
        }
        // persist QR and tab‑completion changes back to the model
        .onChange(of: qrScannedClues) { new in
            teamSetting.qrClues = Array(new)
        }
        .onChange(of: completedScanTabs) { new in
            teamSetting.completedTabs = new.map { $0.rawValue }
        }
    }

    // MARK: — Helpers

    private func resetSession() {
        unlockedLetters = []
        combinationUnlocked = false
        usageLeft = Dictionary(
            uniqueKeysWithValues: ScanTech.allCases.map { ($0, $0.maxUses) }
        )
        letterIndices = Dictionary(
            uniqueKeysWithValues: zip(["A","B","C","D"], (0..<4).shuffled())
        )
        remainingPuzzles = [
            .puzzleWords,
            .puzzleHolidays,
            .puzzleDailyLife,
            .puzzleDailyFood,
            .puzzlePlaces
        ]
        currentPuzzle = nil
        scannerSelectedTab = .qr
        completedScanTabs = []
        nfcScannedClues = []
        qrScannedClues = []
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
