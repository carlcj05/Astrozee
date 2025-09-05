
import SwiftUI

@main
struct AstrozeeApp: App {
    @StateObject private var profileStore = ProfileStore()

    var body: some Scene {
        WindowGroup {
            ProfileListView()
                .environmentObject(profileStore)
                .onAppear { Ephemeris.shared.bootstrap() }
        }
    }
}
