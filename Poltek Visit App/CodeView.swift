//
//  CodeView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI

struct CodeView: View {
    let code: String
    let codeLabel: String
    var onDone: () -> Void

    private let emojis = [
        "🎉", "🔒", "🔓", "✨", "🎈",
        "🥳", "🎊", "🎂", "💥", "🌟",
        "🍾", "🎇", "🎆", "🪅", "🎀"
    ]
    @State private var showEmojis = true

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.8),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if showEmojis {
                ForEach(Array(emojis.enumerated()), id: \.offset) { index, emoji in
                    ExplodingEmojiView(
                        emoji: emoji,
                        delay: Double(index) * 0.15
                    )
                    .allowsHitTesting(false)
                }
            }

            VStack(spacing: 32) {
                // Gradient box
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.pink]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        // expand width to 90% of screen and height to 250
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .padding(.horizontal, 24)
                        .shadow(radius: 10)

                    // Contents
                    VStack(spacing: 8) {
                        if !code.isEmpty {
                            Text(code)
                                .font(.system(size: 120, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text(codeLabel)
                            // larger font when it's "Click Done"
                            .font(.system(
                                size: code.isEmpty ?  fortyEightSize : 28,
                                weight: code.isEmpty ? .bold : .medium
                            ))
                            .foregroundColor(.white)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                }

                // Done button
                Button("Done", action: onDone)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .cornerRadius(30)
                    .padding(.horizontal, 40)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                withAnimation { showEmojis = false }
            }
        }
    }

    // dynamic font-size helper
    private var fortyEightSize: CGFloat { 48 }
}

struct ExplodingEmojiView: View {
    let emoji: String
    let delay: Double

    @State private var x: CGFloat = 0.5
    @State private var y: CGFloat = 0.45
    @State private var rot: Double = 0.0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 1.0

    private let angle = Double.random(in: 0..<360) * .pi / 180
    private let radiusNorm = CGFloat.random(in: 0.3...0.7)

    var body: some View {
        GeometryReader { geo in
            Text(emoji)
                .font(.system(size: 45))
                .opacity(opacity)
                .position(
                    x: geo.size.width * x,
                    y: geo.size.height * y
                )
                .rotationEffect(.degrees(rot))
                .scaleEffect(scale)
                .onAppear {
                    let targetX = 0.5 + cos(angle) * radiusNorm
                    let targetY = 0.45 + sin(angle) * radiusNorm

                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.easeOut(duration: 3)) {
                            x = targetX
                            y = targetY
                            rot = 720
                            scale = 1.5
                            opacity = 0.0
                        }
                    }
                }
        }
    }
}
