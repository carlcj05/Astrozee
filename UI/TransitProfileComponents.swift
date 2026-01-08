import SwiftUI

// MARK: - Thème natal (visuel interactif)
struct NatalChartView: View {
    let positions: [PlanetPosition]
    let houseCusps: [HouseCusp]
    let angles: [ChartAngle]
    @Binding var selectedPlanet: PlanetPosition?
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let chartRadius = radius * 0.84
            let aspectRadius = chartRadius * 0.46
            let houseRingRadius = chartRadius * 0.9
            let planetBaseRadius = chartRadius * 0.98
            let leaderStartRadius = chartRadius * 0.78
            
            ZStack {
                Circle()
                    .fill(Color.white)
                
                Circle()
                    .stroke(Color.indigo.opacity(0.25), lineWidth: 2)
                    .frame(width: chartRadius * 2, height: chartRadius * 2)
                
                Circle()
                    .stroke(Color.indigo.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                    .frame(width: chartRadius * 2, height: chartRadius * 2)
                    .padding(chartRadius * 0.18)

                Circle()
                    .stroke(Color.indigo.opacity(0.2), lineWidth: 1)
                    .frame(width: houseRingRadius * 2, height: houseRingRadius * 2)
                
                ForEach(Array(0..<360), id: \.self) { (degree: Int) in
                    let isHouseMarker = degree % 30 == 0
                    let isMajor = degree % 10 == 0
                    let isMinor = degree % 5 == 0
                    let lineLength: CGFloat
                    let lineWidth: CGFloat
                    let lineOpacity: Double
                    
                    if isHouseMarker {
                        lineLength = chartRadius * 0.18
                        lineWidth = 2.0
                        lineOpacity = 0.9
                    } else if isMajor {
                        lineLength = chartRadius * 0.12
                        lineWidth = 1.4
                        lineOpacity = 0.7
                    } else if isMinor {
                        lineLength = chartRadius * 0.08
                        lineWidth = 1.0
                        lineOpacity = 0.55
                    } else {
                        lineLength = chartRadius * 0.04
                        lineWidth = 0.6
                        lineOpacity = 0.35
                    }
                    
                    let lineStart = point(on: Double(degree) - 90.0, radius: chartRadius - lineLength, center: center)
                    let lineEnd = point(on: Double(degree) - 90.0, radius: chartRadius, center: center)
                    
                    Path { path in
                        path.move(to: lineStart)
                        path.addLine(to: lineEnd)
                    }
                    .stroke(Color.black.opacity(lineOpacity), lineWidth: lineWidth)
                }
                
                ForEach(Array(0..<12), id: \.self) { (index: Int) in
                    let angle = Double(index) * 30.0 - 90.0
                    let lineStart = point(on: angle, radius: chartRadius * 0.38, center: center)
                    let lineEnd = point(on: angle, radius: chartRadius * 0.98, center: center)
                    
                    Path { path in
                        path.move(to: lineStart)
                        path.addLine(to: lineEnd)
                    }
                    .stroke(Color.indigo.opacity(0.12), lineWidth: 1)
                    
                    Text(zodiacSymbols[index])
                        .font(.system(size: size * 0.065, weight: .semibold))
                        .foregroundStyle(Color.indigo.opacity(0.85))
                        .position(point(on: angle, radius: chartRadius * 0.78, center: center))
                }

                ForEach(houseLines) { house in
                    let angle = house.angle - 90.0
                    let lineStart = point(on: angle, radius: chartRadius * 0.32, center: center)
                    let lineEnd = point(on: angle, radius: chartRadius * 0.98, center: center)

                    Path { path in
                        path.move(to: lineStart)
                        path.addLine(to: lineEnd)
                    }
                    .stroke(Color.purple.opacity(0.25), lineWidth: 1.2)

                    Path { path in
                        let tickStart = point(on: angle, radius: houseRingRadius - 6, center: center)
                        let tickEnd = point(on: angle, radius: houseRingRadius + 6, center: center)
                        path.move(to: tickStart)
                        path.addLine(to: tickEnd)
                    }
                    .stroke(Color.black.opacity(0.6), lineWidth: 1.2)

                    let labelPoint = point(on: house.midAngle - 90.0, radius: chartRadius * 0.46, center: center)
                    Text("\(house.index)")
                        .font(.system(size: size * 0.032, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.75))
                        .position(labelPoint)
                }

                ForEach(aspects) { aspect in
                    Path { path in
                        path.move(to: point(on: aspect.startAngle - 90.0, radius: aspectRadius, center: center))
                        path.addLine(to: point(on: aspect.endAngle - 90.0, radius: aspectRadius, center: center))
                    }
                    .stroke(aspect.color.opacity(0.6), lineWidth: 1)
                }

                ForEach(angles) { angle in
                    let label = angleSymbol(for: angle)
                    let point = point(on: angle.longitude - 90.0, radius: chartRadius * 0.92, center: center)
                    Text(label)
                        .font(.system(size: size * 0.035, weight: .semibold))
                        .foregroundStyle(Color.purple.opacity(0.8))
                        .padding(4)
                        .background(Color.white.opacity(0.9), in: Capsule())
                        .position(point)
                }
                
                ForEach(layoutPlanets(positions: positions, baseRadius: planetBaseRadius)) { layout in
                    let planet = layout.planet
                    let planetPoint = point(on: layout.angle, radius: layout.radius, center: center)
                    let isSelected = planet.id == selectedPlanet?.id

                    Path { path in
                        let basePoint = point(on: layout.angle, radius: leaderStartRadius, center: center)
                        path.move(to: basePoint)
                        path.addLine(to: planetPoint)
                    }
                    .stroke(Color.black.opacity(0.6), lineWidth: 1)
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedPlanet = planet
                        }
                    } label: {
                        Text(planetSymbol(for: planet.name))
                            .font(.system(size: size * 0.068, weight: .bold))
                            .foregroundStyle(isSelected ? Color.white : Color.indigo.opacity(0.9))
                            .frame(width: size * 0.095, height: size * 0.095)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.indigo : planetColor(for: planet.name))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.75), lineWidth: isSelected ? 2 : 0.8)
                            )
                            .shadow(color: Color.indigo.opacity(isSelected ? 0.35 : 0.15), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .position(planetPoint)

                    Text(planet.degreeInSign)
                        .font(.system(size: size * 0.03, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.7))
                        .position(point(on: layout.angle, radius: layout.radius + 24, center: center))
                }
                
                VStack(spacing: 4) {
                    Text("Carte astrale")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Touchez une planète")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .position(center)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(height: 360)
        .frame(maxWidth: .infinity)
    }
    
    private func point(on angleDegrees: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let radians = angleDegrees * .pi / 180
        let x = center.x + cos(radians) * radius
        let y = center.y + sin(radians) * radius
        return CGPoint(x: x, y: y)
    }
    
    private func planetSymbol(for name: String) -> String {
        switch name.lowercased() {
        case "soleil": return "☉"
        case "lune": return "☾"
        case "mercure": return "☿"
        case "vénus", "venus": return "♀"
        case "mars": return "♂"
        case "jupiter": return "♃"
        case "saturne": return "♄"
        case "uranus": return "♅"
        case "neptune": return "♆"
        case "pluton": return "♇"
        case "nœud nord (vrai)", "noeud nord (vrai)": return "☊"
        case "chiron": return "⚷"
        case "cérès", "ceres": return "⚳"
        case "pallas": return "⚴"
        case "junon", "juno": return "⚵"
        case "vesta": return "⚶"
        case "lilith": return "⚸"
        default: return "✦"
        }
    }
    
    private func planetColor(for name: String) -> Color {
        switch name.lowercased() {
        case "soleil": return Color.orange.opacity(0.9)
        case "lune": return Color.gray.opacity(0.6)
        case "mercure": return Color.mint.opacity(0.7)
        case "vénus", "venus": return Color.pink.opacity(0.7)
        case "mars": return Color.red.opacity(0.75)
        case "jupiter": return Color.teal.opacity(0.7)
        case "saturne": return Color.brown.opacity(0.7)
        case "uranus": return Color.cyan.opacity(0.7)
        case "neptune": return Color.blue.opacity(0.7)
        case "pluton": return Color.purple.opacity(0.7)
        case "chiron": return Color.indigo.opacity(0.6)
        case "cérès", "ceres": return Color.green.opacity(0.65)
        case "pallas": return Color.teal.opacity(0.6)
        case "junon", "juno": return Color.pink.opacity(0.6)
        case "vesta": return Color.orange.opacity(0.65)
        case "lilith": return Color.black.opacity(0.7)
        default: return Color.indigo.opacity(0.6)
        }
    }
    
    private func layoutPlanets(positions: [PlanetPosition], baseRadius: CGFloat) -> [PlanetLayout] {
        let sorted = positions.sorted { $0.longitude < $1.longitude }
        var layouts: [PlanetLayout] = []
        var lastAngle: Double?
        var stackIndex = 0
        
        for planet in sorted {
            let angle = planet.longitude - 90.0
            if let lastAngle, abs(normalize(angle - lastAngle)) < 6 {
                stackIndex += 1
            } else {
                stackIndex = 0
            }
            
            let radialOffset = CGFloat(stackIndex) * 20.0
            let radius = baseRadius + radialOffset
            layouts.append(
                PlanetLayout(
                    id: planet.id,
                    planet: planet,
                    angle: angle,
                    radius: radius
                )
            )
            lastAngle = angle
        }
        
        return layouts
    }
    
    private func normalize(_ delta: Double) -> Double {
        var value = delta.truncatingRemainder(dividingBy: 360)
        if value < -180 { value += 360 }
        if value > 180 { value -= 360 }
        return abs(value)
    }

    private var aspects: [NatalAspect] {
        let planets = positions
        var results: [NatalAspect] = []
        for i in 0..<planets.count {
            for j in (i + 1)..<planets.count {
                let first = planets[i]
                let second = planets[j]
                let distance = AspectCalculator.shortestDistance(first.longitude, second.longitude)
                for aspect in AspectType.allCases {
                    if abs(distance - aspect.angle) <= aspect.orbe {
                        results.append(
                            NatalAspect(
                                id: "\(first.id)-\(second.id)-\(aspect.rawValue)",
                                startAngle: first.longitude,
                                endAngle: second.longitude,
                                color: colorForAspect(aspect)
                            )
                        )
                        break
                    }
                }
            }
        }
        return results
    }

    private var houseLines: [HouseLine] {
        let cusps = houseCusps.sorted { $0.id < $1.id }
        guard cusps.count == 12 else {
            return (1...12).map { index in
                let angle = Double(index - 1) * 30.0
                let midAngle = angle + 15.0
                return HouseLine(index: index, angle: angle, midAngle: midAngle)
            }
        }

        return cusps.enumerated().map { (offset, cusp) in
            let next = cusps[(offset + 1) % cusps.count]
            let start = normalizeAngle(cusp.longitude)
            let end = normalizeAngle(next.longitude)
            let mid = midpointAngle(start: start, end: end)
            return HouseLine(index: offset + 1, angle: start, midAngle: mid)
        }
    }

    private func midpointAngle(start: Double, end: Double) -> Double {
        let normalizedStart = normalizeAngle(start)
        let normalizedEnd = normalizeAngle(end)
        let delta = normalizedEnd >= normalizedStart ? normalizedEnd - normalizedStart : (normalizedEnd + 360 - normalizedStart)
        return normalizeAngle(normalizedStart + delta / 2)
    }

    private func normalizeAngle(_ angle: Double) -> Double {
        let value = angle.truncatingRemainder(dividingBy: 360)
        return value < 0 ? value + 360 : value
    }

    private func angleSymbol(for angle: ChartAngle) -> String {
        switch angle.id {
        case "asc": return "ASC"
        case "dsc": return "DSC"
        case "mc": return "MC"
        case "ic": return "IC"
        default: return angle.name
        }
    }
    
    private var zodiacSymbols: [String] {
        ["♈︎", "♉︎", "♊︎", "♋︎", "♌︎", "♍︎", "♎︎", "♏︎", "♐︎", "♑︎", "♒︎", "♓︎"]
    }

    private func colorForAspect(_ aspect: AspectType) -> Color {
        switch aspect {
        case .conjonction:
            return .purple
        case .sextile, .trigone:
            return .blue
        case .carre, .opposition:
            return .red
        }
    }
}

