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

    /// Which scanner tabs are “done” and should be disabled
    var completedTabs: [String]

    init(
        teamNumber: String = "",
        qrClues: [Int] = [],
        completedTabs: [String] = []
    ) {
        self.teamNumber = teamNumber
        self.qrClues = qrClues
        self.completedTabs = completedTabs
    }
}
