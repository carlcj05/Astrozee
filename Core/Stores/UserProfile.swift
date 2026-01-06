//import Foundation

struct UserProfile: Codable, Equatable {
    var name: String
    var birthDate: Date
    var latitude: Double
    var longitude: Double
    var cityName: String
}

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    @Published var currentProfile: UserProfile?
    
    // Clé pour sauvegarder dans la mémoire de l'ordi
    private let saveKey = "SavedUserProfile"
    
    init() {
        load()
    }
    
    func save(profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
            self.currentProfile = profile
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.currentProfile = profile
        }
    }
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: saveKey)
        self.currentProfile = nil
    }
}
//  Astrozee
//
//  Created by Carl  Ozee on 06/01/2026.
//

