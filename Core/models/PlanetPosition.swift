
import Foundation

struct PlanetPosition: Identifiable, Codable {
    let id: Int
    let name: String
    let longitude: Double
    let speed: Double
    let sign: String

    var degreeInSign: String {
        var lon = longitude.truncatingRemainder(dividingBy: 360)
        if lon < 0 { lon += 360 }
        let deg = Int(lon) % 30
        let min = Int((lon - floor(lon)) * 60.0)
        return String(format: "%02d°%02d'", deg, min)
    }
}
