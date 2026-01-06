import SwiftUI

struct PlanetPositionsView: View {
    let profile: Profile
    
    // On ne garde que les positions des planètes pour l'instant
    @State private var positions: [PlanetPosition] = []

    var body: some View {
        List {
            // Section unique : Les Planètes Natales
            Section("Positions Natales") {
                ForEach(positions) { p in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(p.name).font(.headline)
                            Text(p.sign).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            // Assure-toi que 'degreeInSign' existe dans ton modèle PlanetPosition
                            // Sinon utilise : Text(String(format: "%.2f°", p.longitude))
                            Text(p.degreeInSign).monospacedDigit()
                            Text(String(format: "%.3f°/j", p.speed)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(profile.name)
        .onAppear(perform: computePositions)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                // --- C'EST ICI LE CHANGEMENT ---
                // On dirige vers TransitsMainView (celle avec les onglets)
                NavigationLink(destination: TransitsMainView(profile: profile)) {
                    Label("Transits", systemImage: "arrow.right.circle")
                }
            }
        }
    }

    private func computePositions() {
        // Calcul simple uniquement des planètes
        let dateUT = profile.birthDateUTC()
        positions = Ephemeris.shared.computePositionsUT(dateUT: dateUT)
    }
}
