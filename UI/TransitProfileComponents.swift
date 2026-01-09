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
            let planetBaseRadius = chartRadius * 1.14
            let planetBubbleSize = size * 0.11
            let planetBubbleMargin = size * 0.016
            let planetRadialStep = size * 0.08
            let degreeAnchorRadius = chartRadius * 0.99
            
            ZStack {
                Circle()
                    .fill(Color(hex: SystemColorHex.white))
                
                Circle()
                    .stroke(Color(hex: SystemColorHex.indigo).opacity(0.25), lineWidth: 2)
                    .frame(width: chartRadius * 2, height: chartRadius * 2)
                
                Circle()
                    .stroke(Color(hex: SystemColorHex.indigo).opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                    .frame(width: chartRadius * 2, height: chartRadius * 2)
                    .padding(chartRadius * 0.18)

                Circle()
                    .stroke(Color(hex: SystemColorHex.indigo).opacity(0.2), lineWidth: 1)
                    .frame(width: houseRingRadius * 2, height: houseRingRadius * 2)
                
                ForEach(0..<360, id: \.self) { degree in
                    let isMajor = degree % 10 == 0
                    let isMedium = degree % 5 == 0
                    let lineLength = isMajor ? chartRadius * 0.12 : (isMedium ? chartRadius * 0.08 : chartRadius * 0.05)
                    let lineStart = point(on: Double(degree) - 90.0, radius: chartRadius - lineLength, center: center)
                    let lineEnd = point(on: Double(degree) - 90.0, radius: chartRadius, center: center)
                    
                    Path { path in
                        path.move(to: lineStart)
                        path.addLine(to: lineEnd)
                    }
                    .stroke(Color(hex: SystemColorHex.indigo).opacity(isMajor ? 0.55 : 0.3), lineWidth: isMajor ? 1.6 : (isMedium ? 1.1 : 0.9))
                }
                
                ForEach(0..<12, id: \.self) { index in
                    let angle = Double(index) * 30.0 - 90.0
                    let lineStart = point(on: angle, radius: chartRadius * 0.38, center: center)
                    let lineEnd = point(on: angle, radius: chartRadius * 0.98, center: center)
                    
                    Path { path in
                        path.move(to: lineStart)
                        path.addLine(to: lineEnd)
                    }
                    .stroke(Color(hex: SystemColorHex.indigo).opacity(0.12), lineWidth: 1)
                    
                    Text(zodiacSymbols[index])
                        .font(.system(size: size * 0.065, weight: .semibold))
                        .foregroundStyle(Color(hex: SystemColorHex.indigo).opacity(0.85))
                        .position(point(on: angle, radius: chartRadius * 0.78, center: center))
                }

                ForEach(houseLines, id: \.index) { house in
                    let angle = house.angle - 90.0
                    let lineStart = point(on: angle, radius: chartRadius * 0.32, center: center)
                    let lineEnd = point(on: angle, radius: chartRadius * 0.98, center: center)

                    Path { path in
                        path.move(to: lineStart)
                        path.addLine(to: lineEnd)
                    }
                    .stroke(Color(hex: SystemColorHex.purple).opacity(0.25), lineWidth: 1.2)

                    Path { path in
                        let tickStart = point(on: angle, radius: houseRingRadius - 6, center: center)
                        let tickEnd = point(on: angle, radius: houseRingRadius + 6, center: center)
                        path.move(to: tickStart)
                        path.addLine(to: tickEnd)
                    }
                    .stroke(Color(hex: SystemColorHex.black).opacity(0.6), lineWidth: 1.2)

                    let labelPoint = point(on: house.midAngle - 90.0, radius: chartRadius * 0.46, center: center)
                    Text("\(house.index)")
                        .font(.system(size: size * 0.032, weight: .semibold))
                        .foregroundStyle(Color(hex: SystemColorHex.black).opacity(0.75))
                        .position(labelPoint)
                }

                ForEach(aspects) { aspect in
                    Path { path in
                        let adjustedRadius = aspectRadius + aspect.radialOffset
                        path.move(to: point(on: aspect.startAngle - 90.0, radius: adjustedRadius, center: center))
                        path.addLine(to: point(on: aspect.endAngle - 90.0, radius: adjustedRadius, center: center))
                    }
                    .stroke(aspect.color.opacity(0.5), lineWidth: 0.6)
                }

                ForEach(angles) { angle in
                    let label = angleSymbol(for: angle)
                    let point = point(on: angle.longitude - 90.0, radius: chartRadius * 0.92, center: center)
                    Text(label)
                        .font(.system(size: size * 0.035, weight: .semibold))
                        .foregroundStyle(Color(hex: SystemColorHex.purple).opacity(0.8))
                        .padding(4)
                        .background(Color(hex: SystemColorHex.white).opacity(0.9), in: Capsule())
                        .position(point)
                }
                
                ForEach(layoutPlanets(
                    positions: positions,
                    baseRadius: planetBaseRadius,
                    center: center,
                    bubbleDiameter: planetBubbleSize,
                    bubbleMargin: planetBubbleMargin,
                    radialStep: planetRadialStep
                )) { layout in
                    let planet = layout.planet
                    let planetPoint = point(on: layout.angle, radius: layout.radius, center: center)
                    let degreePoint = point(on: layout.angle, radius: degreeAnchorRadius, center: center)
                    let isSelected = planet.id == selectedPlanet?.id
                    let finalLabelPoint = layout.labelPoint

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedPlanet = planet
                        }
                    } label: {
                        Text(planetSymbol(for: planet.name))
                            .font(.system(size: size * 0.068, weight: .bold))
                            .foregroundStyle(isSelected ? Color(hex: SystemColorHex.white) : Color(hex: SystemColorHex.indigo).opacity(0.9))
                            .frame(width: size * 0.095, height: size * 0.095)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color(hex: SystemColorHex.indigo) : planetColor(for: planet.name))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: SystemColorHex.white).opacity(0.75), lineWidth: isSelected ? 2 : 0.8)
                            )
                            .shadow(color: Color(hex: SystemColorHex.indigo).opacity(isSelected ? 0.35 : 0.15), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .position(planetPoint)

                    Path { path in
                        path.move(to: planetPoint)
                        path.addLine(to: degreePoint)
                    }
                    .stroke(Color(hex: SystemColorHex.black).opacity(0.45), style: StrokeStyle(lineWidth: 0.7, lineCap: .round, lineJoin: .round))

                    Text(planet.degreeInSign)
                        .font(.system(size: size * 0.032, weight: .semibold))
                        .foregroundStyle(Color(hex: SystemColorHex.black).opacity(0.75))
                        .position(finalLabelPoint)
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
                let angle = planet.longitude - 90.0
                let radius = baseRadius + radialStep * CGFloat(index)
                let labelOffsetRadius = radius + bubbleDiameter * (0.8 + CGFloat(index) * 0.35)
                let labelPoint = point(on: angle, radius: labelOffsetRadius, center: center)
                let angleRadians = angle * .pi / 180
                let isRight = cos(angleRadians) >= 0
                let side: LabelSide = isRight ? .right : .left

                layouts.append(
                    PlanetLayout(
                        id: planet.id,
                        planet: planet,
                        angle: angle,
                        radius: radius,
                        labelPoint: labelPoint,
                        labelSide: side
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
    let labelPoint: CGPoint
    let labelSide: LabelSide
}

private struct NatalAspect: Identifiable {
    let id: String
    let startAngle: Double
    let endAngle: Double
    let color: Color
    let radialOffset: CGFloat
}

private enum LabelSide {
    case left
    case right
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
