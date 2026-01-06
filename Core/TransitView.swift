import SwiftUI

struct TransitsView: View {
    let profile: Profile
    
    @State private var selectedDate = Date()
    @State private var transits: [Transit] = []
    @State private var isCalculating = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- ZONE DE CONTRÔLE ---
            VStack(spacing: 12) {
                Text("Analyse Mensuelle")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    DatePicker("Mois", selection: $selectedDate, displayedComponents: [.date])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "fr_FR"))
                    
                    Button(action: runCalculation) {
                        if isCalculating {
                            ProgressView()
                        } else {
                            Text("Calculer")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .disabled(isCalculating)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            // CORRECTION ICI : On utilise un gris standard au lieu de systemGroupedBackground
            .background(Color.gray.opacity(0.1))
            
            // --- LISTE ---
            if transits.isEmpty {
                ContentUnavailableView(
                    "Aucun transit",
                    systemImage: "sparkles",
                    description: Text("Sélectionnez un mois et lancez le calcul.")
                )
            } else {
                List {
                    Section(header: Text("Résumé")) {
                        Text("\(transits.count) transits détectés.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Section(header: Text("Détails")) {
                        ForEach(transits) { transit in
                            TransitRow(transit: transit)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Météo Astrale")
    }
    
    private func runCalculation() {
        isCalculating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let calendar = Calendar.current
            let month = calendar.component(.month, from: selectedDate)
            let year = calendar.component(.year, from: selectedDate)
            
            let results = TransitService.computeTransitsForMonth(profile: profile, month: month, year: year)
            
            withAnimation {
                self.transits = results
                self.isCalculating = false
            }
        }
    }
}

struct TransitRow: View {
    let transit: Transit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(transit.transitPlanet.capitalized).font(.headline)
                Spacer()
                VStack {
                    Text(transit.meteo)
                    Text(transit.aspect.rawValue.capitalized)
                        .font(.caption2).bold()
                        .padding(4)
                        .background(colorForAspect(transit.aspect).opacity(0.1))
                        .cornerRadius(4)
                        .foregroundStyle(colorForAspect(transit.aspect))
                }
                Spacer()
                Text(transit.natalPlanet.capitalized).font(.subheadline).foregroundStyle(.secondary)
            }
            Divider()
            HStack {
                Text("Pic le \(transit.picDate.formatted(.dateTime.day().month()))")
                    .font(.caption).foregroundStyle(.blue)
                Spacer()
                Text("Orbe: \(String(format: "%.2f", transit.orbe))°")
                    .font(.caption2).monospacedDigit().foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    func colorForAspect(_ aspect: AspectType) -> Color {
        switch aspect {
        case .carre, .opposition: return .red
        case .sextile, .trigone: return .green
        case .conjonction: return .blue
        }
    }
}
