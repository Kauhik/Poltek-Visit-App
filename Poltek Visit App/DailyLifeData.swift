//
//  DailyLifeData.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import Foundation

struct DailyLifePair: Identifiable {
    let id: Int
    let word: String
    let meaning: String
    let origin: String
}

@MainActor
class DailyLifeData: ObservableObject {
    @Published var pairs: [DailyLifePair] = []

    init() {
        loadCSV()
    }

    private func loadCSV() {
        print("[DailyLifeData] Starting loadCSV()")
        guard let url = Bundle.main.url(forResource: "Dailylife", withExtension: "csv") else {
            print(" [DailyLifeData] Dailylife.csv not found")
            return
        }
        do {
            let raw = try String(contentsOf: url)
            // Split into records, newline outside quotes
            var records: [String] = []
            var cur = ""
            var inQuotes = false
            for ch in raw {
                if ch == "\"" {
                    inQuotes.toggle()
                    cur.append(ch)
                } else if (ch == "\n" || ch == "\r\n") && !inQuotes {
                    if !cur.isEmpty {
                        records.append(cur)
                        cur = ""
                    }
                } else {
                    cur.append(ch)
                }
            }
            if !cur.isEmpty { records.append(cur) }
            print("[DailyLifeData] Total records:", records.count)

            // header = list of origins
            let header = records[0]
                .replacingOccurrences(of: "\u{FEFF}", with: "")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            print("[DailyLifeData] origins header:", header)
            var currentOrigin = header.first ?? ""

            var tmp: [DailyLifePair] = []
            for (i, rec) in records.enumerated() {
                if i == 0 { continue }
                let cols = splitCSVLine(rec)
                guard cols.count >= 2 else {
                    print(" [DailyLifeData] skip record \(i):", cols)
                    continue
                }
                // detect embedded origin via newline in word field
                let parts = cols[0]
                    .split(separator: "\n", maxSplits: 1)
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                let word: String
                let origin: String
                if parts.count == 2, header.contains(parts[1]) {
                    word = parts[0]
                    origin = parts[1]
                    currentOrigin = origin
                } else {
                    word = parts[0]
                    origin = currentOrigin
                }
                let meaning = cols[1].trimmingCharacters(in: .whitespacesAndNewlines)

                guard !word.isEmpty, !meaning.isEmpty else {
                    print(" [DailyLifeData] skip empty fields \(i):", word, meaning)
                    continue
                }

                tmp.append(.init(id: i, word: word, meaning: meaning, origin: origin))
                print(" [DailyLifeData] loaded #\(i):", word, "/", meaning, "(\(origin))")
            }

            pairs = tmp
            print("[DailyLifeData] total pairs:", pairs.count)
        } catch {
            print(" [DailyLifeData] Error reading CSV:", error)
        }
    }

    private func splitCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var cur = ""
        var inQuotes = false
        for ch in line {
            if ch == "\"" {
                inQuotes.toggle()
            } else if ch == "," && !inQuotes {
                fields.append(cur)
                cur = ""
                continue
            }
            cur.append(ch)
        }
        fields.append(cur)
        return fields.map {
            var s = $0.trimmingCharacters(in: .whitespacesAndNewlines)
            if s.hasPrefix("\"") && s.hasSuffix("\"") {
                s = String(s.dropFirst().dropLast())
            }
            return s
        }
    }
}
