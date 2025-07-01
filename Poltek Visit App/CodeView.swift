//
//  CodeView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI

struct CodeView: View {
    /// Called when the “Back to Clues” button is tapped
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("You got a code!")
                .font(.title2)
                .bold()

            Text("1")
                .font(.system(size: 80))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.3))
                )

            Button("Back to Clues", action: onDone)
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}
