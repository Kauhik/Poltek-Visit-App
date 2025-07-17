//
//  TeamInputView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import SwiftUI
import Combine

/// Observes keyboard frame changes and publishes the current height.
final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        let willShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }

        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        Publishers.Merge(willShow, willHide)
            .assign(to: \.height, on: self)
            .store(in: &cancellables)
    }
}

struct TeamInputView: View {
    @Binding var teamNumber: String
    var onPlay: () -> Void

    @FocusState private var isTextFieldFocused: Bool
    @StateObject private var keyboard = KeyboardObserver()

    private var isComplete: Bool { teamNumber.count >= 2 }

    var body: some View {
        ZStack {
            // Background: tap outside to dismiss keyboard
            Image("Background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .onTapGesture {
                    isTextFieldFocused = false
                }

            GeometryReader { geo in
                VStack {
                    Spacer(minLength: geo.size.height * 0.1)

                    // Logo
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geo.size.width * 0.6)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                    // smaller fixed gap
                    Spacer().frame(height: 20)

                    // Input card
                    VStack(spacing: 24) {
                        Text("Enter your group number")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack(spacing: 16) {
                            DigitCircleView(digit: teamNumber.digit(at: 0))
                            DigitCircleView(digit: teamNumber.digit(at: 1))
                        }

                        Button(action: onPlay) {
                            Text("Play")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color("AccentTeal")
                                                .opacity(isComplete ? 1 : 0.5))
                                .foregroundColor(.white)
                                .cornerRadius(30)
                        }
                        .disabled(!isComplete)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    .onTapGesture {
                        // tapping the card focuses the hidden textfield
                        isTextFieldFocused = true
                    }

                    Spacer() // lets the bottom padding push it up
                }
                .frame(width: geo.size.width, height: geo.size.height)
                // shift everything up by keyboard height
                .padding(.bottom, keyboard.height)
                .animation(.easeOut(duration: 0.25), value: keyboard.height)
            }

            // Hidden TextField drives the number pad
            TextField("", text: $teamNumber)
                .keyboardType(.numberPad)
                .focused($isTextFieldFocused)
                .frame(width: 0, height: 0)
                .opacity(0)
        }
        .onAppear {
            // show keyboard after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isTextFieldFocused = true
            }
        }
    }
}

private struct DigitCircleView: View {
    let digit: String

    var body: some View {
        Text(digit)
            .font(.title)
            .foregroundColor(.primary)
            .frame(width: 64, height: 64)
            .background(Color.white)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

private extension String {
    func digit(at index: Int) -> String {
        guard count > index else { return "" }
        let idx = self.index(startIndex, offsetBy: index)
        return String(self[idx])
    }
}

struct TeamInputView_Previews: PreviewProvider {
    @State static var number = ""
    static var previews: some View {
        TeamInputView(teamNumber: $number) { }
    }
}
