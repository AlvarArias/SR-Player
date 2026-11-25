//
//  Colors.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2024-04-05.
//

import Foundation
import SwiftUI

extension Color {
    static let brown_light_p1 = Color("brown_light")
    static let gray_light_p2 = Color("gray_light")
    static let gray_p3 = Color("gray")
    static let green_light_p4 = Color("light_green")
    static let green_p5 = Color("green")
    static let orange_light_p6 = Color("orange_light")
    static let red_dark_p6 = Color("red_dark")

    init(hex: String) {
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8)  & 0xFF) / 255,
            blue:  Double( int        & 0xFF) / 255
        )
    }
}
