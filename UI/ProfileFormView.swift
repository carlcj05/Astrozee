import SwiftUI
import MapKit

struct ProfileFormView: View {
    var onSave: (Profile) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var birthLocalDate: Date = Date()

    @StateObject private var locationVM = LocationSearch()
    @State private var selectedCompletion: MKLocalSearchCompletion?
    @State private var placeName: String = ""
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var tzOffsetMinutes: Int = 0
    @State private var timeZoneIdentifier: String?

    struct MapPin: Identifiable { let id = UUID(); let coordinate: CLLocationCoordinate2D }
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
    )
    @State private var hasLocation = false

    @State private var isResolving = false
    @State private var errorMessage: String?

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && hasLocation
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                GroupBox("Identité") {
                    TextField("Nom du profil", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                GroupBox("Naissance (heure locale)") {
                    DatePicker("Date & heure", selection: $birthLocalDate, displayedComponents: [.date, .hourAndMinute])
                        .onChange(of: birthLocalDate) { _ in recomputeTimezoneOffsetIfPossible() }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ville de naissance")
                        HStack {
                            TextField("Tape une ville…", text: $locationVM.query)
                                .textFieldStyle(.roundedBorder)
                            Button("Rechercher") { searchTypedQuery() }
                                .disabled(locationVM.query.trimmingCharacters(in: .whitespaces).isEmpty)
                        }

                        // Suggestions (tap pour valider)
                        if !locationVM.suggestions.isEmpty {
                            List(locationVM.suggestions.indices, id: \.self) { i in
                                let item = locationVM.suggestions[i]
                                Button {
                                    select(completion: item)
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(item.title).bold()
                                        if !item.subtitle.isEmpty {
                                            Text(item.subtitle).font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(maxHeight: 180)
                        }

                        // Carte de confirmation
                        if hasLocation {
                            Map(coordinateRegion: $region,
                                annotationItems: [MapPin(coordinate: .init(latitude: latitude ?? 0, longitude: longitude ?? 0))]) { pin in
                                MapMarker(coordinate: pin.coordinate)
                            }
                            .frame(height: 220)
                            .cornerRadius(8)
                        }

                                            HStack {
                                                Text("Décalage fuseau (calculé)")
                                                Spacer()
                                                Text("\(tzOffsetMinutes) min").font(.headline).monospacedDigit()
                                            }
                                            .help("Calcul automatique selon la ville et la date (DST inclus).")
                                        }
                                    }

                                    GroupBox("Lieu (info)") {
                                        HStack { Text("Latitude");  Spacer(); Text(latitude.map { String(format: "%.5f", $0) } ?? "—") }
                                        HStack { Text("Longitude"); Spacer(); Text(longitude.map { String(format: "%.5f", $0) } ?? "—") }
                                        if !placeName.isEmpty { HStack { Text("Lieu"); Spacer(); Text(placeName) } }
                                    }

                                    if let msg = errorMessage { Text(msg).foregroundStyle(Color(hex: SystemColorHex.red)) }

                                    HStack {
                                        Button("Annuler") { dismiss() }
                                        Spacer()
                                        Button("Enregistrer", action: save).disabled(!canSave)
                                    }
                                }
                            .padding(20)
                            }
                            .task {
                                timeZoneIdentifier = TimeZone.current.identifier
                                tzOffsetMinutes = TimeZone.current.secondsFromGMT(for: birthLocalDate)/60
                            }
                        }

                        // MARK: - Actions
                        private func select(completion: MKLocalSearchCompletion) {
                            selectedCompletion = completion
                            Task { await resolve(from: completion) }
                        }

                        private func searchTypedQuery() {
                            Task {
                                do {
                                    if let item = try await locationVM.resolve(query: locationVM.query) {
                                        applyMapItem(item)
                                    } else {
                                        errorMessage = "Aucun résultat pour \(locationVM.query)"
                                    }
                                } catch {
                                    errorMessage = "Recherche impossible. Vérifie ta connexion internet."
                                }
                            }
                        }

                        private func resolve(from completion: MKLocalSearchCompletion) async {
                            isResolving = true
                            defer { isResolving = false }
                            do {
                                if let item = try await locationVM.resolve(completion: completion) {
                                    applyMapItem(item)
                                }
                            } catch {
                                errorMessage = "Impossible de trouver cette ville. Réessaie."
                            }
                        }

                        private func applyMapItem(_ mapItem: MKMapItem) {
                            placeName = mapItem.placemark.title ?? mapItem.name ?? locationVM.query
                            latitude  = mapItem.placemark.coordinate.latitude
                            longitude = mapItem.placemark.coordinate.longitude

                            let tz = mapItem.placemark.timeZone ?? TimeZone.autoupdatingCurrent
                            timeZoneIdentifier = tz.identifier
                            tzOffsetMinutes = tz.secondsFromGMT(for: birthLocalDate) / 60

                            region = MKCoordinateRegion(center: mapItem.placemark.coordinate,
                                                        span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35))
                            hasLocation = true
                        }

                        private func recomputeTimezoneOffsetIfPossible() {
                            guard hasLocation else { return }
                            let tz = timeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? TimeZone.autoupdatingCurrent
                            tzOffsetMinutes = tz.secondsFromGMT(for: birthLocalDate) / 60
                        }

                        private func save() {
                            let profile = Profile(
                                name: name.isEmpty ? "Profil" : name,
                                birthLocalDate: birthLocalDate,
                                tzOffsetMinutes: tzOffsetMinutes,
                                timeZoneIdentifier: timeZoneIdentifier,
                                placeName: placeName.isEmpty ? nil : placeName,
                                latitude: latitude,
                                longitude: longitude
                            )
                            onSave(profile)
                        }
                    }

