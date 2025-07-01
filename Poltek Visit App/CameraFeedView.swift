//
//  CameraFeedView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI

struct CameraFeedView: View {
    var onDone: ()->Void
    var onBack: ()->Void

    var body: some View {
        NavigationStack {
            VStack {
                Text("Use the camera to scan")
                    .font(.title2)
                Spacer()
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                    .overlay(Text("Camera Feed Placeholder"))
                    .frame(height: 300)
                Spacer()
                Button("Done", action: onDone)
                    .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Camera Scan")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back", action: onBack)
                }
            }
            .padding()
        }
    }
}
