//
//  ScanTech.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 30/6/25.
//

import Foundation

enum ScanTech: CaseIterable, Identifiable {
    case camera, nfc, microphone, ar

    var id: Self { self }

    var name: String {
        switch self {
        case .camera:     return "Camera"
        case .nfc:        return "NFC"
        case .microphone: return "Microphone"
        case .ar:         return "AR Camera"    
        }
    }

    var icon: String {
        switch self {
        case .camera:     return "camera"
        case .nfc:        return "nfc"
        case .microphone: return "mic.fill"
        case .ar:         return "arkit"
        }
    }

    /// How many times you may attempt that tech
    var maxUses: Int {
        switch self {
        case .camera:     return 10   // image/QR
        case .nfc:        return 13
        case .microphone: return 13   // sound
        case .ar:         return 25   // action classifier
        }
    }

    /// How many clues this tech unlocks
    var maxClues: Int {
        switch self {
        case .camera:     return 5
        case .nfc:        return 4
        case .microphone: return 4
        case .ar:         return 2
        }
    }
}
