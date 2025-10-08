//import Foundation

// Structure du contenu dans le JSON
struct InterpretationContent: Codable {
    let influence: String
    let conseils: String
}

// Gestionnaire pour charger le fichier
class InterpretationManager: ObservableObject {
    static let shared = InterpretationManager()
    
    // Dictionnaire qui stocke tout : Clé -> Contenu
    var dictionary: [String: InterpretationContent] = [:]
    
    init() {
        loadJSON()
    }
    
    func loadJSON() {
        // Le nom doit être EXACTEMENT celui de ton fichier dans Xcode (sans le .json)
        guard let url = Bundle.main.url(forResource: "interpretations_clean", withExtension: "json") else {
            print("❌ ERREUR: Fichier interpretations_clean.json introuvable.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.dictionary = try decoder.decode([String: InterpretationContent].self, from: data)
            print("✅ JSON chargé : \(self.dictionary.count) entrées trouvées.")
        } catch {
            print("❌ ERREUR décodage JSON: \(error)")
        }
    }
    
    // Fonction pour récupérer le texte
    func getInterpretation(planetTransit: String, aspect: String, planetNatal: String) -> InterpretationContent? {
        // Reconstitution de la clé exacte du JSON
        // Ex: "Jupiter|carré|Lune|transit->natal"
        let key = "\(planetTransit)|\(aspect)|\(planetNatal)|transit->natal"
        return dictionary[key]
    }
}
//  InterpretationModel.swift
//  Astrozee
//
//  Created by Carl  Ozee on 06/01/2026.
//

