//
//  CodeView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI

struct CodeView: View {
    let code:      String
    let codeLabel: String
    var onDone:    () -> Void
    
    private let emojis = [
        "🎉","🔒","🔓","✨","🎈",
        "🥳","🎊","🎂","💥","🌟",
        "🍾","🎇","🎆","🪅","🎀",
        "🎉","✨","🌟","🎊","💥",
        "🎈","🥳","🎇","🎆","🪅",
        "🎈","🥳","🎇","🎆","🪅"

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
            
            VStack(spacing: 32) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.pink]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .padding(.horizontal, 24)
                        .shadow(radius: 10)
                    
                    VStack(spacing: 8) {
                        if !code.isEmpty {
                            Text(code)
                                .font(.system(size: 120, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text(codeLabel)
                            .font(.system(
                                size: code.isEmpty ? fortyEightSize : 28,
                                weight: code.isEmpty ? .bold : .medium
                            ))
                            .foregroundColor(.white)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                }
                
                Button {
                    onDone()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.teal)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 40)
            }
            
            // Raining emojis on top of everything
            if showEmojis {
                ForEach(Array(emojis.enumerated()), id: \.offset) { index, emoji in
                    RainingEmojiView(emoji: emoji,
                                     delay: Double(index) * 0.15) // Faster spacing between emojis
                        .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                withAnimation { showEmojis = false }
            }
        }
    }
    
    private var fortyEightSize: CGFloat { 48 }
}

/// Individual raining emoji view
struct RainingEmojiView: View {
    let emoji: String
    let delay: Double
    
    @State private var x:       CGFloat = CGFloat.random(in: 0.1...0.9) // Random horizontal start position
    @State private var y:       CGFloat = -0.1 // Start above screen
    @State private var opacity: Double  = 1.0
    
    private let horizontalDrift = CGFloat.random(in: -0.1...0.1) // Slight horizontal movement
    private let fallDuration = Double.random(in: 1.8...3.2) // Faster fall speed
    
    var body: some View {
        GeometryReader { geo in
            Text(emoji)
                .font(.system(size: 40))
                .opacity(opacity)
                .position(
                    x: geo.size.width  * x,
                    y: geo.size.height * y
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.linear(duration: fallDuration)) {
                            y = 1.1 // Fall below screen
                            x = x + horizontalDrift // Slight horizontal drift
                        }
                        
                        // Fade out near the bottom
                        DispatchQueue.main.asyncAfter(deadline: .now() + fallDuration * 0.7) {
                            withAnimation(.easeOut(duration: fallDuration * 0.3)) {
                                opacity = 0
                            }
                        }
                    }
                }
        }
    }
}
