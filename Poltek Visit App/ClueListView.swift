//
//  ClueListView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import Foundation
import SwiftUI

struct ClueListView: View {
    let teamNumber: String
    let unlockedLetters: Set<String>
    var onScan: ()->Void
    var onSelect: (String)->Void

    private let columns = [ GridItem(.flexible()), GridItem(.flexible()) ]
    private let allLetters = ["A","B","C","D","E"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Solve Puzzle!  Locker #\(teamNumber)")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(allLetters, id: \.self) { letter in
                    Button {
                        onSelect(letter)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(unlockedLetters.contains(letter)
                                      ? Color.blue.opacity(0.3)
                                      : Color.gray.opacity(0.2))
                                .frame(height: 80)

                            HStack {
                                Text(letter)
                                    .font(.title2).bold()
                                Spacer()
                                Image(systemName:
                                    unlockedLetters.contains(letter)
                                        ? "lock.open"
                                        : "lock"
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    .disabled(!unlockedLetters.contains(letter))
                }
            }

            Button("Scan Clue", action: onScan)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}
