
import Foundation

struct PlanetPosition: Identifiable, Codable {
    let id: Int
    let name: String
    let longitude: Double
    let speed: Double
    let sign: String

    var degreeInSign: String {
        formatDegreeInSign(longitude)
    }
}
