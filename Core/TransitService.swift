import Foundation

class TransitService {
    
    // Structure interne pour stocker "un jour de transit" avant de regrouper
    private struct DailyHit {
        let date: Date
        let orb: Double
    }
    
    /// Calcule tous les transits pour un MOIS et une ANNÉE donnés
    /// Reproduit la logique de ton script Python (scan jour par jour + regroupement)
    static func computeTransitsForMonth(profile: Profile, month: Int, year: Int) -> [Transit] {
        
        // 1. Définir la plage de dates (Du 1er au dernier jour du mois)
        let calendar = Calendar.current
        var components = DateComponents(year: year, month: month, day: 1)
        
        // Sécurité si la date est invalide
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        let daysCount = range.count
        guard let endOfMonth = calendar.date(byAdding: .day, value: daysCount - 1, to: startOfMonth) else {
            return []
        }
        
        // On élargit la fenêtre de calcul pour capturer les pics proches du mois cible
        let bufferMonths = 3
        guard let scanStart = calendar.date(byAdding: .month, value: -bufferMonths, to: startOfMonth),
              let scanEnd = calendar.date(byAdding: .month, value: bufferMonths, to: endOfMonth) else {
            return []
        }
        let scanDays = (calendar.dateComponents([.day], from: scanStart, to: scanEnd).day ?? 0) + 1
        
        // 2. Calculer les positions NATALES (fixes)
        let natalPlanets = Ephemeris.shared.computePositionsUT(dateUT: profile.birthDateUTC())
        
        // Dictionnaire pour regrouper : Clé = "Mars|conjonction|Vénus", Valeur = Liste des jours
        var rawData: [String: [DailyHit]] = [:]
        
        // 3. BOUCLE JOUR PAR JOUR (Le Scan)
        for dayOffset in 0..<scanDays {
            guard let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: scanStart) else { continue }
            
            // Calculer positions du jour (Transit)
            let transitPlanets = Ephemeris.shared.computePositionsUT(dateUT: currentDate)
            
            for tPlanet in transitPlanets {
                for nPlanet in natalPlanets {
                    // Calcul mathématique de la distance (nécessite Aspects.swift)
                    let dist = AspectCalculator.shortestDistance(tPlanet.longitude, nPlanet.longitude)
                    
                    for type in AspectType.allCases {
                        let delta = abs(dist - type.angle)
                        
                        // Vérifie si on est dans l'orbe défini dans ton AspectType
                        if delta <= type.orbe {
                            // C'est un "hit" ! On le stocke pour le regrouper plus tard
                            // Clé unique pour identifier ce transit spécifique
                            let key = "\(tPlanet.name)|\(type.rawValue)|\(nPlanet.name)"
                            let hit = DailyHit(date: currentDate, orb: delta)
                            
                            if rawData[key] == nil { rawData[key] = [] }
                            rawData[key]?.append(hit)
                        }
                    }
                }
            }
        }
        
        // 4. REGROUPEMENT (Fusionner les jours consécutifs en un seul Transit)
        var finalTransits: [Transit] = []
        
        for (key, hits) in rawData {
            let parts = key.split(separator: "|")
            if parts.count < 3 { continue }
            
            let tName = String(parts[0])
            let aspectRaw = String(parts[1])
            let nName = String(parts[2])
            
            // On retrouve le bon AspectType via son rawValue ("conjonction", etc.)
            guard let aspect = AspectType(rawValue: aspectRaw), !hits.isEmpty else { continue }
            
            // Trier les jours par date pour suivre la chronologie
            let sortedHits = hits.sorted { $0.date < $1.date }
            
            var currentGroup: [DailyHit] = []
            
            for hit in sortedHits {
                if currentGroup.isEmpty {
                    currentGroup.append(hit)
                } else {
                    let lastDate = currentGroup.last!.date
                    // Si c'est le jour suivant (ou le même jour), on continue le groupe
                    if let diff = calendar.dateComponents([.day], from: lastDate, to: hit.date).day, diff <= 1 {
                        currentGroup.append(hit)
                    } else {
                        // Rupture ! (Trou dans les dates) -> On sauvegarde le groupe précédent
                        if let t = createTransitFromHits(group: currentGroup, tName: tName, nName: nName, aspect: aspect) {
                            finalTransits.append(t)
                        }
                        // On commence un nouveau groupe
                        currentGroup = [hit]
                    }
                }
            }
            // Ne pas oublier d'enregistrer le dernier groupe en cours
            if let t = createTransitFromHits(group: currentGroup, tName: tName, nName: nName, aspect: aspect) {
                finalTransits.append(t)
            }
        }
        
        // 5. Résultat final trié par date de pic
        let monthTransits = finalTransits.filter { transit in
            transit.startDate <= endOfMonth && transit.endDate >= startOfMonth
        }
        
        return monthTransits.sorted { $0.picDate < $1.picDate }
    }
    
    // Helper pour transformer une liste de jours en un objet Transit complet
    private static func createTransitFromHits(group: [DailyHit], tName: String, nName: String, aspect: AspectType) -> Transit? {
        guard let first = group.first, let last = group.last else { return nil }
        
        // Trouver le pic : le jour où l'orbe était le plus petit
        let bestHit = group.min(by: { $0.orb < $1.orb }) ?? first
        
        return Transit(
            transitPlanet: tName,
            aspect: aspect,
            natalPlanet: nName,
            startDate: first.date,
            endDate: last.date,
            picDate: bestHit.date,
            orbe: bestHit.orb // Ici ça matche parfaitement ton struct Transit
        )
    }
}
