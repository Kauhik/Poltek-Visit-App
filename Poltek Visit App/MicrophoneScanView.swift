//
//  MicrophoneScanView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import Foundation
import SwiftUI

struct MicrophoneScanView: View {
    var onDone: ()->Void

    var body: some View {
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
        .padding()
    }
}
