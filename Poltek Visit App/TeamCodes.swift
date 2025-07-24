//
//  TeamCodes.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 17/7/25.
//

import Foundation

struct TeamInfo {
    let locker: String
    let pin: String
    let combination: String
}

final class TeamCodes {
    static let shared = TeamCodes()
    private var codes: [Int: TeamInfo] = [:]

    private init() { loadCSV() }

    private func loadCSV() {
        guard let url = Bundle.main.url(forResource: "team_codes", withExtension: "csv") else {
            print("team_codes.csv not found")
            return
        }
        do {
            let text = try String(contentsOf: url)
            let lines = text
                .split(whereSeparator: \.isNewline)
                .map(String.init)

            for line in lines.dropFirst() {
                let cols = line.split(separator: ",").map(String.init)
                guard cols.count >= 4,
                      let team = Int(cols[0]) else {
                    continue
                }
                let locker     = cols[1]
                let pin        = cols[2]
                let combination = cols[3]
                codes[team] = TeamInfo(
                    locker:     locker,
                    pin:        pin,
                    combination: combination
                )
            }
        } catch {
            print("CSV read error:", error)
        }
    }

    func info(for team: Int) -> TeamInfo? {
        codes[team]
    }
}
