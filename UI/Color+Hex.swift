import SwiftUI

enum SystemColorHex {
    static let black: UInt32 = 0x000000
    static let blue: UInt32 = 0x007AFF
    static let brown: UInt32 = 0xA2845E
    static let cyan: UInt32 = 0x32ADE6
    static let gray: UInt32 = 0x8E8E93
    static let green: UInt32 = 0x14FC4E
    static let indigo: UInt32 = 0x5856D6
    static let mint: UInt32 = 0x00C7BE
    static let orange: UInt32 = 0xFF9500
    static let pink: UInt32 = 0xFF2D55
    static let purple: UInt32 = 0xAF52DE
    static let red: UInt32 = 0xFF3B30
    static let teal: UInt32 = 0x5AC8FA
    static let white: UInt32 = 0xFFFFFF
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

//  Color+Hex.swift
//  Astrozee
//
//  Created by Carl  Ozee on 09/01/2026.
//

