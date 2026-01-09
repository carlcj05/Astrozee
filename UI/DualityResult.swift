import Foundation

struct DualityResult {
    let masculine: Double
    let feminine: Double

    var masculinePercent: Int { Int(round(masculine * 100)) }
    var femininePercent: Int { Int(round(feminine * 100)) }
}

//
//  Duality result.swift
//  Astrozee
//
//  Created by Carl  Ozee on 09/01/2026.
//

