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
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.indigo.opacity(0.12),
                                Color.purple.opacity(0.06),
                                Color.white
                            ]),
                            center: .center,
                            startRadius: 12,
                            endRadius: radius
                        )
                    )
                
                Circle()
                    .stroke(Color.indigo.opacity(0.25), lineWidth: 2)
                    .frame(width: chartRadius * 2, height: chartRadius * 2)
                
                Circle()
                    .stroke(Color.indigo.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                    .frame(width: chartRadius * 2, height: chartRadius * 2)
                    .padding(chartRadius * 0.18)
                
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
                    .stroke(Color.indigo.opacity(isMajor ? 0.5 : 0.25), lineWidth: isMajor ? 1.2 : 0.8)
                }
                
                ForEach(0..<12, id: \.self) { index in
                    let angle = Double(index) * 30.0 - 90.0
                    let lineStart = point(on: angle, radius: chartRadius * 0.38, center: center)
                    let lineEnd = point(on: angle, radius: chartRadius * 0.98, center: center)
                    
                    Path { path in
                        path.move(to: lineStart)
                        path.addLine(to: lineEnd)
                    }
                    .stroke(Color.indigo.opacity(0.12), lineWidth: 1)
                    
                    Text(zodiacSymbols[index])
                        .font(.system(size: size * 0.06, weight: .semibold))
                        .foregroundStyle(Color.indigo.opacity(0.7))
                        .position(point(on: angle, radius: chartRadius * 0.78, center: center))
                }

                ForEach(houseCusps) { cusp in
                    let angle = cusp.longitude - 90.0
                    let lineStart = point(on: angle, radius: chartRadius * 0.28, center: center)
                    let lineEnd = point(on: angle, radius: chartRadius * 0.98, center: center)

                    Path { path in
                        path.move(to: lineStart)
                        path.addLine(to: lineEnd)
                    }
                    .stroke(Color.purple.opacity(0.18), lineWidth: 1)
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
                
                ForEach(layoutPlanets(positions: positions, baseRadius: chartRadius * 0.64)) { layout in
                    let planet = layout.planet
                    let planetPoint = point(on: layout.angle, radius: layout.radius, center: center)
                    let isSelected = planet.id == selectedPlanet?.id
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedPlanet = planet
                        }
                    } label: {
                        Text(planetSymbol(for: planet.name))
                            .font(.system(size: size * 0.065, weight: .bold))
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
            if let lastAngle, abs(normalize(angle - lastAngle)) < 8 {
                stackIndex += 1
            } else {
                stackIndex = 0
            }
            
            let radialOffset = CGFloat(stackIndex) * 14.0
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
}

private struct PlanetLayout: Identifiable {
    let id: Int
    let planet: PlanetPosition
    let angle: Double
    let radius: CGFloat
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

        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.08), lineWidth: 18)

                Circle()
                    .trim(from: 0, to: normalizedMasculine)
                    .stroke(Color.black.opacity(0.85), style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: normalizedMasculine, to: 1)
                    .stroke(Color.gray.opacity(0.35), style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                    .rotationEffect(.degrees(-90))

                Text("Dualité")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 140, height: 140)

            HStack(spacing: 20) {
                DualityLabel(symbol: "♂", title: "Masculin", percent: masculinePercent, color: Color.black.opacity(0.85))
                DualityLabel(symbol: "♀", title: "Féminin", percent: femininePercent, color: Color.gray.opacity(0.7))
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
                    .background(Color.white.opacity(0.7))
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
                    .background(Color.white.opacity(0.7))
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
                    .background(Color.white.opacity(0.7))
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

