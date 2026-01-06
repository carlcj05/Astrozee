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
                        NatalChartView(positions: natalPositions, selectedPlanet: $selectedPlanet)
                        
                        NatalPlanetDetailCard(planet: selectedPlanet)
                        
                        NatalPlanetLegend(positions: natalPositions, selectedPlanet: $selectedPlanet)
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
            withAnimation(.easeInOut(duration: 0.4)) {
                natalPositions = positions
                selectedPlanet = positions.first
            }
        }
    }
}

// MARK: - Thème natal (visuel interactif)
private struct NatalChartView: View {
    let positions: [PlanetPosition]
    @Binding var selectedPlanet: PlanetPosition?
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            
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
                
                Circle()
                    .stroke(Color.indigo.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                    .padding(radius * 0.18)
                
                ForEach(0..<12, id: \.self) { index in
                    let angle = Double(index) * 30.0 - 90.0
                    let lineStart = point(on: angle, radius: radius * 0.38, center: center)
                    let lineEnd = point(on: angle, radius: radius * 0.92, center: center)
                    
                    Path { path in
                        path.move(to: lineStart)
                        path.addLine(to: lineEnd)
                    }
                    .stroke(Color.indigo.opacity(0.12), lineWidth: 1)
                    
                    Text(zodiacSymbols[index])
                        .font(.system(size: size * 0.06, weight: .semibold))
                        .foregroundStyle(Color.indigo.opacity(0.7))
                        .position(point(on: angle, radius: radius * 0.78, center: center))
                }
                
                ForEach(positions) { planet in
                    let angle = planet.longitude - 90.0
                    let planetPoint = point(on: angle, radius: radius * 0.6, center: center)
                    let isSelected = planet.id == selectedPlanet?.id
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedPlanet = planet
                        }
                    } label: {
                        Text(planetSymbol(for: planet.name))
                            .font(.system(size: size * 0.08, weight: .bold))
                            .foregroundStyle(isSelected ? Color.white : Color.indigo.opacity(0.85))
                            .frame(width: size * 0.12, height: size * 0.12)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.indigo : planetColor(for: planet.name))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.7), lineWidth: isSelected ? 2 : 1)
                            )
                            .shadow(color: Color.indigo.opacity(isSelected ? 0.35 : 0.2), radius: 8, x: 0, y: 4)
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
        default: return Color.indigo.opacity(0.6)
        }
    }
    
    private var zodiacSymbols: [String] {
        ["♈︎", "♉︎", "♊︎", "♋︎", "♌︎", "♍︎", "♎︎", "♏︎", "♐︎", "♑︎", "♒︎", "♓︎"]
    }
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
        default: return "✦"
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
