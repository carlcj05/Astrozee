import Foundation

struct Profile: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    /// Date & heure locales de naissance
    var birthLocalDate: Date
    /// Décalage de fuseau en minutes à la naissance (DST inclus)
    var tzOffsetMinutes: Int
    /// Lieu (facultatif mais utile)
    var placeName: String?
    var latitude: Double?
    var longitude: Double?
}

extension Profile {
    /// Convertit l’heure locale en UTC pour Swiss Ephemeris
    func birthDateUTC() -> Date {
        birthLocalDate.addingTimeInterval(TimeInterval(-tzOffsetMinutes * 60))
    }
}
