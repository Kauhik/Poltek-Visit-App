//
//  TeamInputView.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//
    
import SwiftUI
import Combine

/// Observes keyboard frame changes.
final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let show = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map(\.height)
        
        let hide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        Publishers.Merge(show, hide)
            .map { $0 * 0.3 }
            .assign(to: \.height, on: self)
            .store(in: &cancellables)
    }
}

struct TeamInputView: View {
    @Binding var teamNumber: String
    var onPlay: () -> Void
    
    @FocusState private var isFocused: Bool
    @StateObject private var keyboard = KeyboardObserver()
    @State private var showToast = false
    
    /// Enable Play as soon as at least one digit is entered
    private var isComplete: Bool { teamNumber.count >= 1 }
    
    /// Valid team number range
    private let validRange = 1...55
    
    var body: some View {
        ZStack {
            Image("Background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .onTapGesture { isFocused = false }
            
            GeometryReader { geo in
                VStack {
                    Spacer(minLength: geo.size.height * 0.1)
                    
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geo.size.width * 0.6)
                        .shadow(radius: 4)
                    
                    Spacer().frame(height: 20)
                    
                    // input card + toast
                    VStack(spacing: 12) {
                        VStack(spacing: 24) {
                            Text("Enter your group number")
                                .font(.headline)
                            
                            HStack(spacing: 16) {
                                DigitCircleView(digit: teamNumber.digit(at: 0))
                                DigitCircleView(digit: teamNumber.digit(at: 1))
                            }
                            
                            Button {
                                isFocused = false
                                attemptPlay()
                            } label: {
                                Text("Play")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(red: 0.9, green: 0.4, blue: 0.0))
                                    .foregroundColor(.white)
                                    .cornerRadius(30)
                            }
                            .disabled(!isComplete)
                            .contentShape(Rectangle())
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .padding(.horizontal, 24)
                        .onTapGesture { isFocused = true }
                        
                        if showToast {
                            Text("pls give a valid team number for 1 to 55")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.horizontal, 24)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { showToast = false }
                                    }
                                }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom, keyboard.height)
                .animation(.easeOut, value: keyboard.height)
            }
            
            // hidden text field to summon the number pad
            TextField("", text: $teamNumber)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .onChange(of: teamNumber) { new in
                    let nums = new.filter(\.isNumber)
                    teamNumber = String(nums.prefix(2))
                }
                .frame(width: 0, height: 0)
                .opacity(0)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isFocused = true
            }
        }
    }
    
    private func attemptPlay() {
        guard let n = Int(teamNumber),
              validRange.contains(n)
        else {
            withAnimation { showToast = true }
            return
        }
        onPlay()
    }
}

private struct DigitCircleView: View {
    let digit: String
    var body: some View {
        Text(digit)
            .font(.title)
            .frame(width: 64, height: 64)
            .background(Color.white)
            .clipShape(Circle())
            .shadow(radius: 4)
    }
}

private extension String {
    func digit(at i: Int) -> String {
        guard count > i else { return "" }
        return String(self[index(startIndex, offsetBy: i)])
    }
}

//struct TeamInput : PreviewProvider {
//    static var previews: some View {
//        TeamInputView(onComplete:{}, onBack: {})
//    }
//}
