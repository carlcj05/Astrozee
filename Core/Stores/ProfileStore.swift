import Foundation


final class ProfileStore: ObservableObject {
    @Published private(set) var profiles: [Profile] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("profiles.json")
    }()

    init() { load() }

    func add(_ profile: Profile) { profiles.append(profile); save() }

    func update(_ profile: Profile) {
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[idx] = profile
            save()
        }
    }


    // déjà présent : suppression via IndexSet (glisser pour supprimer)
    func remove(at offsets: IndexSet) { profiles.remove(atOffsets: offsets); save() }

    // ⬇️ nouveau : suppression directe d’un profil (pour le bouton / menu contextuel)
    func remove(_ profile: Profile) {
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles.remove(at: idx)
            save()
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            profiles = try JSONDecoder().decode([Profile].self, from: data)
        } catch {
            print("[ProfileStore] Load error:", error)
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(profiles)
            try data.write(to: fileURL, options: .atomic)
            
        } catch {
            print("[ProfileStore] Save error:", error)
        }
    }
}
