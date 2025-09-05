import SwiftUI

struct PlanetPositionsView: View {
    let profile: Profile
    @State private var positions: [PlanetPosition] = []

    var body: some View {
        VStack(spacing: 0) {
            List(positions) { p in
                HStack {
                    VStack(alignment: .leading) {
                        Text(p.name).font(.headline)
                        Text(p.sign).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(p.degreeInSign).monospacedDigit()
                        Text(String(format: "%.3f°/j", p.speed)).font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 4)
            }
            Divider()
            VStack(spacing: 6) {
                Text("Naissance (local) : \(profile.birthLocalDate.shortLocalString())  —  TZ: \(profile.tzOffsetMinutes) min")
                    .font(.footnote).foregroundStyle(.secondary)
                Text("Calculé à partir de l’UTC : \(profile.birthDateUTC().shortLocalString()) (affiché en UTC)")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(8)
        }
        .navigationTitle(profile.name)
        .onAppear(perform: compute)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { compute() } label: { Image(systemName: "arrow.clockwise") }
            }
        }
        .frame(minWidth: 520, minHeight: 520)
    }

    private func compute() {
        let dateUT = profile.birthDateUTC()
        positions = Ephemeris.shared.computePositionsUT(dateUT: dateUT)
    }
}
