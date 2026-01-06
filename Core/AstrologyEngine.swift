import Foundation // <--- Cette ligne règle les erreurs Date, Calendar, UUID

struct TransitResult: Identifiable {
    let id = UUID()
    let date: Date
    let planetTransit: String
    let aspect: String
    let planetNatal: String
    let text: String
    
    var score: Double {
        switch aspect.lowercased() {
        case "trigone", "sextile": return 10.0
        case "conjonction": return 5.0
        case "carré", "opposition": return -10.0
        default: return 0.0
        }
    }
}

class AstrologyEngine {
    static let shared = AstrologyEngine()
    
    func calculateTransits(month: Int, year: Int) -> [TransitResult] {
        var results: [TransitResult] = []
        let manager = InterpretationManager.shared
        
        // Données de test (simulation)
        let testData = [
            ("Jupiter", "carré", "Lune", 3),
            ("Jupiter", "carré", "Mars", 10),
            ("Jupiter", "carré", "Mercure", 15),
            ("Jupiter", "carré", "Neptune", 22)
        ]
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        
        for (pT, asp, pN, day) in testData {
            components.day = day
            if let date = calendar.date(from: components) {
                
                let content = manager.getInterpretation(planetTransit: pT, aspect: asp, planetNatal: pN)
                let finalText = content?.influence ?? "Pas de texte trouvé pour : \(pT)|\(asp)|\(pN)"
                
                let result = TransitResult(
                    date: date,
                    planetTransit: pT,
                    aspect: asp,
                    planetNatal: pN,
                    text: finalText
                )
                results.append(result)
            }
        }
        
        return results.sorted(by: { $0.date < $1.date })
    }
}
