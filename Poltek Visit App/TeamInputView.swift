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
    private let validRange = 1...200
    
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
                            
                            // Single number box replacing the two bubbles
                            NumberBoxView(number: teamNumber)
                                .onTapGesture { isFocused = true }
                            
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
                            Text("Give a valid team number between 1 and 200") // remember to edit the cnumber here is the range number is changed
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
                    teamNumber = String(nums.prefix(3)) // allow up to 3 digits now
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

private struct NumberBoxView: View {
    let number: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(height: 64)
                .shadow(radius: 4)
            Text(number.isEmpty ? "--" : number)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(maxWidth: 160)
    }
}

private extension String {
    func digit(at i: Int) -> String {
        guard count > i else { return "--" }
        return String(self[index(startIndex, offsetBy: i)])
    }
}
