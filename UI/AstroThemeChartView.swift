import SwiftUI

// MARK: - Modèles de données (Mock pour l'exemple)
// J'ai créé ces structures pour rendre le code autonome, adapte-les à tes propres modèles.

enum ElementType { case fire, earth, air, water }

struct ChartData {
    // Exemple basé sur ton screenshot (AC en Bélier)
    static let ascendantDegree: Double = 15.7 // 15° Aries

    static let planets: [VisualPlanet] = [
        VisualPlanet(name: "Soleil", degree: 27.5, sign: .cancer, isRetro: false),
        VisualPlanet(name: "Lune", degree: 8.6, sign: .scorpio, isRetro: false),
        VisualPlanet(name: "Mercure", degree: 7.0, sign: .cancer, isRetro: false),
        VisualPlanet(name: "Vénus", degree: 18.6, sign: .gemini, isRetro: false),
        VisualPlanet(name: "Mars", degree: 0.7, sign: .scorpio, isRetro: false),
        VisualPlanet(name: "Jupiter", degree: 18.8, sign: .sagittarius, isRetro: true),
        VisualPlanet(name: "Saturne", degree: 2.2, sign: .taurus, isRetro: true),
        VisualPlanet(name: "Uranus", degree: 19.5, sign: .aquarius, isRetro: true),
        VisualPlanet(name: "Neptune", degree: 5.7, sign: .aquarius, isRetro: true),
        VisualPlanet(name: "Pluton", degree: 11.2, sign: .sagittarius, isRetro: true)
    ]

    // Cusps approximatives basées sur l'image
    static let houses: [Double] = [
        15.7, 45.0, 75.0, 105.0, 135.0, 165.0, // 1-6
        195.7, 225.0, 255.0, 285.0, 315.0, 345.0 // 7-12
    ]
}

struct VisualPlanet: Identifiable {
    let id = UUID()
    let name: String
    let degree: Double // Degré dans le signe (0-30)
    let sign: ZodiacSign
    let isRetro: Bool

    // Calcul de la longitude absolue (0-360)
    var absoluteLongitude: Double {
        Double(sign.index) * 30.0 + degree
    }
}

enum ZodiacSign: String, CaseIterable {
    case aries = "Bélier", taurus = "Taureau", gemini = "Gémeaux", cancer = "Cancer"
    case leo = "Lion", virgo = "Vierge", libra = "Balance", scorpio = "Scorpion"
    case sagittarius = "Sagittaire", capricorn = "Capricorne", aquarius = "Verseau", pisces = "Poissons"

    var index: Int {
        switch self {
        case .aries: return 0
        case .taurus: return 1
        case .gemini: return 2
        case .cancer: return 3
        case .leo: return 4
        case .virgo: return 5
        case .libra: return 6
        case .scorpio: return 7
        case .sagittarius: return 8
        case .capricorn: return 9
        case .aquarius: return 10
        case .pisces: return 11
        }
    }

    var symbol: String {
        switch self {
        case .aries: return "♈︎"
        case .taurus: return "♉︎"
        case .gemini: return "♊︎"
        case .cancer: return "♋︎"
        case .leo: return "♌︎"
        case .virgo: return "♍︎"
        case .libra: return "♎︎"
        case .scorpio: return "♏︎"
        case .sagittarius: return "♐︎"
        case .capricorn: return "♑︎"
        case .aquarius: return "♒︎"
        case .pisces: return "♓︎"
        }
    }

    var element: ElementType {
        switch self {
        case .aries, .leo, .sagittarius: return .fire
        case .taurus, .virgo, .capricorn: return .earth
        case .gemini, .libra, .aquarius: return .air
        case .cancer, .scorpio, .pisces: return .water
        }
    }
}

// MARK: - Couleurs Astrotheme Style
extension Color {
    static let astroFire = Color(red: 230/255, green: 50/255, blue: 40/255)
    static let astroEarth = Color(red: 140/255, green: 110/255, blue: 40/255)
    static let astroAir = Color(red: 0/255, green: 150/255, blue: 160/255)
    static let astroWater = Color(red: 50/255, green: 80/255, blue: 200/255)
    static let astroBackground = Color.white
    static let astroLines = Color.black
}

// MARK: - VUE PRINCIPALE
struct AstroThemeChartView: View {
    // Paramètres
    let planets: [VisualPlanet] = ChartData.planets
    let houseCusps: [Double] = ChartData.houses // Longitudes absolues des cusps
    let ascendant: Double = ChartData.ascendantDegree // L'Ascendant (définit la rotation)

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

