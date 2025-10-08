import Foundation

final class TransitCalculator {
    
    // MARK: - Calcul principal
    /// Calcule tous les transits pour un profil sur un mois donné
    static func calculateTransits(
        for profile: Profile,
        month: Int,
        year: Int
    ) -> [Transit] {
        
        // 1. Récupère les positions natales
        let natalPositions = calculateNatalPositions(for: profile)
        
        // 2. Génère toutes les dates du mois
        let dates = generateDatesForMonth(month: month, year: year)
        
        // 3. Pour chaque jour, calcule les positions de transit et détecte les aspects
        var dailyAspects: [(date: Date, transitPlanet: String, aspect: AspectType, natalPlanet: String, orbe: Double)] = []
        
        for date in dates {
            let transitPositions = calculateTransitPositions(for: date)
            
            // Compare chaque planète de transit avec chaque planète natale
            for (transitName, transitLon) in transitPositions {
                for (natalName, natalLon) in natalPositions {
                    if let (aspect, orbe) = detectAspect(transit: transitLon, natal: natalLon) {
                        dailyAspects.append((date, transitName, aspect, natalName, orbe))
                    }
                }
            }
        }
        
        // 4. Groupe les aspects continus et crée les objets Transit
        let transits = groupContinuousAspects(dailyAspects, month: month, year: year)
        
        return transits
    }
    
    // MARK: - Positions natales
    private static func calculateNatalPositions(for profile: Profile) -> [String: Double] {
        let dateUT = profile.birthDateUTC()
        let positions = Ephemeris.shared.computePositionsUT(dateUT: dateUT)
        
        var result: [String: Double] = [:]
        for pos in positions {
            result[pos.name.lowercased()] = pos.longitude
        }
        return result
    }
    
    // MARK: - Positions de transit
    private static func calculateTransitPositions(for date: Date) -> [String: Double] {
        // Calcule à midi UTC pour cohérence
        let calendar = Calendar(identifier: .gregorian)
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        
        let positions = Ephemeris.shared.computePositionsUT(dateUT: noon)
        
        var result: [String: Double] = [:]
        for pos in positions {
            result[pos.name.lowercased()] = pos.longitude
        }
        return result
    }
    
    // MARK: - Détection d'aspect
    private static func detectAspect(transit: Double, natal: Double) -> (AspectType, Double)? {
        var delta = abs(transit - natal)
        
        // Normalise entre 0 et 180°
        if delta > 180 {
            delta = 360 - delta
        }
        
        // Teste chaque aspect
        for aspect in AspectType.allCases {
            let diff = abs(delta - aspect.angle)
            if diff <= aspect.orbe {
                return (aspect, diff)
            }
        }
        
        return nil
    }
    
    // MARK: - Génération des dates
    private static func generateDatesForMonth(month: Int, year: Int) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let startDate = calendar.date(from: components) else { return [] }
        
        let range = calendar.range(of: .day, in: .month, for: startDate)!
        
        var dates: [Date] = []
        for day in 1...range.count {
            components.day = day
            if let date = calendar.date(from: components) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    // MARK: - Groupement des aspects continus
    private static func groupContinuousAspects(
        _ dailyAspects: [(date: Date, transitPlanet: String, aspect: AspectType, natalPlanet: String, orbe: Double)],
        month: Int,
        year: Int
    ) -> [Transit] {
        
        // Groupe par clé unique (transit + aspect + natal)
        var grouped: [String: [(date: Date, orbe: Double)]] = [:]
        
        for item in dailyAspects {
            let key = "\(item.transitPlanet)|\(item.aspect.rawValue)|\(item.natalPlanet)"
            grouped[key, default: []].append((item.date, item.orbe))
        }
        
        var transits: [Transit] = []
        
        // Pour chaque groupe, trouve les périodes continues
        for (key, entries) in grouped {
            let parts = key.split(separator: "|").map(String.init)
            guard parts.count == 3 else { continue }
            
            let transitPlanet = parts[0]
            let aspectRaw = parts[1]
            let natalPlanet = parts[2]
            
            guard let aspect = AspectType(rawValue: aspectRaw) else { continue }
            
            // Trie par date
            let sorted = entries.sorted { $0.date < $1.date }
            
            // Détecte les groupes continus (max 1 jour d'écart)
            var currentStart = sorted[0].date
            var currentEnd = sorted[0].date
            var minOrbe = sorted[0].orbe
            var picDate = sorted[0].date
            
            for i in 1..<sorted.count {
                let daysDiff = Calendar.current.dateComponents([.day], from: currentEnd, to: sorted[i].date).day ?? 999
                
                if daysDiff <= 1 {
                    // Continue le groupe
                    currentEnd = sorted[i].date
                    if sorted[i].orbe < minOrbe {
                        minOrbe = sorted[i].orbe
                        picDate = sorted[i].date
                    }
                } else {
                    // Fin du groupe, enregistre si dans le mois
                    if isInMonth(start: currentStart, end: currentEnd, month: month, year: year) {
                        transits.append(Transit(
                            transitPlanet: transitPlanet,
                            aspect: aspect,
                            natalPlanet: natalPlanet,
                            startDate: currentStart,
                            endDate: currentEnd,
                            picDate: picDate,
                            orbe: minOrbe
                        ))
                    }
                    
                    // Nouveau groupe
                    currentStart = sorted[i].date
                    currentEnd = sorted[i].date
                    minOrbe = sorted[i].orbe
                    picDate = sorted[i].date
                }
            }
            
            // N'oublie pas le dernier groupe
            if isInMonth(start: currentStart, end: currentEnd, month: month, year: year) {
                transits.append(Transit(
                    transitPlanet: transitPlanet,
                    aspect: aspect,
                    natalPlanet: natalPlanet,
                    startDate: currentStart,
                    endDate: currentEnd,
                    picDate: picDate,
                    orbe: minOrbe
                ))
            }
        }
        
        return transits.sorted { $0.picDate < $1.picDate }
    }
    
    // MARK: - Vérifie si le transit touche le mois cible
    private static func isInMonth(start: Date, end: Date, month: Int, year: Int) -> Bool {
        let calendar = Calendar.current
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let monthStart = calendar.date(from: components) else { return false }
        
        let range = calendar.range(of: .day, in: .month, for: monthStart)!
        components.day = range.count
        guard let monthEnd = calendar.date(from: components) else { return false }
        
        // Le transit touche le mois si :
        // - il commence avant la fin du mois ET
        // - il finit après le début du mois
        return start <= monthEnd && end >= monthStart
    }
}
