import SwiftUI

// MARK: - Thème natal (visuel interactif)
struct NatalChartView: View {
    let positions: [PlanetPosition]
    let houseCusps: [HouseCusp]
    let angles: [ChartAngle]
    @Binding var selectedPlanet: PlanetPosition?
    private let zodiacOrientation: Double = -1.0
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let chartRadius = radius * 0.84
            let aspectRadius = chartRadius * 0.5
            let houseRingRadius = chartRadius * 0.88
            let outerRingRadius = chartRadius * 1.0
            let innerRingRadius = chartRadius * 0.66
            let planetBaseRadius = chartRadius * 1.12
            let planetGlyphSize = size * 0.09
            let planetBubbleMargin = size * 0.016
            let planetRadialStep = size * 0.065
            let degreeAnchorRadius = chartRadius * 0.995
            let signDividerInnerRadius = innerRingRadius
            let signDividerOuterRadius = houseRingRadius
            let signSymbolRadius = (signDividerInnerRadius + signDividerOuterRadius) * 0.5
            let houseLineInnerRadius = aspectRadius
            let houseLineOuterRadius = innerRingRadius
            let houseNumberRadius = (houseLineInnerRadius + houseLineOuterRadius) * 0.5
            
            ZStack {
                Circle()
                    .fill(Color(hex: SystemColorHex.white))
                
                Circle()
                    .stroke(Color(hex: SystemColorHex.black).opacity(0.9), lineWidth: 2.4)
                    .frame(width: outerRingRadius * 2, height: outerRingRadius * 2)
                
                Circle()
                    .stroke(Color(hex: SystemColorHex.black).opacity(0.65), lineWidth: 1.2)
                    .frame(width: houseRingRadius * 2, height: houseRingRadius * 2)

                Circle()
                    .stroke(Color(hex: SystemColorHex.black).opacity(0.85), lineWidth: 1.4)
                    .frame(width: innerRingRadius * 2, height: innerRingRadius * 2)

                Circle()
                    .stroke(Color(hex: SystemColorHex.black).opacity(0.85), lineWidth: 1.3)
                    .frame(width: aspectRadius * 2, height: aspectRadius * 2)

                ForEach(0..<360, id: \.self) { degree in
                    let isMajor = degree % 10 == 0
                    let isMedium = degree % 5 == 0
                    let lineLength = isMajor ? chartRadius * 0.12 : (isMedium ? chartRadius * 0.085 : chartRadius * 0.05)
                    let lineStart = point(on: orientedAngle(Double(degree)), radius: outerRingRadius - lineLength, center: center)
                    let lineEnd = point(on: orientedAngle(Double(degree)), radius: outerRingRadius, center: center)
                    
                    Path { path in
                        path.move(to: lineStart)
                        path.addLine(to: lineEnd)
                    }
                    .stroke(Color(hex: SystemColorHex.black).opacity(isMajor ? 0.9 : 0.65), lineWidth: isMajor ? 1.8 : (isMedium ? 1.3 : 0.9))
                }
                
                ForEach(0..<12, id: \.self) { index in
                    let angle = orientedAngle(Double(index) * 30.0)
                    let symbolAngle = orientedAngle(Double(index) * 30.0 + 15.0)

                    Path { path in
                        let lineStart = point(on: angle, radius: signDividerInnerRadius, center: center)
                        let lineEnd = point(on: angle, radius: signDividerOuterRadius, center: center)
                        path.move(to: lineStart)
                        path.addLine(to: lineEnd)
                    }
                    .stroke(Color(hex: SystemColorHex.black).opacity(0.7), lineWidth: 1.1)

                    Text(zodiacSymbols[index])
                        .font(.system(size: size * 0.07, weight: .semibold))
                        .foregroundStyle(Color(hex: SystemColorHex.indigo).opacity(0.85))
                        .position(point(on: symbolAngle, radius: signSymbolRadius, center: center))
                }

                ForEach(houseLines, id: \.index) { house in
                    let angle = orientedAngle(house.angle)
                    let lineStart = point(on: angle, radius: houseLineInnerRadius, center: center)
                    let lineEnd = point(on: angle, radius: houseLineOuterRadius, center: center)

                    Path { path in
                        path.move(to: lineStart)
                        path.addLine(to: lineEnd)
                    }
                    .stroke(Color(hex: SystemColorHex.black).opacity(0.7), lineWidth: 1.1)

                    Path { path in
                        let tickStart = point(on: angle, radius: houseRingRadius - 7, center: center)
                        let tickEnd = point(on: angle, radius: houseRingRadius + 7, center: center)
                        path.move(to: tickStart)
                        path.addLine(to: tickEnd)
                    }
                    .stroke(Color(hex: SystemColorHex.black).opacity(0.8), lineWidth: 1.2)

                    let labelPoint = point(on: orientedAngle(house.midAngle), radius: houseNumberRadius, center: center)
                    Text("\(house.index)")
                        .font(.system(size: size * 0.03, weight: .semibold))
                        .foregroundStyle(Color(hex: SystemColorHex.black).opacity(0.85))
                        .position(labelPoint)
                }

                ForEach(aspects) { aspect in
                    Path { path in
                        let adjustedRadius = aspectRadius + aspect.radialOffset
                        path.move(to: point(on: orientedAngle(aspect.startAngle), radius: adjustedRadius, center: center))
                        path.addLine(to: point(on: orientedAngle(aspect.endAngle), radius: adjustedRadius, center: center))
                    }
                    .stroke(aspect.color.opacity(0.5), lineWidth: 0.6)
                }

                ForEach(angles) { angle in
                    let label = angleSymbol(for: angle)
                    let point = point(on: orientedAngle(angle.longitude), radius: chartRadius * 0.98, center: center)
                    Text(label)
                        .font(.system(size: size * 0.045, weight: .bold))
                        .foregroundStyle(Color(hex: SystemColorHex.black))
                        .padding(6)
                        .background(Color(hex: SystemColorHex.white), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(hex: SystemColorHex.black), lineWidth: 1.4)
                        )
                        .position(point)
                }
                