            // Rayons des différents cercles (ajustés pour matcher le screenshot)
            let outerRadius = size / 2
            let zodiacSymbolRadius = outerRadius * 0.90
            let tickRingRadius = outerRadius * 0.82
            let planetRingRadius = outerRadius * 0.68
            let houseNumberRadius = outerRadius * 0.35
            let innerAspectRadius = outerRadius * 0.60

            // Rotation pour placer l'Ascendant à 9h.
            let chartRotation = 180.0 - ascendant

            ZStack {
                // 1. Fond blanc propre
                Circle().fill(Color.white)

                // 2. Cercle extérieur fin
                Circle()
                    .stroke(Color.black, lineWidth: 1)

                // 3. Les Signes du Zodiaque (Symboles colorés)
                ForEach(ZodiacSign.allCases, id: \.self) { sign in
                    let startDegree = Double(sign.index) * 30.0
                    let midDegree = startDegree + 15.0

                    Text(sign.symbol)
                        .font(.system(size: size * 0.08, weight: .bold))
                        .foregroundColor(color(for: sign.element))
                        .position(position(for: midDegree + chartRotation, radius: zodiacSymbolRadius, center: center))

                    Path { path in
                        let p1 = position(for: startDegree + chartRotation, radius: tickRingRadius, center: center)
                        let p2 = position(for: startDegree + chartRotation, radius: outerRadius, center: center)
                        path.move(to: p1)
                        path.addLine(to: p2)
                    }
                    .stroke(Color.black, lineWidth: 1)
                }

                // 4. L'anneau des ticks
                TickRing(rotation: chartRotation, radius: tickRingRadius)
                    .stroke(Color.black, lineWidth: 1)

                // 5. Lignes des Maisons
                ForEach(0..<houseCusps.count, id: \.self) { i in
                    let angle = houseCusps[i] + chartRotation
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: position(for: angle, radius: tickRingRadius, center: center))
                    }
                    .stroke(Color.black, lineWidth: 0.8)

                    let nextCusp = i == 11 ? houseCusps[0] : houseCusps[i + 1]
                    let midHouse = midPoint(angle1: houseCusps[i], angle2: nextCusp) + chartRotation

                    Text("\(i + 1)")
                        .font(.system(size: size * 0.025))
                        .position(position(for: midHouse, radius: houseNumberRadius, center: center))
                }

                // 6. Les Planètes
                ForEach(planets) { planet in
                    let angle = planet.absoluteLongitude + chartRotation
                    let pos = position(for: angle, radius: planetRingRadius, center: center)

                    Path { path in
                        path.move(to: pos)
                        path.addLine(to: position(for: angle, radius: tickRingRadius, center: center))
                    }
                    .stroke(planetColor(planet.name).opacity(0.5), lineWidth: 0.5)

                    PlanetTagView(planet: planet, size: size)
                        .position(pos)
                }

                // 7. Aspects
                AspectLinesView(planets: planets, rotation: chartRotation, radius: innerAspectRadius, center: center)

                // 8. Flèches AC / MC
                let ascAngle = 180.0
                ChartArrow(angle: ascAngle, label: "AC", radius: tickRingRadius + (size * 0.02), size: size)
                    .position(center)

                if houseCusps.count > 9 {
                    let mcAngle = houseCusps[9] + chartRotation
                    ChartArrow(angle: mcAngle, label: "MC", radius: tickRingRadius + (size * 0.02), size: size)
                        .position(center)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(20)
    }

    // MARK: - Helpers
    private func position(for angle: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: center.x + radius * CGFloat(cos(radians)),
            y: center.y + radius * CGFloat(sin(radians))
        )
    }

    private func color(for element: ElementType) -> Color {
        switch element {
        case .fire: return .astroFire
        case .earth: return .astroEarth
        case .air: return .astroAir
        case .water: return .astroWater
        }
    }

    private func planetColor(_ name: String) -> Color {
        switch name {
        case "Soleil", "Mars": return .astroFire
        case "Lune": return Color(white: 0.3)
        case "Vénus", "Saturne": return .astroEarth
        case "Mercure": return .purple
        case "Jupiter", "Neptune": return .astroAir
        case "Uranus": return .astroFire
        case "Pluton": return .black
        default: return .black
        }
    }

    private func midPoint(angle1: Double, angle2: Double) -> Double {
        let diff = angle2 - angle1
        if diff < -180 { return angle1 + (diff + 360) / 2 }
        if diff > 180 { return angle1 + (diff - 360) / 2 }
        return angle1 + diff / 2
    }
}

