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
    @State private var dualityResult = DualityResult(masculine: 0.5, feminine: 0.5)

    var body: some View {
        ZStack {
            #if os(iOS)
            Color.gray.opacity(0.1).ignoresSafeArea() // Fond gris clair sur iOS
            #endif
            
            ScrollView {
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

                            NatalDualitySection(result: dualityResult)

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
                }
                .padding(.top)
                .padding(.bottom, 24)
            }
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
                dualityResult = computeDualityResult(positions: positions, cusps: cusps, angles: angles)
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

    private func computeDualityResult(positions: [PlanetPosition], cusps: [HouseCusp], angles: [ChartAngle]) -> DualityResult {
        guard !positions.isEmpty else { return DualityResult(masculine: 0.5, feminine: 0.5) }

        var masculineScore = 0.0
        var feminineScore = 0.0

        let planetWeights: [String: Double] = [
            "soleil": 3,
            "lune": 3,
            "mercure": 2,
            "vénus": 2,
            "venus": 2,
            "mars": 2,
            "jupiter": 1,
            "saturne": 1,
            "uranus": 1,
            "neptune": 1,
            "pluton": 1
        ]

        func addPolarity(for sign: String, weight: Double) {
            guard sign != "—" else { return }
            if isMasculineSign(sign) {
                masculineScore += weight
            } else {
                feminineScore += weight
            }
        }

        for position in positions {
            let key = position.name.lowercased()
            if let weight = planetWeights[key] {
                addPolarity(for: position.sign, weight: weight)
            }
        }

        if let ascendant = angles.first(where: { $0.id == "asc" }) {
            addPolarity(for: ascendant.sign, weight: 3)
        }

        
        let total = max(masculineScore + feminineScore, 1)
        let masculine = masculineScore / total
        let feminine = feminineScore / total
        return DualityResult(masculine: masculine, feminine: feminine)
    }

    private func isMasculineSign(_ sign: String) -> Bool {
        switch sign.lowercased() {
        case "bélier", "gémeaux", "lion", "balance", "sagittaire", "verseau":
            return true
        default:
            return false
        }
    }

    private func houseIndex(for longitude: Double, cusps: [HouseCusp]) -> Int? {
        guard cusps.count == 12 else { return nil }
        let sortedCusps = cusps.sorted { $0.id < $1.id }
        let normalized = normalizeAngle(longitude)

        for index in 0..<sortedCusps.count {
            let start = normalizeAngle(sortedCusps[index].longitude)
            let end = normalizeAngle(sortedCusps[(index + 1) % sortedCusps.count].longitude)

            if start <= end {
                if normalized >= start && normalized < end {
                    return sortedCusps[index].id
                }
            } else if normalized >= start || normalized < end {
                return sortedCusps[index].id
            }
        }
        return nil
    }

    private func ascendantRuler(for sign: String, positions: [PlanetPosition]) -> PlanetPosition? {
        let rulerMap: [String: [String]] = [
            "bélier": ["mars"],
            "taureau": ["vénus", "venus"],
            "gémeaux": ["mercure"],
            "cancer": ["lune"],
            "lion": ["soleil"],
            "vierge": ["mercure"],
            "balance": ["vénus", "venus"],
            "scorpion": ["mars", "pluton"],
            "sagittaire": ["jupiter"],
            "capricorne": ["saturne"],
            "verseau": ["saturne", "uranus"],
            "poissons": ["jupiter", "neptune"]
        ]

        let candidates = rulerMap[sign.lowercased()] ?? []
        return positions.first(where: { candidates.contains($0.name.lowercased()) })
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
    @State private var selectedSignification: Transit?
    @State private var sortColumn: TransitSortColumn = .pic
    @State private var sortAscending = true
    @State private var activeFilters: [TransitSortColumn: Set<String>] = [:]
    @State private var activeFilterColumn: TransitSortColumn?
    @State private var pendingFilterSelections: Set<String> = []
    
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
                    
                    ScrollView(.horizontal) {
                        ScrollView(.vertical) {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                Text("Analyse de \(monthTitle)")
                                    .font(.headline)
                                    .padding(.horizontal, 8)
                                
                                ForEach(groupedTransits, id: \.group) { section in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(section.group.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        
                                        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                                            TransitTableHeader(
                                                sortColumn: sortColumn,
                                                sortAscending: sortAscending,
                                                onSort: toggleSort,
                                                activeFilters: $activeFilters,
                                                activeFilterColumn: $activeFilterColumn,
                                                pendingSelections: $pendingFilterSelections,
                                                filterOptions: filterOptions,
                                                onOpenFilter: openFilter,
                                                onApplyFilter: applyFilter,
                                                onCancelFilter: cancelFilter
                                            )
                                            ForEach(section.transits) { transit in
                                                TransitTableRow(
                                                    transit: transit,
                                                    referenceDate: viewModel.selectedDate,
                                                    selectedSignification: $selectedSignification
                                                )
                                            }
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(16)
                                }
                            }
                            .frame(minWidth: TransitColumnWidth.totalWidth, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                }
                .fileExporter(
                    isPresented: $isExportingCSV,
                    document: TransitCSVDocument(csv: csvContent),
                    contentType: .commaSeparatedText,
                    defaultFilename: "transits-\(fileNameMonth)"
                ) { _ in }
            }
        }
        .overlay {
            if let selectedSignification {
                let interpretation = InterpretationService.shared.getInterpretation(for: selectedSignification)
                SignificationZoomView(
                    transit: selectedSignification,
                    interpretation: interpretation,
                    isPresented: $selectedSignification
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedSignification)
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

    private var groupedTransits: [(group: InfluenceGroup, transits: [Transit])] {
        let calendar = Calendar.current
        let referenceMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: viewModel.selectedDate)) ?? viewModel.selectedDate
        let grouped = Dictionary(grouping: filteredTransits) { transit in
            let picMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: transit.picDate)) ?? transit.picDate
            let delta = calendar.dateComponents([.month], from: referenceMonth, to: picMonth).month ?? 0
            if delta == 0 {
                return InfluenceGroup.currentMonth
            }
            if abs(delta) == 1 {
                return InfluenceGroup.oneMonthOffset
            }
            return InfluenceGroup.moreThanOneMonth
        }

        return InfluenceGroup.allCases.compactMap { group in
            guard let transits = grouped[group] else { return nil }
            let sorted = sortTransits(transits)
            return (group, sorted)
        }
    }

    private var filteredTransits: [Transit] {
        let active = activeFilters.filter { !$0.value.isEmpty }
        guard !active.isEmpty else { return viewModel.transits }
        return viewModel.transits.filter { transit in
            for (column, values) in active {
                let value = filterValue(for: transit, column: column)
                if !values.contains(value) {
                    return false
                }
            }
            return true
        }
    }

    private func toggleSort(_ column: TransitSortColumn) {
        if sortColumn == column {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = true
        }
    }

    private func sortTransits(_ transits: [Transit]) -> [Transit] {
        transits.sorted { lhs, rhs in
            let comparison = sortComparison(lhs, rhs)
            if comparison == .orderedSame {
                return lhs.picDate < rhs.picDate
            }
            return sortAscending ? (comparison == .orderedAscending) : (comparison == .orderedDescending)
        }
    }

    private func sortComparison(_ lhs: Transit, _ rhs: Transit) -> ComparisonResult {
        switch sortColumn {
        case .pic:
            return compare(lhs.picDate, rhs.picDate)
        case .transitPlanet:
            return compare(lhs.transitPlanet, rhs.transitPlanet)
        case .aspect:
            return compareAspect(lhs.aspect, rhs.aspect)
        case .natalPlanet:
            return compare(lhs.natalPlanet, rhs.natalPlanet)
        case .startDate:
            return compare(lhs.startDate, rhs.startDate)
        case .endDate:
            return compare(lhs.endDate, rhs.endDate)
        case .orbe:
            return compare(lhs.orbe, rhs.orbe)
        case .influence:
            return compare(influence(for: lhs), influence(for: rhs))
        case .meteo:
            return compare(lhs.meteo, rhs.meteo)
        case .signification:
            return compare(significationPreview(for: lhs), significationPreview(for: rhs))
        }
    }

    private func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        if lhs == rhs { return .orderedSame }
        return lhs < rhs ? .orderedAscending : .orderedDescending
    }

    private func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        lhs.localizedCaseInsensitiveCompare(rhs)
    }

    private func compare(_ lhs: Date, _ rhs: Date) -> ComparisonResult {
        if lhs == rhs { return .orderedSame }
        return lhs < rhs ? .orderedAscending : .orderedDescending
    }

    private func compare(_ lhs: Double, _ rhs: Double) -> ComparisonResult {
        if lhs == rhs { return .orderedSame }
        return lhs < rhs ? .orderedAscending : .orderedDescending
    }

    private func compareAspect(_ lhs: AspectType, _ rhs: AspectType) -> ComparisonResult {
        let order = TransitSortColumn.aspectOrder
        guard let lhsIndex = order.firstIndex(of: lhs), let rhsIndex = order.firstIndex(of: rhs) else {
            return .orderedSame
        }
        return compare(lhsIndex, rhsIndex)
    }

    private func filterOptions(for column: TransitSortColumn) -> [String] {
        switch column {
        case .pic:
            return viewModel.transits.map { picText(for: $0.picDate) }
        case .transitPlanet:
            return uniqueSortedStrings(viewModel.transits.map { $0.transitPlanet.capitalized })
        case .aspect:
            return uniqueSortedStrings(viewModel.transits.map { $0.aspect.displayName })
        case .natalPlanet:
            return uniqueSortedStrings(viewModel.transits.map { $0.natalPlanet.capitalized })
        case .startDate:
            return viewModel.transits.map { dateText($0.startDate) }
        case .endDate:
            return viewModel.transits.map { dateText($0.endDate) }
        case .orbe:
            return viewModel.transits.map { String(format: "%.2f°", $0.orbe) }
        case .influence:
            return uniqueSortedStrings(viewModel.transits.map { influence(for: $0) })
        case .meteo:
            return uniqueSortedStrings(viewModel.transits.map { $0.meteo })
        case .signification:
            return uniqueSortedStrings(viewModel.transits.map { significationPreview(for: $0) })
        }
    }

    private func filterValue(for transit: Transit, column: TransitSortColumn) -> String {
        switch column {
        case .pic:
            return picText(for: transit.picDate)
        case .transitPlanet:
            return transit.transitPlanet.capitalized
        case .aspect:
            return transit.aspect.displayName
        case .natalPlanet:
            return transit.natalPlanet.capitalized
        case .startDate:
            return dateText(transit.startDate)
        case .endDate:
            return dateText(transit.endDate)
        case .orbe:
            return String(format: "%.2f°", transit.orbe)
        case .influence:
            return influence(for: transit)
        case .meteo:
            return transit.meteo
        case .signification:
            return significationPreview(for: transit)
        }
    }

    private func openFilter(_ column: TransitSortColumn) {
        activeFilterColumn = column
        pendingFilterSelections = activeFilters[column] ?? []
    }

    private func applyFilter() {
        if let column = activeFilterColumn {
            activeFilters[column] = pendingFilterSelections
        }
        activeFilterColumn = nil
    }

    private func cancelFilter() {
        activeFilterColumn = nil
        pendingFilterSelections = []
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func picText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: date)
    }

    private func uniqueSortedStrings(_ items: [String]) -> [String] {
        let unique = Set(items)
        return unique.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func significationPreview(for transit: Transit) -> String {
        let interpretation = InterpretationService.shared.getInterpretation(for: transit)
        let essence = interpretation?.essence?.trimmingCharacters(in: .whitespacesAndNewlines)
        let influence = interpretation?.influence.trimmingCharacters(in: .whitespacesAndNewlines)
        let motsCles = interpretation?.motsCles?.trimmingCharacters(in: .whitespacesAndNewlines)
        return essence?.isEmpty == false ? essence! : (motsCles?.isEmpty == false ? motsCles! : (influence ?? "—"))
    }
}

