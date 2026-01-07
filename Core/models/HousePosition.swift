import Foundation

struct HouseCusp: Identifiable {
    let id: Int
    let longitude: Double
    let sign: String
    let degreeInSign: String
}

struct ChartAngle: Identifiable {
    let id: String
    let name: String
    let longitude: Double
    let sign: String
    let degreeInSign: String
}

struct ChartPoint: Identifiable {
    let id: String
    let name: String
    let longitude: Double
    let sign: String
    let degreeInSign: String
}

struct HouseSystemResult {
    let cusps: [HouseCusp]
    let ascendant: Double
    let midheaven: Double
}
//  HousePosition.swift
//  Astrozee
//
//  Created by Carl  Ozee on 07/01/2026.
//

