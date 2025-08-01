//
//  AdaptiveBackground.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 1/8/25.
//

import Foundation
import SwiftUI

struct AdaptiveBackground: View {
    var body: some View {
        Image("Background")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}
