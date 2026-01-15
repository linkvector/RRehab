//
//  Item.swift
//  RRehab
//
//  Created by lovelin bookair on 15/1/2026.
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
