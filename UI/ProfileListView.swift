import SwiftUI

struct ProfileListView: View {
    @EnvironmentObject var store: ProfileStore
    @State private var showNew = false
    // ⬇️ sélection de ligne pour le bouton Supprimer
    @State private var selection: Profile.ID?

    var body: some View {
        NavigationStack {
            List(selection: $selection) {
                if store.profiles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aucun profil").font(.title2).bold()
                        Text("Ajoute ton premier profil pour calculer les positions natales.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                } else {
                    ForEach(store.profiles) { profile in
                        NavigationLink(value: profile) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.name).font(.headline)
                                HStack(spacing: 8) {
                                    if let p = profile.placeName { Text(p) }
                                    Text("—").foregroundStyle(.secondary)
                                    Text(profile.birthLocalDate.shortLocalString())
                                    Text("TZ: \(profile.tzOffsetMinutes) min").foregroundStyle(.secondary)
                                }
                                .font(.caption)
                            }
                        }
                        // ⬇️ clic droit sur une ligne
                        .contextMenu {
                            Button(role: .destructive) {
                                store.remove(profile)
                                if selection == profile.id { selection = nil }
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: store.remove) // garde le geste/suppression via menu système
                }
            }
            .navigationTitle("Profils")
            .toolbar {
                // Nouveau
                ToolbarItem(placement: .automatic) {
                    Button { showNew = true } label: {
                        Label("Nouveau", systemImage: "plus")
                    }
                }
                // ⬇️ Supprimer (désactivé si rien sélectionné)
                ToolbarItem(placement: .automatic) {
                    Button(role: .destructive) {
                        if let id = selection,
                           let profile = store.profiles.first(where: { $0.id == id }) {
                            store.remove(profile)
                            selection = nil
                        }
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                    .disabled(selection == nil)
                    .keyboardShortcut(.delete) // touche Delete
                }
            }
            .navigationDestination(for: Profile.self) { profile in
                PlanetPositionsView(profile: profile)
            }
            .sheet(isPresented: $showNew) {
                NavigationStack {
                    ProfileFormView { newProfile in
                        store.add(newProfile)
                        showNew = false
                    }
                    .navigationTitle("Nouveau profil")
                }
                .frame(width: 760, height: 680)
                .padding()
            }
        }
        .frame(minWidth: 520, minHeight: 520)
    }
}

