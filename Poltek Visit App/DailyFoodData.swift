//
//  DailyFoodData.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 1/7/25.
//

import Foundation

struct DailyFoodPair: Identifiable {
    let id: Int
    let word: String
    let origin: String
}

@MainActor
class DailyFoodData: ObservableObject {
    @Published var pairs: [DailyFoodPair] = []

    init() {
        loadCSV()
    }

    private func loadCSV() {
        print("[DailyFoodData] Starting loadCSV()")
        guard let url = Bundle.main.url(forResource: "Dailyfood", withExtension: "csv") else {
            print(" [DailyFoodData] Dailyfood.csv not found")
            return
        }
        do {
            let raw = try String(contentsOf: url)
            // split into records on newline outside quotes
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
            print("[DailyFoodData] Total records:", records.count)

            // header row defines the two origins
            let header = records[0]
                .replacingOccurrences(of: "\u{FEFF}", with: "")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard header.count >= 2 else {
                print(" [DailyFoodData] malformed header:", header)
                return
            }
            let originA = header[0]
            let originB = header[1]
            print("[DailyFoodData] origins:", originA, originB)

            var tmp: [DailyFoodPair] = []
            var nextId = 0

            for (i, rec) in records.enumerated() {
                if i == 0 { continue }  // skip header
                let cols = splitCSVLine(rec)
                // first column → originA
                if cols.count > 0 {
                    let w = cols[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !w.isEmpty {
                        tmp.append(.init(id: nextId, word: w, origin: originA))
                        nextId += 1
                    }
                }
                // second column → originB
                if cols.count > 1 {
                    let w2 = cols[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !w2.isEmpty {
                        tmp.append(.init(id: nextId, word: w2, origin: originB))
                        nextId += 1
                    }
                }
            }

            pairs = tmp
            print("[DailyFoodData] total pairs:", pairs.count)
        } catch {
            print(" [DailyFoodData] Error reading CSV:", error)
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
                fields.append(cur); cur = ""; continue
            }
            cur.append(ch)
        }
        fields.append(cur)
        // strip wrapping quotes and whitespace
        return fields.map {
            var s = $0.trimmingCharacters(in: .whitespacesAndNewlines)
            if s.hasPrefix("\"") && s.hasSuffix("\"") {
                s = String(s.dropFirst().dropLast())
            }
            return s
        }
    }
}