private struct PlanetLayout: Identifiable {
    let id: Int
    let planet: PlanetPosition
    let angle: Double
    let radius: CGFloat
}

private struct NatalAspect: Identifiable {
    let id: String
    let startAngle: Double
    let endAngle: Double
    let color: Color
}

private struct HouseLine: Identifiable {
    let id = UUID()
    let index: Int
    let angle: Double
    let midAngle: Double
}

struct NatalPlanetDetailCard: View {
    let planet: PlanetPosition?
    
    var body: some View {
        Group {
            if let planet {
                HStack(spacing: 12) {
                    Text(planetSymbol(for: planet.name))
                        .font(.system(size: 28))
                        .frame(width: 44, height: 44)
                        .background(Color.indigo.opacity(0.12), in: Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(planet.name)
                            .font(.headline)
                        Text("\(planet.sign) • \(planet.degreeInSign)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Voir")
                        .font(.caption)
                        .foregroundStyle(.indigo)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.indigo.opacity(0.12), in: Capsule())
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.8))
                .cornerRadius(14)
            } else {
                Text("Touchez une planète pour découvrir son influence.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func planetSymbol(for name: String) -> String {
        switch name.lowercased() {
        case "soleil": return "☉"
        case "lune": return "☾"
        case "mercure": return "☿"
        case "vénus", "venus": return "♀"
        case "mars": return "♂"
        case "jupiter": return "♃"
        case "saturne": return "♄"
        case "uranus": return "♅"
        case "neptune": return "♆"
        case "pluton": return "♇"
        case "nœud nord (vrai)", "noeud nord (vrai)": return "☊"
        case "chiron": return "⚷"
        case "cérès", "ceres": return "⚳"
        case "pallas": return "⚴"
        case "junon", "juno": return "⚵"
        case "vesta": return "⚶"
        case "lilith": return "⚸"
        default: return "✦"
        }
    }
}

struct NatalPlanetLegend: View {
    let positions: [PlanetPosition]
    @Binding var selectedPlanet: PlanetPosition?
    
    private let columns = [
        GridItem(.adaptive(minimum: 90), spacing: 12, alignment: .leading)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(positions) { planet in
                let isSelected = planet.id == selectedPlanet?.id
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedPlanet = planet
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(planetSymbol(for: planet.name))
                            .font(.system(size: 16))
                            .frame(width: 24, height: 24)
                            .background(Color.indigo.opacity(isSelected ? 0.22 : 0.1), in: Circle())
                        Text(planet.name)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isSelected ? Color.indigo.opacity(0.12) : Color.white.opacity(0.6))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func planetSymbol(for name: String) -> String {
        switch name.lowercased() {
        case "soleil": return "☉"
        case "lune": return "☾"
        case "mercure": return "☿"
        case "vénus", "venus": return "♀"
        case "mars": return "♂"
        case "jupiter": return "♃"
        case "saturne": return "♄"
        case "uranus": return "♅"
        case "neptune": return "♆"
        case "pluton": return "♇"
        case "nœud nord (vrai)", "noeud nord (vrai)": return "☊"
        case "chiron": return "⚷"
        case "cérès", "ceres": return "⚳"
        case "pallas": return "⚴"
        case "junon", "juno": return "⚵"
        case "vesta": return "⚶"
        case "lilith": return "⚸"
        default: return "✦"
        }
    }
}

struct DualityResult {
    let masculine: Double
    let feminine: Double

    var masculinePercent: Int { Int(round(masculine * 100)) }
    var femininePercent: Int { Int(round(feminine * 100)) }
}

struct NatalDualitySection: View {
    let result: DualityResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Polarités")
                .font(.headline)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Masculin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(result.masculinePercent)%")
                        .font(.title3.bold())
                    ProgressView(value: result.masculine)
                        .tint(.orange)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Féminin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(result.femininePercent)%")
                        .font(.title3.bold())
                    ProgressView(value: result.feminine)
                        .tint(.purple)
                }
            }
        }
    }
}

struct NatalAnglesSection: View {
    let angles: [ChartAngle]
    let points: [ChartPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Angles clés")
                .font(.headline)

            ForEach(angles) { angle in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(angle.name)
                            .font(.subheadline.weight(.semibold))
                        Text("\(angle.sign) • \(angle.degreeInSign)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
                Divider()
            }

            ForEach(points) { point in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(point.name)
                            .font(.subheadline.weight(.semibold))
                        Text("\(point.sign) • \(point.degreeInSign)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
                Divider()
            }
        }
    }
}

struct NatalHousesSection: View {
    let cusps: [HouseCusp]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Maisons")
                .font(.headline)

            ForEach(cusps) { cusp in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Maison \(cusp.id)")
                            .font(.subheadline.weight(.semibold))
                        Text("\(cusp.sign) • \(cusp.degreeInSign)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
                Divider()
            }
        }
    }
}
