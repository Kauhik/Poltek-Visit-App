//
//  HolidayData.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import Foundation

struct HolidayPair: Identifiable {
    let id: Int
    let word: String      // holiday name
    let meaning: String   // date or description
    let origin: String    // "Singapore" or "Indonesia"
}

@MainActor
class HolidayData: ObservableObject {
    @Published var pairs: [HolidayPair] = []

    init() {
        loadCSV()
    }

    private func loadCSV() {
        print("[HolidayData] Starting loadCSV()")
        guard let url = Bundle.main.url(forResource: "Holidays", withExtension: "csv") else {
            print("❌ [HolidayData] Holidays.csv not found")
            return
        }
        do {
            let raw = try String(contentsOf: url)
            // 1) Split into records by newline outside quoted fields
            var records: [String] = []
            var cur = ""
            var inQuotes = false
            for ch in raw {
                if ch == "\"" {
                    inQuotes.toggle()
                    cur.append(ch)
                } else if (ch == "\n" || ch == "\r\n") && !inQuotes {
                    // end of record
                    if !cur.isEmpty {
                        records.append(cur)
                        cur = ""
                    }
                } else {
                    cur.append(ch)
                }
            }
            if !cur.isEmpty { records.append(cur) }
            print("[HolidayData] Total records (incl header):", records.count)

            // 2) First record is header listing origins
            let headerLine = records[0]
                .replacingOccurrences(of: "\u{FEFF}", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let originList = headerLine
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            print("[HolidayData] originList:", originList)
            guard !originList.isEmpty else {
                print("❌ [HolidayData] no origins in header")
                return
            }
            var currentOrigin = originList[0]

            // 3) Parse each subsequent record
            var tmp: [HolidayPair] = []
            for (i, rec) in records.enumerated() {
                if i == 0 {
                    // skip header
                    continue
                }
                let cols = splitCSVLine(rec)
                guard cols.count >= 2 else {
                    print("⚠️ [HolidayData] skipping record \(i): not 2+ cols →", cols)
                    continue
                }
                let firstField = cols[0]
                let meaning    = cols[1].trimmingCharacters(in: .whitespacesAndNewlines)

                // detect explicit origin embedded via newline in firstField
                let parts = firstField
                    .split(separator: "\n", maxSplits: 1)
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

                let holiday: String
                let origin: String
                if parts.count == 2,
                   originList.contains(parts[1]) {
                    // explicit origin marker
                    holiday = parts[0]
                    origin  = parts[1]
                    currentOrigin = origin
                    print("ℹ️ [HolidayData] record \(i) explicit origin:", origin)
                } else {
                    // use current block origin
                    holiday = firstField.trimmingCharacters(in: .whitespacesAndNewlines)
                    origin  = currentOrigin
                }

                guard !holiday.isEmpty, !meaning.isEmpty else {
                    print("⚠️ [HolidayData] skipping record \(i): empty holiday/meaning →", holiday, meaning)
                    continue
                }

                tmp.append(.init(id: i, word: holiday, meaning: meaning, origin: origin))
                print("✅ [HolidayData] loaded #\(i): \(holiday) / \(meaning) (\(origin))")
            }

            pairs = tmp
            print("[HolidayData] Loaded pairs count:", pairs.count)
        } catch {
            print("❌ [HolidayData] Error reading CSV:", error)
        }
    }

    /// splits a CSV record into fields, honoring quoted commas
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
            if s.hasPrefix("\""), s.hasSuffix("\"") {
                s = String(s.dropFirst().dropLast())
            }
            return s
        }
    }
}
