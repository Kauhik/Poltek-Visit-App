//
//  MicrophoneScanView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI

struct MicrophoneScanView: View {
    var onDone: ()->Void
    var onBack: ()->Void

    var body: some View {
        NavigationStack {
            VStack {
                Text("Record the clue sound")
                    .font(.title2)
                Spacer()
                Image(systemName: "mic.fill")
                    .font(.system(size: 100))
                Spacer()
                Button("Done", action: onDone)
                    .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Audio Scan")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back", action: onBack)
                }
            }
            .padding()
        }
    }
}
