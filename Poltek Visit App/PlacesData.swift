//
//  PlacesData.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 1/7/25.
//

import Foundation

struct PlacePair: Identifiable {
    let id: Int
    let name: String
    let origin: String
}

@MainActor
class PlacesData: ObservableObject {
    @Published var pairs: [PlacePair] = []

    init() {
        loadCSV()
    }

    private func loadCSV() {
        guard let url = Bundle.main.url(forResource: "Places", withExtension: "csv") else {
            print("[PlacesData] Places.csv not found")
            return
        }
        do {
            let raw = try String(contentsOf: url)
            let lines = raw
                .split(whereSeparator: \.isNewline)
                .map(String.init)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            guard lines.count > 1 else { return }

            var tmp: [PlacePair] = []
            for (i, line) in lines.dropFirst().enumerated() {
                let parts = line.split(separator: ",", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { continue }
                let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let origin = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, !origin.isEmpty else { continue }
                tmp.append(.init(id: i, name: name, origin: origin))
            }
            pairs = tmp
            print("[PlacesData] Loaded pairs:", pairs.count)
        } catch {
            print("[PlacesData] Error reading CSV:", error)
        }
    }
}
