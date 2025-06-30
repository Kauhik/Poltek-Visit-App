//
//  TeamInputView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import Foundation
import SwiftUI

struct TeamInputView: View {
    @Binding var teamNumber: String
    var onPlay: ()->Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Locker Quest!")
                .font(.largeTitle).bold()

            TextField("Enter Team Number", text: $teamNumber)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

            Button("Play", action: onPlay)
                .buttonStyle(.borderedProminent)
                .disabled(teamNumber.isEmpty)
        }
        .padding()
    }
}
