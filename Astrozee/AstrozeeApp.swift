import SwiftUI

@main
struct AstrozeeApp: App {
    // On crée le store une seule fois au démarrage
    @StateObject private var store = ProfileStore()

    var body: some Scene {
        WindowGroup {
            // On lance la vue liste et on lui donne le store
            ProfileListView()
                .environmentObject(store)
                .onAppear {
                    // On initialise le moteur C au lancement
                    Ephemeris.shared.bootstrap()
                }
        }
    }
}
