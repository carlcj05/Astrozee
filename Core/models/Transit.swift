import Foundation

// MARK: - Modèle principal d'un transit détecté
struct Transit: Identifiable, Codable {
    let id: UUID
    let transitPlanet: String       // Ex: "jupiter"
    let aspect: AspectType          // Ex: .conjunction
    let natalPlanet: String         // Ex: "soleil"
    let startDate: Date             // Début du transit
    let endDate: Date               // Fin du transit
    let picDate: Date               // Date du pic (orbe minimum)
    let orbe: Double                // Orbe en degrés au pic
    
    // Métadonnées calculées
    var influence: String {
        let calendar = Calendar.current
        let picMonth = calendar.component(.month, from: picDate)
        let targetMonth = calendar.component(.month, from: startDate)
        
        if picMonth == targetMonth {
            return "pic en \(picDate.formatted(.dateTime.month(.wide))) 🔥"
        } else if abs(picMonth - targetMonth) == 1 {
            return "pic 1 mois avant/après 🔭"
        }
        return "pic plus d'un mois après \(targetMonth) 🔡"
    }
    
    var meteo: String {
        aspect.meteo
    }
    
    init(id: UUID = UUID(),
         transitPlanet: String,
         aspect: AspectType,
         natalPlanet: String,
         startDate: Date,
         endDate: Date,
         picDate: Date,
         orbe: Double) {
        self.id = id
        self.transitPlanet = transitPlanet
        self.aspect = aspect
        self.natalPlanet = natalPlanet
        self.startDate = startDate
        self.endDate = endDate
        self.picDate = picDate
        self.orbe = orbe
    }
}

// MARK: - Type d'aspect astrologique
enum AspectType: String, Codable, CaseIterable {
    case conjonction = "conjonction"
    case sextile = "sextile"
    case carre = "carré"
    case trigone = "trigone"
    case opposition = "opposition"
    
    var angle: Double {
        switch self {
        case .conjonction: return 0
        case .sextile: return 60
        case .carre: return 90
        case .trigone: return 120
        case .opposition: return 180
        }
    }
    
    var orbe: Double {
        switch self {
        case .conjonction: return 5
        case .sextile: return 2
        case .carre: return 3
        case .trigone: return 3
        case .opposition: return 4
        }
    }
    
    var meteo: String {
        switch self {
        case .conjonction: return "🟡⛅️"
        case .sextile, .trigone: return "🟢☀️"
        case .carre: return "🔴🌦️"
        case .opposition: return "🔴⛈️"
        }
    }
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Transit enrichi avec interprétation
struct EnrichedTransit: Identifiable {
    let id: UUID
    let transit: Transit
    var interpretation: TransitInterpretation?
    
    init(transit: Transit, interpretation: TransitInterpretation? = nil) {
        self.id = transit.id
        self.transit = transit
        self.interpretation = interpretation
    }
}

// MARK: - Interprétation depuis le JSON
struct TransitInterpretation: Codable {
    let influence: String
    let conseils: String
    
    // Sections thématiques (optionnelles dans le JSON)
    var essence: String?
    var ceQuiPeutArriver: String?
    var relations: String?
    var travail: String?
    var aEviter: String?
    var aFaire: String?
    var motsCles: String?
}
