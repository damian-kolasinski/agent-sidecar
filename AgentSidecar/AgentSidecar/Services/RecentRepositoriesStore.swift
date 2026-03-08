import Foundation

actor RecentRepositoriesStore {
    private static let defaultsKey = "recentRepositories"
    private static let maxEntries = 10

    private let defaults: UserDefaults
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [RecentRepository] {
        guard let data = defaults.data(forKey: Self.defaultsKey) else { return [] }
        return (try? decoder.decode([RecentRepository].self, from: data)) ?? []
    }

    func addOrUpdate(path: String) {
        var entries = load().filter { $0.path != path }
        let entry = RecentRepository(path: path, lastOpenedAt: Date())
        entries.insert(entry, at: 0)
        if entries.count > Self.maxEntries {
            entries = Array(entries.prefix(Self.maxEntries))
        }
        save(entries)
    }

    func remove(path: String) {
        var entries = load()
        entries.removeAll { $0.path == path }
        save(entries)
    }

    func clearAll() {
        defaults.removeObject(forKey: Self.defaultsKey)
    }

    private func save(_ entries: [RecentRepository]) {
        guard let data = try? encoder.encode(entries) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }
}
