import Foundation

final class InterpretationService {
    static let shared = InterpretationService()
    
    private var interpretations: [String: InterpretationData] = [:]
    private var isLoaded = false
    
    private init() {}
    
    // MARK: - Chargement du JSON
    func loadInterpretations() {
        guard !isLoaded else { return }
        
        guard let url = Bundle.main.url(forResource: "interpretations", withExtension: "json") else {
            print("❌ Fichier interpretations.json introuvable dans le bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            interpretations = try JSONDecoder().decode([String: InterpretationData].self, from: data)
            isLoaded = true
            print("✅ \(interpretations.count) interprétations chargées")
        } catch {
            print("❌ Erreur de chargement du JSON : \(error)")
        }
    }
    
    // MARK: - Récupération d'interprétation
    func getInterpretation(for transit: Transit) -> TransitInterpretation? {
        // Assure que le JSON est chargé
        if !isLoaded {
            loadInterpretations()
        }
        
        // Construit la clé selon le format du JSON
        // Format: "PlaneteTransit|aspect|PlaneteNatale|transit->natal"
        let key = buildKey(
            transitPlanet: transit.transitPlanet,
            aspect: transit.aspect,
            natalPlanet: transit.natalPlanet
        )
        
        guard let data = interpretations[key] else {
            // Pas d'interprétation trouvée
            return nil
        }
        
        return TransitInterpretation(
            influence: data.influence,
            conseils: data.conseils,
            essence: extractSection(from: data.influence, emoji: "✴️"),
            ceQuiPeutArriver: extractSection(from: data.influence, emoji: "🔮"),
            relations: extractSection(from: data.influence, emoji: "❤️"),
            travail: extractSection(from: data.influence, emoji: "💼"),
            aEviter: extractSection(from: data.influence, emoji: "🧭"),
            aFaire: extractSection(from: data.influence, emoji: "🌱"),
            motsCles: extractSection(from: data.influence, emoji: "💡")
        )
    }
    
    // MARK: - Construction de la clé
    private func buildKey(transitPlanet: String, aspect: AspectType, natalPlanet: String) -> String {
        let transit = normalizePlanetName(transitPlanet)
        let natal = normalizePlanetName(natalPlanet)
        
        // Gère le cas sextile/trigone
        let aspectKey: String
        if aspect == .sextile || aspect == .trigone {
            aspectKey = "sextile|trigone"
        } else {
            aspectKey = aspect.rawValue
        }
        
        return "\(transit)|\(aspectKey)|\(natal)|transit->natal"
    }
    
    // MARK: - Normalisation des noms de planètes
    private func normalizePlanetName(_ name: String) -> String {
        let normalized = name.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .folding(options: .diacriticInsensitive, locale: .current)
        
        // Mapping des noms
        switch normalized {
        case "soleil", "soleil ☉": return "Soleil"
        case "lune", "lune ☽": return "Lune"
        case "mercure", "mercure ☿": return "Mercure"
        case "venus", "vénus", "venus ♀": return "Vénus"
        case "mars", "mars ♂": return "Mars"
        case "jupiter", "jupiter ♃": return "Jupiter"
        case "saturne", "saturne ♄": return "Saturne"
        case "uranus", "uranus ♅": return "Uranus"
        case "neptune", "neptune ♆": return "Neptune"
        case "pluton", "pluton ♇": return "Pluton"
        case "noeud nord (vrai)", "nœud nord": return "Ascendant" // Mapping spécial
        case "chiron", "chiron ⚷": return "Chiron"
        default: return normalized.capitalized
        }
    }
    
    // MARK: - Extraction des sections thématiques
    private func extractSection(from text: String, emoji: String) -> String? {
        guard text.contains(emoji) else { return nil }
        
        let sections = text.components(separatedBy: "\n\n")
        for section in sections {
            if section.hasPrefix(emoji) {
                // Retire l'emoji et le titre
                let lines = section.components(separatedBy: "\n")
                if lines.count > 1 {
                    return lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }
}

// MARK: - Structure pour parser le JSON
struct InterpretationData: Codable {
    let influence: String
    let conseils: String
}
