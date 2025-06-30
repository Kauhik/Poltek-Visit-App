//
//  PuzzleData.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import Foundation

/// One row from Book1.csv
struct PuzzlePair: Identifiable {
    let id: Int
    let word: String
    let meaning: String
    let origin: String
}

@MainActor
class PuzzleData: ObservableObject {
    @Published var pairs: [PuzzlePair] = []

    init() { loadCSV() }

    private func loadCSV() {
        print("[PuzzleData] loadCSV()")
        guard let url = Bundle.main.url(forResource: "Book1", withExtension: "csv") else {
            print(" Book1.csv missing")
            return
        }
        do {
            let raw = try String(contentsOf: url)
            let lines = raw
              .split(whereSeparator: \.isNewline)
              .map(String.init)
              .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            guard lines.count > 1 else { return }

            // parse header
            let header = splitCSVLine(lines[0]).map {
                $0.replacingOccurrences(of: "\u{FEFF}", with: "")
                  .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            print("[PuzzleData] header:", header)
            let wIdx = header.firstIndex(of: "Word")    ?? -1
            let mIdx = header.firstIndex(of: "Meaning") ?? -1
            let oIdx = header.firstIndex(of: "Origin")  ?? -1
            print("[PuzzleData] idx Word:\(wIdx), Meaning:\(mIdx), Origin:\(oIdx)")

            var tmp: [PuzzlePair] = []
            for (i, line) in lines.dropFirst().enumerated() {
                let cols = splitCSVLine(line)
                let w = (wIdx>=0 && wIdx<cols.count) ? cols[wIdx] : ""
                let m = (mIdx>=0 && mIdx<cols.count) ? cols[mIdx] : ""
                let o = (oIdx>=0 && oIdx<cols.count) ? cols[oIdx] : ""
                if w.isEmpty || m.isEmpty {
                    print(" skip row \(i):", cols)
                    continue
                }
                tmp.append(.init(id: i, word: w, meaning: m, origin: o))
            }
            pairs = tmp
            print("[PuzzleData] loaded pairs:", pairs.count)
        } catch {
            print(" error reading CSV:", error)
        }
    }

    /// Split a line into CSV fields, handling quoted commas
    private func splitCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var cur = ""
        var inQ = false
        for ch in line {
            switch ch {
            case "\"": inQ.toggle()
            case "," where !inQ:
                fields.append(cur); cur = ""
            default:
                cur.append(ch)
            }
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
