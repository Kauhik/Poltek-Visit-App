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

    /// Expanded set of emojis for confetti
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
                    .zIndex(0)
                }
            }

            VStack(spacing: 24) {
                ZStack {
                    // Enlarged code box
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.pink]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 300, height: 300)
                        .shadow(radius: 10)
                        .zIndex(1)

                    VStack(spacing: 8) {
                        Text(code)
                            .font(.system(size: 120, weight: .bold))
                            .foregroundColor(.white)

                        Text(codeLabel)
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .zIndex(2)
                }

                Text("Fantastic Work!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("You got a code!")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Button(action: onDone) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.teal)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 40)
            }
        }
        .onAppear {
            // Hide emojis after 6 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                withAnimation {
                    showEmojis = false
                }
            }
        }
    }
}

// MARK: - Exploding Emoji

struct ExplodingEmojiView: View {
    let emoji: String
    let delay: Double

    @State private var xNorm: CGFloat = 0.5
    @State private var yNorm: CGFloat = 0.45
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 1.0

    // Random direction and distance
    private let angle = Double.random(in: 0..<360) * .pi / 180
    private let radiusNorm = CGFloat.random(in: 0.3...0.7)

    var body: some View {
        GeometryReader { geo in
            Text(emoji)
                .font(.system(size: 45))
                .opacity(opacity)
                .position(
                    x: geo.size.width * xNorm,
                    y: geo.size.height * yNorm
                )
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
                .onAppear {
                    let targetX = 0.5 + cos(angle) * radiusNorm
                    let targetY = 0.45 + sin(angle) * radiusNorm
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(
                            Animation.easeOut(duration: 3)
                        ) {
                            xNorm = targetX
                            yNorm = targetY
                            rotation = 720
                            scale = 1.5
                            opacity = 0.0
                        }
                    }
                }
        }
    }
}

struct CodeView_Previews: PreviewProvider {
    static var previews: some View {
        CodeView(code: "CDAB", codeLabel: "All Codes") { }
    }
}
