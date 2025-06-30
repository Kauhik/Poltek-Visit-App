//
//  ScannerMenuView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import Foundation
import SwiftUI

struct ScannerMenuView: View {
    let usageLeft: [ScanTech:Int]
    let unlockedCount: Int
    var onSelectTech: (ScanTech)->Void

    private let columns = [ GridItem(.flexible()), GridItem(.flexible()) ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Scanner Page")
                .font(.title2)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(ScanTech.allCases) { tech in
                    let canUse = (usageLeft[tech] ?? 0) > 0
                    Button {
                        onSelectTech(tech)
                    } label: {
                        VStack {
                            Image(systemName: tech.icon)
                                .font(.largeTitle)
                            Text("\(tech.name)\nUses left: \(usageLeft[tech] ?? 0)/\(tech.maxUses)")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(canUse ? Color.gray.opacity(0.2)
                                             : Color.gray.opacity(0.1))
                        )
                    }
                    .disabled(!canUse)
                }
            }

            Spacer()
        }
        .padding()
    }
}
