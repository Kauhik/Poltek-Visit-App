//
//  PuzzleTypeView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI

enum PuzzleType: String, CaseIterable, Identifiable {
    case words     = "Words"
    case holidays  = "Holidays"
    case dailyLife = "Daily Life"
    case dailyFood = "Daily Food"
    case places    = "Places"

    var id: Self { self }
}

struct PuzzleTypeView: View {
    var onSelect: (PuzzleType) -> Void
    var onBack: ()->Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Choose Puzzle Type")
                    .font(.title2).bold()

                ForEach(PuzzleType.allCases) { type in
                    Button(type.rawValue) {
                        onSelect(type)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange, lineWidth: 1)
                    )
                }
                Spacer()
            }
            .navigationTitle("Select Puzzle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back", action: onBack)
                }
            }
            .padding()
        }
    }
}
