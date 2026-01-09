import Charts
import SwiftUI

// MARK: - Moodchart (Histogramme interactif)
struct TransitMoodChartView: View {
    @ObservedObject var viewModel: TransitViewModel
    @State private var selectedWeek: MoodWeekKey?
    @State private var selectedSignification: AttributedString?
    @State private var selectedTransitId: UUID?

    var body: some View {
        VStack(spacing: 16) {
            contentSection
        }
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
        .onChange(of: selectedWeek) { _ in
            selectedTransitId = nil
            selectedSignification = nil
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

                HStack(alignment: .top, spacing: 16) {
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(selectedWeekTransits) { transit in
                                Button {
                                    selectedSignification = significationText(for: transit)
                                    selectedTransitId = transit.id
                                } label: {
                                    MoodTransitSummaryRow(
                                        transit: transit,
                                        isSelected: transit.id == selectedTransitId
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                    .frame(maxWidth: 360, alignment: .leading)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Signification")
                            .font(.headline)
                        if let selectedSignification {
                            ScrollView {
                                Text(selectedSignification)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            Text("Sélectionne un transit pour afficher sa signification.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing)
                }
                .padding(.bottom, 12)
            } else {
                Text("Touchez une barre pour afficher le détail des transits.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.selectedDate).capitalized
    }

    private var filteredTransits: [Transit] {
        let monthFiltered = viewModel.transits.filter { transit in
            isInSelectedMonth(transit.picDate)
        }
        return monthFiltered
    }

    private var moodWeekKeys: [MoodWeekKey] {
        let keys = filteredTransits.map { weekKey(for: $0) }
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
        let weekOfMonth = calendar.component(.weekOfMonth, from: transit.picDate)
        let clampedWeek = min(max(weekOfMonth, 1), 4)
        return MoodWeekKey(weekIndex: clampedWeek)
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

    private func normalizePlanetName(_ name: String) -> String {
        name.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .folding(options: .diacriticInsensitive, locale: .current)
    }

    private func significationText(for transit: Transit) -> AttributedString? {
        let interpretation = InterpretationService.shared.getInterpretation(for: transit)
        let essence = interpretation?.essence?.trimmingCharacters(in: .whitespacesAndNewlines)
        let influence = interpretation?.influence.trimmingCharacters(in: .whitespacesAndNewlines)
        let motsCles = interpretation?.motsCles?.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = essence?.isEmpty == false ? essence! : (motsCles?.isEmpty == false ? motsCles! : (influence ?? "—"))
        let formatted = formatSignification(raw)
        return formatted.characters.isEmpty ? nil : formatted
    }

    private func formatSignification(_ text: String) -> AttributedString {
        let markers = ["✴️", "🔮", "❤️", "💼", "🧭", "🌱", "💡"]
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let sections = extractSignificationSections(from: trimmed, markers: markers)
        guard !sections.isEmpty else {
            return AttributedString(trimmed)
        }

        var result = AttributedString()
        for (index, section) in sections.enumerated() {
            let title = section.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let body = section.body.trimmingCharacters(in: .whitespacesAndNewlines)

            var titleText = AttributedString(title)
            titleText.font = .system(.body).bold()
            result.append(titleText)

            if !body.isEmpty {
                result.append(AttributedString("\n"))
                result.append(AttributedString(body))
            }

            if index < sections.count - 1 {
                result.append(AttributedString("\n\n"))
            }
        }

        return result
    }

    private func extractSignificationSections(from text: String, markers: [String]) -> [(title: String, body: String)] {
        guard !text.isEmpty else { return [] }
        var sectionStarts: [(marker: String, index: String.Index)] = []

        for marker in markers {
            var searchRange = text.startIndex..<text.endIndex
            while let range = text.range(of: marker, range: searchRange) {
                sectionStarts.append((marker, range.lowerBound))
                searchRange = range.upperBound..<text.endIndex
            }
        }

        let sortedStarts = sectionStarts.sorted { $0.index < $1.index }
        guard !sortedStarts.isEmpty else { return [] }

        var sections: [(title: String, body: String)] = []
        for (index, start) in sortedStarts.enumerated() {
            let endIndex = index + 1 < sortedStarts.count ? sortedStarts[index + 1].index : text.endIndex
            let chunk = text[start.index..<endIndex]
            let normalized = chunk.replacingOccurrences(of: "\r\n", with: "\n")
            let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false)
            let title = lines.first.map(String.init) ?? String(chunk)
            let body = lines.dropFirst().joined(separator: "\n")
            sections.append((title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                             body: body.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        return sections
    }

    private func isInSelectedMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let selectedComponents = calendar.dateComponents([.year, .month], from: viewModel.selectedDate)
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        return selectedComponents.year == dateComponents.year
            && selectedComponents.month == dateComponents.month
    }
}

private struct MoodWeekKey: Hashable, Comparable, Identifiable {
    let weekIndex: Int

    var id: String {
        "S\(weekIndex)"
    }

    var label: String {
        "S\(weekIndex)"
    }

    static func < (lhs: MoodWeekKey, rhs: MoodWeekKey) -> Bool {
        lhs.weekIndex < rhs.weekIndex
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
            return Color(hex: SystemColorHex.green)
        case .challenge:
            return Color(hex: SystemColorHex.red)
        case .transformant:
            return Color(hex: SystemColorHex.purple)
        case .neutre:
            return Color(hex: SystemColorHex.blue)
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

private struct MoodTransitSummaryRow: View {
    let transit: Transit
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(picText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(transit.transitPlanet.capitalized)
                .font(.headline)
            aspectCell
            Text(transit.natalPlanet.capitalized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(selectionBackground)
    }

    private var selectionBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
            )
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
            .background(colorForAspect(transit.aspect).opacity(0.12))
            .cornerRadius(6)
            .foregroundStyle(colorForAspect(transit.aspect))
    }

    private func colorForAspect(_ aspect: AspectType) -> Color {
        switch aspect {
        case .carre, .opposition:
            return Color(hex: SystemColorHex.red)
        case .sextile, .trigone:
            return Color(hex: SystemColorHex.green)
        case .conjonction:
            return Color(hex: SystemColorHex.blue)
        }
    }
}