// MARK: - Sous-Vues Spécifiques
struct TickRing: Shape {
    let rotation: Double
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)

        for i in 0..<360 {
            let angle = Double(i) + rotation
            let rad = angle * .pi / 180

            let length: CGFloat
            if i % 10 == 0 { length = 10 }
            else if i % 5 == 0 { length = 7 }
            else { length = 4 }

            let start = CGPoint(
                x: center.x + (radius - length) * cos(rad),
                y: center.y + (radius - length) * sin(rad)
            )
            let end = CGPoint(
                x: center.x + radius * cos(rad),
                y: center.y + radius * sin(rad)
            )

            path.move(to: start)
            path.addLine(to: end)
        }
        return path
    }
}

struct PlanetTagView: View {
    let planet: VisualPlanet
    let size: CGFloat

    var body: some View {
        let glyphSize = size * 0.055
        let textSize = size * 0.025

        VStack(spacing: 0) {
            Text("\(Int(planet.degree))°")
                .font(.system(size: textSize, design: .serif))
                .offset(x: -4, y: 4)

            HStack(spacing: 2) {
                Text(planetSymbol(planet.name))
                    .font(.system(size: glyphSize))
                    .foregroundColor(planetColor(planet.name))

                if planet.isRetro {
                    Text("R")
                        .font(.system(size: textSize * 0.8))
                        .foregroundColor(.red)
                        .offset(y: 4)
                }
            }

            let minutes = Int((planet.degree - Double(Int(planet.degree))) * 60)
            Text("\(minutes)'")
                .font(.system(size: textSize, design: .serif))
                .foregroundColor(.gray)
                .offset(x: 4, y: -4)
        }
    }

    private func planetSymbol(_ name: String) -> String {
        switch name {
        case "Soleil": return "☉"
        case "Lune": return "☽"
        case "Mercure": return "☿"
        case "Vénus": return "♀"
        case "Mars": return "♂"
        case "Jupiter": return "♃"
        case "Saturne": return "♄"
        case "Uranus": return "♅"
        case "Neptune": return "♆"
        case "Pluton": return "♇"
        default: return "?"
        }
    }

    private func planetColor(_ name: String) -> Color {
        switch name {
        case "Soleil", "Mars": return .astroFire
        case "Lune": return .gray
        case "Vénus", "Saturne": return .astroEarth
        case "Mercure": return .purple
        case "Jupiter", "Neptune": return .astroAir
        case "Uranus": return .astroFire
        case "Pluton": return .black
        default: return .black
        }
    }
}

struct ChartArrow: View {
    let angle: Double
    let label: String
    let radius: CGFloat
    let size: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radians = angle * .pi / 180
            let tip = CGPoint(
                x: center.x + radius * CGFloat(cos(radians)),
                y: center.y + radius * CGFloat(sin(radians))
            )

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: -8, y: -6))
                    path.addLine(to: CGPoint(x: -8, y: 6))
                    path.closeSubpath()
                }
                .fill(Color.black)
                .rotationEffect(Angle(degrees: angle))
                .position(tip)

                let textRadius = radius + 25
                let textPos = CGPoint(
                    x: center.x + textRadius * CGFloat(cos(radians)),
                    y: center.y + textRadius * CGFloat(sin(radians))
                )

                Text(label)
                    .font(.system(size: size * 0.05, weight: .bold, design: .serif))
                    .position(textPos)
            }
        }
    }
}

struct AspectLinesView: View {
    let planets: [VisualPlanet]
    let rotation: Double
    let radius: CGFloat
    let center: CGPoint

    var body: some View {
        Path { path in
            for i in 0..<planets.count {
                for j in (i + 1)..<planets.count {
                    let p1 = planets[i]
                    let p2 = planets[j]

                    let diff = abs(p1.absoluteLongitude - p2.absoluteLongitude)
                    let angle = min(diff, 360 - diff)

                    if isAspect(angle) {
                        let pos1 = position(for: p1.absoluteLongitude + rotation, radius: radius, center: center)
                        let pos2 = position(for: p2.absoluteLongitude + rotation, radius: radius, center: center)
                        path.move(to: pos1)
                        path.addLine(to: pos2)
                    }
                }
            }
        }
        .stroke(Color.blue.opacity(0.4), lineWidth: 0.8)
    }

    private func isAspect(_ angle: Double) -> Bool {
        let orbe: Double = 8
        let aspects = [60.0, 90.0, 120.0, 180.0]
        for asp in aspects {
            if abs(angle - asp) < orbe { return true }
        }
        return false
    }

    private func position(for angle: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: center.x + radius * CGFloat(cos(radians)),
            y: center.y + radius * CGFloat(sin(radians))
        )
    }
}

// MARK: - Preview
struct AstroChart_Preview: PreviewProvider {
    static var previews: some View {
        AstroThemeChartView()
            .frame(width: 400, height: 400)
            .background(Color.white)
    }
}
//  Astrothemechartview.swift
//  Astrozee
//
//  Created by Carl  Ozee on 09/01/2026.
//

