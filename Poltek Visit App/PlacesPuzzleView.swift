//
//  PlacesPuzzleView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 1/7/25.
//


import SwiftUI

struct PlacesPuzzleView: View {
    /// Called once all 5 places have been answered
    var onComplete: () -> Void

    @StateObject private var data = PlacesData()
    @State private var items: [PlacePair] = []
    @State private var currentIndex = 0
    @State private var selection: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            Text("Places Puzzle")
                .font(.title2)
                .bold()

            Text("Tap the country code for the landmark")
                .font(.subheadline)

            Spacer()

            if currentIndex < items.count {
                Image(items[currentIndex].name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 250)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()

                HStack(spacing: 24) {
                    countryButton(code: "SG", country: "Singapore")
                    countryButton(code: "ID", country: "Indonesia")
                }
                .disabled(selection != nil)
            }

            Spacer()
        }
        .padding()
        .onReceive(data.$pairs) { all in
            guard all.count >= 5 else {
                print("[PlacesPuzzle] Not enough items")
                return
            }
            // pick 5 with at least one SG and one ID
            var chosen: [PlacePair]
            repeat {
                chosen = Array(all.shuffled().prefix(5))
            } while !(
                chosen.contains(where: { $0.origin == "Singapore" }) &&
                chosen.contains(where: { $0.origin == "Indonesia" })
            )
            items = chosen
            currentIndex = 0
            selection = nil
        }
    }

    private func countryButton(code: String, country: String) -> some View {
        Button(action: {
            selection = country
            let correct = (items[currentIndex].origin == country)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if correct {
                    currentIndex += 1
                    if currentIndex >= items.count {
                        onComplete()
                    }
                }
                selection = nil
            }
        }) {
            Text(code)
                .font(.title)
                .frame(width: 60, height: 60)
                .background(backgroundColor(for: country))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.orange, lineWidth: 1)
                )
        }
    }

    private func backgroundColor(for country: String) -> Color {
        guard let sel = selection, sel == country else {
            return Color.white
        }
        return sel == items[currentIndex].origin
            ? Color.green.opacity(0.5)
            : Color.red.opacity(0.5)
    }
}