                ForEach(layoutPlanets(
                    positions: positions,
                    baseRadius: planetBaseRadius,
                    center: center,
                    bubbleDiameter: planetGlyphSize,
                    bubbleMargin: planetBubbleMargin,
                    radialStep: planetRadialStep
                )) { layout in
                    let planet = layout.planet
                    let planetPoint = point(on: layout.angle, radius: layout.radius, center: center)
                    let degreePoint = point(on: layout.angle, radius: degreeAnchorRadius, center: center)
                    let isSelected = planet.id == selectedPlanet?.id

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedPlanet = planet
                        }
                    } label: {
                        Text(planetSymbol(for: planet.name))
                            .font(.system(size: planetGlyphSize, weight: .bold))
                            .foregroundStyle(planetColor(for: planet.name))
                            .shadow(color: Color(hex: SystemColorHex.black).opacity(isSelected ? 0.25 : 0.1), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .position(planetPoint)

                    Path { path in
                        path.move(to: planetPoint)
                        path.addLine(to: degreePoint)
                    }
                    .stroke(planetColor(for: planet.name).opacity(0.9), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))

                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(height: 460)
        .frame(maxWidth: .infinity)
        .drawingGroup()
    }
    
    private func point(on angleDegrees: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let radians = angleDegrees * .pi / 180
        let x = center.x + cos(radians) * radius
        let y = center.y + sin(radians) * radius
        return CGPoint(x: x, y: y)
    }

    private func orientedAngle(_ angle: Double) -> Double {
        (angle * zodiacOrientation) - 90.0
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
        case "soleil": return Color(hex: SystemColorHex.orange).opacity(0.9)
        case "lune": return Color(hex: SystemColorHex.gray).opacity(0.6)
        case "mercure": return Color(hex: SystemColorHex.mint).opacity(0.7)
        case "vénus", "venus": return Color(hex: SystemColorHex.pink).opacity(0.7)
        case "mars": return Color(hex: SystemColorHex.red).opacity(0.75)
        case "jupiter": return Color(hex: SystemColorHex.teal).opacity(0.7)
        case "saturne": return Color(hex: SystemColorHex.brown).opacity(0.7)
        case "uranus": return Color(hex: SystemColorHex.cyan).opacity(0.7)
        case "neptune": return Color(hex: SystemColorHex.blue).opacity(0.7)
        case "pluton": return Color(hex: SystemColorHex.purple).opacity(0.7)
        case "chiron": return Color(hex: SystemColorHex.indigo).opacity(0.6)
        case "cérès", "ceres": return Color(hex: SystemColorHex.green).opacity(0.65)
        case "pallas": return Color(hex: SystemColorHex.teal).opacity(0.6)
        case "junon", "juno": return Color(hex: SystemColorHex.pink).opacity(0.6)
        case "vesta": return Color(hex: SystemColorHex.orange).opacity(0.65)
        case "lilith": return Color(hex: SystemColorHex.black).opacity(0.7)
        default: return Color(hex: SystemColorHex.indigo).opacity(0.6)
        }
    }
    
    private func layoutPlanets(
        positions: [PlanetPosition],
        baseRadius: CGFloat,
        center: CGPoint,
        bubbleDiameter: CGFloat,
        bubbleMargin: CGFloat,
        radialStep: CGFloat
    ) -> [PlanetLayout] {
        let sorted = positions.sorted { $0.longitude < $1.longitude }
        let minSeparation = bubbleSeparationDegrees(
            radius: baseRadius,
            bubbleDiameter: bubbleDiameter,
            bubbleMargin: bubbleMargin
        )
        let grouped = clusterPlanets(sorted, minSeparation: minSeparation)
        var layouts: [PlanetLayout] = []
        layouts.reserveCapacity(positions.count)

        for cluster in grouped {
            for (index, planet) in cluster.enumerated() {
                let angle = orientedAngle(planet.longitude)
                let radius = baseRadius + radialStep * CGFloat(index)

                layouts.append(
                    PlanetLayout(
                        id: planet.id,
                        planet: planet,
                        angle: angle,
                        radius: radius
                    )
                )
            }
        }
        return layouts
    }

    private func bubbleSeparationDegrees(radius: CGFloat, bubbleDiameter: CGFloat, bubbleMargin: CGFloat) -> Double {
        let total = bubbleDiameter + bubbleMargin
        guard radius > 0 else { return 0 }
        let radians = Double(total / radius)
        return radians * 180 / .pi
    }

    private func clusterPlanets(_ planets: [PlanetPosition], minSeparation: Double) -> [[PlanetPosition]] {
        guard !planets.isEmpty else { return [] }
        var clusters: [[PlanetPosition]] = []
        var current: [PlanetPosition] = []
        var lastLongitude: Double?

        for planet in planets {
            if let lastLongitude, shortestAngleDistance(planet.longitude, lastLongitude) < minSeparation {
                current.append(planet)
            } else {
                if !current.isEmpty {
                    clusters.append(current)
                }
                current = [planet]
            }
            lastLongitude = planet.longitude
        }

        if !current.isEmpty {
            clusters.append(current)
        }

        if clusters.count > 1,
           let first = clusters.first,
           let last = clusters.last,
           let firstLongitude = first.first?.longitude,
           let lastLongitude = last.last?.longitude,
           shortestAngleDistance(firstLongitude, lastLongitude) < minSeparation {
            clusters[0] = last + first
            clusters.removeLast()
        }

        return clusters
    }
    
    
    private func shortestAngleDistance(_ a: Double, _ b: Double) -> Double {
        var value = (a - b).truncatingRemainder(dividingBy: 360)
        if value < -180 { value += 360 }
        if value > 180 { value -= 360 }
        return abs(value)
    }


    private var aspects: [NatalAspect] {
        let planets = positions
        var results: [NatalAspect] = []
        var index = 0
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
                                color: colorForAspect(aspect),
                                radialOffset: aspectOffset(for: aspect, index: index)
                            )
                        )
                        index += 1
                        break
                    }
                }
            }
        }
        return results
    }

    private func aspectOffset(for aspect: AspectType, index: Int) -> CGFloat {
        let base: CGFloat
        switch aspect {
        case .conjonction:
            base = 0
        case .sextile, .trigone:
            base = 4
        case .carre, .opposition:
            base = -4
        }
        let oscillation = (index % 3) - 1
        return base + CGFloat(oscillation) * 2
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
            return Color(hex: SystemColorHex.purple)
        case .sextile, .trigone:
            return Color(hex: SystemColorHex.blue)
        case .carre, .opposition:
            return Color(hex: SystemColorHex.red)
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
    let radialOffset: CGFloat
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
                        .background(Color(hex: SystemColorHex.indigo).opacity(0.12), in: Circle())
                    
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
                        .foregroundStyle(Color(hex: SystemColorHex.indigo))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: SystemColorHex.indigo).opacity(0.12), in: Capsule())
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(hex: SystemColorHex.white).opacity(0.8))
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
        case "uranus": return ""
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
                            .background(Color(hex: SystemColorHex.indigo).opacity(isSelected ? 0.22 : 0.1), in: Circle())
                        Text(planet.name)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isSelected ? Color(hex: SystemColorHex.indigo).opacity(0.12) : Color(hex: SystemColorHex.white).opacity(0.6))
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

