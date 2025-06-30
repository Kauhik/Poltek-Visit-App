//
//  PuzzleView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import Foundation
import SwiftUI

struct PuzzleView: View {
    let letter: String
    var onDone: ()->Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Puzzle for Clue \(letter)")
                .font(.title2)
            Rectangle()
                .fill(Color.yellow.opacity(0.3))
                .cornerRadius(12)
                .overlay(Text("Puzzle Placeholder"))
                .frame(height: 300)
            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
