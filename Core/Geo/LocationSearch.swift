import Foundation
import MapKit
import Combine

/// Autocomplétion de villes avec MapKit (macOS) — version déléguée
final class LocationSearch: NSObject, ObservableObject {
    @Published var query: String = ""
    @Published var suggestions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()
    private var bag = Set<AnyCancellable>()

    override init() {
        super.init()
        completer.resultTypes = .address
        completer.delegate = self

        $query
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.completer.queryFragment = text
            }
            .store(in: &bag)
    }

    /// Résout une suggestion en MKMapItem (coordonnées + time zone)
    func resolve(completion: MKLocalSearchCompletion) async throws -> MKMapItem? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems.first
    }

    /// Recherche directe à partir d'un texte libre (si l'utilisateur ne clique pas une suggestion)
    func resolve(query: String) async throws -> MKMapItem? {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = query
        req.resultTypes = .address
        let search = MKLocalSearch(request: req)
        let resp = try await search.start()
        return resp.mapItems.first
    }
}

extension LocationSearch: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async { [weak self] in
            self?.suggestions = completer.results
        }
    }
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.suggestions = []
        }
    }
}