struct NatalDualitySection: View {
    let result: DualityResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dualité")
                .font(.headline)

            DualityDonutView(masculine: result.masculine, feminine: result.feminine)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

struct DualityDonutView: View {
    let masculine: Double
    let feminine: Double

    private var normalizedMasculine: Double {
        let total = max(masculine + feminine, 1)
        return masculine / total
    }

    var body: some View {
        let masculinePercent = Int(round(normalizedMasculine * 100))
        let femininePercent = 100 - masculinePercent
        let masculineColor = Color(hex: 0x99EBFF)
        let feminineColor = Color(hex: 0xF199FF)

        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color(hex: SystemColorHex.black).opacity(0.08), lineWidth: 18)

                Circle()
                    .trim(from: 0, to: normalizedMasculine)
                    .stroke(masculineColor, style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: normalizedMasculine, to: 1)
                    .stroke(feminineColor, style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                    .rotationEffect(.degrees(-90))

                Text("Dualité")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 140, height: 140)

            HStack(spacing: 20) {
                DualityLabel(symbol: "♀", title: "Féminin", percent: femininePercent, color: feminineColor)
                DualityLabel(symbol: "♂", title: "Masculin", percent: masculinePercent, color: masculineColor)
            }
        }
    }
}

struct DualityLabel: View {
    let symbol: String
    let title: String
    let percent: Int
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(symbol)
                .font(.headline)
                .foregroundStyle(color)
                .padding(6)
                .background(color.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(percent)%")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
        }
    }
}

