//import Foundation

struct TransitResult: Identifiable {
    let id = UUID()
    let date: Date
    let planetTransit: String
    let aspect: String
    let planetNatal: String
    let text: String
    
    // Score pour le graphique (Mood Chart)
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
        
        // --- SIMULATION DES DONNÉES (Pour tester l'affichage) ---
        // Ici, on fait semblant d'avoir trouvé ces aspects ce mois-ci
        // Ces planètes doivent exister dans ton JSON pour afficher le texte
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
                
                // On cherche le texte correspondant dans ton JSON
                let content = manager.getInterpretation(planetTransit: pT, aspect: asp, planetNatal: pN)
                
                // Si on trouve le texte dans le JSON, on l'affiche, sinon on met un message d'erreur
                let finalText = content?.influence ?? "⚠️ Pas de texte trouvé dans le JSON pour : \(pT)|\(asp)|\(pN)"
                
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
//  AstrologyEngine.swift
//  Astrozee
//
//  Created by Carl  Ozee on 06/01/2026.
//

