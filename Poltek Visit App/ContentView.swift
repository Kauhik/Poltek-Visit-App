

//
//  ContentView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 27/6/25.
//

import SwiftUI
import SwiftData

enum Page: String, Codable {
    case teamEntry, clueGrid, scanner
    case puzzleSelect, puzzleWords, puzzleHolidays, puzzleDailyLife, puzzleDailyFood, puzzlePlaces
    case codeReveal
}

struct ContentView: View {
    // MARK: — SwiftData bindings
    @Query private var settings: [TeamSetting]
    @Environment(\.modelContext) private var modelContext

    // Persist last page across launches
    @AppStorage("PoltekVisit_LastPage") private var lastPageRaw: String = Page.teamEntry.rawValue

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
    @State private var currentPage: Page = .teamEntry {
        didSet {
            lastPageRaw = currentPage.rawValue
        }
    }

    // MARK: — Persistent state
    @State private var qrScannedClues: Set<Int> = []
    @State private var nfcScannedClues: Set<Int> = []
    @State private var listenScannedClues: Set<Int> = []
    @State private var completedScanTabs: Set<ScannerContainerView.Tab> = []

    // MARK: — Ephemeral (but persisted) state
    @State private var usageLeft: [ScanTech: Int] = [:]
    @State private var unlockedLetters: [String] = []
    @State private var combinationUnlocked: Bool = false
    @State private var letterIndices: [String: Int] = [:]

    @State private var scannerSelectedTab: ScannerContainerView.Tab = .qr
    @State private var remainingPuzzles: [Page] = []
    @State private var currentPuzzle: Page?
    @State private var didRestoreState = false

    private var teamInfo: TeamInfo? {
        guard let n = Int(teamSetting.teamNumber) else { return nil }
        return TeamCodes.shared.info(for: n)
    }

    var body: some View {
        content
            .onAppear(perform: restoreState)
            .onChange(of: qrScannedClues)     { teamSetting.qrClues       = Array($0) }
            .onChange(of: nfcScannedClues)    { teamSetting.nfcClues      = Array($0) }
            .onChange(of: listenScannedClues) { teamSetting.listenClues   = Array($0) }
            .onChange(of: completedScanTabs)  { teamSetting.completedTabs = $0.map { $0.rawValue } }
            .onChange(of: unlockedLetters)    { teamSetting.unlockedLetters    = $0 }
            .onChange(of: combinationUnlocked){ teamSetting.combinationUnlocked = $0 }
            .onChange(of: letterIndices)      { teamSetting.letterIndices      = $0 }
    }

    @ViewBuilder
    private var content: some View {
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
                teamNumber:          teamInfo?.locker ?? teamSetting.teamNumber,
                unlockedLetters:     Set(unlockedLetters),
                pin:                 teamInfo?.pin ?? "",
                letterIndices:       letterIndices,
                combinationUnlocked: combinationUnlocked
            ) {
                scannerSelectedTab = ScannerContainerView.Tab.allCases.first {
                    !completedScanTabs.contains($0)
                } ?? .qr
                currentPage = .scanner
            }

        case .scanner:
            ScannerContainerView(
                selectedTab:         $scannerSelectedTab,
                completedTabs:       $completedScanTabs,
                qrScannedClues:      $qrScannedClues,
                nfcScannedClues:     $nfcScannedClues,
                listenScannedClues:  $listenScannedClues,
                usageLeft:           usageLeft,
                onBack:              { currentPage = .clueGrid },
                onNext: { tech in
                    usageLeft[tech] = max((usageLeft[tech] ?? 0) - 1, 0)
                    completedScanTabs.insert(scannerSelectedTab)
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
            CodeView(
                code: combinationUnlocked ? "" :
                      (unlockedLetters.last.flatMap {
                        String(pin[pin.index(pin.startIndex,
                                             offsetBy: letterIndices[$0]!)]
                        )
                      } ?? "0"),
                codeLabel: combinationUnlocked
                           ? "Click Done"
                           : (unlockedLetters.last.map { "Code \($0)" } ?? "Code")
            ) {
                currentPage = .clueGrid
            }
        }
    }

    private func restoreState() {
        guard !didRestoreState,
              !teamSetting.teamNumber.isEmpty
        else { return }
        didRestoreState = true

        qrScannedClues     = Set(teamSetting.qrClues)
        nfcScannedClues    = Set(teamSetting.nfcClues)
        listenScannedClues = Set(teamSetting.listenClues)
        completedScanTabs  = Set(
            teamSetting.completedTabs.compactMap {
                ScannerContainerView.Tab(rawValue: $0)
            }
        )
        unlockedLetters    = teamSetting.unlockedLetters
        combinationUnlocked = teamSetting.combinationUnlocked

        if teamSetting.letterIndices.isEmpty {
            let mapping = Dictionary(
                uniqueKeysWithValues:
                    zip(["A","B","C","D"], (0..<4).shuffled())
            )
            letterIndices = mapping
            teamSetting.letterIndices = mapping
        } else {
            letterIndices = teamSetting.letterIndices
        }

        usageLeft = Dictionary(
            uniqueKeysWithValues:
                ScanTech.allCases.map { ($0, $0.maxUses) }
        )
        remainingPuzzles = [
            .puzzleWords, .puzzleHolidays, .puzzleDailyLife,
            .puzzleDailyFood, .puzzlePlaces
        ]

        // Restore last page if it was a puzzle page
        if let saved = Page(rawValue: lastPageRaw),
           saved != .teamEntry && saved != .clueGrid && saved != .scanner {
            currentPage = saved
        } else {
            currentPage = .clueGrid
        }
    }

    private func resetSession() {
        qrScannedClues      = []
        nfcScannedClues     = []
        listenScannedClues  = []
        completedScanTabs   = []
        unlockedLetters     = []
        combinationUnlocked = false

        usageLeft = Dictionary(
            uniqueKeysWithValues:
                ScanTech.allCases.map { ($0, $0.maxUses) }
        )
        let mapping = Dictionary(
            uniqueKeysWithValues:
                zip(["A","B","C","D"], (0..<4).shuffled())
        )
        letterIndices = mapping
        teamSetting.letterIndices = mapping

        remainingPuzzles = [
            .puzzleWords, .puzzleHolidays, .puzzleDailyLife,
            .puzzleDailyFood, .puzzlePlaces
        ]
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
