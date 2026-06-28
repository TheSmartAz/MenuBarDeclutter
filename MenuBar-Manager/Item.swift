//
//  Item.swift
//  MenuBar-Manager
//
//  Created by Yongjun Zhang on 2026-06-28.
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
