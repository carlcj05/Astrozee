import Foundation

// C'est le modèle unique utilisé par toute l'application maintenant
struct Profile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var birthLocalDate: Date
    var tzOffsetMinutes: Int // Décalage en minutes par rapport à GMT
    
    var placeName: String?
    var latitude: Double?
    var longitude: Double?
    
    // Initialiseur par défaut
    init(id: UUID = UUID(), name: String, birthLocalDate: Date, tzOffsetMinutes: Int, placeName: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.birthLocalDate = birthLocalDate
        self.tzOffsetMinutes = tzOffsetMinutes
        self.placeName = placeName
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // Helper pour obtenir la date UTC (nécessaire pour Swiss Ephemeris)
    // Swiss Ephemeris a besoin de l'heure universelle, pas l'heure locale
    func birthDateUTC() -> Date {
        return birthLocalDate.addingTimeInterval(TimeInterval(-tzOffsetMinutes * 60))
    }
}
