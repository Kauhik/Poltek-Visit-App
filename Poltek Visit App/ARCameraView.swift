//
//  ARCameraView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import Foundation
import SwiftUI

struct ARCameraView: View {
    var onDone: () -> Void

    var body: some View {
        VStack {
            Text("AR Camera")
                .font(.title2)
            Spacer()
            Rectangle()
                .fill(Color.blue.opacity(0.2))
                .cornerRadius(12)
                .overlay(Text("AR Camera Placeholder"))
                .frame(height: 300)
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
