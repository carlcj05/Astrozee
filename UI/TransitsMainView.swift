import SwiftUI
import UniformTypeIdentifiers

// MARK: - 1. LE VIEWMODEL (Le cerveau qui partage les données)
class TransitViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var transits: [Transit] = []
    @Published var isCalculating = false
    @Published var calculationDone = false // Pour savoir si on affiche les résultats
    
    func calculate(for profile: Profile) {
        isCalculating = true
        calculationDone = false
        
        // Petit délai pour l'effet UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let calendar = Calendar.current
            let month = calendar.component(.month, from: self.selectedDate)
            let year = calendar.component(.year, from: self.selectedDate)
            
            let results = TransitService.computeTransitsForMonth(profile: profile, month: month, year: year)
            
            withAnimation {
                self.transits = results
                self.isCalculating = false
                self.calculationDone = true
            }
        }
    }
}

// MARK: - 2. LA VUE PRINCIPALE (Le conteneur avec les onglets)
struct TransitsMainView: View {
    let profile: Profile
    @StateObject private var viewModel = TransitViewModel()
    @State private var activeTab = 0 // 0 = Profil, 1 = Période, 2 = Résultats
    
    var body: some View {
        TabView(selection: $activeTab) {
            
            // --- ONGLET 1 : PROFIL ---
            TransitProfileView(profile: profile)
                .tabItem {
                    Label("Profil", systemImage: "person.crop.circle")
                }
                .tag(0)
            
            // --- ONGLET 2 : SÉLECTION ---
            TransitDateSelectionView(profile: profile, viewModel: viewModel, activeTab: $activeTab)
                .tabItem {
                    Label("Période", systemImage: "calendar")
                }
                .tag(1)
            
            // --- ONGLET 3 : RÉSULTATS ---
            TransitResultsView(viewModel: viewModel)
                .tabItem {
                    Label("Résultats", systemImage: "list.star")
                }
                .tag(2)
        }
        .navigationTitle("Météo Astrale")
        // FIX MAC: On applique .inline uniquement sur iOS
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - 3. ONGLET PROFIL
struct TransitProfileView: View {
    let profile: Profile
    @State private var natalPositions: [PlanetPosition] = []
    @State private var selectedPlanet: PlanetPosition?
    @State private var houseCusps: [HouseCusp] = []
    @State private var chartAngles: [ChartAngle] = []
    @State private var chartPoints: [ChartPoint] = []
    @State private var displayHouseCusps: [HouseCusp] = []
    @State private var displayChartAngles: [ChartAngle] = []
    @State private var displayChartPoints: [ChartPoint] = []

    var body: some View {
        ZStack {
            #if os(iOS)
            Color.gray.opacity(0.1).ignoresSafeArea() // Fond gris clair sur iOS
            #endif
            
            VStack(spacing: 30) {
                
                // Carte d'info Profil
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.indigo)
                        .padding(.bottom, 5)
                    
                    Text("Analyse pour \(profile.name)")
                        .font(.title2).bold()
                    
                    Text("Né(e) le \(profile.birthLocalDate.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                // FIX MAC: Fond blanc sur iOS, transparent ou adapté sur Mac
                .background(Color.white.opacity(0.8))
                .cornerRadius(15)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Thème natal")
                            .font(.headline)
                        Spacer()
                        if let place = profile.placeName, !place.isEmpty {
                            Text(place)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if natalPositions.isEmpty {
                        ContentUnavailableView(
                            "Calcul en cours",
                            systemImage: "sparkles",
                            description: Text("Nous préparons le visuel astral de \(profile.name).")
                        )
                    } else {
                        NatalChartView(
                            positions: natalPositions,
                            houseCusps: houseCusps,
                            angles: chartAngles,
                            selectedPlanet: $selectedPlanet
                        )
                        
                        NatalPlanetDetailCard(planet: selectedPlanet)
                        
                        NatalPlanetLegend(positions: natalPositions, selectedPlanet: $selectedPlanet)

                        NatalAnglesSection(angles: displayChartAngles, points: displayChartPoints)

                        NatalHousesSection(cusps: displayHouseCusps)

                        if profile.latitude == nil || profile.longitude == nil {
                            Text("Ajoute une ville pour obtenir les maisons, l'Ascendant et le Milieu du Ciel.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                
                Spacer()
            }
            .padding(.top)
        }
        .task {
            let positions = Ephemeris.shared.computePositionsUT(dateUT: profile.birthDateUTC())
            var cusps: [HouseCusp] = []
            var angles: [ChartAngle] = []
            var points: [ChartPoint] = []

                if let latitude = profile.latitude, let longitude = profile.longitude,
                   let houses = Ephemeris.shared.computeHousesUT(
                    dateUT: profile.birthDateUTC(),
                    latitude: latitude,
                    longitude: longitude,
                    houseSystem: SE_HSYS_PLACIDUS
                   ) {
                    cusps = houses.cusps
                    angles = makeAngles(from: houses)
                    points = makePoints(from: positions, ascendant: houses.ascendant)
                }

            withAnimation(.easeInOut(duration: 0.4)) {
                natalPositions = positions
                selectedPlanet = positions.first
                houseCusps = cusps
                chartAngles = angles
                chartPoints = points
                displayHouseCusps = cusps.isEmpty ? placeholderCusps() : cusps
                displayChartAngles = angles.isEmpty ? placeholderAngles() : angles
                displayChartPoints = points.isEmpty ? placeholderPoints() : points
            }
        }
    }

    private func makeAngles(from result: HouseSystemResult) -> [ChartAngle] {
        let ascendant = normalizeAngle(result.ascendant)
        let midheaven = normalizeAngle(result.midheaven)
        let descendant = normalizeAngle(ascendant + 180)
        let imumCoeli = normalizeAngle(midheaven + 180)

        return [
            ChartAngle(
                id: "asc",
                name: "Ascendant",
                longitude: ascendant,
                sign: zodiacName(for: ascendant),
                degreeInSign: formatDegreeInSign(ascendant)
            ),
            ChartAngle(
                id: "dsc",
                name: "Descendant",
                longitude: descendant,
                sign: zodiacName(for: descendant),
                degreeInSign: formatDegreeInSign(descendant)
            ),
            ChartAngle(
                id: "mc",
                name: "Milieu du Ciel",
                longitude: midheaven,
                sign: zodiacName(for: midheaven),
                degreeInSign: formatDegreeInSign(midheaven)
            ),
            ChartAngle(
                id: "ic",
                name: "Fond du Ciel",
                longitude: imumCoeli,
                sign: zodiacName(for: imumCoeli),
                degreeInSign: formatDegreeInSign(imumCoeli)
            )
        ]
    }

    private func makePoints(from positions: [PlanetPosition], ascendant: Double) -> [ChartPoint] {
        guard let sun = positions.first(where: { $0.name.lowercased() == "soleil" })?.longitude,
              let moon = positions.first(where: { $0.name.lowercased() == "lune" })?.longitude else {
            return []
        }

        let fortune = normalizeAngle(ascendant + moon - sun)

        return [
            ChartPoint(
                id: "fortune",
                name: "Part de Fortune",
                longitude: fortune,
                sign: zodiacName(for: fortune),
                degreeInSign: formatDegreeInSign(fortune)
            )
        ]
    }

    private func placeholderCusps() -> [HouseCusp] {
        (1...12).map { index in
            HouseCusp(id: index, longitude: 0, sign: "—", degreeInSign: "--")
        }
    }

    private func placeholderAngles() -> [ChartAngle] {
        [
            ChartAngle(id: "asc", name: "Ascendant", longitude: 0, sign: "—", degreeInSign: "--"),
            ChartAngle(id: "dsc", name: "Descendant", longitude: 0, sign: "—", degreeInSign: "--"),
            ChartAngle(id: "mc", name: "Milieu du Ciel", longitude: 0, sign: "—", degreeInSign: "--"),
            ChartAngle(id: "ic", name: "Fond du Ciel", longitude: 0, sign: "—", degreeInSign: "--")
        ]
    }

    private func placeholderPoints() -> [ChartPoint] {
        [
            ChartPoint(id: "fortune", name: "Part de Fortune", longitude: 0, sign: "—", degreeInSign: "--")
        ]
    }
}

// MARK: - Thème natal (visuel interactif)
private struct NatalChartView: View {
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
        .frame(maxWidth: 360)
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

private struct NatalPlanetDetailCard: View {
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

private struct NatalPlanetLegend: View {
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

private struct NatalAnglesSection: View {
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

private struct NatalHousesSection: View {
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

// MARK: - 4. ONGLET SÉLECTION (Mois + Calcul)
struct TransitDateSelectionView: View {
    let profile: Profile
    @ObservedObject var viewModel: TransitViewModel
    @Binding var activeTab: Int
    
    var body: some View {
        ZStack {
            #if os(iOS)
            Color.gray.opacity(0.1).ignoresSafeArea()
            #endif
            
            VStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Période d'analyse")
                        .font(.headline)
                    
                    DatePicker("Choisir le mois", selection: $viewModel.selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale(identifier: "fr_FR"))
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    viewModel.calculate(for: profile)
                    withAnimation {
                        activeTab = 2
                    }
                }) {
                    HStack {
                        if viewModel.isCalculating {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                            Text("Lancer le Calcul")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top)
        }
    }
}

// MARK: - 5. ONGLET RÉSULTATS (La liste)
struct TransitResultsView: View {
    @ObservedObject var viewModel: TransitViewModel
    @State private var isExportingCSV = false
    
    var body: some View {
        VStack {
            if viewModel.isCalculating {
                ProgressView("Calcul des positions planétaires...")
                    .scaleEffect(1.5)
                    .padding()
            } else if !viewModel.calculationDone {
                // État initial avant calcul
                ContentUnavailableView(
                    "En attente",
                    systemImage: "arrow.left.circle",
                    description: Text("Allez dans l'onglet 'Période' pour lancer une analyse.")
                )
            } else if viewModel.transits.isEmpty {
                // Calcul fait mais rien trouvé
                ContentUnavailableView(
                    "Aucun transit majeur",
                    systemImage: "moon.stars",
                    description: Text("Le ciel est calme pour cette période.")
                )
            } else {
                // Affichage des résultats
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        Button {
                            isExportingCSV = true
                        } label: {
                            Label("Exporter CSV", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal)
                    
                    List {
                        Section(header: Text("Analyse de \(monthTitle)")) {
                            ForEach(viewModel.transits) { transit in
                                TransitRow(transit: transit) // Utilise ta ligne existante
                            }
                        }
                    }
                }
                // FIX MAC: Utiliser un style compatible Mac et iOS
                #if os(macOS)
                .listStyle(.inset)
                #else
                .listStyle(.insetGrouped)
                #endif
                .fileExporter(
                    isPresented: $isExportingCSV,
                    document: TransitCSVDocument(csv: csvContent),
                    contentType: .commaSeparatedText,
                    defaultFilename: "transits-\(fileNameMonth)"
                ) { _ in }
            }
        }
    }
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.selectedDate).capitalized
    }

    private var fileNameMonth: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM-yyyy"
        return formatter.string(from: viewModel.selectedDate).lowercased()
    }
    
    private var csvContent: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "yyyy-MM-dd"
        
        let header = [
            "Planete transit",
            "Aspect",
            "Planete natale",
            "Debut",
            "Fin",
            "Pic",
            "Orbe",
            "Influence",
            "Meteo",
            "Signification"
        ].joined(separator: ",")
        
        let rows = viewModel.transits.map { transit in
            let interpretation = InterpretationService.shared.getInterpretation(for: transit)
            let signification = formatInterpretation(interpretation)
            let row = [
                csvField(transit.transitPlanet),
                csvField(transit.aspect.displayName),
                csvField(transit.natalPlanet),
                csvField(formatter.string(from: transit.startDate)),
                csvField(formatter.string(from: transit.endDate)),
                csvField(formatter.string(from: transit.picDate)),
                csvField(String(format: "%.2f", transit.orbe)),
                csvField(influence(for: transit)),
                csvField(transit.meteo),
                csvField(signification)
            ]
            return row.joined(separator: ",")
        }
        
        return ([header] + rows).joined(separator: "\n")
    }
    
    private func csvField(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
    
    private func formatInterpretation(_ interpretation: TransitInterpretation?) -> String {
        guard let interpretation else { return "" }
        let sections: [String] = [
            interpretation.essence.map { "Essence: \($0)" },
            interpretation.ceQuiPeutArriver.map { "Ce qui peut arriver: \($0)" },
            interpretation.relations.map { "Relations: \($0)" },
            interpretation.travail.map { "Travail: \($0)" },
            interpretation.aEviter.map { "A éviter: \($0)" },
            interpretation.aFaire.map { "A faire: \($0)" },
            interpretation.motsCles.map { "Mots-cles: \($0)" },
            !interpretation.conseils.isEmpty ? "Conseils: \(interpretation.conseils)" : nil
        ].compactMap { $0 }
        
        if sections.isEmpty {
            return interpretation.influence
        }
        
        return sections.joined(separator: "\n")
    }
    
    private func influence(for transit: Transit) -> String {
        let calendar = Calendar.current
        let picMonth = calendar.component(.month, from: transit.picDate)
        let referenceMonth = calendar.component(.month, from: viewModel.selectedDate)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM"
        let referenceMonthName = formatter.string(from: viewModel.selectedDate).capitalized
        
        if picMonth == referenceMonth {
            return "pic en \(referenceMonthName) 🔥"
        }
        
        if abs(picMonth - referenceMonth) == 1 {
            return "pic 1 mois avant/après 🔭"
        }
        
        return "pic plus d'un mois après \(referenceMonthName) 📡"
    }
}

struct TransitCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var csv: String
    
    init(csv: String) {
        self.csv = csv
    }
    
    init(configuration: ReadConfiguration) throws {
        csv = ""
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(csv.utf8))
    }
}

