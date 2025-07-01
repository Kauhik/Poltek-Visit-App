//
//  ScannerMenuView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI

struct ScannerMenuView: View {
    let usageLeft: [ScanTech:Int]
    let unlockedCount: Int
    var onBack: ()->Void
    var onSelectTech: (ScanTech)->Void

    @State private var selectedTech: ScanTech = .camera

    var body: some View {
        NavigationStack {
            VStack {
                Text("Uses left: \(usageLeft[selectedTech] ?? 0)/\(selectedTech.maxUses)")
                    .font(.subheadline)
                    .padding(.top, 20)

                Spacer()

                Button("Scan \(selectedTech.name)") {
                    onSelectTech(selectedTech)
                }
                .buttonStyle(.borderedProminent)
                .disabled((usageLeft[selectedTech] ?? 0) <= 0)

                Spacer()
            }
            .navigationTitle("Scanner")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back", action: onBack)
                }
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $selectedTech) {
                        ForEach(ScanTech.allCases) { tech in
                            Text(tech.name).tag(tech)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)
                }
            }
            .padding()
        }
    }
}
