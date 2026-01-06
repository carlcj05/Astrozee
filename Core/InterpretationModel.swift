import Foundation
import Combine  // <--- C'est cette ligne qui règle l'erreur ObservableObject

// Structure du contenu dans le JSON
struct InterpretationContent: Codable {
    let influence: String
    let conseils: String
}

// Gestionnaire pour charger le fichier
class InterpretationManager: ObservableObject {
    static let shared = InterpretationManager()
    
    @Published var dictionary: [String: InterpretationContent] = [:]
    
    init() {
        loadJSON()
    }
    
    func loadJSON() {
        // Le fichier doit s'appeler "interpretations.json" dans Xcode
        guard let url = Bundle.main.url(forResource: "interpretations", withExtension: "json") else {
            print("❌ ERREUR: Fichier interpretations.json introuvable.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.dictionary = try decoder.decode([String: InterpretationContent].self, from: data)
            print("✅ JSON chargé : \(self.dictionary.count) entrées.")
        } catch {
            print("❌ ERREUR décodage JSON: \(error)")
        }
    }
    
    func getInterpretation(planetTransit: String, aspect: String, planetNatal: String) -> InterpretationContent? {
        let key = "\(planetTransit)|\(aspect)|\(planetNatal)|transit->natal"
        return dictionary[key]
    }
}
