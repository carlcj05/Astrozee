import Foundation

let SE_SUN: Int32       = 0
let SE_MOON: Int32      = 1
let SE_MERCURY: Int32   = 2
let SE_VENUS: Int32     = 3
let SE_MARS: Int32      = 4
let SE_JUPITER: Int32   = 5
let SE_SATURN: Int32    = 6
let SE_URANUS: Int32    = 7
let SE_NEPTUNE: Int32   = 8
let SE_PLUTO: Int32     = 9
let SE_MEAN_NODE: Int32 = 10
let SE_TRUE_NODE: Int32 = 11
let SE_MEAN_APOG: Int32 = 12
let SE_CHIRON: Int32    = 15
let SE_CERES: Int32     = 17
let SE_PALLAS: Int32    = 18
let SE_JUNO: Int32      = 19
let SE_VESTA: Int32     = 20

let SEFLG_SWIEPH: Int32 = 2
let SEFLG_SPEED: Int32  = 256
let SE_GREG_CAL: Int32  = 1
let SEFLG_MOSEPH: Int32 = 4   // fallback sans fichiers .se1

let DEFAULT_PLANETS: [(id: Int32, name: String)] = [
    (SE_SUN, "Soleil"),
    (SE_MOON, "Lune"),
    (SE_MERCURY, "Mercure"),
    (SE_VENUS, "Vénus"),
    (SE_MARS, "Mars"),
    (SE_JUPITER, "Jupiter"),
    (SE_SATURN, "Saturne"),
    (SE_URANUS, "Uranus"),
    (SE_NEPTUNE, "Neptune"),
    (SE_PLUTO, "Pluton"),
    (SE_TRUE_NODE, "Nœud Nord (vrai)"),
    (SE_CHIRON, "Chiron"),
    (SE_CERES, "Cérès"),
    (SE_PALLAS, "Pallas"),
    (SE_JUNO, "Junon"),
    (SE_VESTA, "Vesta"),
    (SE_MEAN_APOG, "Lilith")
]

let ZODIAC_SIGNS = [
    "Bélier","Taureau","Gémeaux","Cancer","Lion","Vierge",
    "Balance","Scorpion","Sagittaire","Capricorne","Verseau","Poissons"
]

func zodiacName(for eclipticLongitude: Double) -> String {
    var lon = eclipticLongitude.truncatingRemainder(dividingBy: 360.0)
    if lon < 0 { lon += 360.0 }
    let index = Int(floor(lon / 30.0))
    return ZODIAC_SIGNS[max(0, min(11, index))]
}

// --- SEConstants.swift --- (Ajoute ça à la fin)

// Codes pour les systèmes de maisons (House Systems)
let SE_HSYS_PLACIDUS: Int32 = 80  // Code ASCII pour 'P'
let SE_HSYS_KOCH: Int32     = 75  // Code ASCII pour 'K'
let SE_HSYS_WHOLE: Int32    = 87  // Code ASCII pour 'W' (Signes entiers)
