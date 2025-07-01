//
//  NFCScanView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI

struct NFCScanView: View {
    var onDone: ()->Void
    var onBack: ()->Void

    var body: some View {
        NavigationStack {
            VStack {
                Text("Tap an NFC tag")
                    .font(.title2)
                Spacer()
                Image(systemName: "nfc")
                    .font(.system(size: 100))
                Spacer()
                Button("Done", action: onDone)
                    .buttonStyle(.borderedProminent)
            }
            .navigationTitle("NFC Scan")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back", action: onBack)
                }
            }
            .padding()
        }
    }
}
