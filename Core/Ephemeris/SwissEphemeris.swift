import Foundation

// MARK: - Status (diagnostic)
struct EphemerisStatus {
    enum Engine: String { case swisseph = "SWIEPH", moshier = "MOSEPH" }
    var engine: Engine
    var seVersion: String?
    var sePath: String?
    var lastError: String?

    var isUsingFiles: Bool { engine == .swisseph }
}

final class Ephemeris {
    static let shared = Ephemeris()
    private init() {}

    private(set) var status = EphemerisStatus(engine: .moshier, seVersion: nil, sePath: nil, lastError: nil)

    /// Initialise : si des .se1 sont trouvés dans Resources/se/, on utilise SWISSEPH,
    /// sinon on bascule automatiquement en MOSEPH (aucun fichier requis).
    func bootstrap() {
        // 1) Essaie de trouver le dossier "se" (folder reference) dans le bundle
        if let sePath = Bundle.main.path(forResource: "se", ofType: nil) {
            // Y a-t-il au moins un fichier .se1 ?
            let files = (try? FileManager.default.contentsOfDirectory(atPath: sePath)) ?? []
            if files.first(where: { $0.lowercased().hasSuffix(".se1") }) != nil {
                sePath.withCString { swe_set_ephe_path($0) }
                var ver = [Int8](repeating: 0, count: 48)
                swe_version(&ver)
                let version = String(cString: ver)
                status = EphemerisStatus(engine: .swisseph, seVersion: version, sePath: sePath, lastError: nil)
                return
            } else {
                status = EphemerisStatus(engine: .moshier, seVersion: nil, sePath: sePath, lastError: "Aucun .se1 trouvé — utilisation de MOSEPH.")
            }
        } else {
            status = EphemerisStatus(engine: .moshier, seVersion: nil, sePath: nil, lastError: "Dossier se/ introuvable — utilisation de MOSEPH.")
        }

        // Si on arrive ici → fallback : MOSEPH (pas besoin de set_ephe_path)
        var ver = [Int8](repeating: 0, count: 48)
        swe_version(&ver)
        status.seVersion = String(cString: ver)
    }

    func computePositionsUT(dateUT: Date) -> [PlanetPosition] {
        return SwissEphemerisProvider.shared.computePositionsUT(
            dateUT: dateUT,
            useMoshier: status.engine == .moshier,
            errorOut: &status.lastError
        )
    }
}

// MARK: - Calculateur
final class SwissEphemerisProvider {
    static let shared = SwissEphemerisProvider()
    private init() {}

    func computePositionsUT(dateUT: Date, useMoshier: Bool, errorOut: inout String?) -> [PlanetPosition] {
        var results: [PlanetPosition] = []

        // Décomposition de la date en UTC
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(secondsFromGMT: 0)!
        let comps = utcCal.dateComponents([.year,.month,.day,.hour,.minute,.second], from: dateUT)
        guard let y = comps.year, let m = comps.month, let d = comps.day else { return results }
        let hour = Double(comps.hour ?? 0) + Double(comps.minute ?? 0)/60.0 + Double(comps.second ?? 0)/3600.0

        // Jour julien UT
        let tjd_ut = swe_julday(Int32(y), Int32(m), Int32(d), hour, SE_GREG_CAL)

        // Flags : SWIEPH (avec fichiers) sinon MOSEPH (sans fichiers) + vitesses
        let baseFlag: Int32 = useMoshier ? SEFLG_MOSEPH : SEFLG_SWIEPH
        let iflag: Int32 = baseFlag | SEFLG_SPEED

        var xx = [Double](repeating: 0, count: 6)
        var serr = [Int8](repeating: 0, count: 256)

        for item in DEFAULT_PLANETS {
            xx = [Double](repeating: 0, count: 6)
            serr = [Int8](repeating: 0, count: 256)
            let rc = swe_calc_ut(tjd_ut, item.id, iflag, &xx, &serr)
            if rc < 0 {
                errorOut = String(cString: serr)
                continue
            }
            let lon = xx[0]  // longitude écliptique géocentrique (tropicale)
            let speed = xx[3]
            results.append(
                PlanetPosition(id: Int(item.id),
                               name: item.name,
                               longitude: lon,
                               speed: speed,
                               sign: zodiacName(for: lon))
            )
        }
        return results
    }
}
