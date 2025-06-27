//
//  Item.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 27/6/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