private enum TransitSortColumn: Hashable {
    case pic
    case transitPlanet
    case aspect
    case natalPlanet
    case startDate
    case endDate
    case orbe
    case influence
    case meteo
    case signification

    static let aspectOrder: [AspectType] = [
        .conjonction,
        .carre,
        .opposition,
        .trigone,
        .sextile
    ]
}

private struct TransitTableHeader: View {
    let sortColumn: TransitSortColumn
    let sortAscending: Bool
    let onSort: (TransitSortColumn) -> Void
    @Binding var activeFilters: [TransitSortColumn: Set<String>]
    @Binding var activeFilterColumn: TransitSortColumn?
    @Binding var pendingSelections: Set<String>
    let filterOptions: (TransitSortColumn) -> [String]
    let onOpenFilter: (TransitSortColumn) -> Void
    let onApplyFilter: () -> Void
    let onCancelFilter: () -> Void

    var body: some View {
        GridRow {
            headerCell("Pic", column: .pic, width: TransitColumnWidth.pic)
            headerCell("Planète transit", column: .transitPlanet, width: TransitColumnWidth.planet)
            headerCell("Aspect", column: .aspect, width: TransitColumnWidth.aspect)
            headerCell("Planète natale", column: .natalPlanet, width: TransitColumnWidth.planet)
            headerCell("Début", column: .startDate, width: TransitColumnWidth.date)
            headerCell("Fin", column: .endDate, width: TransitColumnWidth.date)
            headerCell("Orbe", column: .orbe, width: TransitColumnWidth.orbe)
            headerCell("Influence", column: .influence, width: TransitColumnWidth.influence)
            headerCell("Météo", column: .meteo, width: TransitColumnWidth.meteo)
            headerCell("Signification", column: .signification, width: TransitColumnWidth.signification)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private func headerCell(_ text: String, column: TransitSortColumn, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                onSort(column)
            } label: {
                HStack(spacing: 4) {
                    Text(text)
                    if sortColumn == column {
                        Image(systemName: sortAscending ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                            .font(.caption2)
                    }
                }
                .frame(width: width, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                onOpenFilter(column)
            } label: {
                Image(systemName: activeFilters[column]?.isEmpty == false
                      ? "line.3.horizontal.decrease.circle.fill"
                      : "line.3.horizontal.decrease.circle")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
            .popover(isPresented: Binding(
                get: { activeFilterColumn == column },
                set: { isPresented in
                    if !isPresented {
                        onCancelFilter()
                    }
                }
            )) {
                FilterSelectionView(
                    title: text,
                    options: filterOptions(column),
                    selections: $pendingSelections,
                    onApply: onApplyFilter,
                    onCancel: onCancelFilter
                )
            }
        }
    }
}

private struct FilterSelectionView: View {
    let title: String
    let options: [String]
    @Binding var selections: Set<String>
    let onApply: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filtrer \(title.lowercased())")
                .font(.headline)
            Divider()
            if options.isEmpty {
                Text("Aucun filtre")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(options, id: \.self) { option in
                            Button {
                                toggle(option)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: selections.contains(option) ? "checkmark.square" : "square")
                                    Text(option)
                                        .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 240)
            }
            Divider()
            HStack {
                Button("Tout afficher") {
                    selections.removeAll()
                    onApply()
                }
                Spacer()
                Button("Annuler") {
                    onCancel()
                }
                Button("Valider") {
                    onApply()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 260)
    }

    private func toggle(_ option: String) {
        if selections.contains(option) {
            selections.remove(option)
        } else {
            selections.insert(option)
        }
    }
}

private struct TransitTableRow: View {
    let transit: Transit
    let referenceDate: Date
    @Binding var selectedSignification: Transit?

    private var interpretation: TransitInterpretation? {
        InterpretationService.shared.getInterpretation(for: transit)
    }

    var body: some View {
        GridRow {
            cell(picText, width: TransitColumnWidth.pic)
            cell(transit.transitPlanet.capitalized, width: TransitColumnWidth.planet)
            aspectCell
            cell(transit.natalPlanet.capitalized, width: TransitColumnWidth.planet)
            cell(dateText(transit.startDate), width: TransitColumnWidth.date)
            cell(dateText(transit.endDate), width: TransitColumnWidth.date)
            cell(String(format: "%.2f°", transit.orbe), width: TransitColumnWidth.orbe)
            cell(influenceText, width: TransitColumnWidth.influence)
            cell(transit.meteo, width: TransitColumnWidth.meteo)
            significationCell
        }
        Divider()
    }

    private var picText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: transit.picDate)
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private var influenceText: String {
        let calendar = Calendar.current
        let picMonth = calendar.component(.month, from: transit.picDate)
        let referenceMonth = calendar.component(.month, from: referenceDate)

        if picMonth == referenceMonth {
            return "pic du mois"
        }
        if abs(picMonth - referenceMonth) == 1 {
            return "pic 1 mois avant/après"
        }
        return "pic plus d'un mois après"
    }

    private var significationText: String {
        let essence = interpretation?.essence?.trimmingCharacters(in: .whitespacesAndNewlines)
        let influence = interpretation?.influence.trimmingCharacters(in: .whitespacesAndNewlines)
        let motsCles = interpretation?.motsCles?.trimmingCharacters(in: .whitespacesAndNewlines)
        return essence?.isEmpty == false ? essence! : (motsCles?.isEmpty == false ? motsCles! : (influence ?? "—"))
    }

    private var aspectCell: some View {
        Text(transit.aspect.displayName)
            .font(.caption.weight(.semibold))
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .frame(width: TransitColumnWidth.aspect, alignment: .leading)
            .background(colorForAspect(transit.aspect).opacity(0.12))
            .cornerRadius(6)
            .foregroundStyle(colorForAspect(transit.aspect))
    }

    private func cell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.subheadline)
            .frame(width: width, alignment: .leading)
            .lineLimit(2)
    }