struct NatalAnglesSection: View {
    let angles: [ChartAngle]
    let points: [ChartPoint]

    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 12, alignment: .leading)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Angles & points")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(angles) { angle in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(angleLabel(for: angle))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(angle.sign) • \(angle.degreeInSign)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: SystemColorHex.white).opacity(0.7))
                    .cornerRadius(12)
                }

                ForEach(points) { point in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pointLabel(for: point))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(point.sign) • \(point.degreeInSign)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: SystemColorHex.white).opacity(0.7))
                    .cornerRadius(12)
                }
            }
        }
    }

    private func angleLabel(for angle: ChartAngle) -> String {
        switch angle.id {
        case "asc": return "ASC • \(angle.name)"
        case "dsc": return "DSC • \(angle.name)"
        case "mc": return "MC • \(angle.name)"
        case "ic": return "IC • \(angle.name)"
        default: return angle.name
        }
    }

    private func pointLabel(for point: ChartPoint) -> String {
        switch point.id {
        case "fortune": return "⊗ \(point.name)"
        default: return point.name
        }
    }
}

struct NatalHousesSection: View {
    let cusps: [HouseCusp]

    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 12, alignment: .leading)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Maisons")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(cusps) { cusp in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Maison \(cusp.id)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(cusp.sign) • \(cusp.degreeInSign)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: SystemColorHex.white).opacity(0.7))
                    .cornerRadius(12)
                }
            }
        }
    }
}

//  TransitProfileComponent.swift
//  Astrozee
//
//  Created by Carl  Ozee on 07/01/2026.
//
