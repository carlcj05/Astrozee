import Charts
import SwiftUI

// MARK: - Moodchart (Histogramme interactif)
struct TransitMoodChartView: View {
    @ObservedObject var viewModel: TransitViewModel
    @State private var selectedWeek: MoodWeekKey?
    @State private var selectedSignification: String?
    @State private var activeThemeFilters: Set<ThemeCategory> = []

    var body: some View {
        VStack(spacing: 16) {
            contentSection
        }
        .overlay {
            if let selectedSignification {
                SignificationZoomView(
                    text: selectedSignification,
                    isPresented: $selectedSignification
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedSignification)
    }

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isCalculating {
            ProgressView("Calcul des positions planétaires...")
                .scaleEffect(1.5)
                .padding()
        } else if !viewModel.calculationDone {
            ContentUnavailableView(
                "En attente",
                systemImage: "arrow.left.circle",
                description: Text("Lance une analyse pour afficher le moodchart.")
            )
        } else if filteredTransits.isEmpty {
            ContentUnavailableView(
                "Aucun transit",
                systemImage: "moon.stars",
                description: Text("Aucun transit ne correspond aux filtres sélectionnés.")
            )
        } else {
            moodContent
        }
    }

    private var moodContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Moodchart · \(monthTitle)")
                .font(.headline)
                .padding(.horizontal)

            themeFilterBar
                .padding(.horizontal)

            chartSection

            moodLegend
                .padding(.horizontal)

            Divider()
                .padding(.horizontal)

            moodDetailSection
        }
        .onAppear {
            if selectedWeek == nil {
                selectedWeek = moodWeekKeys.first
            }
        }
        .onChange(of: moodWeekKeys) { newKeys in
            if let selectedWeek, newKeys.contains(selectedWeek) {
                return
            }
            selectedWeek = newKeys.first
        }
    }

    private var chartSection: some View {
        Chart {
            ForEach(moodWeekData) { item in
                BarMark(
                    x: .value("Semaine", item.weekKey.id),
                    y: .value("Score", item.value)
                )
                .foregroundStyle(by: .value("Catégorie", item.category.displayName))
                .position(by: .value("Catégorie", item.category.displayName))
                .cornerRadius(4)
            }
        }
        .chartForegroundStyleScale(
            domain: MoodCategory.allCases.map(\.displayName),
            range: MoodCategory.allCases.map(\.color)
        )
        .chartXAxis {
            AxisMarks(values: moodWeekKeys.map(\.id)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let id = value.as(String.self),
                       let weekKey = moodWeekKeyMap[id] {
                        Text(weekKey.label)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let origin = geometry[proxy.plotAreaFrame].origin
                                let locationX = value.location.x - origin.x
                                if let weekId: String = proxy.value(atX: locationX),
                                   let weekKey = moodWeekKeyMap[weekId] {
                                    selectedWeek = weekKey
                                }
                            }
                    )
            }
        }
        .frame(height: 260)
        .padding(.horizontal)
    }

    private var themeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ThemeCategory.allCases) { category in
                    let isActive = activeThemeFilters.contains(category)
                    Button {
                        toggleTheme(category)
                    } label: {
                        Text(category.displayName)
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(isActive ? Color.indigo.opacity(0.2) : Color.gray.opacity(0.12))
                            .foregroundStyle(isActive ? .indigo : .secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if !activeThemeFilters.isEmpty {
                    Button("Réinitialiser") {
                        activeThemeFilters.removeAll()
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var moodLegend: some View {
        HStack(spacing: 12) {
            ForEach(MoodCategory.allCases) { category in
                HStack(spacing: 6) {
                    Circle()
                        .fill(category.color)
                        .frame(width: 10, height: 10)
                    Text(category.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var moodDetailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let selectedWeek {
                HStack {
                    Text("Transits · \(selectedWeek.label)")
                        .font(.headline)
                    Spacer()
                    Text("\(selectedWeekTransits.count) transit(s)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                ScrollView(.horizontal) {
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            MoodTransitTableHeader()
                            ForEach(selectedWeekTransits) { transit in
                                MoodTransitRow(
                                    transit: transit,
                                    selectedSignification: $selectedSignification
                                )
                            }
                        }
                        .frame(minWidth: MoodTransitColumnWidth.totalWidth, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                }
            } else {
                Text("Touchez une barre pour afficher le détail des transits.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }

    private func toggleTheme(_ category: ThemeCategory) {
        if activeThemeFilters.contains(category) {
            activeThemeFilters.remove(category)
        } else {
            activeThemeFilters.insert(category)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.selectedDate).capitalized
    }

    private var filteredTransits: [Transit] {
        guard !activeThemeFilters.isEmpty else { return viewModel.transits }
        return viewModel.transits.filter { transit in
            let themes = themeCategories(for: transit)
            return !themes.isDisjoint(with: activeThemeFilters)
        }
    }

    private var moodWeekKeys: [MoodWeekKey] {
        let calendar = Calendar(identifier: .iso8601)
        let keys = filteredTransits.map { transit -> MoodWeekKey in
            let week = calendar.component(.weekOfYear, from: transit.picDate)
            let year = calendar.component(.yearForWeekOfYear, from: transit.picDate)
            return MoodWeekKey(year: year, week: week)
        }
        return Array(Set(keys)).sorted()
    }

    private var moodWeekKeyMap: [String: MoodWeekKey] {
        Dictionary(uniqueKeysWithValues: moodWeekKeys.map { ($0.id, $0) })
    }

    private var moodWeekData: [MoodWeekData] {
        let grouped = Dictionary(grouping: filteredTransits, by: weekKey(for:))
        var results: [MoodWeekData] = []

        for weekKey in moodWeekKeys {
            let transits = grouped[weekKey] ?? []
            for category in MoodCategory.allCases {
                let total = transits
                    .filter { moodCategory(for: $0) == category }
                    .map { impactScore(for: $0) }
                    .reduce(0, +)
                if total != 0 {
                    results.append(MoodWeekData(weekKey: weekKey, category: category, value: total))
                }
            }
        }
        return results
    }

    private var selectedWeekTransits: [Transit] {
        guard let selectedWeek else { return [] }
        return filteredTransits
            .filter { weekKey(for: $0) == selectedWeek }
            .sorted { $0.picDate < $1.picDate }
    }

    private func weekKey(for transit: Transit) -> MoodWeekKey {
        let calendar = Calendar(identifier: .iso8601)
        let week = calendar.component(.weekOfYear, from: transit.picDate)
        let year = calendar.component(.yearForWeekOfYear, from: transit.picDate)
        return MoodWeekKey(year: year, week: week)
    }

    private func moodCategory(for transit: Transit) -> MoodCategory {
        let normalized = normalizePlanetName(transit.transitPlanet)
        if MoodCategory.transformantPlanets.contains(normalized) {
            return .transformant
        }

        switch transit.aspect {
        case .sextile, .trigone:
            return .fluide
        case .carre, .opposition:
            return .challenge
        case .conjonction:
            return .neutre
        }
    }

    private func impactScore(for transit: Transit) -> Int {
        switch transit.aspect {
        case .sextile, .trigone:
            return 2
        case .conjonction:
            return 1
        case .carre, .opposition:
            return -2
        }
    }

    private func themeCategories(for transit: Transit) -> Set<ThemeCategory> {
        let interpretation = InterpretationService.shared.getInterpretation(for: transit)
        var themes: Set<ThemeCategory> = []

        if interpretation?.relations != nil {
            themes.insert(.relationnel)
        }
        if interpretation?.travail != nil {
            themes.insert(.carriere)
        }
        if themes.isEmpty {
            themes.insert(.emotion)
        }

        return themes
    }

    private func normalizePlanetName(_ name: String) -> String {
        name.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .folding(options: .diacriticInsensitive, locale: .current)
    }
}

private struct MoodWeekKey: Hashable, Comparable, Identifiable {
    let year: Int
    let week: Int

    var id: String {
        "\(year)-\(week)"
    }

    var label: String {
        "S\(week)"
    }

    static func < (lhs: MoodWeekKey, rhs: MoodWeekKey) -> Bool {
        if lhs.year == rhs.year {
            return lhs.week < rhs.week
        }
        return lhs.year < rhs.year
    }
}

private struct MoodWeekData: Identifiable {
    let id = UUID()
    let weekKey: MoodWeekKey
    let category: MoodCategory
    let value: Int
}

private enum MoodCategory: String, CaseIterable, Identifiable {
    case fluide
    case challenge
    case transformant
    case neutre

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fluide:
            return "Fluide / Porteur"
        case .challenge:
            return "Challenge / Résistance / Tension"
        case .transformant:
            return "Transformant / Profond / Intense"
        case .neutre:
            return "Neutre / Conjonction modérée"
        }
    }

    var color: Color {
        switch self {
        case .fluide:
            return .green
        case .challenge:
            return .red
        case .transformant:
            return .purple
        case .neutre:
            return .blue
        }
    }

    static let transformantPlanets: Set<String> = [
        "pluton",
        "neptune",
        "uranus",
        "saturne",
        "chiron"
    ]
}

private enum ThemeCategory: String, CaseIterable, Identifiable {
    case relationnel
    case carriere
    case emotion

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .relationnel:
            return "Relationnel"
        case .carriere:
            return "Carrière"
        case .emotion:
            return "Émotion"
        }
    }
}

private struct MoodTransitTableHeader: View {
    var body: some View {
        GridRow {
            headerCell("Pic", width: MoodTransitColumnWidth.pic)
            headerCell("Planète transit", width: MoodTransitColumnWidth.planet)
            headerCell("Aspect", width: MoodTransitColumnWidth.aspect)
            headerCell("Planète natale", width: MoodTransitColumnWidth.planet)
            headerCell("Signification", width: MoodTransitColumnWidth.signification)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private func headerCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .frame(width: width, alignment: .leading)
    }
}

private struct MoodTransitRow: View {
    let transit: Transit
    @Binding var selectedSignification: String?

    private var interpretation: TransitInterpretation? {
        InterpretationService.shared.getInterpretation(for: transit)
    }

    var body: some View {
        GridRow {
            cell(picText, width: MoodTransitColumnWidth.pic)
            cell(transit.transitPlanet.capitalized, width: MoodTransitColumnWidth.planet)
            aspectCell
            cell(transit.natalPlanet.capitalized, width: MoodTransitColumnWidth.planet)
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

    private var aspectCell: some View {
        Text(transit.aspect.displayName)
            .font(.caption.weight(.semibold))
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .frame(width: MoodTransitColumnWidth.aspect, alignment: .leading)
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

    private var significationText: String {
        let essence = interpretation?.essence?.trimmingCharacters(in: .whitespacesAndNewlines)
        let influence = interpretation?.influence.trimmingCharacters(in: .whitespacesAndNewlines)
        let motsCles = interpretation?.motsCles?.trimmingCharacters(in: .whitespacesAndNewlines)
        return essence?.isEmpty == false ? essence! : (motsCles?.isEmpty == false ? motsCles! : (influence ?? "—"))
    }

    private var significationCell: some View {
        Text(significationText)
            .font(.subheadline)
            .frame(width: MoodTransitColumnWidth.signification, alignment: .leading)
            .lineLimit(2)
            .contentShape(Rectangle())
            .onTapGesture {
                guard significationText != "—" else { return }
                selectedSignification = significationText
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

private enum MoodTransitColumnWidth {
    static let pic: CGFloat = 80
    static let planet: CGFloat = 130
    static let aspect: CGFloat = 110
    static let signification: CGFloat = 320
    static let totalWidth: CGFloat = pic + planet + aspect + planet + signification + 60
}