    private var significationCell: some View {
        Text(significationText)
            .font(.subheadline)
            .frame(width: TransitColumnWidth.signification, alignment: .leading)
            .lineLimit(2)
            .contentShape(Rectangle())
            .onTapGesture {
                guard significationText != "—" else { return }
                selectedSignification = transit
            }
    }

    private func colorForAspect(_ aspect: AspectType) -> Color {
        switch aspect {
        case .carre, .opposition:
            return .red
        case .sextile, .trigone:
            return .green
        case .conjonction:
            return .blue
        }
    }
}

private struct SignificationZoomView: View {
    let transit: Transit
    let interpretation: TransitInterpretation?
    @Binding var isPresented: Transit?

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = nil
                    }
                }

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Signification")
                        .font(.headline)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                HStack(alignment: .center, spacing: 16) {
                    planetCard(title: transit.transitPlanet.capitalized)
                    aspectCard
                    planetCard(title: transit.natalPlanet.capitalized)
                }
                .frame(maxWidth: .infinity)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(significationSections, id: \.title) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(section.body)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .background(Color.white.opacity(0.75))
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 360)
            }
            .padding(20)
            .frame(maxWidth: 560)
            .background(Color(.systemGray6))
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 10)
            .padding()
        }
    }

    private var significationSections: [(title: String, body: String)] {
        guard let interpretation else {
            return [("Influence", "Aucune interprétation disponible pour ce transit.")]
        }
        let sections: [(String, String?)] = [
            ("Essence du transit", interpretation.essence),
            ("Ce qui peut arriver", interpretation.ceQuiPeutArriver),
            ("Vie affective & familiale", interpretation.relations),
            ("Vie professionnelle & sociale", interpretation.travail),
            ("À éviter", interpretation.aEviter),
            ("À faire", interpretation.aFaire),
            ("Mots-clés", interpretation.motsCles),
            ("Conseils d'intégration", interpretation.conseils.isEmpty ? nil : interpretation.conseils)
        ]

        let compacted = sections.compactMap { title, body -> (String, String)? in
            guard let body, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return (title, body)
        }

        if compacted.isEmpty {
            return [("Influence", interpretation.influence)]
        }

        return compacted
    }

    private func planetCard(title: String) -> some View {
        VStack(spacing: 8) {
            Text(planetSymbol(for: title))
                .font(.system(size: 26))
                .frame(width: 44, height: 44)
                .background(Color.indigo.opacity(0.15), in: Circle())
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.85))
        .cornerRadius(14)
    }

    private var aspectCard: some View {
        VStack(spacing: 6) {
            Text(transit.aspect.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.indigo)
            Text(aspectSymbol(for: transit.aspect))
                .font(.system(size: 28))
        }
        .frame(width: 90, height: 90)
        .background(Color.white.opacity(0.85))
        .cornerRadius(16)
    }

    private func aspectSymbol(for aspect: AspectType) -> String {
        switch aspect {
        case .trigone:
            return "△"
        case .sextile:
            return "✶"
        case .carre:
            return "□"
        case .opposition:
            return "☍"
        case .conjonction:
            return "☌"
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

private enum TransitColumnWidth {
    static let pic: CGFloat = 80
    static let planet: CGFloat = 130
    static let aspect: CGFloat = 110
    static let date: CGFloat = 130
    static let orbe: CGFloat = 70
    static let influence: CGFloat = 170
    static let meteo: CGFloat = 70
    static let signification: CGFloat = 280
    static let totalWidth: CGFloat = pic + planet + aspect + planet + date + date + orbe + influence + meteo + signification + 108
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
