//
//  TeamSetting.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 22/7/25.
//

import SwiftData

@Model
final class TeamSetting {
    /// The last‑entered team number
    var teamNumber: String

    /// Which QR clues have been found (1…5)
    var qrClues: [Int]

    /// Which scanner tabs are “done”
    var completedTabs: [String]

    /// Which letter‑codes have been unlocked (e.g. ["A","C"])
    var unlockedLetters: [String]

    /// Whether the full combination (ABCD) has been unlocked
    var combinationUnlocked: Bool

    /// The random mapping from letter → index
    var letterIndices: [String: Int]

    /// Which NFC clues (1…4) have been found
    var nfcClues: [Int]

    /// Which listen (microphone) clues (1…4) have been found
    var listenClues: [Int]

    init(
        teamNumber: String = "",
        qrClues: [Int] = [],
        completedTabs: [String] = [],
        unlockedLetters: [String] = [],
        combinationUnlocked: Bool = false,
        letterIndices: [String: Int] = [:],
        nfcClues: [Int] = [],
        listenClues: [Int] = []
    ) {
        self.teamNumber = teamNumber
        self.qrClues = qrClues
        self.completedTabs = completedTabs
        self.unlockedLetters = unlockedLetters
        self.combinationUnlocked = combinationUnlocked
        self.letterIndices = letterIndices
        self.nfcClues = nfcClues
        self.listenClues = listenClues
    }
}
